import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/api_service.dart' as api;

class TeacherTasksScreen extends StatefulWidget {
  @override
  _TeacherTasksScreenState createState() => _TeacherTasksScreenState();
}

class _TeacherTasksScreenState extends State<TeacherTasksScreen> {
  List<dynamic> tasks = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  Future<void> fetchTasks() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await api.ApiService.authenticatedRequest(
        'teacher/tasks/',
        method: 'GET',
      );

      debugPrint('Tasks response status: ${response.statusCode}');
      debugPrint('Tasks response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          // Handle both paginated (with 'results' key) and non-paginated responses
          if (data is Map && data.containsKey('results')) {
            tasks = data['results'] is List ? data['results'] : [];
          } else if (data is List) {
            tasks = data;
          } else {
            tasks = [];
          }
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load tasks: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Exception loading tasks: $e');
      setState(() {
        errorMessage = 'Error loading tasks: $e';
        isLoading = false;
      });
    }
  }

  Color _getPriorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(errorMessage, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: fetchTasks,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : tasks.isEmpty
                  ? const Center(
                      child: Text(
                        'No tasks yet. Create one from the dashboard!',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: fetchTasks,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.task_alt,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              task['title'] ?? 'Untitled Task',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getPriorityColor(task['priority']).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          task['priority']?.toUpperCase() ?? 'MEDIUM',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: _getPriorityColor(task['priority']),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (task['description'] != null && task['description'].toString().isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: Text(
                                        task['description'],
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Due: ${task['due_date'] ?? 'Not set'}',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                      const SizedBox(width: 16),
                                      if (task['category'] != null)
                                        Chip(
                                          label: Text(
                                            task['category'].toString().toUpperCase(),
                                            style: const TextStyle(fontSize: 10),
                                          ),
                                          backgroundColor: Colors.purple.shade50,
                                          padding: EdgeInsets.zero,
                                        ),
                                      const Spacer(),
                                      if (task['class_obj'] != null && task['class_obj']['name'] != null)
                                        Chip(
                                          label: Text(
                                            'Class ${task['class_obj']['name']} ${task['class_obj']['section'] ?? ''}',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                          backgroundColor: Colors.blue.shade50,
                                        )
                                      else if (task['subject'] != null && task['subject'] != 'General')
                                        Chip(
                                          label: Text(
                                            'Class ${task['subject']}',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                          backgroundColor: Colors.blue.shade50,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () {
                                          _viewTask(task);
                                        },
                                        icon: const Icon(Icons.visibility, size: 16),
                                        label: const Text('View'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(0xFF667eea),
                                          side: const BorderSide(color: Color(0xFF667eea)),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          _editTask(task);
                                        },
                                        icon: const Icon(Icons.edit, size: 16),
                                        label: const Text('Edit'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF667eea),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          _deleteTask(task['id']);
                                        },
                                        icon: const Icon(Icons.delete, size: 16),
                                        label: const Text('Delete'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  void _viewTask(Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task['title'] ?? 'Task Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Description', task['description'] ?? 'No description'),
              _buildDetailRow('Category', task['category']?.toUpperCase() ?? 'N/A'),
              _buildDetailRow('Priority', task['priority']?.toUpperCase() ?? 'N/A'),
              _buildDetailRow('Due Date', task['due_date'] ?? 'Not set'),
              if (task['class_obj'] != null && task['class_obj']['name'] != null)
                _buildDetailRow('Class', 'Class ${task['class_obj']['name']} ${task['class_obj']['section'] ?? ''}'),
              _buildDetailRow('Created', task['created_at'] ?? 'N/A'),
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

  Future<void> _deleteTask(int taskId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await api.ApiService.authenticatedRequest(
          'teacher/tasks/$taskId/',
          method: 'DELETE',
        );

        if (response.statusCode == 204) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Task deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          fetchTasks();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editTask(Map<String, dynamic> task) {
    final titleController = TextEditingController(text: task['title']);
    final descriptionController = TextEditingController(text: task['description']);
    final subjectController = TextEditingController(text: task['subject']);
    final dueDateController = TextEditingController(
      text: task['due_date']?.split('T')[0] ?? '',
    );
    String selectedCategory = task['category'] ?? 'homework';
    String selectedPriority = task['priority'] ?? 'medium';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: ['homework', 'assignment', 'project', 'exam', 'other']
                      .map((cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(cat.toUpperCase()),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value!;
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedPriority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items: ['low', 'medium', 'high']
                      .map((pri) => DropdownMenuItem(
                            value: pri,
                            child: Text(pri.toUpperCase()),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedPriority = value!;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dueDateController,
                  decoration: const InputDecoration(
                    labelText: 'Due Date (YYYY-MM-DD)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                // Prepare update data
                final updateData = {
                  'title': titleController.text,
                  'subject': subjectController.text,
                  'description': descriptionController.text,
                  'category': selectedCategory,
                  'priority': selectedPriority,
                  'due_date': dueDateController.text,
                };

                try {
                  final response = await api.ApiService.authenticatedRequest(
                    'teacher/tasks/${task['id']}/',
                    method: 'PATCH',
                    body: updateData,
                  );

                  if (response.statusCode == 200) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Task updated successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    fetchTasks(); // Refresh the list
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update: ${response.statusCode}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating task: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
