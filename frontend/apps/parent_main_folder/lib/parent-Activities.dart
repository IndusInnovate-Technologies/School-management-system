import 'package:flutter/material.dart';
import 'package:main_login/main.dart' as main_login;
import 'services/api_service.dart';
import 'package:intl/intl.dart';

// --- UTILITY FUNCTION TO CREATE CUSTOM MATERIAL COLOR ---
MaterialColor createMaterialColor(Color color) {
  List strengths = <double>[.05, .1, .2, .3, .4, .5, .6, .7, .8, .9];
  Map<int, Color> swatch = {};
  final int r = color.red, g = color.green, b = color.blue;

  swatch[50] = Color.fromRGBO(r, g, b, .05);
  for (int i = 0; i < strengths.length; i++) {
    final strength = strengths[i];
    // Cast to int for Map key as strength * 1000 is double
    swatch[((strength * 1000)).round()] = Color.fromRGBO(r, g, b, strength);
  }
  return MaterialColor(color.value, swatch);
}

// -------------------------------------------------------------------------
// 1. DATA MODELS
// -------------------------------------------------------------------------

class Event {
  final int id;
  final String name;
  final String status;
  final DateTime? startDatetime;
  final DateTime? endDatetime;
  final String location;
  final String category;
  final String description;
  final String organizer;
  final int participants;

  const Event({
    required this.id,
    required this.name,
    required this.status,
    required this.startDatetime,
    this.endDatetime,
    required this.location,
    this.category = '',
    this.description = '',
    this.organizer = '',
    this.participants = 0,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    DateTime? start;
    DateTime? end;
    
    // Parse Start Date
    if (json['start_datetime'] != null) {
       start = DateTime.tryParse(json['start_datetime']);
    } else if (json['date'] != null) {
       // Fallback for older API format
       try {
         start = DateTime.parse(json['date']);
       } catch (_) {}
    }

    // Parse End Date
    if (json['end_datetime'] != null) {
       end = DateTime.tryParse(json['end_datetime']);
    }

    return Event(
      id: json['id'] is int ? json['id'] : 0,
      name: json['title'] ?? json['name'] ?? 'Unnamed Event',
      status: json['status'] ?? 'Upcoming',
      startDatetime: start,
      endDatetime: end,
      location: json['location'] ?? 'School',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      organizer: json['organizer'] ?? '',
      participants: json['participants'] ?? 0,
    );
  }
}

class Activity {
  final int id;
  final String name;
  final String status;
  final String role;
  final String schedule;
  final String time;
  final String instructor;
  final int participation;
  final String category;
  final String description;

  const Activity({
    this.id = 0,
    required this.name,
    required this.status,
    required this.role,
    required this.schedule,
    required this.time,
    required this.instructor,
    required this.participation,
    this.category = '',
    this.description = '',
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    // Backend returns: schedule, start_date, max_participants, description, etc.
    String scheduleStr = json['schedule'] ?? 'N/A';
    String timeStr = '';
    
    // Try to extract time if present in schedule
    // Logic kept simple as per requirement
    if (scheduleStr.contains(' ')) {
      // Very basic heuristic
       // timeStr = ...
    }

    return Activity(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unnamed Activity',
      status: json['status'] ?? 'active', 
      role: 'Member', // Default as we don't track specific student role yet
      schedule: scheduleStr,
      time: timeStr,
      instructor: json['instructor'] ?? 'Unknown',
      participation: json['max_participants'] ?? 0,
      category: json['category'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

class Achievement {
  final String title;
  final String level;
  final String date;
  final String description;

  const Achievement({
    required this.title,
    required this.level,
    required this.date,
    required this.description,
  });
}

class Skill {
  final String name;
  final String level;
  final String description;
  final int progress;

  const Skill({
    required this.name,
    required this.level,
    required this.description,
    required this.progress,
  });
}

// -------------------------------------------------------------------------
// 2. MAIN APP SETUP & WIDGETS
// -------------------------------------------------------------------------

class ActivityScreen extends StatefulWidget {
  final String? studentId;
  const ActivityScreen({super.key, this.studentId});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  List<Activity> _activities = [];
  List<Event> _events = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchActivitiesAndEvents();
  }

  Future<void> _fetchActivitiesAndEvents() async {
    try {
      // 1. Fetch Activities
      final activityData = await ApiService.fetchActivities(studentId: widget.studentId);
      
      // 2. Fetch All Events (Replaced fetchRecentEvents to show full list)
      final eventData = await ApiService.fetchAllEvents(studentId: widget.studentId);

      List<Activity> loadedActivities = [];
      List<Event> loadedEvents = [];

      if (activityData != null) {
         loadedActivities = activityData.map((json) => Activity.fromJson(json)).toList();
      }

      if (eventData != null) {
         loadedEvents = eventData.map((json) => Event.fromJson(json)).toList();
      }

      if (mounted) {
        setState(() {
          _activities = loadedActivities;
          _events = loadedEvents;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  int _calculateAvgAttendance() {
    // Placeholder logic since we don't have per-activity attendance
    if (_activities.isEmpty) return 0;
    return 85; // Default average for display if data missing
  }

  void _handleAction(BuildContext context, String action) {
    if (action == 'Logout') {
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const main_login.LoginScreen(),
                    ),
                    (route) => false,
                  );
                },
                child: const Text('Logout', style: TextStyle(color: Colors.red)),
              ),
            ],
          );
        },
      );
    } else if (action == 'Back to Dashboard') {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$action tapped!')));
    }
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text(
        'Activities & Events',
        style: TextStyle(color: Colors.white),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () => _handleAction(context, 'Logout'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: _buildAppBar(context),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage.isNotEmpty && _activities.isEmpty && _events.isEmpty) {
      return Scaffold(
        appBar: _buildAppBar(context),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage),
              ElevatedButton(
                onPressed: _fetchActivitiesAndEvents,
                child: const Text('Retry'),
              )
            ],
          ),
        ),
      );
    }

    // Since we don't have achievements/skills models yet, we show placeholders or 0
    final achievementsCount = 0; 
    final skillsCount = 0;
    final avgAttendance = _calculateAvgAttendance();

    final List<Map<String, dynamic>> originalStats = [
      {
        'number': _activities.length.toString(),
        'label': 'Active Activities',
        'emoji': '✨',
        'color': const Color(0xFF667EEA), 
      },
      {
        'number': _events.length.toString(),
        'label': 'Upcoming Events',
        'emoji': '📅',
        'color': const Color(0xFFFF5722),
      },
      {
        'number': achievementsCount.toString(),
        'label': 'Achievements',
        'emoji': '🏆',
        'color': const Color(0xFF40C057),
      },
      {
        'number': '$avgAttendance%',
        'label': 'Avg. Attendance',
        'emoji': '📈',
        'color': const Color(0xFFFFC107), 
      },
      {
        'number': skillsCount.toString(),
        'label': 'Skills',
        'emoji': '🧠',
        'color': const Color(0xFF9C27B0),
      },
    ];

    final List<Widget> statCards = originalStats
        .map(
          (stat) => _StatCard(
            number: stat['number'] as String,
            label: stat['label'] as String,
            emoji: stat['emoji'] as String,
            borderColor: stat['color'] as Color,
          ),
        )
        .toList();

    return Scaffold(
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16.0,
          16.0,
          16.0,
          MediaQuery.of(context).padding.bottom + 20.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Stat Cards Section
            SizedBox(
              height: 160, 
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: statCards.length,
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: MediaQuery.of(context).size.width * 0.45,
                    child: statCards[index],
                  );
                },
                separatorBuilder: (context, index) => const SizedBox(width: 10),
              ),
            ),
            const SizedBox(height: 35),

            // Current Activities Section
            _SectionHeader(title: 'Current Activities 🎯'),
            _activities.isEmpty 
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No activities found.'),
                )
              : _SectionContainer(
              children: _activities
                  .map(
                    (a) => _ActivityListTile(
                      activity: a,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ActivityDetailScreen(activity: a),
                          ),
                        );
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 35),
            
             // Current Events Section
            _SectionHeader(title: 'Upcoming Events 📅'),
            _events.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No upcoming events found.'),
                  )
                : _SectionContainer(
                    children: _events.map((e) => _EventListTile(event: e)).toList(),
                  ),
            const SizedBox(height: 35),

            // Achievements Section (Placeholder)
            _SectionHeader(title: 'Achievements & Awards 🏆'),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text("No achievements recorded yet.", style: TextStyle(color: Colors.grey)),
            ),
            const SizedBox(height: 35),

            // Skills Section (Placeholder)
            _SectionHeader(title: 'Skills Developed 🎨'),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text("No skills recorded yet.", style: TextStyle(color: Colors.grey)),
            ),
            const SizedBox(height: 35),

            // Quick Actions Section
            _QuickActionsCard(
              onAction: (action) => _handleAction(context, action),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------------------
// 3. REUSABLE COMPONENTS
// -------------------------------------------------------------------------

class _StatCard extends StatelessWidget {
  final String number;
  final String label;
  final String emoji;
  final Color borderColor;

  const _StatCard({
    required this.number,
    required this.label,
    required this.emoji,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 110, // Matching the requested rectangle look
      margin: const EdgeInsets.symmetric(horizontal: 5),
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
              color: borderColor,
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
                Text(emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 4),
                Text(
                  number,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
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
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
        ),
      ),
    );
  }
}

class _SectionContainer extends StatelessWidget {
  final List<Widget> children;
  const _SectionContainer({required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _ActivityListTile extends StatelessWidget {
  final Activity activity;
  final VoidCallback onTap;

  const _ActivityListTile({required this.activity, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
        child: Icon(Icons.star, color: Theme.of(context).primaryColor),
      ),
      title: Text(activity.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(activity.category),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
    );
  }
}

class _EventListTile extends StatelessWidget {
  final Event event;
  const _EventListTile({required this.event});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailScreen(event: event),
          ),
        );
      },
      leading: CircleAvatar(
        backgroundColor: Colors.orange.withOpacity(0.1),
        child: const Icon(Icons.event, color: Colors.orange),
      ),
      title: Text(event.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(event.status),
      trailing: Text(
        event.startDatetime != null 
            ? DateFormat('MM/dd').format(event.startDatetime!) 
            : '',
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }
}

class ActivityDetailScreen extends StatelessWidget {
  final Activity activity;
  const ActivityDetailScreen({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(activity.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Instructor: ${activity.instructor}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Schedule: ${activity.schedule}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Text('Description: ${activity.description}', style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class EventDetailScreen extends StatelessWidget {
  final Event event;

  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(event.name),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.event_note, size: 40, color: Colors.orange.shade800),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event.category.isNotEmpty ? event.category : 'General',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: event.status == 'Upcoming' ? Colors.green.shade100 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      event.status,
                      style: TextStyle(
                        color: event.status == 'Upcoming' ? Colors.green.shade800 : Colors.grey.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Details Section
            const Text(
              "Event Details",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            
            _buildDetailRow(Icons.calendar_today, "Start Date", 
              event.startDatetime != null 
                ? DateFormat('EEEE, MMM d, yyyy • h:mm a').format(event.startDatetime!)
                : 'TBA'
            ),
            if (event.endDatetime != null)
              _buildDetailRow(Icons.calendar_today, "End Date", 
                DateFormat('EEEE, MMM d, yyyy • h:mm a').format(event.endDatetime!)
              ),
            _buildDetailRow(Icons.location_on, "Location", event.location),
            if (event.organizer.isNotEmpty)
              _buildDetailRow(Icons.person, "Organizer", event.organizer),
            if (event.participants > 0)
              _buildDetailRow(Icons.groups, "Participants", "${event.participants} people"),

            const SizedBox(height: 24),
            
            // Description Section
            if (event.description.isNotEmpty) ...[
              const Text(
                "Description",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  event.description,
                  style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SkillDetailScreen extends StatelessWidget {
  final Skill skill;
  const SkillDetailScreen({super.key, required this.skill});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(skill.name)),
      body: const Center(child: Text("Details comming soon")),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  final Function(String) onAction;
  const _QuickActionsCard({required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.arrow_back),
              title: const Text('Back to Dashboard'),
              onTap: () => onAction('Back to Dashboard'),
            ),
             ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () => onAction('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
