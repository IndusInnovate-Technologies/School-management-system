import 'package:flutter/material.dart';
import 'package:main_login/main.dart' as main_login;
import 'services/api_service.dart' as api;
import 'package:core/api/api_service.dart';
import 'package:core/api/endpoints.dart';
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
// 1. DATA MODELS & MOCK DATA DEFINITIONS (ORIGINAL CONTENT RESTORED)
// -------------------------------------------------------------------------

class Activity {
  final int id;
  final String name;
  final String status;
  final String role;
  final String schedule;
  final String time;
  final String instructor;
  final int participation;

  const Activity({
    this.id = 0,
    required this.name,
    required this.role,
    required this.status,
    required this.schedule,
    required this.time,
    required this.instructor,
    required this.participation,
  });


  factory Activity.fromJson(Map<String, dynamic> json) {
    // Extract time from schedule if possible, or use a default
    // Schedule format might be "Monday 10:00 AM" or just "2025-01-01 10:00 AM"
    String timeStr = 'N/A';
    String scheduleStr = json['schedule'] ?? 'N/A';
    
    // Simple logic to extract time part if it looks like a datetime
    try {
      if (scheduleStr.contains(' ')) {
        // e.g. "2026-01-01 10:30 AM" -> split and take last parts?
        // Let's just keep the full schedule string in 'schedule' 
        // and try to parse a readable time for the 'time' field.
        // If it matches our knowing format:
         DateTime dt = DateFormat('yyyy-MM-dd hh:mm a').parse(scheduleStr);
         timeStr = DateFormat('hh:mm a').format(dt);
         scheduleStr = DateFormat('EEE, MMM d').format(dt);
      }
    } catch (e) {
      // Fallback if parsing fails
      timeStr = ''; 
    }

    return Activity(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unnamed Activity',
      status: 'active', // Default validation since status removed from backend
      role: 'Member', // Default role
      schedule: scheduleStr,
      time: timeStr,
      instructor: json['instructor'] ?? 'Unknown',
      participation: json['max_participants'] ?? 0, // Using max_participants as proxy for now
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

const List<Activity> mockActivities = [
  Activity(
    name: 'NCC (National Cadet Corps)',
    status: 'active',
    role: 'Active Member',
    schedule: 'Every Saturday',
    time: '4:00 PM - 5:30 PM',
    instructor: 'Capt. Sharma',
    participation: 100,
  ),
  Activity(
    name: 'Basketball Team',
    status: 'active',
    role: 'Team Captain',
    schedule: 'Mon, Wed, Fri',
    time: '3:30 PM - 5:00 PM',
    instructor: 'Coach Johnson',
    participation: 95,
  ),
  Activity(
    name: 'School Band',
    status: 'active',
    role: 'Lead Guitarist',
    schedule: 'Tuesday & Thursday',
    time: '5:00 PM - 6:00 PM',
    instructor: 'Ms. Davis',
    participation: 90,
  ),
  Activity(
    name: 'Drama Club',
    status: 'active',
    role: 'Actor',
    schedule: 'Friday Evening',
    time: '6:00 PM - 8:00 PM',
    instructor: 'Mr. Wilson',
    participation: 85,
  ),
  Activity(
    name: 'Science Club',
    status: 'inactive',
    role: 'Member',
    schedule: 'Monthly',
    time: '2:00 PM - 3:00 PM',
    instructor: 'Dr. Brown',
    participation: 75,
  ),
];

const List<Achievement> mockAchievements = [
  Achievement(
    title: 'District Basketball Champion',
    level: 'state',
    date: '2024-11-15',
    description: 'Led team to victory in district tournament',
  ),
  Achievement(
    title: 'NCC Best Cadet Award',
    level: 'school',
    date: '2024-10-20',
    description: 'Outstanding performance in NCC activities',
  ),
  Achievement(
    title: 'Music Competition Winner',
    level: 'school',
    date: '2024-09-30',
    description: 'First place in school music competition',
  ),
];

const List<Skill> mockSkills = [
  Skill(
    name: 'Leadership',
    level: 'excellent',
    description: 'Team captain, NCC leadership',
    progress: 95,
  ),
  Skill(
    name: 'Teamwork',
    level: 'excellent',
    description: 'Collaboration in sports and music',
    progress: 90,
  ),
  Skill(
    name: 'Communication',
    level: 'good',
    description: 'Public speaking, drama',
    progress: 85,
  ),
];

// -------------------------------------------------------------------------
// 2. MAIN APP SETUP & WIDGETS
// -------------------------------------------------------------------------

void main() {
  runApp(const SchoolApp());
}

class SchoolApp extends StatelessWidget {
  const SchoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF667EEA);

    return MaterialApp(
      title: 'Extracurricular Tracker',
      theme: ThemeData(
        primaryColor: primaryColor,
        fontFamily: 'Roboto',
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryColor,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        primarySwatch: createMaterialColor(primaryColor),
        scaffoldBackgroundColor: const Color(0xfff5f5f5),
        colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
      ),
      home: const ActivityScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {

  List<Achievement> _realAchievements = [];
  int _totalSchoolAwardsCount = 0;
  bool _isLoading = true;
  String? _error;

  List<Activity> _activities = [];

  String _errorMessage = '';


  @override
  void initState() {
    super.initState();

    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Fetch student-specific awards for display
      final studentData = await api.ApiService.fetchStudentProfile();
      if (studentData != null && studentData['awards'] != null) {
        final List<dynamic> awardsJson = studentJsonToAwards(studentData);
        
        setState(() {
          _realAchievements = awardsJson.map((a) {
            return Achievement(
              title: _safeString(a['title']),
              level: _safeString(a['level']),
              date: _safeString(a['date']),
              description: '${_safeString(a['category'])} - ${_safeString(a['description'])}',
            );
          }).toList();
        });
      } else {
        setState(() {
          _realAchievements = []; // Fallback to empty if no awards
        });
      }
      
      // Fetch all school awards for stat card count
      final allAwards = await api.ApiService.fetchAllAwards();
      setState(() {
        _totalSchoolAwardsCount = allAwards.length;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load data: $e';
          _isLoading = false;
        });
      }
    }
  }

  List<dynamic> studentJsonToAwards(Map<String, dynamic> data) {
    if (data['awards'] == null || data['awards'] is! List) return [];
    final list = List<dynamic>.from(data['awards']);
    
    // SORT LATEST-FIRST (ID primary for newest additions, Date secondary)
    list.sort((a, b) {
      final idA = int.tryParse(a['id']?.toString() ?? '0') ?? 0;
      final idB = int.tryParse(b['id']?.toString() ?? '0') ?? 0;
      if (idB != idA) return idB.compareTo(idA);

      final dateAStr = a['date']?.toString() ?? '';
      final dateBStr = b['date']?.toString() ?? '';
      final dateA = DateTime.tryParse(dateAStr) ?? DateTime(1900);
      final dateB = DateTime.tryParse(dateBStr) ?? DateTime(1900);
      return dateB.compareTo(dateA);
    });
    
    return list;
  }

  String _safeString(dynamic val) => val?.toString() ?? '';


  Future<void> _fetchActivities() async {
    try {
      final apiService = ApiService();
      final response = await apiService.get(Endpoints.activities);

      if (response.success && response.data != null) {
        List<dynamic> data = [];
        if (response.data is Map && response.data.containsKey('results')) {
          data = response.data['results'];
        } else if (response.data is List) {
          data = response.data;
        }

        setState(() {
          _activities = data.map((json) => Activity.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load activities';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  int _calculateAvgAttendance() {
    if (_activities.isEmpty) return 0;
    int totalParticipation = 0;
    for (var activity in _activities) {
      totalParticipation += activity.participation;
    }
    return (totalParticipation / _activities.length).round();

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
        'Extracurricular Dashboard',
        style: TextStyle(color: Colors.white),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(

          icon: const Icon(Icons.schedule),
          tooltip: 'Activity Schedule',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ActivityScheduleScreen(),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.person),
          onPressed: () => _handleAction(context, 'Profile'),
        ),
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


    if (_errorMessage.isNotEmpty && _activities.isEmpty) {
      return Scaffold(
        appBar: _buildAppBar(context),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage),
              ElevatedButton(
                onPressed: _fetchActivities,
                child: const Text('Retry'),
              )
            ],
          ),
        ),
      );
    }

    final activeActivitiesCount = _activities
        .where((a) => a.status == 'active')
        .length;
    final achievementsCount = mockAchievements.length;
    final skillsCount = mockSkills.length;
    final avgAttendance = _calculateAvgAttendance();

    // The list of stat cards using the custom design and original data
    // The list of stat cards using the custom design and original data
    final List<Map<String, dynamic>> originalStats = [
      {
        'number': activeActivitiesCount.toString(),
        'label': 'Active Activities',
        'emoji': '✨',
        'color': const Color(0xFF667EEA), // Blue/Purple (Like 'Due' from image)
      },
      {
        'number': achievementsCount.toString(),
        'label': 'Total Achievements',
        'emoji': '🏆',
        'color': const Color(0xFF40C057), // Green (Like 'Paid' from image)
      },
      {
        'number': '$avgAttendance%',
        'label': 'Avg. Attendance',
        'emoji': '📈',
        'color': const Color(0xFFFFC107), // Yellow/Orange
      },
      {
        'number': skillsCount.toString(),
        'label': 'Skills Developed',
        'emoji': '🧠',
        'color': const Color(0xFF9C27B0), // Purple (Like 'Date' from image)
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
          // Dynamic bottom padding for safe area + extra buffer
          MediaQuery.of(context).padding.bottom + 20.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // MODIFIED: Stat Cards Section using horizontal ListView
            SizedBox(
              height: 140, // Fixed height for the horizontal slider
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: statCards.length,
                itemBuilder: (context, index) {
                  // Wrap each card in a container to define its fixed width
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

                        // Pass 'a' (the Activity object) to detail screen
                        // Make sure ActivityDetailScreen can accept this Activity object
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

            // Achievements Section with Activity Schedule Tab
            _SectionHeader(title: 'Achievements & Awards 🏆'),
            _buildAchievementsScheduleSection(context),
            const SizedBox(height: 35),

            // Skills Section
            _SectionHeader(title: 'Skills Developed 🎨'),
            _SectionContainer(
              children: mockSkills
                  .map(
                    (s) => _SkillListTile(
                      skill: s,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SkillDetailScreen(skill: s),
                          ),
                        );
                      },
                    ),
                  )
                  .toList(),
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

  // Builds a tabbed card that shows Achievements and an Activity Schedule
  Widget _buildAchievementsScheduleSection(BuildContext context) {
    final int achCount = mockAchievements.length;

    final int actCount = mockActivities.length;

    final int maxCount = achCount > actCount ? achCount : actCount;
    final double computedHeight = (maxCount * 78.0) + 100.0;
    final double height = computedHeight.clamp(220.0, 600.0);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              labelColor: const Color(0xFF333333),
              indicatorColor: const Color(0xFF667EEA),
              tabs: const [
                Tab(text: 'Achievements'),
                Tab(text: 'Activity Schedule'),
              ],
            ),
            SizedBox(
              height: height,
              child: TabBarView(
                children: [
                  // Achievements list
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _realAchievements.isEmpty ? mockAchievements.length : _realAchievements.length,
                      itemBuilder: (context, index) {
                        final a = _realAchievements.isEmpty ? mockAchievements[index] : _realAchievements[index];

                        return _AchievementListTile(
                          achievement: a,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AchievementDetailScreen(achievement: a),
                              ),
                            );
                          },
                        );
                      },
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1, indent: 72, endIndent: 16),
                    ),
                  ),

                  // Activity Schedule list
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {

                        final a = mockActivities[index];

                        return _ActivityScheduleTile(
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
                        );
                      },
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1, indent: 16, endIndent: 16),

                      itemCount: mockActivities.length,

                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------------------
// 3. REUSABLE COMPONENTS (MODIFIED _StatCard UI)
// -------------------------------------------------------------------------

// MODIFIED WIDGET: Implements the requested UI style using original data structure
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

// Section Header Widget
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF333333),
        ),
      ),
    );
  }
}

// Section Container (using Card)
class _SectionContainer extends StatelessWidget {
  final List<Widget> children;

  const _SectionContainer({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(children: children),
    );
  }
}

// Activity Card using ListTile pattern
class _ActivityListTile extends StatelessWidget {
  final Activity activity;
  final VoidCallback onTap;

  const _ActivityListTile({required this.activity, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isActive = activity.status == 'active';
    final Color statusColor = isActive
        ? Colors.green.shade500
        : Colors.yellow.shade700;
    final IconData icon = isActive
        ? Icons.directions_run
        : Icons.pause_circle_outline;

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 8.0,
          ),
          leading: CircleAvatar(

            backgroundColor: statusColor.withValues(alpha: 0.1),

            child: Icon(icon, color: statusColor),
          ),
          title: Text(
            activity.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          subtitle: Text(
            '${activity.role} | ${activity.schedule}',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          trailing: Chip(
            label: Text(
              activity.status.toUpperCase(),
              style: TextStyle(
                color: isActive ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
            backgroundColor: statusColor,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
          ),
          onTap: onTap,
        ),
        // Add a Divider if it's not the last item in the list
        // Note: We need to access the list length to know if it is last.
        // For simplicity, we can just always add divider or handle this in ListView.separated
        // But since this is inside a column mapping, we'll leave as is or verify logic.
        // Assuming _ActivityListTile is used within a map, we can't easily check 'last' without context.
        // Let's just remove the divider logic here and rely on the container, or just leave it.
        // Ideally we should pass 'isLast' bool to this widget.
        const Divider(height: 1, indent: 72, endIndent: 16),
      ],
    );
  }
}

// Activity Schedule Tile with time pill on the right
class _ActivityScheduleTile extends StatelessWidget {
  final Activity activity;
  final VoidCallback onTap;

  const _ActivityScheduleTile({required this.activity, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isActive = activity.status == 'active';
    final Color accent = isActive
        ? Colors.green.shade500
        : Colors.grey.shade600;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ),
      leading: CircleAvatar(


        backgroundColor: accent.withValues(alpha: 0.12),

        child: Icon(Icons.event, color: accent),
      ),
      title: Text(
        activity.name,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Text(
        '${activity.role} • ${activity.schedule}',
        style: const TextStyle(color: Colors.grey, fontSize: 13),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.teal.shade400,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          activity.time,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      onTap: onTap,
    );
  }
}

// Achievement Card using ListTile pattern
class _AchievementListTile extends StatelessWidget {
  final Achievement achievement;
  final VoidCallback onTap;

  const _AchievementListTile({required this.achievement, required this.onTap});

  Color getLevelColor() {
    switch (achievement.level) {
      case 'state':
        return const Color(0xFF4DABF7);
      case 'school':
        return const Color(0xFFFFD43B);
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color color = getLevelColor();
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ),
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(Icons.star, color: color),
      ),
      title: Text(
        achievement.title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Text(
        'Awarded: ${achievement.date}',
        style: const TextStyle(color: Colors.grey, fontSize: 13),
      ),
      trailing: Chip(
        label: Text(
          achievement.level.toUpperCase(),
          style: TextStyle(
            color: achievement.level == 'school'
                ? Colors.black87
                : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      ),
      onTap: onTap,

    );
  }
}

// Skill Card using ListTile pattern
class _SkillListTile extends StatelessWidget {
  final Skill skill;
  final VoidCallback onTap;

  const _SkillListTile({required this.skill, required this.onTap});

  Color getLevelColor() {
    switch (skill.level) {
      case 'excellent':
        return const Color(0xFF40C057);
      case 'good':
        return const Color(0xFF4DABF7);
      default:
        return const Color(0xFFFFC107);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color color = getLevelColor();

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 8.0,
          ),
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(Icons.psychology_outlined, color: color),
          ),
          title: Text(
            skill.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          // Subtitle showing progress bar
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: LinearProgressIndicator(
              value: skill.progress / 100,
              backgroundColor: Colors.grey.shade300,
              color: color,
              minHeight: 5,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          trailing: Chip(
            label: Text(
              skill.level.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
          ),
          onTap: onTap,
        ),
        if (mockSkills.indexOf(skill) != mockSkills.length - 1)
          const Divider(height: 1, indent: 72, endIndent: 16),
      ],

    );
  }
}

// --- NEW WIDGET: Gradient Action Button ---
class _GradientActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  // Define gradient colors matching the overall theme
  static const List<Color> gradientColors = [
    Color(0xFF5568D7), // Darker indigo/purple
    Color(0xFF667EEA), // Original primary color
  ];

  const _GradientActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      // Add margin for spacing between buttons
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: const LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(

            color: const Color(0xFF667EEA).withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- NEW WIDGET: Quick Actions Card (Replaces _QuickActionsGrid logic) ---
class _QuickActionsCard extends StatelessWidget {
  final Function(String) onAction;

  const _QuickActionsCard({required this.onAction});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> actions = [
      {'label': 'Join New Activity', 'icon': Icons.add},
      {'label': 'Contact Coach', 'icon': Icons.chat_bubble_outline},
      {'label': 'View Calendar', 'icon': Icons.calendar_today},
      {'label': 'Download Certificates', 'icon': Icons.file_download_outlined},
    ];

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header matching the image style
            const Padding(
              padding: EdgeInsets.only(bottom: 15.0),
              child: Text(
                '⚡ Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            // Separator as seen in the image
            const Divider(height: 1, thickness: 1, color: Colors.grey),
            const SizedBox(height: 15),

            // Stacked gradient buttons
            ...actions.map((action) {
              return _GradientActionButton(
                label: action['label'] as String,
                icon: action['icon'] as IconData,
                onPressed: () => onAction(action['label'] as String),
              );
            }),
            // The last button already has padding from its internal margin.
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------------------
// 4. DETAIL SCREENS (Optimized for no overflow)
// -------------------------------------------------------------------------

class ActivityDetailScreen extends StatelessWidget {
  final Activity activity;
  const ActivityDetailScreen({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final bool isActive = activity.status == 'active';
    return Scaffold(
      appBar: AppBar(title: Text(activity.name)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Container(
              padding: const EdgeInsets.all(30.0),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Details for ${activity.name}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF667EEA),
                    ),
                  ),
                  const Divider(height: 30),
                  _DetailRow(
                    label: 'Role',
                    value: activity.role,
                    icon: Icons.person,
                  ),
                  _DetailRow(
                    label: 'Schedule',
                    value: activity.schedule,
                    icon: Icons.schedule,
                  ),
                  _DetailRow(
                    label: 'Instructor',
                    value: activity.instructor,
                    icon: Icons.school,
                  ),
                  _DetailRow(
                    label: 'Participation',
                    value: '${activity.participation}%',
                    icon: Icons.bar_chart,
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Chip(
                      label: Text(
                        activity.status.toUpperCase(),
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.black,
                        ),
                      ),
                      backgroundColor: isActive
                          ? Colors.green
                          : Colors.yellow.shade600,
                    ),
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

class AchievementDetailScreen extends StatelessWidget {
  final Achievement achievement;
  const AchievementDetailScreen({super.key, required this.achievement});

  Color getLevelColor() {
    switch (achievement.level) {
      case 'state':
        return const Color(0xFF4DABF7);
      case 'school':
        return const Color(0xFFFFD43B);
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color color = getLevelColor();
    return Scaffold(
      appBar: AppBar(title: Text(achievement.title)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Container(
              padding: const EdgeInsets.all(30.0),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    achievement.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF667EEA),
                    ),
                  ),
                  const Divider(height: 30),
                  _DetailRow(
                    label: 'Awarded on',
                    value: achievement.date,
                    icon: Icons.date_range,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Description:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    achievement.description,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Chip(
                      label: Text(
                        achievement.level.toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: color,
                    ),
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

class SkillDetailScreen extends StatelessWidget {
  final Skill skill;
  const SkillDetailScreen({super.key, required this.skill});

  Color getLevelColor() {
    switch (skill.level) {
      case 'excellent':
        return const Color(0xFF40C057);
      case 'good':
        return const Color(0xFF4DABF7);
      default:
        return const Color(0xFFFFC107);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color color = getLevelColor();
    return Scaffold(
      appBar: AppBar(title: Text(skill.name)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Container(
              padding: const EdgeInsets.all(30.0),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    skill.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF667EEA),
                    ),
                  ),
                  const Divider(height: 30),
                  _DetailRow(
                    label: 'Level',
                    value: skill.level.toUpperCase(),
                    icon: Icons.trending_up,
                    color: color,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Progress: ${skill.progress}%',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  LinearProgressIndicator(
                    value: skill.progress / 100,
                    backgroundColor: Colors.grey.shade300,
                    color: color,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Description:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    skill.description,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
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

// Reusable Detail Row for detail screens
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
    this.color = const Color(0xFF667EEA),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start, // Align to start for long text
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(
            '$label:',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 5),
          Expanded(
            // Used Expanded for proper space distribution
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              overflow: TextOverflow.ellipsis, // Added overflow handling
              maxLines: 2, // Allow value to span up to 2 lines
            ),
          ),
        ],
      ),
    );
  }
}

// Full screen Activity Schedule for quick access
class ActivityScheduleScreen extends StatelessWidget {
  const ActivityScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activity Schedule')),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          itemCount: mockActivities.length,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            final a = mockActivities[index];
            return _ActivityScheduleTile(
              activity: a,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ActivityDetailScreen(activity: a),
                  ),
                );
              },
            );
          },
          separatorBuilder: (context, index) =>
              const Divider(height: 1, indent: 16, endIndent: 16),
        ),
      ),
    );
  }
}
