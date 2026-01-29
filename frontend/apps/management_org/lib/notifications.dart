import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:main_login/main.dart' as main_login;
import 'package:core/api/api_service.dart';
import 'main.dart' as app;
import 'dashboard.dart';
import 'widgets/school_profile_header.dart';
import 'widgets/management_sidebar.dart';

enum NotificationPriority { high, medium, low }
enum NotificationStatus { read, unread }
enum TargetAudience { all, teachers, students, parents, management }

class NotificationRecord {
  final int id;
  final String title;
  final String category;
  final NotificationPriority priority;
  final String content;
  final TargetAudience targetAudience;
  NotificationStatus status;
  final DateTime timestamp;

  NotificationRecord({
    required this.id,
    required this.title,
    required this.category,
    required this.priority,
    required this.content,
    required this.targetAudience,
    required this.status,
    required this.timestamp,
  });

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  NotificationRecord copyWith({
    int? id,
    String? title,
    String? category,
    NotificationPriority? priority,
    String? content,
    TargetAudience? targetAudience,
    NotificationStatus? status,
    DateTime? timestamp,
  }) {
    return NotificationRecord(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      content: content ?? this.content,
      targetAudience: targetAudience ?? this.targetAudience,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

class NotificationsManagementPage extends StatefulWidget {
  const NotificationsManagementPage({super.key});

  @override
  State<NotificationsManagementPage> createState() =>
      _NotificationsManagementPageState();
}

class _NotificationsManagementPageState
    extends State<NotificationsManagementPage> {
  final List<NotificationRecord> _allNotifications = [
    NotificationRecord(
      id: 1,
      title: 'Bus Delay Alert',
      category: 'Transport',
      priority: NotificationPriority.high,
      content:
          'Bus #1 is running 15 minutes late due to traffic. Expected arrival at 8:15 AM.',
      targetAudience: TargetAudience.students,
      status: NotificationStatus.unread,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    NotificationRecord(
      id: 2,
      title: 'Parent-Teacher Meeting',
      category: 'Academic',
      priority: NotificationPriority.medium,
      content:
          'Parent-teacher meeting scheduled for Friday, January 20th at 3:00 PM in the auditorium.',
      targetAudience: TargetAudience.parents,
      status: NotificationStatus.read,
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    NotificationRecord(
      id: 3,
      title: 'Science Fair Registration',
      category: 'Events',
      priority: NotificationPriority.medium,
      content:
          'Registration for the annual science fair is now open. Deadline: January 25th.',
      targetAudience: TargetAudience.students,
      status: NotificationStatus.unread,
      timestamp: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    NotificationRecord(
      id: 4,
      title: 'Weather Alert',
      category: 'Emergency',
      priority: NotificationPriority.high,
      content:
          'Heavy rain expected today. Students should bring umbrellas and raincoats.',
      targetAudience: TargetAudience.all,
      status: NotificationStatus.unread,
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    NotificationRecord(
      id: 5,
      title: 'Library Book Return',
      category: 'General',
      priority: NotificationPriority.low,
      content:
          'Reminder: All library books must be returned by the end of this week.',
      targetAudience: TargetAudience.students,
      status: NotificationStatus.read,
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
    ),
    NotificationRecord(
      id: 6,
      title: 'Sports Day Preparation',
      category: 'Events',
      priority: NotificationPriority.medium,
      content:
          'Sports day practice sessions will begin next week. All students are encouraged to participate.',
      targetAudience: TargetAudience.students,
      status: NotificationStatus.read,
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    ),
    NotificationRecord(
      id: 7,
      title: 'Examination Schedule Released',
      category: 'Academic',
      priority: NotificationPriority.high,
      content:
          'Final examination schedule for all classes has been released. Please check the notice board.',
      targetAudience: TargetAudience.all,
      status: NotificationStatus.read,
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
    ),
    NotificationRecord(
      id: 8,
      title: 'New Library Books Arrived',
      category: 'General',
      priority: NotificationPriority.low,
      content:
          'New collection of books has arrived in the library. Students are welcome to borrow.',
      targetAudience: TargetAudience.students,
      status: NotificationStatus.read,
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  late List<NotificationRecord> _visibleNotifications;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  String? _newCategory;
  NotificationPriority? _newPriority;
  TargetAudience? _newTargetAudience;

  String _searchQuery = '';
  String? _categoryFilter;
  NotificationPriority? _priorityFilter;
  NotificationStatus? _statusFilter;

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
              color: const Color(0xFF495057).withOpacity(0.3),
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
    _visibleNotifications = List<NotificationRecord>.from(_allNotifications);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _filterNotifications() {
    setState(() {
      _visibleNotifications = _allNotifications.where((notification) {
        final matchesSearch = _searchQuery.isEmpty ||
            notification.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            notification.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            notification.category.toLowerCase().contains(_searchQuery.toLowerCase());

        final matchesCategory =
            _categoryFilter == null || notification.category == _categoryFilter;

        final matchesPriority =
            _priorityFilter == null || notification.priority == _priorityFilter;

        final matchesStatus =
            _statusFilter == null || notification.status == _statusFilter;

        return matchesSearch &&
            matchesCategory &&
            matchesPriority &&
            matchesStatus;
      }).toList();
    });
  }

  Map<String, int> _stats() {
    final total = _allNotifications.length;
    final unread = _allNotifications
        .where((n) => n.status == NotificationStatus.unread)
        .length;
    final highPriority = _allNotifications
        .where((n) => n.priority == NotificationPriority.high)
        .length;

    final today = DateTime.now();
    final todayNotifications = _allNotifications
        .where((n) =>
            n.timestamp.year == today.year &&
            n.timestamp.month == today.month &&
            n.timestamp.day == today.day)
        .length;

    return {
      'total': total,
      'unread': unread,
      'highPriority': highPriority,
      'today': todayNotifications,
    };
  }

  void _addNotification() {
    if (!_formKey.currentState!.validate()) return;
    if (_newCategory == null ||
        _newPriority == null ||
        _newTargetAudience == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final notification = NotificationRecord(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: _titleController.text.trim(),
      category: _newCategory!,
      priority: _newPriority!,
      content: _contentController.text.trim(),
      targetAudience: _newTargetAudience!,
      status: NotificationStatus.unread,
      timestamp: DateTime.now(),
    );

    setState(() {
      _allNotifications.insert(0, notification);
      _filterNotifications();
    });

    _formKey.currentState!.reset();
    _titleController.clear();
    _contentController.clear();
    setState(() {
      _newCategory = null;
      _newPriority = null;
      _newTargetAudience = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification sent successfully!')),
    );
  }

  void _viewNotification(NotificationRecord notification) {
    setState(() {
      notification.status = NotificationStatus.read;
    });

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                notification.content,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Category', notification.category),
              _buildDetailRow('Priority', notification.priority.name),
              _buildDetailRow(
                  'Target Audience', notification.targetAudience.name),
              _buildDetailRow('Time', notification.timeAgo),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _editNotification(NotificationRecord notification) {
    _titleController.text = notification.title;
    _contentController.text = notification.content;
    _newCategory = notification.category;
    _newPriority = notification.priority;
    _newTargetAudience = notification.targetAudience;

    showDialog<void>(
      context: context,
      builder: (context) => _AddNotificationDialog(
        formKey: _formKey,
        titleController: _titleController,
        contentController: _contentController,
        category: _newCategory,
        onCategoryChanged: (value) => setState(() => _newCategory = value),
        priority: _newPriority,
        onPriorityChanged: (value) => setState(() => _newPriority = value),
        targetAudience: _newTargetAudience,
        onTargetAudienceChanged: (value) =>
            setState(() => _newTargetAudience = value),
        onSubmit: () {
          if (_formKey.currentState!.validate() &&
              _newCategory != null &&
              _newPriority != null &&
              _newTargetAudience != null) {
            final index = _allNotifications.indexOf(notification);
            if (index != -1) {
              setState(() {
                _allNotifications[index] = notification.copyWith(
                  title: _titleController.text.trim(),
                  content: _contentController.text.trim(),
                  category: _newCategory,
                  priority: _newPriority,
                  targetAudience: _newTargetAudience,
                );
                _filterNotifications();
              });
            }
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notification updated!')),
            );
          }
        },
        onCancel: () {
          Navigator.pop(context);
          _titleController.clear();
          _contentController.clear();
          setState(() {
            _newCategory = null;
            _newPriority = null;
            _newTargetAudience = null;
          });
        },
      ),
    );
  }

  void _deleteNotification(NotificationRecord notification) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content: Text('Are you sure you want to delete "${notification.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _allNotifications.remove(notification);
                _filterNotifications();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notification deleted')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _openAddDialog() {
    _titleController.clear();
    _contentController.clear();
    setState(() {
      _newCategory = null;
      _newPriority = null;
      _newTargetAudience = null;
    });

    showDialog<void>(
      context: context,
      builder: (context) => _AddNotificationDialog(
        formKey: _formKey,
        titleController: _titleController,
        contentController: _contentController,
        category: _newCategory,
        onCategoryChanged: (value) => setState(() => _newCategory = value),
        priority: _newPriority,
        onPriorityChanged: (value) => setState(() => _newPriority = value),
        targetAudience: _newTargetAudience,
        onTargetAudienceChanged: (value) =>
            setState(() => _newTargetAudience = value),
        onSubmit: _addNotification,
        onCancel: () {
          Navigator.pop(context);
          _titleController.clear();
          _contentController.clear();
          setState(() {
            _newCategory = null;
            _newPriority = null;
            _newTargetAudience = null;
          });
        },
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
                    child: ManagementSidebar(gradient: gradient, activeRoute: '/notifications'),
                  ),
                ),
          body: Row(
            children: [
              if (showSidebar) ManagementSidebar(gradient: gradient, activeRoute: '/notifications'),
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
                                    'Notifications Management',
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
                          _StatsRow(stats: stats),
                          const SizedBox(height: 24),
                          _SearchNotificationSection(
                            searchQuery: _searchQuery,
                            onSearchChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                              _filterNotifications();
                            },
                            onAddNotification: _openAddDialog,
                          ),
                          const SizedBox(height: 24),
                          _NotificationsGrid(
                            notifications: _visibleNotifications,
                            onView: _viewNotification,
                            onEdit: _editNotification,
                            onDelete: _deleteNotification,
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



class _StatsRow extends StatelessWidget {
  final Map<String, int> stats;

  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 20,
      runSpacing: 20,
      children: [
        _StatCard(
          label: 'Total Notifications',
          value: '${stats['total']}',
          icon: '🔔',
          color: const Color(0xFF667EEA),
        ),
        _StatCard(
          label: 'Unread',
          value: '${stats['unread']}',
          icon: '📧',
          color: Colors.green,
        ),
        _StatCard(
          label: 'High Priority',
          value: '${stats['highPriority']}',
          icon: '⚠️',
          color: Colors.red,
        ),
        _StatCard(
          label: 'Today',
          value: '${stats['today']}',
          icon: '📩',
          color: Colors.blue,
        ),
      ],
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
      child: Container(
        width: 200,
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

class _ActionsBar extends StatelessWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final String? categoryFilter;
  final ValueChanged<String?> onCategoryChanged;
  final NotificationPriority? priorityFilter;
  final ValueChanged<NotificationPriority?> onPriorityChanged;
  final NotificationStatus? statusFilter;
  final ValueChanged<NotificationStatus?> onStatusChanged;
  final VoidCallback onAddNotification;

  const _ActionsBar({
    required this.searchQuery,
    required this.onSearchChanged,
    required this.categoryFilter,
    required this.onCategoryChanged,
    required this.priorityFilter,
    required this.onPriorityChanged,
    required this.statusFilter,
    required this.onStatusChanged,
    required this.onAddNotification,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isStacked = constraints.maxWidth < 800;
          return Flex(
            direction: isStacked ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: TextField(
                        controller: TextEditingController(text: searchQuery)
                          ..selection = TextSelection.collapsed(
                              offset: searchQuery.length),
                        onChanged: onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Search notifications...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE1E5E9)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE1E5E9)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF667EEA)),
                          ),
                        ),
                      ),
                    ),
                    if (isStacked) const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: 150,
                          child: DropdownButtonFormField<String>(
                            initialValue: categoryFilter,
                            decoration: InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            items: [
                              const DropdownMenuItem(
                                  value: null, child: Text('All Categories')),
                              const DropdownMenuItem(
                                  value: 'General', child: Text('General')),
                              const DropdownMenuItem(
                                  value: 'Academic', child: Text('Academic')),
                              const DropdownMenuItem(
                                  value: 'Transport', child: Text('Transport')),
                              const DropdownMenuItem(
                                  value: 'Events', child: Text('Events')),
                              const DropdownMenuItem(
                                  value: 'Emergency', child: Text('Emergency')),
                            ],
                            onChanged: onCategoryChanged,
                          ),
                        ),
                        SizedBox(
                          width: 150,
                          child: DropdownButtonFormField<NotificationPriority>(
                            initialValue: priorityFilter,
                            decoration: InputDecoration(
                              labelText: 'Priority',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            items: [
                              const DropdownMenuItem(
                                  value: null, child: Text('All Priorities')),
                              const DropdownMenuItem(
                                  value: NotificationPriority.high,
                                  child: Text('High')),
                              const DropdownMenuItem(
                                  value: NotificationPriority.medium,
                                  child: Text('Medium')),
                              const DropdownMenuItem(
                                  value: NotificationPriority.low,
                                  child: Text('Low')),
                            ],
                            onChanged: onPriorityChanged,
                          ),
                        ),
                        SizedBox(
                          width: 150,
                          child: DropdownButtonFormField<NotificationStatus>(
                            initialValue: statusFilter,
                            decoration: InputDecoration(
                              labelText: 'Status',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            items: [
                              const DropdownMenuItem(
                                  value: null, child: Text('All Status')),
                              const DropdownMenuItem(
                                  value: NotificationStatus.read,
                                  child: Text('Read')),
                              const DropdownMenuItem(
                                  value: NotificationStatus.unread,
                                  child: Text('Unread')),
                            ],
                            onChanged: onStatusChanged,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isStacked) const SizedBox(width: 20),
              if (isStacked) const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: onAddNotification,
                icon: const Icon(Icons.add),
                label: const Text('Add Notification'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667EEA),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SearchNotificationSection extends StatelessWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onAddNotification;

  const _SearchNotificationSection({
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onAddNotification,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: TextEditingController(text: searchQuery)
                ..selection = TextSelection.collapsed(offset: searchQuery.length),
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search notifications...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE1E5E9)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE1E5E9)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF667EEA)),
                ),
              ),
            ),
          ),
          if (ApiService().userRole != 'financial') ...[
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: onAddNotification,
              icon: const Icon(Icons.add),
              label: const Text('Add Notification'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NotificationsGrid extends StatelessWidget {
  final List<NotificationRecord> notifications;
  final ValueChanged<NotificationRecord> onView;
  final ValueChanged<NotificationRecord> onEdit;
  final ValueChanged<NotificationRecord> onDelete;

  const _NotificationsGrid({
    required this.notifications,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.notifications_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No notifications found',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1200
            ? 3
            : constraints.maxWidth > 800
                ? 2
                : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            mainAxisExtent: 240,
          ),
          itemCount: notifications.length,
          itemBuilder: (context, index) => _NotificationCard(
            notification: notifications[index],
            onView: () => onView(notifications[index]),
            onEdit: () => onEdit(notifications[index]),
            onDelete: () => onDelete(notifications[index]),
          ),
        );
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationRecord notification;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.notification,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  Color _getPriorityColor() {
    switch (notification.priority) {
      case NotificationPriority.high:
        return Colors.red;
      case NotificationPriority.medium:
        return Colors.orange;
      case NotificationPriority.low:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border(
          left: BorderSide(color: priorityColor, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      '🔔',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF667EEA).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          notification.category,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF667EEA),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.timeAgo,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              notification.content,
              style: const TextStyle(
                color: Color(0xFF555555),
                fontSize: 13,
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onView,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF667EEA),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('View', style: TextStyle(fontSize: 12)),
                  ),
                ),
                if (ApiService().userRole != 'financial') ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onEdit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Edit', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onDelete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Delete', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddNotificationDialog extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController contentController;
  final String? category;
  final ValueChanged<String?> onCategoryChanged;
  final NotificationPriority? priority;
  final ValueChanged<NotificationPriority?> onPriorityChanged;
  final TargetAudience? targetAudience;
  final ValueChanged<TargetAudience?> onTargetAudienceChanged;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  const _AddNotificationDialog({
    required this.formKey,
    required this.titleController,
    required this.contentController,
    required this.category,
    required this.onCategoryChanged,
    required this.priority,
    required this.onPriorityChanged,
    required this.targetAudience,
    required this.onTargetAudienceChanged,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Add New Notification',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      onPressed: onCancel,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter title' : null,
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: InputDecoration(
                    labelText: 'Category *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'General', child: Text('General')),
                    DropdownMenuItem(value: 'Academic', child: Text('Academic')),
                    DropdownMenuItem(
                        value: 'Transport', child: Text('Transport')),
                    DropdownMenuItem(value: 'Events', child: Text('Events')),
                    DropdownMenuItem(
                        value: 'Emergency', child: Text('Emergency')),
                  ],
                  onChanged: onCategoryChanged,
                  validator: (value) =>
                      value == null ? 'Please select category' : null,
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<NotificationPriority>(
                  initialValue: priority,
                  decoration: InputDecoration(
                    labelText: 'Priority *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: NotificationPriority.high, child: Text('High')),
                    DropdownMenuItem(
                        value: NotificationPriority.medium,
                        child: Text('Medium')),
                    DropdownMenuItem(
                        value: NotificationPriority.low, child: Text('Low')),
                  ],
                  onChanged: onPriorityChanged,
                  validator: (value) =>
                      value == null ? 'Please select priority' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: contentController,
                  decoration: InputDecoration(
                    labelText: 'Content *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  maxLines: 4,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter content' : null,
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<TargetAudience>(
                  initialValue: targetAudience,
                  decoration: InputDecoration(
                    labelText: 'Target Audience',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: TargetAudience.all, child: Text('All')),
                    DropdownMenuItem(
                        value: TargetAudience.teachers,
                        child: Text('Teachers')),
                    DropdownMenuItem(
                        value: TargetAudience.students,
                        child: Text('Students')),
                    DropdownMenuItem(
                        value: TargetAudience.parents, child: Text('Parents')),
                    DropdownMenuItem(
                        value: TargetAudience.management,
                        child: Text('Management')),
                  ],
                  onChanged: onTargetAudienceChanged,
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: onCancel,
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 15),
                    ElevatedButton(
                      onPressed: onSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF667EEA),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Send Notification'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}



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
