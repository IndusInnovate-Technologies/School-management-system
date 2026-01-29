import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:core/api/api_service.dart';
import 'package:core/api/endpoints.dart';

import 'dashboard.dart';
import 'widgets/school_profile_header.dart';
import 'widgets/dynamic_calendar_icon.dart';
import 'widgets/management_sidebar.dart';

// ==========================================
// 1. ROBUST DATA MODEL
// ==========================================

class CalendarEvent {
  final int id;
  final String title;
  final String type;
  final DateTime date;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final String? timeString;
  final String description;
  final String? location;
  final String? organizer;
  final DateTime? endDate;
  final bool isRecurring;
  final String? recurrencePattern;
  final int? participants;
  final String? status;
  final bool isActivity;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.type,
    required this.date,
    this.startTime,
    this.endTime,
    this.timeString,
    required this.description,
    this.location,
    this.organizer,
    this.endDate,
    this.isRecurring = false,
    this.recurrencePattern,
    this.participants,
    this.status,
    this.isActivity = false,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate = DateTime.now();
    TimeOfDay? parsedStartTime;
    DateTime? parsedEndDate;
    TimeOfDay? parsedEndTime;

    try {
      // Prioritize start_datetime
      if (json['start_datetime'] != null) {
        final startDt = DateTime.parse(json['start_datetime']);
        parsedDate = startDt;
        parsedStartTime = TimeOfDay.fromDateTime(startDt);
      } else if (json['date'] != null) {
        parsedDate = DateTime.parse(json['date']);
        parsedStartTime = _parseTime(json['start_time'] ?? json['time']);
      }

      // Prioritize end_datetime
      if (json['end_datetime'] != null) {
        final endDt = DateTime.parse(json['end_datetime']);
        parsedEndDate = endDt;
        parsedEndTime = TimeOfDay.fromDateTime(endDt);
      } else if (json['end_date'] != null) {
        parsedEndDate = DateTime.parse(json['end_date']);
        parsedEndTime = _parseTime(json['end_time']);
      } else if (json['end_time'] != null) {
        parsedEndTime = _parseTime(json['end_time']);
      }
    } catch (e) {
      debugPrint('Error parsing event date: $e');
    }

    return CalendarEvent(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['name'] ?? json['title'] ?? 'Untitled Event',
      type: json['category'] ?? json['type'] ?? 'Academic',
      date: parsedDate,
      endDate: parsedEndDate,
      startTime: parsedStartTime,
      endTime: parsedEndTime,
      timeString: json['time']?.toString(),
      description: json['description'] ?? '',
      location: json['location']?.toString(),
      organizer: json['organizer']?.toString(),
      isRecurring: json['is_recurring'] == true,
      recurrencePattern: json['recurrence_pattern']?.toString(),
      participants: json['participants'] is int ? json['participants'] : int.tryParse(json['participants']?.toString() ?? '0'),
      // Use computed_status if available, otherwise fallback to status
      status: json['computed_status']?.toString() ?? json['status']?.toString(),
    );
  }

  factory CalendarEvent.fromActivityJson(Map<String, dynamic> json) {
    DateTime parsedDate = DateTime.now();
    TimeOfDay? parsedStartTime;
    
    // Parse schedule string: "yyyy-MM-dd hh:mm a"
    if (json['schedule'] != null) {
      try {
        final format = DateFormat('yyyy-MM-dd hh:mm a');
        final dt = format.parse(json['schedule']);
        parsedDate = dt;
        parsedStartTime = TimeOfDay.fromDateTime(dt);
      } catch (e) {
        debugPrint('Error parsing activity schedule: $e');
      }
    } else if (json['start_date'] != null) {
       // Fallback to start_date if schedule is missing/invalid
       try {
         parsedDate = DateTime.parse(json['start_date']);
       } catch (_) {}
    }

    return CalendarEvent(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['name'] ?? 'Untitled Activity',
      type: json['category'] ?? 'Activity',
      date: parsedDate,
      startTime: parsedStartTime,
      // Activities don't usually have end time in schedule string, unless parsed from duration
      // For now, we leave endTime null or could set a default duration
      description: json['description'] ?? '',
      location: json['location']?.toString(),
      organizer: json['instructor']?.toString(),
      status: json['status']?.toString(),
      participants: json['max_participants'] is int ? json['max_participants'] : int.tryParse(json['max_participants']?.toString() ?? '0'),
      isActivity: true,
    );
  }

  static TimeOfDay? _parseTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return null;
    try {
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return null;
    }
  }

  String get formattedTime {
    if (timeString != null && timeString!.isNotEmpty) return timeString!;
    if (startTime == null) return "No time specified";
    final start = "${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}";
    if (endTime == null) return start;
    final end = "${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}";
    return "$start - $end";
  }
}

// ==========================================
// 2. MAIN SCREEN
// ==========================================

class CalendarManagementPage extends StatefulWidget {
  const CalendarManagementPage({super.key});

  @override
  State<CalendarManagementPage> createState() => _CalendarManagementPageState();
}

class _CalendarManagementPageState extends State<CalendarManagementPage> {
  final Color gradientStart = const Color(0xFF667eea);
  final Color gradientEnd = const Color(0xFF764ba2);

  List<CalendarEvent> _allEvents = [];
  bool _isLoading = true;
  String _errorMessage = '';

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _locController = TextEditingController();
  final TextEditingController _orgController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  
  String? _selectedType;
  DateTime? _selectedDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _filterType;
  int? _filterMonth;
  String _sortBy = 'date';
  bool _sortAscending = true;

  DateTime _focusedMonth = DateTime.now();

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
      
      // Fetch both Events and Activities in parallel
      final results = await Future.wait([
        apiService.get(Endpoints.events),
        apiService.get(Endpoints.activities),
      ]);
      
      final eventsResponse = results[0];
      final activitiesResponse = results[1];

      List<CalendarEvent> loadedEvents = [];

      // Process Events
      if (eventsResponse.success && eventsResponse.data != null) {
        List<dynamic> eventsJson = [];
        if (eventsResponse.data is List) {
          eventsJson = eventsResponse.data as List<dynamic>;
        } else if (eventsResponse.data is Map) {
          final dataMap = eventsResponse.data as Map<String, dynamic>;
          if (dataMap.containsKey('results')) {
            eventsJson = dataMap['results'] as List<dynamic>;
          } else if (dataMap.containsKey('data')) {
            eventsJson = dataMap['data'] as List<dynamic>;
          } else {
            eventsJson = [dataMap];
          }
        }
        
        loadedEvents.addAll(
          eventsJson.map((json) => CalendarEvent.fromJson(json as Map<String, dynamic>))
        );
      }

      // Process Activities
      if (activitiesResponse.success && activitiesResponse.data != null) {
        List<dynamic> activitiesJson = [];
         if (activitiesResponse.data is List) {
          activitiesJson = activitiesResponse.data as List<dynamic>;
        } else if (activitiesResponse.data is Map) {
          final dataMap = activitiesResponse.data as Map<String, dynamic>;
          if (dataMap.containsKey('results')) {
            activitiesJson = dataMap['results'] as List<dynamic>;
          } else if (dataMap.containsKey('data')) {
            activitiesJson = dataMap['data'] as List<dynamic>;
          } else {
            activitiesJson = [dataMap];
          }
        }
        
        loadedEvents.addAll(
          activitiesJson.map((json) => CalendarEvent.fromActivityJson(json as Map<String, dynamic>))
        );
      }

      if (mounted) {
        setState(() {
          _allEvents = loadedEvents;
          _isLoading = false;
        });
      }
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading calendar data: $e';
          _isLoading = false;
        });
      }
    }
  }

  List<CalendarEvent> get _filteredEvents {
    if (_selectedDate == null) return [];
    return _allEvents.where((e) => DateUtils.isSameDay(e.date, _selectedDate)).toList();
  }

  void _updateEvent(CalendarEvent updatedEvent) {
    setState(() {
      final index = _allEvents.indexWhere((e) => e.id == updatedEvent.id);
      if (index != -1) {
        _allEvents[index] = updatedEvent;
      }
    });
  }

  void _deleteEvent(int id) {
    setState(() {
      _allEvents.removeWhere((e) => e.id == id);
    });
  }

  void _exportData() {
    final csv = StringBuffer();
    csv.writeln('ID,Title,Type,Date,Start Time,End Time,Location,Organizer,Description');
    for (final event in _allEvents) {
      csv.writeln(
          '${event.id},${event.title},${event.type},${DateFormat('yyyy-MM-dd').format(event.date)},${event.startTime?.format(context) ?? ""},${event.endTime?.format(context) ?? ""},${event.location ?? ""},${event.organizer ?? ""},"${event.description}"');
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exported ${_allEvents.length} events to Clipboard (Simulated)'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      body: Row(
        children: [
          if (isDesktop) SizedBox(
            width: 280,
            child: ManagementSidebar(
              gradient: const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              activeRoute: '/calendar',
            ),
          ),
          Expanded(
            child: Container(
              color: const Color(0xFFF5F6FA),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isDesktop)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: IconButton(
                                icon: const Icon(Icons.menu),
                                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Menu tapped')),
                                ),
                              ),
                            ),
                          _buildHeader(),
                          const SizedBox(height: 30),
                          _buildCalendarView(),
                          const SizedBox(height: 30),
                          _buildEventsGrid(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const DynamicCalendarIcon(),
                  const SizedBox(width: 15),
                  const Text(
                    "School Calendar",
                    style: TextStyle(
                      color: Color(0xFF333333),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              const Text(
                "Manage school events, holidays, and important dates",
                style: TextStyle(color: Color(0xFF666666)),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              IconButton(
                onPressed: _exportData,
                icon: const Icon(Icons.download, color: Color(0xFF666666)),
                tooltip: "Export CSV",
              ),
              const SizedBox(width: 10),
              SchoolProfileHeader(apiService: ApiService()),
              const SizedBox(width: 10),
              _buildBackButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContainer({required String title, required Widget icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              icon,
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildEventsGrid() {
    if (_isLoading) {
      return _buildSectionContainer(
        title: "All Events",
        icon: const DynamicCalendarIcon(),
        child: const SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return _buildSectionContainer(
        title: "All Events",
        icon: const DynamicCalendarIcon(),
        child: SizedBox(
          height: 100,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 10),
                ElevatedButton(onPressed: _loadEvents, child: const Text("Retry")),
              ],
            ),
          ),
        ),
      );
    }

    if (_selectedDate == null) {
      return _buildSectionContainer(
        title: "All Events",
        icon: const DynamicCalendarIcon(),
        child: const SizedBox(
          height: 100,
          child: Center(child: Text("Select a date on the calendar to view events.", style: TextStyle(color: Colors.grey))),
        ),
      );
    }

    if (_filteredEvents.isEmpty) {
      return _buildSectionContainer(
        title: "Events for ${DateFormat('MMM dd, yyyy').format(_selectedDate!)}",
        icon: const DynamicCalendarIcon(),
        child: const SizedBox(
          height: 100,
          child: Center(child: Text("No events found for this date.", style: TextStyle(color: Colors.grey))),
        ),
      );
    }

    final events = _filteredEvents.where((e) => !e.isActivity).toList();
    final activities = _filteredEvents.where((e) => e.isActivity).toList();

    return _buildSectionContainer(
      title: _selectedDate == null 
          ? "All Items" 
          : "Schedule for ${DateFormat('MMM dd, yyyy').format(_selectedDate!)}",
      icon: const DynamicCalendarIcon(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // EVENTS SECTION
          if (events.isNotEmpty) ...[
             const Padding(
              padding: EdgeInsets.only(bottom: 15),
              child: Text(
                "Events",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 280, 
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
              ),
              itemCount: events.length,
              itemBuilder: (context, index) {
                return _buildEventCard(events[index]);
              },
            ),
          ],
          
          if (events.isNotEmpty && activities.isNotEmpty)
            const SizedBox(height: 30),

          // ACTIVITIES SECTION
          if (activities.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(bottom: 15),
              child: Text(
                "Activities",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 280, 
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
              ),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                return _buildEventCard(activities[index]);
              },
            ),
          ],

          if (events.isEmpty && activities.isEmpty)
             const SizedBox(
              height: 100,
              child: Center(child: Text("No events or activities found for this date.", style: TextStyle(color: Colors.grey))),
            ),
        ],
      ),
    );
  }

  Widget _buildEventCard(CalendarEvent event) {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => _EventDetailDialog(event: event),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(event.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                Row(
                  children: [
                    _eventTypeBadge(event.type),
                  ],
                ),
              ],
            ),
            const Divider(height: 20),
            _detailRow("Date:", event.endDate != null 
                ? "${DateFormat('MMM dd').format(event.date)} - ${DateFormat('MMM dd, yyyy').format(event.endDate!)}"
                : DateFormat('MMM dd, yyyy').format(event.date), icon: "📅"),
            if (event.startTime != null)
              _detailRow("Time:", event.formattedTime, icon: "🕐"),
            _detailRow("Location:", event.location ?? "Not specified", icon: "📍"),
            if (event.organizer != null && event.organizer!.isNotEmpty)
              _detailRow("Organizer:", event.organizer!),
             if (event.status != null && event.status!.isNotEmpty)
              _detailRow("Status:", event.status!),
            
            const Spacer(),
            Text(
              "📝 ${event.description}",
              style: TextStyle(fontSize: 13, color: Colors.grey[800]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _eventTypeBadge(String type) {
    Color bg;
    Color text;
    switch (type) {
      case 'Academic': bg = const Color(0xFFE3F2FD); text = const Color(0xFF1976D2); break;
      case 'Sports': bg = const Color(0xFFF3E5F5); text = const Color(0xFF7B1FA2); break;
      case 'Cultural': bg = const Color(0xFFFFF3E0); text = const Color(0xFFF57C00); break;
      case 'Administrative': bg = const Color(0xFFE8F5E8); text = const Color(0xFF388E3C); break;
      case 'Holiday': bg = const Color(0xFFFFEBEE); text = const Color(0xFFD32F2F); break;
      case 'Exam': bg = const Color(0xFFEDE7F6); text = const Color(0xFF5E35B1); break;
      case 'Career': bg = const Color(0xFFE0F2F1); text = const Color(0xFF00796B); break;
      default: bg = Colors.grey.shade100; text = Colors.grey.shade800;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(type, style: TextStyle(color: text, fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }

  Widget _detailRow(String label, String value, {String? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24, 
            child: icon != null ? Text(icon, style: const TextStyle(fontSize: 14)) : null,
          ),
          SizedBox(
            width: 90, 
            child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value, style: const TextStyle(color: Color(0xFF333333), fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildCalendarView() {
    final daysInMonth = DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final int offset = firstDay.weekday == 7 ? 0 : firstDay.weekday; 

    return _buildSectionContainer(
      title: "Calendar View",
      icon: const DynamicCalendarIcon(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1)),
                icon: const Icon(Icons.arrow_back),
                style: IconButton.styleFrom(backgroundColor: gradientStart, foregroundColor: Colors.white),
              ),
              Text(
                DateFormat('MMMM yyyy').format(_focusedMonth),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1)),
                icon: const Icon(Icons.arrow_forward),
                style: IconButton.styleFrom(backgroundColor: gradientStart, foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map((day) => Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Colors.grey.shade100, border: Border.all(color: Colors.grey.shade200)),
                child: Text(day, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            )).toList(),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 2.0),
            itemCount: daysInMonth + offset,
            itemBuilder: (context, index) {
              if (index < offset) return Container(decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200)));
              
              final day = index - offset + 1;
              final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
              final isToday = DateUtils.isSameDay(date, DateTime.now());
              
              final isSelected = _selectedDate != null && DateUtils.isSameDay(date, _selectedDate);
              
              final dayEvents = _allEvents.where((e) => DateUtils.isSameDay(e.date, date)).toList();
              final hasEvents = dayEvents.isNotEmpty;

              return InkWell(
                onTap: () {
                  setState(() {
                    if (_selectedDate != null && DateUtils.isSameDay(date, _selectedDate)) {
                      _selectedDate = null;
                    } else {
                      _selectedDate = date;
                    }
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? gradientStart 
                        : (isToday ? Colors.orangeAccent.withOpacity(0.2) : (hasEvents ? const Color(0xFFE3F2FD) : Colors.white)),
                    border: Border.all(
                        color: isSelected 
                            ? gradientStart 
                            : (hasEvents ? gradientStart : Colors.grey.shade200),
                        width: isSelected ? 2 : 1),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "$day",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isSelected ? Colors.white : (isToday ? Colors.orange[800] : Colors.black),
                        ),
                      ),
                      if (hasEvents)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            "${dayEvents.length} event(s)",
                            style: TextStyle(
                                fontSize: 9, 
                                color: isSelected ? Colors.white70 : (isToday ? Colors.orange[900] : Colors.grey[600])),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                    ],
                  ),
                ),
              );
            },
          )
        ],
      ),
    );
  }
}

// ==========================================
// SIDEBAR NAVIGATION ITEM WITH HOVER
// ==========================================

class _NavItem extends StatelessWidget {
  final Widget icon;
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
        leading: icon,
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

// ==========================================
// 5. DIALOG WIDGETS
// ==========================================

class _EventFormDialog extends StatefulWidget {
  final CalendarEvent? event;
  final Function(CalendarEvent) onSave;

  const _EventFormDialog({
    this.event,
    required this.onSave,
  });

  @override
  State<_EventFormDialog> createState() => _EventFormDialogState();
}

class _EventFormDialogState extends State<_EventFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _organizerController;

  DateTime? _eventDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String _type = '';
  bool _isRecurring = false;
  String _recurrencePattern = 'weekly';

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    _titleController = TextEditingController(text: event?.title ?? '');
    _descriptionController = TextEditingController(text: event?.description ?? '');
    _locationController = TextEditingController(text: event?.location ?? '');
    _organizerController = TextEditingController(text: event?.organizer ?? '');
    _eventDate = event?.date ?? DateTime.now();
    _startTime = event?.startTime;
    _endTime = event?.endTime;
    _type = event?.type ?? '';
    _isRecurring = event?.isRecurring ?? false;
    _recurrencePattern = event?.recurrencePattern ?? 'weekly';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            children: [
              Text(widget.event == null ? 'Add Event' : 'Edit Event', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Divider(),
              const SizedBox(height: 10),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title *'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                initialValue: _type.isEmpty ? null : _type,
                decoration: const InputDecoration(labelText: 'Type *'),
                items: ["Academic", "Sports", "Cultural", "Administrative", "Career", "Holiday", "Exam", "Other"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _type = v!),
                validator: (v) => v == null ? 'Required' : null,
              ),
               const SizedBox(height: 15),
               ListTile(
                 title: Text(_eventDate == null ? 'Select Date' : DateFormat('yyyy-MM-dd').format(_eventDate!)),
                 trailing: const Icon(Icons.calendar_today),
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: BorderSide(color: Colors.grey.shade300)),
                 tileColor: Colors.white,
                 onTap: () async {
                   final picked = await showDatePicker(context: context, initialDate: _eventDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                   if (picked != null) setState(() => _eventDate = picked);
                 },
               ),
               const SizedBox(height: 10),
               Row(children: [
                 Expanded(
                   child: ListTile(
                     title: Text(_startTime == null ? 'Start Time' : _startTime!.format(context)),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: BorderSide(color: Colors.grey.shade300)),
                     tileColor: Colors.white,
                     onTap: () async {
                        final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                        if(t!=null) setState(() => _startTime = t);
                     },
                   ),
                 ),
                 const SizedBox(width: 10),
                 Expanded(
                   child: ListTile(
                     title: Text(_endTime == null ? 'End Time' : _endTime!.format(context)),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: BorderSide(color: Colors.grey.shade300)),
                     tileColor: Colors.white,
                     onTap: () async {
                        final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                        if(t!=null) setState(() => _endTime = t);
                     },
                   ),
                 ),
               ]),
               const SizedBox(height: 10),
               TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
               const SizedBox(height: 10),
               CheckboxListTile(
                 title: const Text("Recurring Event"),
                 value: _isRecurring,
                 onChanged: (v) => setState(() => _isRecurring = v!),
               ),
               if (_isRecurring)
                  DropdownButtonFormField<String>(
                    initialValue: _recurrencePattern,
                    decoration: const InputDecoration(labelText: "Recurrence Pattern"),
                    items: ['daily', 'weekly', 'monthly', 'yearly'].map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase()))).toList(),
                    onChanged: (v) => setState(() => _recurrencePattern = v!),
                  ),
               const SizedBox(height: 20),
               SizedBox(
                 height: 50,
                 child: ElevatedButton(
                   style: ElevatedButton.styleFrom(
                     backgroundColor: const Color(0xFF667eea), 
                     foregroundColor: Colors.white,
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                   ),
                   onPressed: () {
                     if (_formKey.currentState!.validate()) {
                       final event = CalendarEvent(
                         id: widget.event?.id ?? DateTime.now().millisecondsSinceEpoch,
                         title: _titleController.text,
                         type: _type,
                         date: _eventDate!,
                         startTime: _startTime,
                         endTime: _endTime,
                         description: _descriptionController.text,
                         location: _locationController.text,
                         organizer: _organizerController.text,
                         isRecurring: _isRecurring,
                         recurrencePattern: _isRecurring ? _recurrencePattern : null,
                       );
                       widget.onSave(event);
                     }
                   },
                   child: const Text("Save Event", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                 ),
               )
            ],
          ),
        ),
      ),
    );
  }
}

class _EventDetailDialog extends StatelessWidget {
  final CalendarEvent event;
  const _EventDetailDialog({required this.event});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
              child: Text(event.type, style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
             _row("Date", event.endDate != null 
                ? "${DateFormat('MMM dd, yyyy').format(event.date)} - ${DateFormat('MMM dd, yyyy').format(event.endDate!)}"
                : DateFormat('yyyy-MM-dd').format(event.date)),
            if(event.startTime != null) _row("Time", event.formattedTime),
            _row("Location", event.location ?? 'N/A'),
            _row("Organizer", event.organizer ?? 'N/A'),
            _row("Status", event.status ?? 'N/A'),
            if((event.participants ?? 0) > 0) _row("Participants", "${event.participants}"),
            if(event.isRecurring) _row("Recurrence", event.recurrencePattern!.toUpperCase()),
            const SizedBox(height: 10),
            const Text("Description:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(event.description),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
            )
          ],
        ),
      ),
    );
  }
  
  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text("$label:", style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _DayEventsDialog extends StatelessWidget {
  final DateTime date;
  final List<CalendarEvent> events;
  const _DayEventsDialog({required this.date, required this.events});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Events on ${DateFormat('MMM dd').format(date)}"),
      content: SizedBox(
        width: 400,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: events.length,
          itemBuilder: (context, index) {
            final e = events[index];
            return ListTile(
              title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("${e.type} • ${e.formattedTime}"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                showDialog(context: context, builder: (ctx) => _EventDetailDialog(event: e));
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))
      ],
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
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
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
