import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const SchoolManagementSystemApp());
}

class SchoolManagementSystemApp extends StatelessWidget {
  const SchoolManagementSystemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Academic Calendar - School Management App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF667eea),
          primary: const Color(0xFF667eea),
          secondary: const Color(0xFF764ba2),
        ),
        fontFamily: 'Segoe UI',
        useMaterial3: true,
      ),
      home: const AcademicCalendarPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AcademicEvent {
  final int id;
  final String title;
  final DateTime date;
  final String type;
  final String description;

  AcademicEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.type,
    required this.description,
  });
}

class AcademicCalendarPage extends StatefulWidget {
  const AcademicCalendarPage({super.key});

  @override
  State<AcademicCalendarPage> createState() => _AcademicCalendarPageState();
}

class _AcademicCalendarPageState extends State<AcademicCalendarPage> {
  late DateTime _currentDate;
  late int _currentMonth;
  late int _currentYear;
  late DateTime _selectedDate;
  String _currentFilter = 'all';

  List<AcademicEvent> _academicEvents = [];

  final List<AcademicEvent> _indianPublicHolidays = [
    AcademicEvent(
      id: 10001,
      title: 'Republic Day',
      date: DateTime(DateTime.now().year, 1, 26),
      type: 'holiday',
      description: 'National holiday to honor the Constitution of India.',
    ),
    AcademicEvent(
      id: 10002,
      title: 'Independence Day',
      date: DateTime(DateTime.now().year, 8, 15),
      type: 'holiday',
      description: 'National holiday commemorating Indian independence.',
    ),
    AcademicEvent(
      id: 10003,
      title: 'Gandhi Jayanti',
      date: DateTime(DateTime.now().year, 10, 2),
      type: 'holiday',
      description: "Birth anniversary of Mahatma Gandhi.",
    ),
  ];

  late final List<AcademicEvent> _allEvents;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _allEvents = [..._academicEvents, ..._indianPublicHolidays];
    _currentDate = DateTime.now();
    _currentMonth = _currentDate.month;
    _currentYear = _currentDate.year;
    _selectedDate = DateTime(
      _currentDate.year,
      _currentDate.month,
      _currentDate.day,
    );
    _loadEvents();
  }


  Future<void> _loadEvents() async {
    try {
      // 1. Get Student ID
      final profile = await ApiService.fetchStudentProfile();
      String? studentId;
      if (profile != null && profile['student_id'] != null) {
        studentId = profile['student_id'].toString();
      } else {
         // Fallback: try parent profile to get first student
         final parentProfile = await ApiService.fetchParentProfile();
         if (parentProfile != null && parentProfile['students'] != null) {
            final students = parentProfile['students'] as List;
            if (students.isNotEmpty) {
               studentId = students[0]['id'].toString();
            }
         }
      }

      if (studentId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // 2. Fetch Data (Exams, Events, Activities, Attendance)
      final List<dynamic> results = await Future.wait([
        ApiService.fetchStudentExams(studentId: studentId),
        ApiService.fetchAllEvents(studentId: studentId),
        ApiService.fetchActivities(studentId: studentId),
        ApiService.fetchAttendanceHistory(studentId: studentId), // Added Attendance fetch
      ]);

      final exams = results[0] as List<dynamic>?;
      final events = results[1] as List<dynamic>?;
      final activities = results[2] as List<dynamic>?;
      final attendance = results[3] as Map<String, dynamic>?; // Attendance result
      
      List<AcademicEvent> fetchedEvents = [];

      // Process Exams
      if (exams != null) {
        fetchedEvents.addAll(exams.map((e) {
             // Parse Date: YYYY-MM-DDTHH:MM:SSZ
             DateTime date = DateTime.tryParse(e['exam_date'] ?? '') ?? DateTime.now();
             return AcademicEvent(
               id: e['id'] is int ? e['id'] : int.tryParse(e['id'].toString()) ?? 0,
               title: e['title'] ?? 'Exam',
               date: date,
               type: 'exam',
               description: "${e['subject']} - ${e['description'] ?? ''}",
             );
        }));
      }

      // Process Events
      if (events != null) {
        fetchedEvents.addAll(events.map((e) {
             DateTime date = DateTime.tryParse(e['start_datetime'] ?? e['date'] ?? '') ?? DateTime.now();
             String type = 'activity';
             String cat = (e['category'] ?? '').toString().toLowerCase();
             if (cat == 'administrative' || cat == 'meeting') type = 'meeting';
             else if (cat == 'holiday') type = 'holiday';
             
             return AcademicEvent(
               id: e['id'] is int ? e['id'] : int.tryParse(e['id'].toString()) ?? 0,
               title: e['name'] ?? e['title'] ?? 'Event',
               date: date,
               type: type,
               description: e['description'] ?? '',
             );
        }));
      }

      // Process Activities
      if (activities != null) {
        fetchedEvents.addAll(activities.map((a) {
             DateTime date = DateTime.tryParse(a['start_date'] ?? '') ?? DateTime.now();
             return AcademicEvent(
               id: a['id'] is int ? a['id'] : int.tryParse(a['id'].toString()) ?? 0,
               title: a['name'] ?? 'Activity',
               date: date,
               type: 'activity',
               description: "${a['category'] ?? 'Activity'} - ${a['description'] ?? ''}",
             );
        }));
      }

      // Process Attendance
      if (attendance != null && attendance['history'] != null) {
        final history = attendance['history'] as List;
        debugPrint('Attendance History Count: ${history.length}'); // DEBUG
        
        for (var record in history) {
           final dateStr = record['date'];
           final status = record['status']?.toString().toLowerCase();
           final date = DateTime.tryParse(dateStr ?? '');
           
           debugPrint('Processing Record: Date=$dateStr, Status=$status, ParsedDate=$date'); // DEBUG
           
           if (date != null && status != null) {
             // Mapping Logic: 'present' -> Green, 'absent' -> Red
             String type = '';
             // ... rest of logic
             String title = '';
             
             if (status == 'present') {
               type = 'attendance_present';
               title = 'Present';
             } else if (status == 'absent') {
               type = 'attendance_absent';
               title = 'Absent';
             } else if (status == 'late') {
               type = 'attendance_late';
               title = 'Late';
             }

             if (type.isNotEmpty) {
                fetchedEvents.add(AcademicEvent(
                  id: 90000 + date.day, // Pseudo-ID
                  title: title,
                  date: date,
                  type: type,
                  description: 'Attendance: $status',
                ));
             }
           }
        }
      }

      if (mounted) {
        setState(() {
          _academicEvents = fetchedEvents;
          _allEvents = [..._indianPublicHolidays, ..._academicEvents];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading calendar events: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String getMonthName(int month) {
    return DateFormat.MMMM().format(DateTime(0, month));
  }

  // --- Calendar Logic ---

  List<DateTime> getCalendarDays() {
    final firstDayOfMonth = DateTime(_currentYear, _currentMonth, 1);
    final startDay = firstDayOfMonth.subtract(
      Duration(days: firstDayOfMonth.weekday % 7),
    );
    return List.generate(42, (index) => startDay.add(Duration(days: index)));
  }

  List<AcademicEvent> getEventsForDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return _allEvents
        .where(
          (e) =>
              e.date.year == dateOnly.year &&
              e.date.month == dateOnly.month &&
              e.date.day == dateOnly.day,
        )
        .toList();
  }

  List<AcademicEvent> getFilteredEventsForDate(DateTime date) {
    if (_currentFilter == 'all') {
      return getEventsForDate(date);
    }
    return getEventsForDate(
      date,
    ).where((e) => e.type == _currentFilter).toList();
  }

  List<AcademicEvent> getUpcomingEvents() {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    return _allEvents
        .where(
          (e) =>
              e.date.isAfter(normalizedToday) ||
              e.date.isAtSameMomentAs(normalizedToday),
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  void previousMonth() {
    setState(() {
      _currentMonth--;
      if (_currentMonth < 1) {
        _currentMonth = 12;
        _currentYear--;
      }
      _selectedDate = DateTime(_currentYear, _currentMonth, 1);
    });
  }

  void nextMonth() {
    setState(() {
      _currentMonth++;
      if (_currentMonth > 12) {
        _currentMonth = 1;
        _currentYear++;
      }
      _selectedDate = DateTime(_currentYear, _currentMonth, 1);
    });
  }

  Color getEventTypeColor(String type) {
    switch (type) {
      case 'exam':
        return Colors.red.shade700;
      case 'holiday':
        return Colors.amber.shade700;
      case 'activity':
        return Colors.green.shade700;
      case 'meeting':
        return Colors.blue.shade700;
        // Attendance Colors
      case 'attendance_present':
        return Colors.green.shade600;
      case 'attendance_absent':
        return Colors.red.shade600;
      case 'attendance_late':
        return Colors.orange.shade800;
      default:
        return Colors.grey.shade600;
    }
  }

  // --- UI Widgets ---

  Widget buildColoredStatCard({
    required IconData icon,
    required String number,
    required String label,
    required Color iconAndNumberColor,
  }) {
    final isCalendarCard = label == 'Total Events';
    final monthAbbrev = DateFormat.MMM().format(DateTime.now());

    return Container(
      width: 140,
      height: 110, // Matching the requested rectangle look
      margin: const EdgeInsets.only(right: 12),
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
              color: iconAndNumberColor,
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
                isCalendarCard
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.calendar_month,
                            size: 28,
                            color: iconAndNumberColor,
                          ),
                          Positioned(
                            top: 4,
                            child: Text(
                              monthAbbrev,
                              style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 5,
                            child: Text(
                              DateTime.now().day.toString(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Icon(icon, size: 28, color: iconAndNumberColor),
                const SizedBox(height: 6),
                Text(
                  number,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: iconAndNumberColor,
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

  Widget buildCalendarHeaderAndNav() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: previousMonth,
          ),
          Text(
            '${getMonthName(_currentMonth)} $_currentYear',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            onPressed: nextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildEventTypeLegend() {
    final legendItems = [
      {'label': 'Exam', 'color': Colors.red.shade700},
      {'label': 'Holiday', 'color': Colors.amber.shade400},
      {'label': 'Activity', 'color': Colors.green.shade400},
      {'label': 'Meeting', 'color': Colors.blue.shade700},
      {'label': 'Present', 'color': Colors.green.shade600},
      {'label': 'Absent', 'color': Colors.red.shade600},
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 5),
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        children: legendItems.map((item) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: item['color'] as Color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                item['label'] as String,
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget buildCalendarSection(List<DateTime> calendarDays) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            color: Color(0x14000000),
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildCalendarHeaderAndNav(),
          const SizedBox(height: 16),
          buildFilterControls(),
          _buildEventTypeLegend(),
          const SizedBox(height: 12),
          buildCalendarGrid(calendarDays),
        ],
      ),
    );
  }

  Widget buildFilterControls() {
    final List<List<String>> filters = [
      ['All', 'all'],
      ['Exams', 'exam'],
      ['Holidays', 'holiday'],
      ['Activities', 'activity'],
      ['Meetings', 'meeting'],
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Wrap(
        spacing: 8,
        children: filters.map((List<String> f) {
          return ChoiceChip(
            label: Text(f[0]),
            selected: _currentFilter == f[1],
            selectedColor: const Color(0xFF667eea),
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: _currentFilter == f[1]
                  ? Colors.white
                  : const Color(0xFF667eea),
              fontWeight: FontWeight.w600,
            ),
            side: const BorderSide(color: Color(0xFF667eea), width: 1),
            onSelected: (bool val) {
              if (val) {
                setState(() {
                  _currentFilter = f[1];
                });
              }
            },
          );
        }).toList(),
      ),
    );
  }

  Widget buildCalendarGrid(List<DateTime> calendarDays) {
    final List<String> daysOfWeek = [
      'Sun',
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
    ];

    return Column(
      children: <Widget>[
        // Days of Week Header
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.4,
          children: daysOfWeek.map((String day) {
            return Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                day,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 4),
        // Days Grid
        GridView.builder(
          itemCount: calendarDays.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (context, index) {
            final date = calendarDays[index];
            final isInMonth = date.month == _currentMonth;
            final eventsOnDate = getEventsForDate(date);
            final hasEvent = eventsOnDate.isNotEmpty;

            // 🚨 FIX: isToday calculation moved into the builder scope
            final isToday =
                date.year == DateTime.now().year &&
                date.month == DateTime.now().month &&
                date.day == DateTime.now().day;

            Color? bgColor;
            bool isExamDay = eventsOnDate.any((e) => e.type == 'exam');
            bool isHoliday = eventsOnDate.any((e) => e.type == 'holiday');

            if (hasEvent) {
              if (isExamDay) {
                bgColor = Colors.red.shade700;
              } else if (isHoliday) {
                bgColor = Colors.amber.shade400;
              } else {
                bgColor = Colors.green.shade400;
              }
            } else if (isToday) {
              bgColor = const Color(0xFF667eea);
            }

            return GestureDetector(
              onTap: () {
                if (hasEvent) {
                  _showDayEventsModal(date, eventsOnDate);
                }
                setState(() {
                  _selectedDate = date;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isInMonth
                      ? bgColor ?? const Color(0xFFF8F9FA)
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                  border:
                      _selectedDate.year == date.year &&
                          _selectedDate.month == date.month &&
                          _selectedDate.day == date.day
                      ? Border.all(color: const Color(0xFF764ba2), width: 3)
                      : null,
                  boxShadow: [
                    if (isInMonth)
                      const BoxShadow(
                        color: Color(0x14000000),
                        offset: Offset(0, 3),
                        blurRadius: 4,
                      ),
                  ],
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      date.day.toString(),
                      style: TextStyle(
                        color: isInMonth
                            ? (bgColor != null ? Colors.white : Colors.black87)
                            : Colors.grey.shade600,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    if (hasEvent)
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: bgColor == Colors.white
                                ? Colors.black
                                : Colors.transparent,
                            width: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget buildEventListSection(List<AcademicEvent> events) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            color: Color(0x14000000),
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📋', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Events on ${DateFormat.yMMMMd().format(_selectedDate)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          if (events.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No events scheduled for this date.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            Column(
              children: events.map((event) {
                final Color typeColor = getEventTypeColor(event.type);
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border(
                      left: BorderSide(color: typeColor, width: 4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: typeColor.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: typeColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            child: Text(
                              event.type[0].toUpperCase() +
                                  event.type.substring(1),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        DateFormat.yMMMMEEEEd().format(event.date),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        event.description,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget buildSidebarSection(List<AcademicEvent> upcomingEvents) {
    final eventsToShow = upcomingEvents.take(5).toList();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            color: Color(0x14000000),
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('⏰', style: TextStyle(fontSize: 20)),
              SizedBox(width: 15),
              Text(
                'Upcoming Events',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          if (eventsToShow.isEmpty)
            const Text(
              'No upcoming events.',
              style: TextStyle(color: Colors.grey),
            )
          else
            Column(
              children: eventsToShow.map((event) {
                final Color borderColor = getEventTypeColor(event.type);
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border(
                      left: BorderSide(color: borderColor, width: 4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: borderColor.withValues(alpha: 0.1),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat.yMMMMd().format(event.date),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          const Divider(height: 24),
          const Row(
            children: [
              Text('📊', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text(
                'Statistics',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          buildStatSummaryItem('School Days', '180 days'),
          const SizedBox(height: 10),
          buildStatSummaryItem('Exam Periods', '4 periods'),
          const SizedBox(height: 10),
          buildStatSummaryItem('PT Meetings', '3 meetings'),
        ],
      ),
    );
  }

  Widget buildStatSummaryItem(String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF667eea),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showDayEventsModal(DateTime date, List<AcademicEvent> events) {
    final titleText = events.isEmpty
        ? 'No Events on ${DateFormat.yMMMMd().format(date)}'
        : 'Events on ${DateFormat.yMMMMd().format(date)}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          height:
              MediaQuery.of(context).size.height *
              0.75, // Take 75% of screen height
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titleText,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(height: 25),
              Expanded(
                child: events.isEmpty
                    ? Center(
                        child: Text(
                          "Enjoy the free day!",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView(
                        children: events.map((event) {
                          final typeColor = getEventTypeColor(event.type);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 15),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border(
                                left: BorderSide(color: typeColor, width: 5),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: typeColor.withValues(alpha: 0.1),
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Type: ${event.type[0].toUpperCase()}${event.type.substring(1)}",
                                  style: TextStyle(
                                    color: typeColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  event.description,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final calendarDays = getCalendarDays();
    final filteredEvents = getFilteredEventsForDate(_selectedDate);
    final upcoming = getUpcomingEvents();

    const Color primaryPurple = Color(0xFF667eea);
    const Color amberColor = Color(0xFFFFC107);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryPurple, Color(0xFF764ba2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'School Calendar',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        actions: const [],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Title/Description
            const Text(
              'Academic Calendar',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'View and manage important dates',
              style: TextStyle(color: Color(0xFF666666), fontSize: 14),
            ),
            const SizedBox(height: 20),

            // 2. Horizontal Stats Section (Matching Image UI)
            SizedBox(
              height: 140, // Fixed height
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // CARD 1: Total Events (Calendar Icon Mock)
                  buildColoredStatCard(
                    icon: Icons.event,
                    number: _allEvents.length.toString(),
                    label: 'Total Events',
                    iconAndNumberColor: primaryPurple,
                  ),
                  // CARD 2: Upcoming Exams (Books Icon Mock)
                  buildColoredStatCard(
                    icon: Icons.menu_book,
                    number: _allEvents
                        .where(
                          (e) =>
                              e.type == 'exam' &&
                              e.date.isAfter(DateTime.now()),
                        )
                        .length
                        .toString(),
                    label: 'Upcoming Exams',
                    iconAndNumberColor: primaryPurple,
                  ),
                  // CARD 3: Holidays (Trophy Icon Mock)
                  buildColoredStatCard(
                    icon: Icons.emoji_events,
                    number: _allEvents
                        .where((e) => e.type == 'holiday')
                        .length
                        .toString(),
                    label: 'Holidays',
                    iconAndNumberColor: amberColor,
                  ),
                  // CARD 4: Activities (Graph Icon Mock)
                  buildColoredStatCard(
                    icon: Icons.auto_graph,
                    number: _allEvents
                        .where((e) => e.type == 'activity')
                        .length
                        .toString(),
                    label: 'Activities',
                    iconAndNumberColor: primaryPurple,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. Calendar View (Main Content - Full Width)
            buildCalendarSection(calendarDays),
            const SizedBox(height: 24),

            // 4. Event List for Selected Date (Stacked)
            buildEventListSection(filteredEvents),
            const SizedBox(height: 24),

            // 5. Upcoming Events/Statistics Sidebar (Stacked)
            buildSidebarSection(upcoming),
          ],
        ),
      ),
    );
  }
}
