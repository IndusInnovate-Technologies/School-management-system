import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'services/api_service.dart' as api;

// ---------------------- Main Function ----------------------
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Teacher Timetable',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: const TeacherTimetableScreen(),
    );
  }
}

// ---------------------- TeacherTimetableScreen ----------------------

class TeacherTimetableScreen extends StatefulWidget {
  const TeacherTimetableScreen({super.key});

  @override
  State<TeacherTimetableScreen> createState() => _TeacherTimetableScreenState();
}

class _TeacherTimetableScreenState extends State<TeacherTimetableScreen> {
  // --------------------- State Variables ---------------------
  DateTime currentWeek = DateTime.now();
  String currentView = 'weekly';
  bool _isLoading = true;
  List<Map<String, dynamic>> _timetableEntries = [];
  List<String> _timeSlots = [];
  
  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  @override
  void initState() {
    super.initState();
    _fetchTimetable();
  }

  Future<void> _fetchTimetable() async {
    setState(() => _isLoading = true);
    
    try {
      final entries = await api.ApiService.fetchTimetable();
      
      // Generate unique sorted time slots from entries
      final slots = <String>{};
      for (var entry in entries) {
        final startTime = entry['start_time'] as String;
        final formatted = _formatTimeSlot(startTime);
        slots.add(formatted);
      }
      
      final sortedSlots = slots.toList()..sort((a, b) {
        int to24(String t) {
          final h = int.parse(t.split(':')[0]);
          final m = int.parse(t.split(':')[1].split(' ')[0]);
          final isPM = t.contains('PM');
          return (isPM && h != 12 ? h + 12 : (h == 12 && !isPM ? 0 : h)) * 100 + m;
        }
        return to24(a).compareTo(to24(b));
      });
      
      setState(() {
        _timetableEntries = entries;
        _timeSlots = sortedSlots.isEmpty ? [
          '8:00 AM', '9:00 AM', '10:00 AM', '11:00 AM',
          '12:00 PM', '1:00 PM', '2:00 PM', '3:00 PM'
        ] : sortedSlots;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching timetable: $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatTimeSlot(String time24) {
    try {
      final parts = time24.split(':');
      var hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final ampm = hour >= 12 ? 'PM' : 'AM';
      hour = hour % 12;
      if (hour == 0) hour = 12;
      return '$hour:${minute.toString().padLeft(2, '0')} $ampm';
    } catch (e) {
      return time24;
    }
  }

  Map<String, dynamic>? _getEntryForDayAndTime(int dayIndex, String timeSlot) {
    for (var entry in _timetableEntries) {
      if (entry['day_of_week'] == dayIndex) {
        final startTime = entry['start_time'] as String;
        if (_formatTimeSlot(startTime) == timeSlot) {
          return entry;
        }
      }
    }
    return null;
  }

  // ----------------------- Navigation Logic ------------------------
  void nextWeek() {
    setState(() => currentWeek = currentWeek.add(const Duration(days: 7)));
  }

  void previousWeek() {
    setState(() => currentWeek = currentWeek.subtract(const Duration(days: 7)));
  }

  void setView(String view) {
    setState(() => currentView = view);
  }

  String get weekDisplay {
    DateTime start = currentWeek.subtract(
      Duration(days: currentWeek.weekday == 7 ? 6 : currentWeek.weekday - 1),
    );
    return "Week of ${DateFormat('MMMM d, yyyy').format(start)}";
  }

  List<Map<String, dynamic>> get dailyClasses {
    final today = DateFormat('EEEE').format(DateTime.now());
    final dayIndex = _days.indexOf(today);
    if (dayIndex == -1) return [];
    
    return _timetableEntries.where((entry) => entry['day_of_week'] == dayIndex).toList()
      ..sort((a, b) => (a['start_time'] as String).compareTo(b['start_time'] as String));
  }

  // ----------------------- UI BUILD ------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4.0)],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text(
              "My Timetable",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_outlined, color: Colors.white),
                onPressed: _fetchTimetable,
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPageHeader(),
                            const SizedBox(height: 30),
                            _buildStatsHorizontalList(),
                            const SizedBox(height: 30),
                            _buildTimetableControls(),
                            const SizedBox(height: 30),
                            _buildTimetableContent(),
                            const SizedBox(height: 20),
                            _buildLegend(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPageHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10),
        Text(
          "View your class schedule and upcoming sessions",
          style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
        ),
      ],
    );
  }

  Widget _buildStatsHorizontalList() {
    final totalClasses = _timetableEntries.where((e) => e['entry_type'] == 'class').length;
    final totalBreaks = _timetableEntries.where((e) => e['entry_type'] == 'break').length;
    final totalLunch = _timetableEntries.where((e) => e['entry_type'] == 'lunch').length;
    final todayClasses = dailyClasses.length;

    final List<Map<String, String>> stats = [
      {"icon": "📅", "number": "$totalClasses", "label": "Total Classes"},
      {"icon": "⏰", "number": "$todayClasses", "label": "Classes Today"},
      {"icon": "☕", "number": "$totalBreaks", "label": "Break Slots"},
      {"icon": "🍴", "number": "$totalLunch", "label": "Lunch Slots"},
    ];

    return SizedBox(
      height: 170,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: stats.length,
        itemBuilder: (context, index) {
          final stat = stats[index];
          return Padding(
            padding: EdgeInsets.only(right: index < stats.length - 1 ? 20 : 0),
            child: _statCard(stat["icon"]!, stat["number"]!, stat["label"]!),
          );
        },
      ),
    );
  }

  Widget _statCard(String icon, String number, String label) {
    return Container(
      width: 170,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Bar
          Container(
            height: 4,
            decoration: const BoxDecoration(
              color: Color(0xFF667eea),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(icon, style: const TextStyle(fontSize: 32)),
                const SizedBox(height: 6),
                Text(
                  number,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF667eea),
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

  Widget _buildTimetableControls() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: 20,
        runSpacing: 20,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _navButton("‹", previousWeek),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  weekDisplay,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              _navButton("›", nextWeek),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _viewButton("Weekly", "weekly"),
              _viewButton("Daily", "daily"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _navButton(String t, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          t,
          style: const TextStyle(fontSize: 20, color: Colors.white),
        ),
      ),
    );
  }

  Widget _viewButton(String name, String key) {
    bool active = currentView == key;
    return GestureDetector(
      onTap: () => setView(key),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: active ? const Color(0xFF667eea) : Colors.white,
          border: Border.all(color: const Color(0xFF667eea), width: 2),
        ),
        child: Text(
          name,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFF667eea),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTimetableContent() {
    if (currentView == 'daily') {
      return _buildDailyTimetable();
    }
    return _buildTimetableBox();
  }

  Widget _buildTimetableBox() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Table(
            border: TableBorder.all(color: const Color(0xFFE9ECEF), width: 1),
            defaultColumnWidth: const IntrinsicColumnWidth(),
            columnWidths: const {0: IntrinsicColumnWidth(flex: 1.0)},
            children: [
              _buildTableHeader(),
              ..._timeSlots.map((timeSlot) => _buildTableRow(timeSlot)),
            ],
          ),
        ),
      ),
    );
  }

  TableRow _buildTableHeader() {
    return TableRow(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      children: [
        _headerCell("Time"),
        ..._days.map((day) => _headerCell(day)),
      ],
    );
  }

  Widget _headerCell(String t) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      child: Center(
        child: Text(
          t,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  TableRow _buildTableRow(String timeSlot) {
    DateTime now = DateTime.now();
    String today = DateFormat('EEEE').format(now);

    return TableRow(
      children: [
        _timeCell(timeSlot),
        ..._days.map((day) {
          bool highlight = (day == today);
          final dayIndex = _days.indexOf(day);
          var entry = _getEntryForDayAndTime(dayIndex, timeSlot);
          return _classCell(entry, highlight);
        }),
      ],
    );
  }

  Widget _timeCell(String time) {
    return Container(
      padding: const EdgeInsets.all(15),
      color: const Color(0xFFF8F9FA),
      child: Center(
        child: Text(
          time,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF667eea),
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _classCell(Map<String, dynamic>? entry, bool highlight) {
    Color cellColor = highlight
        ? const Color(0xFF667eea).withOpacity(0.1)
        : Colors.white;

    if (entry == null) {
      return Container(
        padding: const EdgeInsets.all(10),
        color: cellColor,
        child: const Center(
          child: Text(
            "Free",
            style: TextStyle(
              color: Color(0xFFCCCCCC),
              fontStyle: FontStyle.italic,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    final entryType = entry['entry_type'] ?? 'class';
    Color color;
    
    if (entryType == 'break') {
      color = const Color(0xFFED8936);
    } else if (entryType == 'lunch') {
      color = const Color(0xFF48BB78);
    } else {
      color = const Color(0xFF667eea);
    }

    return Container(
      padding: const EdgeInsets.all(10),
      color: cellColor,
      child: InkWell(
        onTap: () => _showEntryDetails(entry),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (entryType != 'class')
                Icon(
                  entryType == 'break' ? Icons.coffee_rounded : Icons.restaurant_rounded,
                  color: color,
                  size: 16,
                ),
              Text(
                entry['subject'] ?? (entryType == 'break' ? 'Break' : 'Lunch'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              if (entryType == 'class' && entry['class_obj'] != null) ...[
                const SizedBox(height: 3),
                Text(
                  'Class ${entry['class_obj']['name']} - ${entry['class_obj']['section']}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: color, fontSize: 10),
                ),
              ],
              if (entry['room'] != null && entry['room'].toString().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  entry['room'],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color.withOpacity(0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showEntryDetails(Map<String, dynamic> entry) {
    final entryType = entry['entry_type'] ?? 'class';
    Color color;
    
    if (entryType == 'break') {
      color = const Color(0xFFED8936);
    } else if (entryType == 'lunch') {
      color = const Color(0xFF48BB78);
    } else {
      color = const Color(0xFF667eea);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            if (entryType != 'class')
              Icon(
                entryType == 'break' ? Icons.coffee_rounded : Icons.restaurant_rounded,
                color: color,
              ),
            if (entryType != 'class') const SizedBox(width: 8),
            Expanded(
              child: Text(
                entry['subject'] ?? 'No Subject',
                style: TextStyle(color: color),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(Icons.access_time, '${_formatTimeSlot(entry['start_time'])} - ${_formatTimeSlot(entry['end_time'])}'),
            const SizedBox(height: 12),
            if (entry['class_obj'] != null)
              _buildDetailRow(Icons.people, 'Class ${entry['class_obj']['name']} - ${entry['class_obj']['section']}'),
            if (entry['class_obj'] != null) const SizedBox(height: 12),
            if (entry['room'] != null && entry['room'].toString().isNotEmpty) ...[
              _buildDetailRow(Icons.location_on, 'Room: ${entry['room']}'),
              const SizedBox(height: 12),
            ],
            _buildDetailRow(Icons.calendar_today, _days[entry['day_of_week'] ?? 0]),
          ],
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

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF667eea)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyTimetable() {
    final today = DateFormat('EEEE').format(DateTime.now());
    final classes = dailyClasses;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Text(
              'Schedule for $today (${classes.length} entries)',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF667eea),
              ),
            ),
          ),
          if (classes.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: Text(
                  '🎉 No classes scheduled for today!',
                  style: TextStyle(fontSize: 16, color: Colors.green),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: classes.length,
              itemBuilder: (context, index) {
                final entry = classes[index];
                final entryType = entry['entry_type'] ?? 'class';
                Color color;
                
                if (entryType == 'break') {
                  color = const Color(0xFFED8936);
                } else if (entryType == 'lunch') {
                  color = const Color(0xFF48BB78);
                } else {
                  color = const Color(0xFF667eea);
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withOpacity(0.2),
                      child: Icon(
                        entryType == 'break' ? Icons.coffee_rounded :
                        entryType == 'lunch' ? Icons.restaurant_rounded :
                        Icons.book,
                        color: color,
                      ),
                    ),
                    title: Text(
                      entry['subject'] ?? (entryType == 'break' ? 'Break' : 'Lunch'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${_formatTimeSlot(entry['start_time'])} - ${_formatTimeSlot(entry['end_time'])}'),
                        if (entry['class_obj'] != null)
                          Text('Class ${entry['class_obj']['name']} - ${entry['class_obj']['section']}'),
                        if (entry['room'] != null && entry['room'].toString().isNotEmpty)
                          Text('Room: ${entry['room']}'),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showEntryDetails(entry),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Legend',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 20,
            runSpacing: 10,
            children: [
              _legendItem(const Color(0xFF667eea), 'Class'),
              _legendItem(const Color(0xFFED8936), 'Break'),
              _legendItem(const Color(0xFF48BB78), 'Lunch'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
        ),
      ],
    );
  }
}
