import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:core/api/endpoints.dart';
import 'services/api_service.dart' as api;

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
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const HomeworkDashboardScreen(),
    );
  }
}

class Homework {
  final int? id;
  final String title;
  final String subject;
  final String description;
  final String dueDate;
  final String assignedDate;
  final String className;
  final int classId;
  final String priority;
  final bool isCompleted;

  Homework({
    this.id,
    required this.title,
    required this.subject,
    required this.description,
    required this.dueDate,
    required this.assignedDate,
    required this.className,
    required this.classId,
    required this.priority,
    this.isCompleted = false,
  });

  factory Homework.fromJson(Map<String, dynamic> json) {
    String className = 'Unknown';
    int classId = 0;
    if (json['class_obj'] != null) {
      className = "${json['class_obj']['name']} - ${json['class_obj']['section']}";
      classId = json['class_obj']['id'] ?? 0;
    }
    
    return Homework(
      id: json['id'],
      title: json['title'] ?? '',
      subject: json['subject'] ?? '',
      description: json['description'] ?? '',
      dueDate: json['due_date'] ?? '',
      assignedDate: json['assigned_date'] ?? '',
      className: className,
      classId: classId,
      priority: json['priority'] ?? 'Medium',
      isCompleted: json['is_completed'] ?? false,
    );
  }
}

class HomeworkDashboardScreen extends StatefulWidget {
  const HomeworkDashboardScreen({super.key});

  @override
  _HomeworkDashboardScreenState createState() => _HomeworkDashboardScreenState();
}

class _HomeworkDashboardScreenState extends State<HomeworkDashboardScreen> {
  List<Homework> _allHomework = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHomework();
  }

  Future<void> _loadHomework() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      final url = Endpoints.buildUrl(Endpoints.teacherHomework);
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        List<dynamic> data = [];
        
        if (decoded is Map && decoded.containsKey('results')) {
          data = decoded['results'];
        } else if (decoded is List) {
          data = decoded;
        }

        if (mounted) {
          setState(() {
            _allHomework = data.map((json) => Homework.fromJson(json)).toList();
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load homework');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteHomework(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      final response = await http.delete(
        Uri.parse('${Endpoints.buildUrl(Endpoints.teacherHomework)}$id/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 204) {
        _loadHomework();
      } else {
        throw Exception('Failed to delete homework');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _toggleCompletion(Homework homework) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      final response = await http.patch(
        Uri.parse('${Endpoints.buildUrl(Endpoints.teacherHomework)}${homework.id}/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'is_completed': !homework.isCompleted}),
      );

      if (response.statusCode == 200) {
        _loadHomework();
      } else {
        throw Exception('Failed to update homework');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Homeworks', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.indigo,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadHomework,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allHomework.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _allHomework.length,
                  itemBuilder: (context, index) {
                    return _buildHomeworkCard(_allHomework[index]);
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.indigo,
        onPressed: () => _showHomeworkForm(),
        label: const Text('Post Homework', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No homework assigned yet',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeworkCard(Homework homework) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          homework.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: homework.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text('${homework.subject} • ${homework.className}'),
        trailing: _buildPriorityBadge(homework.priority),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(homework.description, style: TextStyle(color: Colors.grey[800])),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Assigned: ${homework.assignedDate}', style: const TextStyle(fontSize: 12)),
                    Text('Due: ${homework.dueDate}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(
                        homework.isCompleted ? Icons.check_circle : Icons.check_circle_outline,
                        color: homework.isCompleted ? Colors.green : Colors.grey,
                      ),
                      onPressed: () => _toggleCompletion(homework),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showHomeworkForm(homework: homework),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDelete(homework),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color color;
    switch (priority.toLowerCase()) {
      case 'high':
        color = Colors.red;
        break;
      case 'medium':
        color = Colors.orange;
        break;
      default:
        color = Colors.green;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        priority,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _confirmDelete(Homework homework) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Homework'),
        content: const Text('Are you sure you want to delete this homework?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteHomework(homework.id!);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showHomeworkForm({Homework? homework}) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: HomeworkFormDialog(
          homework: homework,
          onSave: () => _loadHomework(),
        ),
      ),
    );
  }
}

class HomeworkFormDialog extends StatefulWidget {
  final Homework? homework;
  final VoidCallback onSave;

  const HomeworkFormDialog({super.key, this.homework, required this.onSave});

  @override
  _HomeworkFormDialogState createState() => _HomeworkFormDialogState();
}

class _HomeworkFormDialogState extends State<HomeworkFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _subjectController;
  late TextEditingController _descriptionController;
  String? _assignedDate;
  String? _dueDate;
  String? _priority;
  int? _selectedClassId;
  String? _selectedClassName;
  String? _selectedSection;
  List<dynamic> _classes = [];
  bool _isSaving = false;
  bool _isLoadingClasses = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.homework?.title ?? '');
    _subjectController = TextEditingController(text: widget.homework?.subject ?? '');
    _descriptionController = TextEditingController(text: widget.homework?.description ?? '');
    _assignedDate = widget.homework?.assignedDate;
    _dueDate = widget.homework?.dueDate;
    _priority = widget.homework?.priority;
    _selectedClassId = widget.homework?.classId;
    
    // Pre-populate name and section if editing
    if (widget.homework != null && widget.homework!.className.contains('-')) {
      final parts = widget.homework!.className.split('-');
      if (parts.length >= 2) {
        _selectedClassName = parts[0].trim();
        _selectedSection = parts[1].trim();
      }
    }

    _loadClasses();
  }

  void _updateSelectedClassId() {
    if (_selectedClassName != null && _selectedSection != null) {
      try {
        // Try to find a match in the loaded classes
        final match = _classes.firstWhere(
          (c) => c['name'].toString().trim() == _selectedClassName && 
                 c['section'].toString().trim() == _selectedSection,
          orElse: () => null,
        );
        
        setState(() {
          _selectedClassId = match != null ? match['id'] : null;
        });
      } catch (e) {
        print('Error resolving class ID: $e');
      }
    }
  }

  Future<void> _loadClasses() async {
    try {
      final classes = await api.ApiService.fetchTeacherClasses();
      if (mounted) {
        setState(() {
          _classes = classes;
          _isLoadingClasses = false;
          // Trigger resolution once classes are loaded
          if (_selectedClassName != null && _selectedSection != null) {
             _updateSelectedClassId();
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading classes: $e');
      if (mounted) {
        setState(() => _isLoadingClasses = false);
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isDueDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        final formatted = DateFormat('yyyy-MM-dd').format(picked);
        if (isDueDate) {
          _dueDate = formatted;
        } else {
          _assignedDate = formatted;
        }
      });
    }
  }

  Future<void> _saveHomework() async {
    bool validClass = _selectedClassId != null || (_selectedClassName != null && _selectedSection != null);
    bool validDates = _assignedDate != null && _dueDate != null;
    bool validPriority = _priority != null;
    
    if (!_formKey.currentState!.validate() || !validClass || !validDates || !validPriority) {
      if (!validClass) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a class and section')));
      } else if (!validDates) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select assigned and due dates')));
      } else if (!validPriority) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select priority')));
      }
      return;
    }

    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      final data = {
        'title': _titleController.text,
        'subject': _subjectController.text,
        'description': _descriptionController.text,
        'assigned_date': _assignedDate,
        'due_date': _dueDate,
        'priority': _priority?.toLowerCase(),
        'class_id': _selectedClassId, 
        'target_class': _selectedClassName, 
        'target_section': _selectedSection,
      };

      http.Response response;
      if (widget.homework == null) {
        response = await http.post(
          Uri.parse(Endpoints.buildUrl(Endpoints.teacherHomework)),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode(data),
        );
      } else {
        response = await http.put(
          Uri.parse('${Endpoints.buildUrl(Endpoints.teacherHomework)}${widget.homework!.id}/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode(data),
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        widget.onSave();
        if (mounted) {
           Navigator.of(context).pop();
        }
      } else {
        throw Exception('Failed to save homework: ${response.body}');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.homework == null ? 'Post New Homework' : 'Edit Homework',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Enter title' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Enter subject' : null,
              ),
              const SizedBox(height: 12),
              // --- Class & Section Selection ---
              Row(
                children: [
                   Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Class', border: OutlineInputBorder()),
                      value: _selectedClassName,
                      items: [
                        'Nursery', 'LKG', 'UKG',
                        ...List.generate(12, (index) => 'Class ${index + 1}')
                      ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) {
                         setState(() {
                           _selectedClassName = val;
                           _updateSelectedClassId();
                         });
                      },
                      validator: (v) => v == null ? 'Select Class' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Section', border: OutlineInputBorder()),
                      value: _selectedSection,
                      items: ['A', 'B', 'C', 'D']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedSection = val;
                          _updateSelectedClassId();
                        });
                      },
                      validator: (v) => v == null ? 'Select Section' : null,
                    ),
                  ),
                ],
              ),
              // ------------------------------------
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Enter description' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                   Expanded(
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Assigned Date',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(_assignedDate ?? 'Select Date'),
                        trailing: const Icon(Icons.calendar_today, size: 20),
                        onTap: () => _selectDate(context, false),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Due Date',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(_dueDate ?? 'Select Date'),
                        trailing: const Icon(Icons.calendar_today, size: 20),
                        onTap: () => _selectDate(context, true),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
                value: _priority?.toLowerCase(),
                hint: const Text('Select Priority'),
                items: ['low', 'medium', 'high'].map((p) => DropdownMenuItem(
                  value: p, 
                  child: Text(p[0].toUpperCase() + p.substring(1))
                )).toList(),
                onChanged: (val) => setState(() => _priority = val!),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _isSaving ? null : _saveHomework,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Save Homework', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ],
          ),
        ),
      ),
    );
  }
}
