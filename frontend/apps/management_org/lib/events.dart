import 'dart:ui';

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:core/api/api_service.dart';
import 'package:core/api/endpoints.dart';
import 'main.dart' as app;
import 'dashboard.dart';
import 'widgets/school_profile_header.dart';
import 'management_routes.dart';
import 'widgets/dynamic_calendar_icon.dart';
import 'widgets/management_sidebar.dart';

class Event {
  final int id;
  final String name;
  final String category;
  final String? startDatetime;
  final String? endDatetime;
  final String location;
  final String organizer;
  final int participants;
  final String status;
  final String? computedStatus;
  final String description;

  final String? schoolId;
  final String? schoolName;
  final String? createdAt;
  final String? updatedAt;

  const Event({
    required this.id,
    required this.name,
    required this.category,
    this.startDatetime,
    this.endDatetime,
    required this.location,
    required this.organizer,
    required this.participants,
    required this.status,
    this.computedStatus,
    required this.description,
    this.schoolId,
    this.schoolName,
    this.createdAt,
    this.updatedAt,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      category: json['category'] ?? 'Other',
      startDatetime: json['start_datetime'],
      endDatetime: json['end_datetime'],
      location: json['location'] ?? '',
      organizer: json['organizer'] ?? '',
      participants: json['participants'] ?? 0,
      status: json['status'] ?? 'Upcoming',
      computedStatus: json['computed_status'],
      description: json['description'] ?? '',
      schoolId: json['school_id'],
      schoolName: json['school_name'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}

class EventsManagementPage extends StatefulWidget {
  const EventsManagementPage({super.key});

  @override
  State<EventsManagementPage> createState() => _EventsManagementPageState();
}

class _EventsManagementPageState extends State<EventsManagementPage> {
  List<Event> _events = [];
  Timer? _statusUpdateTimer;
  bool _isLoading = true;
  String _errorMessage = '';

  final TextEditingController _searchController = TextEditingController();
  late List<Event> _visibleEvents;

  // Check if user has edit permissions
  bool get _canEdit => ApiService().userRole != 'financial';

  @override
  void initState() {
    super.initState();
    _visibleEvents = [];
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final apiService = ApiService();
      await apiService.initialize();
      final response = await apiService.get(Endpoints.events);

      if (response.success && response.data != null) {
        // Handle different response formats
        List<dynamic> eventsJson;
        
        if (response.data is List) {
          // Direct list response
          eventsJson = response.data as List<dynamic>;
        } else if (response.data is Map) {
          // Wrapped response (e.g., {"results": [...]} or {"data": [...]})
          final dataMap = response.data as Map<String, dynamic>;
          if (dataMap.containsKey('results')) {
            eventsJson = dataMap['results'] as List<dynamic>;
          } else if (dataMap.containsKey('data')) {
            eventsJson = dataMap['data'] as List<dynamic>;
          } else {
            // If it's a single object, wrap it in a list
            eventsJson = [dataMap];
          }
        } else {
          eventsJson = [];
        }
        
        setState(() {
          _events = eventsJson.map((json) => Event.fromJson(json as Map<String, dynamic>)).toList();
          _visibleEvents = List<Event>.from(_events);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.error ?? 'Failed to load events';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading events: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int get _totalEvents => _events.length;
  int get _upcomingEvents =>
      _events.where((e) => e.status == 'Upcoming').length;
  int get _completedEvents =>
      _events.where((e) => e.status == 'Completed').length;
  int get _eventCategories => _events.map((e) => e.category).toSet().length;

  void _filterEvents(String query) {
    setState(() {
      if (query.isEmpty) {
        _visibleEvents = List<Event>.from(_events);
      } else {
        final lower = query.toLowerCase();
        _visibleEvents = _events.where((event) {
          return event.name.toLowerCase().contains(lower) ||
              event.category.toLowerCase().contains(lower);
        }).toList();
      }
    });
  }

  void _viewEvent(Event event) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(event.name),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Description: ${event.description}'),
                const SizedBox(height: 8),
                if (event.startDatetime != null)
                  Text('Start: ${_formatDateTime(event.startDatetime!)}'),
                if (event.endDatetime != null)
                  Text('End: ${_formatDateTime(event.endDatetime!)}'),
                Text('Location: ${event.location}'),
                Text('Organizer: ${event.organizer}'),
                Text('Participants: ${event.participants}'),
                if (event.createdAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Created: ${_formatDateTime(event.createdAt!)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                if (event.updatedAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Last Updated: ${_formatDateTime(event.updatedAt!)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
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
        );
      },
    );
  }

  String getDisplayStatus(Event event) {
    // Use computed_status from API if available, otherwise use manual status
    if (event.computedStatus != null && event.computedStatus!.isNotEmpty) {
      return event.computedStatus!;
    }
    return event.status;
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Upcoming':
        return Colors.blue;
      case 'Ongoing':
        return Colors.green;
      case 'Completed':
        return Colors.grey;
      case 'Cancelled':
        return Colors.red;
      case 'Postponed':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _computeEventStatus(Event event) {
    if (event.startDatetime == null && event.endDatetime == null) {
      return event.status;
    }

    final now = DateTime.now();
    
    try {
      final start = event.startDatetime != null ? DateTime.parse(event.startDatetime!) : null;
      final end = event.endDatetime != null ? DateTime.parse(event.endDatetime!) : null;

      if (start != null && end != null) {
        if (now.isBefore(start)) {
          return 'Upcoming';
        } else if (now.isAfter(start) && now.isBefore(end)) {
          return 'Ongoing';
        } else {
          return 'Completed';
        }
      } else if (start != null) {
        return now.isBefore(start) ? 'Upcoming' : 'Ongoing';
      } else if (end != null) {
        return now.isBefore(end) ? 'Upcoming' : 'Completed';
      }
    } catch (e) {
      // If parsing fails, return the manual status
      return event.status;
    }

    return event.status;
  }

  String _formatDateTime(String datetime) {
    try {
      final dt = DateTime.parse(datetime);
      return '${dt.day}/${dt.month}/${dt.year} at ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return datetime;
    }
  }

  void _editEvent(Event event) async {
    await Navigator.pushNamed(
      context,
      ManagementRoutes.editEvent,
      arguments: event.id,
    );
    _loadEvents(); // Reload events after returning from edit page
  }

  void _deleteEvent(Event event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Delete ${event.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        final apiService = ApiService();
        await apiService.initialize();
        final response = await apiService.delete('${Endpoints.events}${event.id}/');

        if (response.success) {
          await _loadEvents(); // Reload events from server
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Event deleted successfully!')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to delete event: ${response.error}')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting event: $e')),
          );
        }
      }
    }
  }

  void _addEvent() async {
    await Navigator.pushNamed(context, ManagementRoutes.addEvent);
    _loadEvents(); // Reload events after returning from add page
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 900;

            if (isCompact) {
              return Column(
                children: [
                  Expanded(
                    child: Container(
                      color: const Color(0xFFF5F6FA),
                      child: _buildMainContent(isMobile: true),
                    ),
                  ),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 280,
                  child: ManagementSidebar(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    activeRoute: '/events',
                  ),
                ),
                Expanded(
                  child: Container(
                    color: const Color(0xFFF5F6FA),
                    child: _buildMainContent(isMobile: false),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }




  Widget _buildMainContent({required bool isMobile}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassContainer(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
            margin: const EdgeInsets.only(bottom: 30),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const DynamicCalendarIcon(),
                          const SizedBox(width: 15),
                          Text(
                            'Events Management',
                            style: TextStyle(
                              fontSize: isMobile ? 22 : 28,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF333333),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Manage school events, calendar, and scheduling',
                        style: TextStyle(color: Color(0xFF666666), fontSize: 16),
                      ),
                    ],
                  ),
                ),
                if (!isMobile) ...[
                  _buildUserInfo(),
                  const SizedBox(width: 20),
                  _buildBackButton(),
                ],
              ],
            ),
          ),
          if (isMobile)
            GlassContainer(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 20),
              child: Row(
                children: [
                  Expanded(child: SchoolProfileHeader(apiService: ApiService(), isMobile: true)),
                  const Icon(Icons.arrow_back_ios_new, size: 16),
                ],
              ),
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = isMobile ? 1 : 4;
              final childAspectRatio = isMobile ? 3.4 : 1.35;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                childAspectRatio: childAspectRatio,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                children: [
                  _StatCard(
                    label: 'Total Events',
                    value: '$_totalEvents',
                    icon: const DynamicCalendarIcon(),
                    color: const Color(0xFF667EEA),
                  ),
                  _StatCard(
                    label: 'Upcoming Events',
                    value: '$_upcomingEvents',
                    icon: const Text('🔔', style: TextStyle(fontSize: 40, color: Colors.orange)),
                    color: Colors.orange,
                  ),
                  _StatCard(
                    label: 'Completed Events',
                    value: '$_completedEvents',
                    icon: const Text('✅', style: TextStyle(fontSize: 40, color: Colors.green)),
                    color: Colors.green,
                  ),
                  _StatCard(
                    label: 'Event Categories',
                    value: '$_eventCategories',
                    icon: const Text('🎭', style: TextStyle(fontSize: 40, color: Colors.blue)),
                    color: Colors.blue,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 30),
          GlassContainer(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 30),
            child: Flex(
              direction: isMobile ? Axis.vertical : Axis.horizontal,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFE1E5E9),
                        width: 2,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterEvents,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Search events by name or category...',
                        prefixIcon: Icon(Icons.search),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: isMobile ? 0 : 20,
                  height: isMobile ? 15 : 0,
                ),
                InkWell(
                  onTap: _addEvent,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: isMobile ? double.infinity : null,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 24,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF51CF66), Color(0xFF40C057)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF51CF66).withValues(alpha: 0.25),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Add New Event',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(50.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_errorMessage.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(50.0),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadEvents,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (_visibleEvents.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(50.0),
                child: Column(
                  children: [
                    const Icon(Icons.event_busy, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'No events found',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add your first event to get started',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final spacing = 20.0;
                final cardWidth = (constraints.maxWidth - spacing) / 2;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: _visibleEvents.map((event) {
                    return ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: cardWidth,
                      ),
                      child: _buildEventCard(event),
                    );
                  }).toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    return _EventCardWithHover(
      event: event,
      onView: () => _viewEvent(event),
      onEdit: () => _editEvent(event),
      onDelete: () => _deleteEvent(event),
    );
  }

  Widget _buildUserInfo() {
    return SchoolProfileHeader(apiService: ApiService());
  }

  Widget _buildBackButton() {
    return InkWell(
      onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => DashboardPage())),
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
            Icon(Icons.arrow_back, color: Colors.white, size: 16),
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
}

class _EventCardWithHover extends StatefulWidget {
  final Event event;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EventCardWithHover({
    required this.event,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_EventCardWithHover> createState() => _EventCardWithHoverState();
}

class _EventCardWithHoverState extends State<_EventCardWithHover> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        transform: Matrix4.identity()
          ..translate(0.0, _isHovered ? -8.0 : 0.0),
        child: GlassContainer(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.event.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Color(0xFF666666),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.event.category,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF666666),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = (constraints.maxWidth - 10) / 2;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      if (widget.event.startDatetime != null)
                        SizedBox(
                          width: constraints.maxWidth,
                          child: _DetailItem(
                            title: 'Start',
                            value: _formatDateTime(widget.event.startDatetime!),
                          ),
                        ),
                      if (widget.event.endDatetime != null)
                        SizedBox(
                          width: constraints.maxWidth,
                          child: _DetailItem(
                            title: 'End',
                            value: _formatDateTime(widget.event.endDatetime!),
                          ),
                        ),
                      SizedBox(
                        width: itemWidth,
                        child: _DetailItem(
                          title: 'Location',
                          value: widget.event.location,
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _DetailItem(
                          title: 'Organizer',
                          value: widget.event.organizer,
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _DetailItem(
                          title: 'Status',
                          value: widget.event.status,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _GradientButton(
                      label: 'View',
                      colors: const [Color(0xFF667EEA), Color(0xFF764BA2)],
                      onTap: widget.onView,
                    ),
                  ),
                  if (ApiService().userRole != 'financial') ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: _GradientButton(
                        label: 'Edit',
                        colors: const [Color(0xFFFFD93D), Color(0xFFFCC419)],
                        textColor: const Color(0xFF333333),
                        onTap: widget.onEdit,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _GradientButton(
                        label: 'Delete',
                        colors: const [Color(0xFFFF6B6B), Color(0xFFEE5A52)],
                        onTap: widget.onDelete,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  Color getStatusColor(String status) {
    switch (status) {
      case 'Upcoming':
        return Colors.blue;
      case 'Ongoing':
        return Colors.green;
      case 'Completed':
        return Colors.grey;
      case 'Cancelled':
        return Colors.red;
      case 'Postponed':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _computeEventStatus(Event event) {
    if (event.startDatetime == null && event.endDatetime == null) {
      return event.status;
    }

    final now = DateTime.now();
    
    try {
      final start = event.startDatetime != null ? DateTime.parse(event.startDatetime!) : null;
      final end = event.endDatetime != null ? DateTime.parse(event.endDatetime!) : null;

      if (start != null && end != null) {
        if (now.isBefore(start)) {
          return 'Upcoming';
        } else if (now.isAfter(start) && now.isBefore(end)) {
          return 'Ongoing';
        } else {
          return 'Completed';
        }
      } else if (start != null) {
        return now.isBefore(start) ? 'Upcoming' : 'Ongoing';
      } else if (end != null) {
        return now.isBefore(end) ? 'Upcoming' : 'Completed';
      }
    } catch (e) {
      // If parsing fails, return the manual status
      return event.status;
    }

    return event.status;
  }

  String _formatDateTime(String datetime) {
    try {
      final dt = DateTime.parse(datetime);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return datetime;
    }
  }
}

class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final bool drawRightBorder;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.margin,
    this.borderRadius = 15,
    this.drawRightBorder = false,
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

class _NavItem extends StatelessWidget {
  final String icon;
  final String title;
  final VoidCallback? onTap;
  final bool isActive;

  const _NavItem({
    required this.icon,
    required this.title,
    this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.white.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Text(
          icon,
          style: const TextStyle(fontSize: 18),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Widget icon;
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                label.toUpperCase(),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 11,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String title;
  final String value;

  const _DetailItem({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF666666),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final List<Color> colors;
  final Color textColor;
  final VoidCallback onTap;

  const _GradientButton({
    required this.label,
    required this.colors,
    this.textColor = Colors.white,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          gradient: LinearGradient(colors: colors),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
