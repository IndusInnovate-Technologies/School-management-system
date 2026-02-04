import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:core/api/api_service.dart';
import 'dashboard.dart';
import 'widgets/school_profile_header.dart';
import 'widgets/management_sidebar.dart';

class NotificationsManagementPage extends StatefulWidget {
  const NotificationsManagementPage({super.key});

  @override
  State<NotificationsManagementPage> createState() =>
      _NotificationsManagementPageState();
}

class _NotificationsManagementPageState
    extends State<NotificationsManagementPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;

  Future<void> _loadNotifications() async {
    final apiService = ApiService();
    await apiService.initialize();
    final response = await apiService.getPushNotificationLogs();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (response.success && response.data is List) {
        _notifications = List<Map<String, dynamic>>.from(
          (response.data as List).map((e) => Map<String, dynamic>.from(e as Map)),
        );
      } else {
        _notifications = [];
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

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

  void _openSendPushDialog() {
    final parentContext = context;
    showDialog<void>(
      context: parentContext,
      builder: (dialogContext) => _SendPushDialogContent(
        onSentSuccess: () async {
          await showDialog<void>(
            context: parentContext,
            builder: (ctx) => AlertDialog(
              title: const Text('Success'),
              content: const Text('Send notification successfully.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          if (parentContext.mounted) _loadNotifications();
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
                          _SendPushSection(onSendPush: _openSendPushDialog),
                          const SizedBox(height: 24),
                          _NotificationListSection(
                            notifications: _notifications,
                            loading: _loading,
                            onRefresh: _loadNotifications,
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



class _SendPushSection extends StatelessWidget {
  final VoidCallback onSendPush;

  const _SendPushSection({required this.onSendPush});

  @override
  Widget build(BuildContext context) {
    if (ApiService().userRole == 'financial') {
      return const SizedBox.shrink();
    }
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
          const Expanded(
            child: Text(
              'Send push notifications to students and teachers.',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF555555),
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: onSendPush,
            icon: const Icon(Icons.notifications_active),
            label: const Text('Send Push'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationListSection extends StatelessWidget {
  final List<Map<String, dynamic>> notifications;
  final bool loading;
  final VoidCallback onRefresh;

  const _NotificationListSection({
    required this.notifications,
    required this.loading,
    required this.onRefresh,
  });

  static String _formatAudience(String? audience) {
    switch (audience) {
      case 'both':
        return 'Students & Teachers';
      case 'all_students':
        return 'Students only';
      case 'all_teachers':
        return 'Teachers only';
      default:
        return audience ?? '—';
    }
  }

  static String _formatDate(dynamic value) {
    if (value == null) return '—';
    if (value is String) {
      try {
        final d = DateTime.tryParse(value);
        if (d != null) {
          final now = DateTime.now();
          final diff = now.difference(d);
          if (diff.inDays > 0) return '${diff.inDays}d ago';
          if (diff.inHours > 0) return '${diff.inHours}h ago';
          if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
          return 'Just now';
        }
      } catch (_) {}
      return value;
    }
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const CircularProgressIndicator(color: Color(0xFF667EEA)),
        ),
      );
    }
    if (notifications.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.notifications_none, size: 64, color: Color(0xFF667EEA)),
              SizedBox(height: 16),
              Text(
                'Use the button above to send push notifications',
                style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sent notifications (${notifications.length})',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: notifications.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final n = notifications[index];
            final title = n['title'] as String? ?? '—';
            final body = n['body'] as String? ?? '';
            final audience = _formatAudience(n['audience'] as String?);
            final createdAt = _formatDate(n['created_at']);
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF667EEA).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.notifications_active, color: Color(0xFF667EEA), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              audience,
                              style: TextStyle(
                                fontSize: 12,
                                color: const Color(0xFF667EEA).withValues(alpha: 0.9),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              createdAt,
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      body,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF666666),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SendPushDialogContent extends StatefulWidget {
  final VoidCallback onSentSuccess;

  const _SendPushDialogContent({required this.onSentSuccess});

  @override
  State<_SendPushDialogContent> createState() => _SendPushDialogContentState();
}

class _SendPushDialogContentState extends State<_SendPushDialogContent> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  String _audience = 'both';
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _bodyController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty && body.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter title or message')),
        );
      }
      return;
    }
    setState(() => _sending = true);
    final apiService = ApiService();
    await apiService.initialize();
    // Send only to the selected audience: all_students, all_teachers, or both
    final audience = _audience;
    final response = await apiService.sendPushNotification(
      title: title.isEmpty ? '(No title)' : title,
      body: body.isEmpty ? '(No message)' : body,
      audience: audience,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (response.success) {
      Navigator.of(context).pop();
      widget.onSentSuccess();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.error ?? 'Failed to send push'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Send Push Notification',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        onPressed: _sending ? null : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _titleController,
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
                  TextFormField(
                    controller: _bodyController,
                    decoration: InputDecoration(
                      labelText: 'Message *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    maxLines: 4,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Please enter message' : null,
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _audience,
                    decoration: InputDecoration(
                      labelText: 'Send to',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'both',
                          child: Text('Students & Teachers')),
                      DropdownMenuItem(
                          value: 'all_students',
                          child: Text('Students only')),
                      DropdownMenuItem(
                          value: 'all_teachers',
                          child: Text('Teachers only')),
                    ],
                    onChanged: _sending
                        ? null
                        : (value) {
                            if (value != null) setState(() => _audience = value);
                          },
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _sending ? null : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 15),
                      ElevatedButton(
                        onPressed: _sending ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF667EEA),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _sending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Send Notification'),
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
