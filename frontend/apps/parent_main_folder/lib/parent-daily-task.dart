// Mobile Version of Daily Tasks Page

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'services/api_service.dart' as api;

void main() => runApp(const DailyTasksApp());

class DailyTasksApp extends StatelessWidget {
  const DailyTasksApp({super.key});

  // Custom MaterialColor utility (retained for completeness)
  MaterialColor createMaterialColor(Color color) {
    List strengths = <double>[.05, .1, .2, .3, .4, .5, .6, .7, .8, .9];
    Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 0; i < 10; i++) {
      int strengthKey = (strengths[i] * 1000).round();
      if (strengthKey < 100) strengthKey = 50;
      swatch[strengthKey] = Color.fromRGBO(r, g, b, strengths[i]);
    }
    return MaterialColor(color.value, swatch);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Tasks - School Management System',
      theme: ThemeData(
        fontFamily: 'Segoe UI',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.indigo)
            .copyWith(
              secondary: const Color(
                0xff28a745,
              ), // A secondary color for accents
              primary: const Color(
                0xFF3F51B5,
              ), // Explicit primary color (Indigo 500)
            ),
      ),
      home: const DailyTasksPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Task {
  final int id;
  String title;
  String description;
  String category;
  String priority;
  String status;
  String dueDate;
  String subject;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.dueDate,
    required this.subject,
  });
}

class DailyTasksPage extends StatefulWidget {
  const DailyTasksPage({super.key});

  @override
  State<DailyTasksPage> createState() => _DailyTasksPageState();
}

class _DailyTasksPageState extends State<DailyTasksPage>
    with SingleTickerProviderStateMixin {
  List<Task> dailyTasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    try {
      final response = await api.ApiService.authenticatedRequest('student-parent/tasks/', method: 'GET');
      if (response.statusCode == 200) {
        final dynamic rawData = json.decode(response.body);
        final List<dynamic> data;
         if (rawData is List) {
          data = rawData;
        } else if (rawData is Map && rawData.containsKey('results')) {
          data = rawData['results'];
        } else {
          data = [];
        }

        setState(() {
          dailyTasks = data.map((json) {
            return Task(
              id: json['id'],
              title: json['title'] ?? 'Untitled',
              description: json['description'] ?? '',
              category: json['category'] ?? 'homework',
              priority: json['priority'] ?? 'medium',
              status: 'pending', // Task model in backend doesn't track status per student yet, assuming pending
              dueDate: json['due_date'] ?? '',
              subject: json['subject'] ?? 'General',
            );
          }).toList();
          _isLoading = false;
        });
      } else {
         setState(() => _isLoading = false);
         debugPrint('Failed to load tasks: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error: $e');
    }
  }

  String currentFilter = 'all';
  late TabController _tabController;



  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- Task Management Methods ---
  void _completeTask(Task task) {
    setState(() {
      task.status = 'completed';
      _showSnack('Task "${task.title}" completed! Good job. 🎉');
    });
  }

  void _deleteTask(Task task) {
    setState(() {
      dailyTasks.remove(task);
      _showSnack('Task "${task.title}" deleted.');
    });
  }

  void _addNewTask(Task newTask) {
    setState(() {
      dailyTasks.add(newTask);
      _showSnack('Task "${newTask.title}" added successfully!');
    });
  }

  // METHOD: Update an existing task
  void _editTask(
    Task taskToEdit,
    String newTitle,
    String newDescription,
    String newCategory,
    String newPriority,
    String newDueDate,
    String newSubject,
  ) {
    setState(() {
      taskToEdit.title = newTitle;
      taskToEdit.description = newDescription;
      taskToEdit.category = newCategory;
      taskToEdit.priority = newPriority;
      taskToEdit.dueDate = newDueDate;
      taskToEdit.subject = newSubject;
      _showSnack('Task "$newTitle" updated!');
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // --- Reusable Dialog Builder ---

  // Helper method to build the common form structure for both Add and Edit
  Widget _buildTaskForm(
    Task? task, // Null if adding, not null if editing
    TextEditingController titleController,
    TextEditingController descriptionController,
    TextEditingController subjectController,
    String initialCategory,
    String initialPriority,
    String initialDueDate,
    GlobalKey<FormState> formKey,
    Function(String) onCategoryChanged,
    Function(String) onPriorityChanged,
    Function(String) onDateChanged,
  ) {
    // These local variables will be updated by the form and passed to task methods
    String category = initialCategory;
    String priority = initialPriority;
    String dueDate = initialDueDate;

    return StatefulBuilder(
      builder: (context, setStateSB) {
        return AlertDialog(
          title: Text(
            task == null ? "➕ Add New Task" : "✏️ Edit Task",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: "Task Title",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Title cannot be empty' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: "Description",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: subjectController,
                    decoration: const InputDecoration(
                      labelText: "Subject (e.g., Science)",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Subject required' : null,
                  ),
                  const SizedBox(height: 15),
                  // Dropdown for Category
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Category",
                      border: OutlineInputBorder(),
                    ),
                    initialValue: category,
                    items: const [
                      DropdownMenuItem(
                        value: 'homework',
                        child: Text("📚 Homework"),
                      ),
                      DropdownMenuItem(value: 'study', child: Text("📖 Study")),
                      DropdownMenuItem(
                        value: 'activity',
                        child: Text("🏃 Activity"),
                      ),
                    ],
                    onChanged: (String? newValue) {
                      setStateSB(() {
                        category = newValue!;
                        onCategoryChanged(newValue);
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  // Dropdown for Priority
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Priority",
                      border: OutlineInputBorder(),
                    ),
                    initialValue: priority,
                    items: const [
                      DropdownMenuItem(value: 'high', child: Text("🚨 High")),
                      DropdownMenuItem(
                        value: 'medium',
                        child: Text("🟡 Medium"),
                      ),
                      DropdownMenuItem(value: 'low', child: Text("🟢 Low")),
                    ],
                    onChanged: (String? newValue) {
                      setStateSB(() {
                        priority = newValue!;
                        onPriorityChanged(newValue);
                      });
                    },
                  ),
                  const SizedBox(height: 15),
                  // Due Date Picker (Simplified)
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.indigo),
                      const SizedBox(width: 8),
                      Text("Due Date: $dueDate"),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.parse(dueDate),
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2030),
                          );
                          if (pickedDate != null) {
                            setStateSB(() {
                              dueDate = pickedDate.toString().substring(0, 10);
                              onDateChanged(dueDate);
                            });
                          }
                        },
                        child: const Text("Select Date"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Colors.white,
              ),
              child: Text(task == null ? 'Add Task' : 'Save Changes'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  if (task == null) {
                    // Add new task logic
                    final newTask = Task(
                      id: dailyTasks.length + 1,
                      title: titleController.text,
                      description: descriptionController.text.isEmpty
                          ? 'No description provided.'
                          : descriptionController.text,
                      category: category,
                      priority: priority,
                      status: 'pending',
                      dueDate: dueDate,
                      subject: subjectController.text,
                    );
                    _addNewTask(newTask);
                  } else {
                    // Edit existing task logic
                    _editTask(
                      task,
                      titleController.text,
                      descriptionController.text.isEmpty
                          ? 'No description provided.'
                          : descriptionController.text,
                      category,
                      priority,
                      dueDate,
                      subjectController.text,
                    );
                  }
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  // METHOD: Show Add Task Dialog
  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final subjectController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    String category = 'homework';
    String priority = 'medium';
    String dueDate = DateTime.now().toString().substring(0, 10);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _buildTaskForm(
          null, // Indicates 'Add' mode
          titleController,
          descriptionController,
          subjectController,
          category,
          priority,
          dueDate,
          formKey,
          (newCategory) => category = newCategory,
          (newPriority) => priority = newPriority,
          (newDate) => dueDate = newDate,
        );
      },
    );
  }

  // METHOD: Show Edit Task Dialog
  void _showEditTaskDialog(Task task) {
    final titleController = TextEditingController(text: task.title);
    final descriptionController = TextEditingController(text: task.description);
    final subjectController = TextEditingController(text: task.subject);
    final formKey = GlobalKey<FormState>();

    // These local variables will be updated by the form and passed to _editTask
    String category = task.category;
    String priority = task.priority;
    String dueDate = task.dueDate;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _buildTaskForm(
          task, // Pass the existing task to indicate 'Edit' mode
          titleController,
          descriptionController,
          subjectController,
          category,
          priority,
          dueDate,
          formKey,
          (newCategory) => category = newCategory,
          (newPriority) => priority = newPriority,
          (newDate) => dueDate = newDate,
        );
      },
    );
  }

  // --- Widget Builders ---

  Widget _buildTaskCard(Task task) {
    Color statusColor;
    String icon;

    switch (task.status) {
      case 'completed':
        statusColor = Colors.green;
        icon = '✅';
        break;
      case 'overdue':
        statusColor = Colors.red;
        icon = '⚠️';
        break;
      default:
        statusColor = Colors.orange;
        icon = '⏳';
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: statusColor, width: 2),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.1),
          child: Text(icon, style: const TextStyle(fontSize: 20)),
        ),
        title: Text(
          task.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              task.description,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  task.dueDate,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 8),
                Icon(Icons.label_outline, size: 12, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  task.category,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (String result) {
            switch (result) {
              case 'complete':
                _completeTask(task);
                break;
              case 'edit':
                _showEditTaskDialog(task);
                break;
              case 'delete':
                _deleteTask(task);
                break;
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            if (task.status != 'completed')
              const PopupMenuItem<String>(
                value: 'complete',
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Mark Complete'),
                  ],
                ),
              ),
            const PopupMenuItem<String>(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Edit Task'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete Task'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterButton(String label, String filter) {
    final active = currentFilter == filter;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ActionChip(
        avatar: active
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : null,
        label: Text(label),
        backgroundColor: active ? Theme.of(context).primaryColor : Colors.white,
        labelStyle: TextStyle(
          color: active ? Colors.white : Theme.of(context).primaryColor,
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(
          color: active ? Theme.of(context).primaryColor : Colors.grey.shade300,
        ),
        onPressed: () => setState(() => currentFilter = filter),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildTaskListView(List<Task> tasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              "All clear! No ${currentFilter == 'all' ? '' : currentFilter} tasks found.",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) => _buildTaskCard(tasks[index]),
    );
  }

  // The original buildStatsView is kept for the Summary Tab
  Widget _buildStatsView(int completed, int pending, int homework, int rate) {
    final totalTasks = dailyTasks.length;
    final overdueCount = dailyTasks.where((t) => t.status == 'overdue').length;
    const studyHours = 4.5; // Mock data
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Include Task Categories in the Summary tab
            _buildTaskCategoriesSection(),
            const SizedBox(height: 8),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with icon and title
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.assignment,
                            color: Theme.of(context).primaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Daily Summary',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Summary details
                    _buildSummaryRow(
                      'Total Tasks:',
                      totalTasks.toString(),
                      Colors.black87,
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow(
                      'Completed:',
                      completed.toString(),
                      Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow(
                      'Pending:',
                      pending.toString(),
                      Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow(
                      'Overdue:',
                      overdueCount.toString(),
                      Colors.red,
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow(
                      'Study Hours:',
                      '$studyHours hrs',
                      Colors.purple,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Quick Actions appear below the summary card
            _buildQuickActionsSection(),
          ],
        ),
      ),
    );
  }

  // Helper to build each summary row
  Widget _buildSummaryRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCards(int completed, int pending, int homework, int rate) {
    Widget statCard(String icon, String value, String label, Color valueColor) {
      return Container(
        width: 140.0,
        height: 110.0,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
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
                color: valueColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(icon, style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: valueColor,
                    ),
                  ),
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
      );
    }

    return Padding(
      padding: const EdgeInsets.only(
        top: 8.0,
        left: 8.0,
        right: 8.0,
        bottom: 4.0,
      ),
      child: SizedBox(
        height: 120.0,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            statCard(
              '✅',
              completed.toString(),
              'Completed Today',
              Colors.green,
            ),
            const SizedBox(width: 8),
            statCard('⏳', pending.toString(), 'Pending Tasks', Colors.orange),
            const SizedBox(width: 8),
            statCard(
              '📚',
              homework.toString(),
              'Homework',
              Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            statCard('🎯', '$rate%', 'Completion Rate', Colors.purple),
          ],
        ),
      ),
    );
  }

  // --- Task Categories Section ---
  Widget _buildTaskCategoriesSection() {
    // compute counts
    final homeworkCount = dailyTasks
        .where((t) => t.category == 'homework')
        .length;
    final studyCount = dailyTasks.where((t) => t.category == 'study').length;
    final activityCount = dailyTasks
        .where((t) => t.category == 'activity')
        .length;

    Widget categoryRow(String title, int count) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFECEFF6)),
        ),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 36,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Task Categories',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          categoryRow('Homework', homeworkCount),
          categoryRow('Study', studyCount),
          categoryRow('Activity', activityCount),
        ],
      ),
    );
  }

  // --- Quick Actions Section ---
  Widget _buildQuickActionsSection() {
    final actions = [
      {
        'label': 'Add Homework',
        'icon': Icons.book,
        'onTap': () => _showAddTaskDialog(),
      },
      {
        'label': 'Study Task',
        'icon': Icons.menu_book,
        'onTap': () => _showAddTaskDialog(),
      },
      {
        'label': 'Add Reminder',
        'icon': Icons.alarm,
        'onTap': () => _showAddTaskDialog(),
      },
    ];

    // Render actions as full-width stacked buttons (row-by-row)
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...actions.map((act) {
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 6.0),
              child: ElevatedButton.icon(
                onPressed: act['onTap'] as void Function()?,
                icon: Icon(act['icon'] as IconData, color: Colors.white),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  child: Text(
                    act['label'] as String,
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculations for the stats
    final filteredTasks = dailyTasks.where((task) {
      if (currentFilter == 'all') return true;
      if (currentFilter == 'pending') return task.status == 'pending';
      if (currentFilter == 'completed') return task.status == 'completed';
      if (currentFilter == 'overdue') return task.status == 'overdue';
      if (currentFilter == 'homework') return task.category == 'homework';
      if (currentFilter == 'study') return task.category == 'study';
      return true;
    }).toList();

    final completedCount = dailyTasks
        .where((t) => t.status == 'completed')
        .length;
    final pendingCount = dailyTasks.where((t) => t.status == 'pending').length;
    final homeworkCount = dailyTasks
        .where((t) => t.category == 'homework')
        .length;
    final totalTasks = dailyTasks.length;
    final completionRate = totalTasks == 0
        ? 0
        : ((completedCount / totalTasks) * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Daily Tasks",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.list_alt), text: "Tasks"),
            Tab(icon: Icon(Icons.bar_chart), text: "Summary"),
          ],
        ),
      ),
      // FloatingActionButton removed per user request
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Display the optimized 2x2 grid of stat cards
          _buildStatCards(
            completedCount,
            pendingCount,
            homeworkCount,
            completionRate,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // --- Tab 1: Task List ---
                // Use CustomScrollView so Filters, Task Categories and Quick Actions
                // are part of the scrollable content alongside the task list.
                CustomScrollView(
                  slivers: [
                    // Filters first (now above categories)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _filterButton('All Tasks', 'all'),
                              _filterButton('Pending', 'pending'),
                              _filterButton('Completed', 'completed'),
                              _filterButton('Overdue', 'overdue'),
                              _filterButton('Homework', 'homework'),
                              _filterButton('Study', 'study'),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // (Task Categories and Quick Actions removed from Tasks tab)
                    if (filteredTasks.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                size: 80,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "All clear! No ${currentFilter == 'all' ? '' : currentFilter} tasks found.",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              _buildTaskCard(filteredTasks[index]),
                          childCount: filteredTasks.length,
                        ),
                      ),
                    // Extra bottom padding so FAB doesn't overlap last item
                    const SliverToBoxAdapter(child: SizedBox(height: 80)),
                  ],
                ),

                // --- Tab 2: Summary Stats (Detailed List) ---
                _buildStatsView(
                  completedCount,
                  pendingCount,
                  homeworkCount,
                  completionRate,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
