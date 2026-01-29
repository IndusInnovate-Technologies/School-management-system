import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Mock Data for Subjects, Classes, and Sections ---
const List<String> allSubjects = [
  'Mathematics',
  'General Science',   
  'Social Studies',
  'Language I/II/III',
  'Physics',
  'Chemistry',
  'Biology',
  'English Core',
  'Computer Science',
  'History/Civics/Geography',
  'English Language/Literature',
  'Psychology',
  'Economics',
  'Art',
  'Music',
  'History',
];



// --- Model Class: Homework ---
class Homework {
  final int id;
  String title;
  String subject;
  final int classId;
  String className;
  String section;
  DateTime assignedDate;
  DateTime dueDate;
  String description;
  String priority;
  bool isCompleted;

  Homework({
    required this.id,
    required this.title,
    required this.subject,
    required this.classId,
    required this.className,
    required this.section,
    required this.assignedDate,
    required this.dueDate,
    required this.description,
    this.priority = 'Medium',
    this.isCompleted = false,
  });

  Homework copyWith({
    int? id,
    String? title,
    String? subject,
    int? classId,
    String? className,
    String? section,
    DateTime? assignedDate,
    DateTime? dueDate,
    String? description,
    String? priority,
    bool? isCompleted,
  }) {
    return Homework(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      section: section ?? this.section,
      assignedDate: assignedDate ?? this.assignedDate,
      dueDate: dueDate ?? this.dueDate,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

// --- Main Application Widget ---
void main() {
  runApp(const HomeworkApp());
}

class HomeworkApp extends StatelessWidget {
  const HomeworkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Homework Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        fontFamily: 'Segoe UI',
      ),
      home: const HomeworkDashboardScreen(),
    );
  }
}

// --- Dashboard Screen ---
class HomeworkDashboardScreen extends StatefulWidget {
  const HomeworkDashboardScreen({super.key});

  @override
  State<HomeworkDashboardScreen> createState() =>
      _HomeworkDashboardScreenState();
}

class _HomeworkDashboardScreenState extends State<HomeworkDashboardScreen> {
  late List<Homework> homeworkList;
  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd');


  // Filter state
  String _filterStatus = 'All';
  String? _filterSubject;
  String? _filterClass;
  String? _filterSection;

  @override
  void initState() {
    super.initState();
    homeworkList = [];
    _loadHomework();
  }



  Future<void> _loadHomework() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Try to get student ID from various possible keys
      String? studentId = prefs.getString('selected_student_id') ?? prefs.getString('student_id');
      
      print('DEBUG: Loading homework for studentId: $studentId');

      final dataList = await ApiService.fetchHomework(studentId: studentId);
      
      // Load locally saved completed homework IDs
      // Safe guard: use 'all' if studentId is null, but we expect it to be set now
      String key = 'completed_homework_ids_student_${studentId ?? "default"}';
      final List<String> savedCompletedIds = prefs.getStringList(key) ?? [];
      
      print('DEBUG: Found ${savedCompletedIds.length} locally completed items for $key');

      if (dataList != null) {
        setState(() {
          homeworkList = dataList.map((json) {
            dynamic classObj = json['class_obj'];
            String classNameVal = 'Unknown Class';
            String sectionVal = '';
            int classIdVal = 0;

            if (classObj is Map) {
               classIdVal = classObj['id'] is int ? classObj['id'] : int.tryParse(classObj['id'].toString()) ?? 0;
               classNameVal = classObj['name']?.toString() ?? 'Unknown Class';
               sectionVal = classObj['section']?.toString() ?? '';
            } else if (json['className'] != null) {
               classNameVal = json['className'].toString();
            }
            
            int hwId = json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0;
            
            // Persistent logic: check both local storage and API
            bool isLocallyCompleted = savedCompletedIds.contains(hwId.toString());
            bool isApiCompleted = json['is_completed'] == true || json['status'] == 'completed';

            return Homework(
              id: hwId,
              title: json['title'] as String? ?? 'Untitled',
              subject: json['subject'] as String? ?? 'General',
              classId: classIdVal,
              className: classNameVal,
              section: sectionVal,
              assignedDate: DateTime.parse(json['assigned_date'] ?? json['assignedDate'] ?? DateTime.now().toString()),
              dueDate: DateTime.parse(json['due_date'] ?? json['dueDate'] ?? DateTime.now().toString()),
              description: json['description'] as String? ?? '',
              priority: (json['priority'] as String? ?? 'medium'),
              isCompleted: isLocallyCompleted || isApiCompleted, 
            );
          }).toList();
        });
      }
    } catch (e) {
      print('Exception loading homework: $e');
      _showSnackBar('Connection error: $e');
    }
  }

  Future<void> _updateHomework(Homework updatedHomework) async {
    setState(() {
      final index = homeworkList.indexWhere((h) => h.id == updatedHomework.id);
      if (index != -1) {
        homeworkList[index] = updatedHomework;
      }
    });

    if (updatedHomework.isCompleted) {
        try {
            final prefs = await SharedPreferences.getInstance();
            String? studentId = prefs.getString('selected_student_id') ?? prefs.getString('student_id');
            String key = 'completed_homework_ids_student_${studentId ?? "default"}';
            
            List<String> savedIds = prefs.getStringList(key) ?? [];
            if (!savedIds.contains(updatedHomework.id.toString())) {
                savedIds.add(updatedHomework.id.toString());
                await prefs.setStringList(key, savedIds);
                print('DEBUG: Locked homework ${updatedHomework.id} in $key');
            }
        } catch (e) {
            print('Error saving local homework status: $e');
        }
    }
    _showSnackBar('Homework marked as completed!');
  }





  Map<String, dynamic> getHomeworkStatus(Homework homework) {
    if (homework.isCompleted) {
      return {'text': 'Completed', 'color': Colors.blue};
    }

    final now = DateTime.now().copyWith(
      hour: 0,
      minute: 0,
      second: 0,
      millisecond: 0,
    );
    final due = homework.dueDate.copyWith(
      hour: 0,
      minute: 0,
      second: 0,
      millisecond: 0,
    );
    final diffDays = due.difference(now).inDays;

    if (diffDays < 0) {
      return {'text': 'Overdue', 'color': Colors.redAccent};
    } else if (diffDays <= 1) {
      return {'text': 'Due Soon', 'color': Colors.amber.shade700};
    } else {
      return {'text': 'Active', 'color': Colors.green};
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'immediate':
        return Colors.red.shade700;
      case 'high':
        return Colors.orange.shade700;
      case 'medium':
        return Colors.blue.shade600;
      case 'low':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  List<Homework> get filteredHomework {
    return homeworkList.where((homework) {
      // Status filter
      if (_filterStatus == 'Pending' && homework.isCompleted) return false;
      if (_filterStatus == 'Completed' && !homework.isCompleted) return false;
      if (_filterStatus == 'Overdue') {
        final status = getHomeworkStatus(homework);
        if (status['text'] != 'Overdue') return false;
      }

      // Subject filter
      if (_filterSubject != null && homework.subject != _filterSubject) {
        return false;
      }

      // Class filter
      if (_filterClass != null && homework.className != _filterClass) {
        return false;
      }

      // Section filter
      if (_filterSection != null && homework.section != _filterSection) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filteredHomework;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Homework Management'),
        backgroundColor: const Color(0xFF667eea),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Section Removed
        
          // Stats Overview
          _buildStatsOverview(),

          // Homework List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No homework found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                         // Debug Info Button (Hidden in prod, useful now)
                        TextButton(
                          onPressed: _loadHomework,
                          child: const Text('Refresh'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final homework = filtered[index];
                      return _buildHomeworkCard(homework);
                    },
                  ),
          ),
        ],
      ),

    );
  }



  Widget _buildHomeworkCard(Homework homework) {
    final status = getHomeworkStatus(homework);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: status['color'],
          width: 2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showHomeworkDetails(homework),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      homework.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: status['color'],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status['text'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.subject, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    homework.subject,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.class_, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${homework.className} - ${homework.section}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Assigned: ${_dateFormatter.format(homework.assignedDate)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.event, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Due: ${_dateFormatter.format(homework.dueDate)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.flag, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(homework.priority),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      homework.priority,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                homework.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Edit and Delete buttons removed for Parent App
                  ElevatedButton.icon(
                    onPressed: homework.isCompleted
                        ? null // Disable if already completed
                        : () {
                            // Only allow marking as completed
                            setState(() {
                              final updated =
                                  homework.copyWith(isCompleted: true);
                              _updateHomework(updated);
                            });
                          },
                    icon: Icon(
                      homework.isCompleted
                          ? Icons.check_circle
                          : Icons.check_circle_outline,
                      size: 18,
                    ),
                    label: Text(
                        homework.isCompleted ? 'Completed' : 'Mark as Completed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: homework.isCompleted
                          ? Colors.grey // Visual indication of disabled state
                          : const Color(0xFF51cf66),
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHomeworkDetails(Homework homework) {
    final status = getHomeworkStatus(homework);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(homework.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Subject', homework.subject),
              _buildDetailRow('Class', homework.className),
              _buildDetailRow('Section', homework.section),
              _buildDetailRow(
                'Assigned Date',
                _dateFormatter.format(homework.assignedDate),
              ),
              _buildDetailRow(
                'Due Date',
                _dateFormatter.format(homework.dueDate),
              ),
              _buildDetailRow('Priority', homework.priority),
              _buildDetailRow('Status', status['text']),
              const SizedBox(height: 12),
              const Text(
                'Description:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                homework.description,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview() {
    int total = homeworkList.length;
    int completed = homeworkList.where((h) => h.isCompleted).length;
    int pending = total - completed;
    int overdue = homeworkList.where((h) {
      if (h.isCompleted) return false;
      final status = getHomeworkStatus(h);
      return status['text'] == 'Overdue';
    }).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        children: [
          _buildStatCard('Total', total.toString(), const Color(0xFF5A67C4)),
          const SizedBox(width: 12),
          _buildStatCard('Pending', pending.toString(), const Color(0xFFF39C12)),
          const SizedBox(width: 12),
          _buildStatCard('Completed', completed.toString(), const Color(0xFF27AE60)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String count, Color barColor) {
    return Expanded(
      child: Container(
        height: 100, // Balanced height
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Bar
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    count,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: barColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}



