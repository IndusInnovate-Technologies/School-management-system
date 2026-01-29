import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:main_login/main.dart' as main_login;
import 'main.dart' as app;
import 'dashboard.dart';
import 'package:core/api/api_service.dart';
import 'package:core/api/endpoints.dart';
import 'widgets/school_profile_header.dart';
import 'widgets/management_sidebar.dart';
import 'widgets/edit_exam_dialog.dart';
import 'widgets/add_exam_section.dart';

import 'models/examination.dart';
// Examination class moved to models/examination.dart

class ExaminationManagementPage extends StatefulWidget {
  const ExaminationManagementPage({super.key});

  @override
  State<ExaminationManagementPage> createState() =>
      _ExaminationManagementPageState();
}

class _ExaminationManagementPageState
    extends State<ExaminationManagementPage> {
  List<Examination> _allExams = [];
  late List<Examination> _visibleExams;
  
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool _isSubmitting = false;
  Timer? _statusCheckTimer;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _durationController = TextEditingController();
  final _marksController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  String? _newType;
  String? _newClass;
  String? _newSection;
  // String? _newSubject; // Changed to text controller
  final _subjectController = TextEditingController();
  DateTime? _newDate;
  TimeOfDay? _newTime;

  String _searchQuery = '';
  String? _statusFilter;
  String? _classFilter;

  // -- Helper Widgets --

  Widget _buildUserInfo() {
    return SchoolProfileHeader(apiService: ApiService());
  }

  Widget _buildBackButton() {
    return InkWell(
      onTap: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DashboardPage()),
      ),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C757D), Color(0xFF495057)],
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF495057).withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.arrow_back, size: 16, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Back to Dashboard',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }


  @override
  void initState() {
    super.initState();
    _visibleExams = List<Examination>.from(_allExams);
    _loadExaminations();
    // Start periodic status checking (every minute)
    _statusCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkAndUpdateExamStatuses();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    _marksController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _subjectController.dispose();
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  // -- API Methods --
  
  Future<void> _loadExaminations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.get(Endpoints.examinations);

      if (response.success && response.data != null) {
        List<Examination> exams = [];
        
        // Handle different response formats
        dynamic data = response.data;
        
        // If response is a list, use it directly
        if (data is List) {
          for (var item in data) {
            if (item is Map<String, dynamic>) {
              final exam = _parseExaminationFromJson(item);
              if (exam != null) {
                exams.add(exam);
              }
            }
          }
        }
        // If response is an object with a 'results' field (pagination)
        else if (data is Map<String, dynamic>) {
          if (data['results'] != null && data['results'] is List) {
            for (var item in data['results'] as List) {
              if (item is Map<String, dynamic>) {
                final exam = _parseExaminationFromJson(item);
                if (exam != null) {
                  exams.add(exam);
                }
              }
            }
          }
          // If data itself is a list-like structure
          else if (data['data'] != null && data['data'] is List) {
            for (var item in data['data'] as List) {
              if (item is Map<String, dynamic>) {
                final exam = _parseExaminationFromJson(item);
                if (exam != null) {
                  exams.add(exam);
                }
              }
            }
          }
        }

        setState(() {
          _allExams = exams;
          _filterExams();
        });
        
        // Check and update statuses immediately after loading
        _checkAndUpdateExamStatuses();
      } else {
        // Handle error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load examinations: ${response.error ?? "Unknown error"}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading examinations: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Examination? _parseExaminationFromJson(Map<String, dynamic> json) {
    try {
      // Parse dates and times from backend format
      DateTime? examDate;
      TimeOfDay? examTime;
      
      // Parse Exam_Date (DateTime field)
      if (json['Exam_Date'] != null) {
        if (json['Exam_Date'] is String) {
          examDate = DateTime.tryParse(json['Exam_Date']);
        } else if (json['Exam_Date'] is DateTime) {
          examDate = json['Exam_Date'];
        }
      }
      
      // Parse Exam_Time (Time field)
      if (json['Exam_Time'] != null) {
        if (json['Exam_Time'] is String) {
          // Parse time string (format: "HH:MM:SS" or "HH:MM")
          final timeStr = json['Exam_Time'] as String;
          final timeParts = timeStr.split(':');
          if (timeParts.length >= 2) {
            final hour = int.tryParse(timeParts[0]) ?? 0;
            final minute = int.tryParse(timeParts[1]) ?? 0;
            examTime = TimeOfDay(hour: hour, minute: minute);
          }
        }
      }
      
      // If Exam_Date contains time info, extract it
      if (examDate != null && examTime == null) {
        examTime = TimeOfDay(hour: examDate.hour, minute: examDate.minute);
        // Reset date to just the date part
        examDate = DateTime(examDate.year, examDate.month, examDate.day);
      }
      
      // Default values
      examDate ??= DateTime.now();
      examTime ??= TimeOfDay.now();

      return Examination(
        id: json['id'] ?? 0,
        title: json['Exam_Title'] ?? '',
        type: json['Exam_Type'] ?? '',
        date: examDate,
        time: examTime,
        grade: json['Exam_Class'] ?? json['Exam_Grade'] ?? json['grade'] ?? '', // Handle multiple formats
        subject: json['Exam_Subject'] ?? json['subject'] ?? '', // Handle both formats
        durationMinutes: json['Exam_Duration'] ?? 0,
        maxMarks: json['Exam_Marks'] ?? 0,
        description: json['Exam_Description'] ?? '',
        location: json['Exam_Location'] ?? '',
        status: json['Exam_Status'] ?? 'upcoming',
        section: json['Exam_Section'] ?? 'ALL',
      );
    } catch (e) {
      print('Error parsing examination: $e');
      return null;
    }
  }

  Map<String, dynamic> _examinationToJson(Examination exam) {
    // Combine date and time into a single DateTime for Exam_Date
    final examDateTime = DateTime(
      exam.date.year,
      exam.date.month,
      exam.date.day,
      exam.time.hour,
      exam.time.minute,
    );

    return {
      'Exam_Title': exam.title,
      'Exam_Type': exam.type,
      'Exam_Date': examDateTime.toIso8601String(),
      'Exam_Time': '${exam.time.hour.toString().padLeft(2, '0')}:${exam.time.minute.toString().padLeft(2, '0')}:00',
      'Exam_Subject': exam.subject,
      'Exam_Class': exam.grade,
      'Exam_Duration': exam.durationMinutes,
      'Exam_Marks': exam.maxMarks,
      'Exam_Description': exam.description,
      'Exam_Location': exam.location,
      'Exam_Status': exam.status,
      'Exam_Section': exam.section,
    };
  }

  // Check and update exam statuses based on current time
  Future<void> _checkAndUpdateExamStatuses() async {
    if (!mounted || _allExams.isEmpty) return;
    
    final now = DateTime.now();
    List<Map<String, dynamic>> updates = []; // Store {id, newStatus}
    
    for (var exam in _allExams) {
      // Only check upcoming and ongoing exams (skip completed)
      if (exam.status == 'completed') continue;
      
      // Create exam start DateTime
      final examStartDateTime = DateTime(
        exam.date.year,
        exam.date.month,
        exam.date.day,
        exam.time.hour,
        exam.time.minute,
      );
      
      // Calculate exam end time
      final examEndDateTime = examStartDateTime.add(
        Duration(minutes: exam.durationMinutes),
      );
      
      String? newStatus;
      
      // Check if exam should be ongoing
      if (exam.status == 'upcoming' && 
          now.isAfter(examStartDateTime.subtract(const Duration(seconds: 1))) && 
          now.isBefore(examEndDateTime)) {
        newStatus = 'ongoing';
      }
      // Check if exam should be completed
      else if (now.isAfter(examEndDateTime.subtract(const Duration(seconds: 1)))) {
        newStatus = 'completed';
      }
      
      // Only update if status actually changed
      if (newStatus != null && newStatus != exam.status) {
        updates.add({'id': exam.id, 'status': newStatus, 'exam': exam});
      }
    }
    
    // Update database and local state
    if (updates.isNotEmpty) {
      // Update in database
      for (var update in updates) {
        await _updateExamStatus(update['id'], update['status']);
      }
      
      // Update local state
      if (mounted) {
        setState(() {
          for (var update in updates) {
            final exam = update['exam'] as Examination;
            final newStatus = update['status'] as String;
            final index = _allExams.indexWhere((e) => e.id == exam.id);
            if (index != -1) {
              _allExams[index] = exam.copyWith(status: newStatus);
            }
          }
          _filterExams();
        });
      }
    }
  }

  // Update exam status in the database
  Future<void> _updateExamStatus(int examId, String newStatus) async {
    try {
      final response = await _apiService.patch(
        '${Endpoints.examinations}$examId/',
        body: {'Exam_Status': newStatus},
      );
      
      if (!response.success) {
        print('Failed to update exam status: ${response.error}');
      }
    } catch (e) {
      print('Error updating exam status: $e');
    }
  }

  void _filterExams() {
    setState(() {
      _visibleExams = _allExams.where((exam) {
        final matchesSearch = _searchQuery.isEmpty ||
            exam.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            exam.subject.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesStatus =
            _statusFilter == null || exam.status == _statusFilter;
        final matchesClass = _classFilter == null || exam.grade == _classFilter;
        return matchesSearch && matchesStatus && matchesClass;
      }).toList();
    });
  }

  Map<String, int> _stats() {
    final total = _allExams.length;
    final upcoming =
        _allExams.where((exam) => exam.status == 'upcoming').length;
    final completed =
        _allExams.where((exam) => exam.status == 'completed').length;
    final ongoing =
        _allExams.where((exam) => exam.status == 'ongoing').length;
    final avgScore = completed == 0
        ? 0
        : (_allExams
                .where((exam) => exam.status == 'completed')
                .fold<int>(0, (sum, exam) => sum + exam.maxMarks) /
            completed);
    return {
      'total': total,
      'upcoming': upcoming,
      'completed': completed,
      'ongoing': ongoing,
      'avg': avgScore.round(),
    };
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _newDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() => _newDate = date);
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _newTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => _newTime = time);
    }
  }

  Future<void> _addExam() async {
    if (!_formKey.currentState!.validate()) return;
    if (_newType == null ||
        _newClass == null ||
        _subjectController.text.isEmpty ||
        _newDate == null ||
        _newTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    // Prepare exam data
    final exam = Examination(
      id: 0, // Will be set by backend
      title: _titleController.text.trim(),
      type: _newType!,
      date: _newDate!,
      time: _newTime!,
      grade: _newClass!,
      subject: _subjectController.text.trim(),
      section: _newSection ?? 'ALL',
      durationMinutes: int.parse(_durationController.text.trim()),
      maxMarks: int.parse(_marksController.text.trim()),
      description: _descriptionController.text.trim(),
      location: _locationController.text.trim(),
      status: 'upcoming',
    );

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Convert to backend format
      final examData = _examinationToJson(exam);
      
      // Call API to create examination
      final response = await _apiService.post(
        Endpoints.examinations,
        body: examData,
      );

      if (response.success && response.data != null) {
        // Parse the created exam from response
        final createdExam = _parseExaminationFromJson(response.data);
        
        if (createdExam != null) {
          setState(() {
            _allExams.insert(0, createdExam);
            _filterExams();
          });

          // Clear form
          _formKey.currentState!.reset();
          _titleController.clear();
          _durationController.clear();
          _marksController.clear();
          _descriptionController.clear();
          _locationController.clear();
          setState(() {
            _newType = null;
            _newClass = null;
            _newSection = null;
            _subjectController.clear();
            _newDate = null;
            _newTime = null;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Examination added successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          throw Exception('Failed to parse created examination');
        }
      } else {
        throw Exception(response.error ?? 'Failed to create examination');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding examination: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _handleDeleteExam(Examination exam) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Examination'),
        content: Text('Are you sure you want to delete "${exam.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await _apiService.delete('${Endpoints.examinations}${exam.id}/');
        
        if (!response.success) {
            throw Exception(response.error ?? 'Failed to delete');
        }

        setState(() {
          _allExams.removeWhere((e) => e.id == exam.id);
          _filterExams();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Examination deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting: $e')),
          );
        }
      }
    }
  }

  Future<void> _handleEditExam(Examination exam) async {
      await showDialog(
        context: context,
        builder: (context) => EditExamDialog(
          exam: exam, 
          onUpdate: (id, data) async {
             final response = await _apiService.put(
                '${Endpoints.examinations}$id/',
                body: data
             );
             
             if (response.success) {
                 final updatedExam = _parseExaminationFromJson(response.data);
                 if (updatedExam != null) {
                    setState(() {
                        final index = _allExams.indexWhere((e) => e.id == id);
                        if (index != -1) {
                            _allExams[index] = updatedExam;
                            _filterExams();
                        }
                    });
                     if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Examination updated successfully!')),
                        );
                    }
                 }
             } else {
                 throw Exception(response.error ?? 'Failed to update');
             }
          }
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final gradient = const LinearGradient(
      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    final stats = _stats();

    return LayoutBuilder(
      builder: (context, constraints) {
        final showSidebar = constraints.maxWidth >= 1100;
        return Scaffold(
          key: _scaffoldKey,
          drawer: showSidebar
              ? null
              : Drawer(
                  child: SizedBox(
                    width: 280,
                    child: ManagementSidebar(gradient: gradient, activeRoute: '/examinations'),
                  ),
                ),
          body: Row(
            children: [
              if (showSidebar) ManagementSidebar(gradient: gradient, activeRoute: '/examinations'),
              Expanded(
                child: Container(
                  color: const Color(0xFFF5F6FA),
                  child: SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- TOP HEADER ---
                          GlassContainer(
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                            margin: const EdgeInsets.only(bottom: 30),
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Examination Management',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF333333),
                                    ),
                                  ),
                                ),
                                _buildUserInfo(),
                                const SizedBox(width: 20),
                                _buildBackButton(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          _StatsOverview(stats: stats),
                          const SizedBox(height: 24),
                          LayoutBuilder(
                            builder: (context, inner) {
                              final stacked = inner.maxWidth < 1100;
                              return Flex(
                                mainAxisSize: MainAxisSize.min,
                                direction:
                                    stacked ? Axis.vertical : Axis.horizontal,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              if (ApiService().userRole != 'financial')
                                Flexible(
                                  fit: FlexFit.loose,
                                  child: AddExamSection(
                                      formKey: _formKey,
                                      titleController: _titleController,
                                      typeValue: _newType,
                                      onTypeChanged: (value) =>
                                          setState(() => _newType = value),
                                      dateValue: _newDate,
                                      onPickDate: _pickDate,
                                      timeValue: _newTime,
                                      onPickTime: _pickTime,
                                      classValue: _newClass,
                                      onClassChanged: (value) =>
                                          setState(() => _newClass = value),
                                      sectionValue: _newSection,
                                      onSectionChanged: (value) =>
                                          setState(() => _newSection = value),
                                      subjectController: _subjectController,
                                      // subjectValue: _newSubject,
                                      // onSubjectChanged: (value) =>
                                      //     setState(() => _newSubject = value),
                                      durationController: _durationController,
                                      marksController: _marksController,
                                      descriptionController:
                                          _descriptionController,
                                      locationController: _locationController,
                                      onSubmit: _addExam,
                                      isSubmitting: _isSubmitting,
                                    ),
                                  ),
                                  SizedBox(
                                    width: stacked ? 0 : 24,
                                    height: stacked ? 24 : 0,
                                  ),
                              Flexible(
                                fit: FlexFit.loose,
                                    child: _SearchFilterSection(
                                      searchQuery: _searchQuery,
                                      onSearchChanged: (value) {
                                        setState(() => _searchQuery = value);
                                        _filterExams();
                                      },
                                      statusFilter: _statusFilter,
                                      onStatusChanged: (value) {
                                        setState(() => _statusFilter = value);
                                        _filterExams();
                                      },
                                      classFilter: _classFilter,
                                      onClassChanged: (value) {
                                        setState(() => _classFilter = value);
                                        _filterExams();
                                      },
                                      exams: _visibleExams,
                                      isLoading: _isLoading,
                                      onEdit: _handleEditExam,
                                      onDelete: _handleDeleteExam,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}



class _StatsOverview extends StatelessWidget {
  final Map<String, int> stats;

  const _StatsOverview({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 24),
      child: GridView.count(
        crossAxisCount: 4,
        childAspectRatio: 1.0,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        children: [
          _StatCard(
            label: 'Total Exams',
            value: '${stats['total']}',
            icon: '📝',
            color: const Color(0xFF667EEA),
          ),
          _StatCard(
            label: 'Upcoming',
            value: '${stats['upcoming']}',
            icon: '📅',
            color: Colors.orange,
          ),
          _StatCard(
            label: 'Completed',
            value: '${stats['completed']}',
            icon: '✅',
            color: Colors.green,
          ),
          _StatCard(
            label: 'Avg Marks',
            value: '${stats['avg']}%',
            icon: '📈',
            color: Colors.blue,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: TextStyle(fontSize: 40, color: color)),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF666666),
                fontSize: 12,
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

// Import moved widget


// Removed classes _AddExamSection, _DatePickerField, _TimePickerField as they are now in widgets/add_exam_section.dart

class _SearchFilterSection extends StatelessWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final String? statusFilter;
  final ValueChanged<String?> onStatusChanged;
  final String? classFilter;
  final ValueChanged<String?> onClassChanged;
  final List<Examination> exams;
  final bool isLoading;
  final Function(Examination) onEdit;
  final Function(Examination) onDelete;

  const _SearchFilterSection({
    required this.searchQuery,
    required this.onSearchChanged,
    required this.statusFilter,
    required this.onStatusChanged,
    required this.classFilter,
    required this.onClassChanged,
    required this.exams,
    required this.isLoading,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🔍 Search & Filter',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search examinations...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: statusFilter,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Status')),
                    DropdownMenuItem(value: 'upcoming', child: Text('Upcoming')),
                    DropdownMenuItem(value: 'ongoing', child: Text('Ongoing')),
                    DropdownMenuItem(value: 'completed', child: Text('Completed')),
                  ],
                  onChanged: onStatusChanged,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: classFilter,
                  decoration: InputDecoration(
                    labelText: 'Class',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Classes')),
                    ..._classOptions,
                  ],
                  onChanged: onClassChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (exams.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No examinations found',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            _ExamGrid(exams: exams, onEdit: onEdit, onDelete: onDelete),
        ],
      ),
    );
  }
}

class _ExamGrid extends StatelessWidget {
  final List<Examination> exams;
  final Function(Examination) onEdit;
  final Function(Examination) onDelete;

  const _ExamGrid({
    required this.exams,
    required this.onEdit,
    required this.onDelete,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'upcoming':
        return const Color(0xFFFEEBC8);
      case 'ongoing':
        return const Color(0xFFC6F6D5);
      case 'completed':
        return const Color(0xFFBEE3F8);
      default:
        return Colors.grey.shade200;
    }
  }

  Color _statusTextColor(String status) {
    switch (status) {
      case 'upcoming':
        return const Color(0xFF7B341E);
      case 'ongoing':
        return const Color(0xFF2F855A);
      case 'completed':
        return const Color(0xFF2C5282);
      default:
        return Colors.black54;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (exams.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: const [
            Icon(Icons.error_outline, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('No examinations match your filters'),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        mainAxisExtent: 300,
      ),
      itemCount: exams.length,
      itemBuilder: (context, index) {
        final exam = exams[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border(
              left: BorderSide(
                color: _statusTextColor(exam.status),
                width: 5,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Expanded(
                    child: Text(
                      exam.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit(exam);
                      } else if (value == 'delete') {
                        onDelete(exam);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _Chip(label: exam.type.replaceAll('-', ' ').toUpperCase()),
                  _Chip(label: exam.grade.replaceAll('-', ' ').toUpperCase()),
                  _Chip(label: 'Sec: ${exam.section}'),
                  _Chip(label: exam.subject.replaceAll('-', ' ').toUpperCase()),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Date: ${exam.date.day}/${exam.date.month}/${exam.date.year}',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'Time: ${exam.time.format(context)}',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'Duration: ${exam.durationMinutes} mins',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'Max Marks: ${exam.maxMarks}',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'Location: ${exam.location.isEmpty ? 'TBA' : exam.location}',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.bottomLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusColor(exam.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    exam.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _statusTextColor(exam.status),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _showStudentsDialog(BuildContext context, Examination exam) {
    showDialog(
      context: context,
      builder: (context) => _ExamStudentsDialog(exam: exam),
    );
  }
}

class _ExamStudentsDialog extends StatefulWidget {
  final Examination exam;

  const _ExamStudentsDialog({required this.exam});

  @override
  State<_ExamStudentsDialog> createState() => _ExamStudentsDialogState();
}

class _ExamStudentsDialogState extends State<_ExamStudentsDialog> {
  List<dynamic> _students = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    try {
      final apiService = ApiService();
      // Mocking fetch logic - in real app, filter by class and section from backend
      // Assuming GET /api/management/students/ has filters
      // Mapping class-1 -> 1, etc.
      String classFilter = widget.exam.grade; // e.g., "class-1"
      String sectionFilter = widget.exam.section;
      
      // Fetch all students (optimize with backend filters if available)
      final response = await apiService.get(Endpoints.students);
      
      if (response.success && response.data != null) {
        List<dynamic> allStudents = [];
        if (response.data is List) {
          allStudents = response.data;
        } else if (response.data is Map && (response.data as Map)['results'] != null) {
          allStudents = (response.data as Map)['results'];
        }

        // Filter locally if backend doesn't support complex filtering yet
        // This is a temporary solution until backend search is optimized
        final filtered = allStudents.where((student) {
             // Basic matching logic
             final studentClass = student['applying_class'] ?? student['class_name'] ?? '';
             final studentSection = student['grade'] ?? ''; // Assuming 'grade' field holds section (A, B, C...) or use proper field
             
             // Normalize strings
             final sClassNorm = studentClass.toString().toLowerCase().replaceAll(' ', '-'); // "class 1" -> "class-1"
             final eClassNorm = classFilter.toLowerCase();
             
             bool classMatch = sClassNorm.contains(eClassNorm) || eClassNorm.contains(sClassNorm);
             bool sectionMatch = sectionFilter == 'ALL' || studentSection.toString().toUpperCase() == sectionFilter;
             
             return classMatch && sectionMatch;
        }).toList();

        if (mounted) {
          setState(() {
            _students = filtered;
            _isLoading = false;
          });
        }
      } else {
         if (mounted) setState(() => _error = 'Failed to load students');
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          width: 600,
          height: 500,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Text(
                'Students for ${widget.exam.title}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                'Class: ${widget.exam.grade}, Section: ${widget.exam.section}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (_error.isNotEmpty)
                Expanded(child: Center(child: Text(_error, style: const TextStyle(color: Colors.red))))
              else if (_students.isEmpty)
                const Expanded(child: Center(child: Text('No students found for this class and section.')))
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: _students.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final student = _students[index];
                      final name = student['student_name'] ?? student['user']?['first_name'] ?? 'Unknown';
                      final id = student['student_id'] ?? 'N/A';
                      return ListTile(
                        leading: CircleAvatar(child: Text(name[0])),
                        title: Text(name),
                        subtitle: Text('ID: $id'),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              )
            ],
          ),
        ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;

  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, color: Colors.black54),
      ),
    );
  }
}

List<DropdownMenuItem<String>> get _classOptions => const [
      DropdownMenuItem(value: 'class-1', child: Text('Class 1')),
      DropdownMenuItem(value: 'class-2', child: Text('Class 2')),
      DropdownMenuItem(value: 'class-3', child: Text('Class 3')),
      DropdownMenuItem(value: 'class-4', child: Text('Class 4')),
      DropdownMenuItem(value: 'class-5', child: Text('Class 5')),
      DropdownMenuItem(value: 'class-6', child: Text('Class 6')),
      DropdownMenuItem(value: 'class-7', child: Text('Class 7')),
      DropdownMenuItem(value: 'class-8', child: Text('Class 8')),
      DropdownMenuItem(value: 'class-9', child: Text('Class 9')),
      DropdownMenuItem(value: 'class-10', child: Text('Class 10')),
      DropdownMenuItem(value: 'class-11', child: Text('Class 11')),
      DropdownMenuItem(value: 'class-12', child: Text('Class 12')),
    ];

List<DropdownMenuItem<String>> get _subjectOptions => const [
      DropdownMenuItem(value: 'mathematics', child: Text('Mathematics')),
      DropdownMenuItem(value: 'science', child: Text('Science')),
      DropdownMenuItem(value: 'english', child: Text('English')),
      DropdownMenuItem(value: 'hindi', child: Text('Hindi')),
      DropdownMenuItem(value: 'social-studies', child: Text('Social Studies')),
      DropdownMenuItem(value: 'computer-science', child: Text('Computer Science')),
      DropdownMenuItem(value: 'physics', child: Text('Physics')),
      DropdownMenuItem(value: 'chemistry', child: Text('Chemistry')),
      DropdownMenuItem(value: 'biology', child: Text('Biology')),
    ];



// Glass Container Widget
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool drawRightBorder;
  final double borderRadius;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.drawRightBorder = false,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final radius = drawRightBorder
        ? BorderRadius.zero
        : BorderRadius.circular(borderRadius);

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: radius,
              border: Border(
                right: drawRightBorder
                    ? BorderSide(color: Colors.white.withValues(alpha: 0.2))
                    : BorderSide.none,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 24,
                  offset: const Offset(2, 6),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
