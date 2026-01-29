import 'dart:math';
import 'package:flutter/material.dart';
import 'package:main_login/main.dart' as main_login;
import 'services/api_service.dart' as api;

void main() {
  runApp(const MyClassesApp());
}

class MyClassesApp extends StatelessWidget {
  const MyClassesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Teacher Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF667eea),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        useMaterial3: false,
      ),
      home: const MyClassesPage(),
    );
  }
}

class MyClassesPage extends StatefulWidget {
  const MyClassesPage({super.key});

  @override
  State<MyClassesPage> createState() => _MyClassesPageState();
}

class _MyClassesPageState extends State<MyClassesPage> {
  bool isLoading = true;
  List<Map<String, dynamic>> classes = [];

  // Define colors for the class card borders and stats backgrounds
  final List<Color> classColors = const [
    Color(0xFF667eea), // Blue/Purple for Mathematics (Class A)
    Color(0xFF28a745), // Green for Science (Class B)
    Color(0xFFFDCB3F), // Yellow/Gold for English (Class C)
    Color(0xFFff6b6b), // Red/Pink for History (Class D)
    Color(0xFF845ef7), // Indigo for Geography (Class E)
    Color(0xFFfd7e14), // Orange for Physics (Class F)
  ];

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  void _loadClasses() async {
    try {
      final data = await api.ApiService.fetchTeacherClasses();
      setState(() {
        classes = data.map<Map<String, dynamic>>((json) {
           return {
             'id': json['id'],
             'name': json['name'],
             'section': json['section'],
             'subject': (json['subjects'] != null && (json['subjects'] as List).isNotEmpty) 
                 ? (json['subjects'] as List).first.toString() 
                 : 'General',
             'icon': '📚', // Default icon
             'students': json['students_count'] ?? 0,
             'attendance': -1, // Not provided by this API
             'schedule': json['schedule_summary'] ?? 'TBA',
             'room': json['room_number'] ?? 'TBA',
             'color': classColors[classes.length % classColors.length],
           };
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading classes: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) return;
        Navigator.of(context).pop();
      },
      child: Scaffold(
        body: Column(
          children: [
            _buildHeader(context),
          Expanded(
            child: isLoading
                ? _buildLoading()
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            "My Classes",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF667eea),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildStatsSummary(context), // Horizontal Stats View
                        const SizedBox(height: 20),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            "Class Details",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF444444),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildClassList(context),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2), Color(0xFFF093FB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              "My Classes",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- MODIFIED METHOD FOR HORIZONTAL SLIDE VIEW ---
  Widget _buildStatsSummary(BuildContext context) {
    final totalClasses = classes.length;
    final totalStudents = classes.fold(
      0,
      (sum, c) => sum + (c['students'] as int),
    );
    final subjects = classes.map((c) => c['subject']).toSet().length;
    final avgAttendance = classes.isNotEmpty
        ? (classes.fold(0, (sum, c) => sum + (c['attendance'] as int)) /
                  classes.length)
              .round()
        : 0;

    // The statistics data map
    final List<Map<String, dynamic>> stats = [
      {
        'icon': Icons.menu_book,
        'value': totalClasses.toString(),
        'label': 'Total Classes',
        'color': const Color(0xFF667eea),
      },
      {
        'icon': Icons.group,
        'value': totalStudents.toString(),
        'label': 'Total Students',
        'color': const Color(0xFF845ef7),
      },
      {
        'icon': Icons.edit_note,
        'value': subjects.toString(),
        'label': 'Subjects Taught',
        'color': const Color(0xFF667eea),
      },
      {
        'icon': Icons.trending_up,
        'value': '$avgAttendance%',
        'label': 'Avg Attendance',
        'color': const Color(0xFF28a745),
      },
    ];

    // Grouping stats into pairs for side-by-side view (2 cards per "slide")
    final int pageCount = (stats.length / 2).ceil();

    return SizedBox(
      height: 180, // Fixed height for the horizontal list view
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: pageCount,
        itemBuilder: (context, index) {
          // Calculate the start index for the pair of cards
          final int startIndex = index * 1;

          // Get the first stat card in the pair
          final Map<String, dynamic> stat1 = stats[startIndex];

          // Check if there is a second stat card
          final Map<String, dynamic>? stat2 = startIndex + 1 < stats.length
              ? stats[startIndex + 1]
              : null;

          return Container(
            width: MediaQuery.of(
              context,
            ).size.width, // Each item takes full width
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // First Stat Card
                _buildStatCard(context, stat1),

                const SizedBox(width: 12),

                // Second Stat Card (if available)
                stat2 != null
                    ? _buildStatCard(context, stat2)
                    : const Expanded(
                        child: SizedBox.shrink(),
                      ), // Keep alignment if odd number of cards
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, Map<String, dynamic> stat) {
    final Color txtColor = stat['color'] as Color;

    return Expanded(
      child: Container(
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
              decoration: BoxDecoration(
                color: txtColor,
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
                  Icon(stat['icon'] as IconData, size: 28, color: txtColor),
                  const SizedBox(height: 6),
                  Text(
                    stat['value'],
                    style: TextStyle(
                      color: txtColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    stat['label'],
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
      ),
    );
  }

  /// ✅ Replaced grid with vertical list layout
  Widget _buildClassList(BuildContext context) {
    return Column(
      children: classes.map((c) {
        final Color borderColor =
            c['color'] as Color; // Get color for the border

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
            border: Border(
              left: BorderSide(
                color: borderColor,
                width: 5,
              ), // Apply unique left border color
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          c['subject'],
                          style: TextStyle(
                            color: const Color(0xFF667eea),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Text(c['icon'], style: const TextStyle(fontSize: 26)),
                  ],
                ),
                const SizedBox(height: 8),
                _detailItem("Students", "${c['students']}"),
                _detailItem("Attendance", "${c['attendance']}%"),
                _detailItem("Schedule", c['schedule']),
                _detailItem("Room", c['room']),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _actionButton(
                        "👥 Students",
                        const Color(0xFF667eea),
                        null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _actionButton(
                        "📊 Attendance",
                        const Color(0xFF28a745),
                        null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _detailItem(String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF666666),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF000000),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String text, Color color, VoidCallback? onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(60.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF667eea)),
            SizedBox(height: 20),
            Text(
              "Loading your classes...",
              style: TextStyle(
                color: Color(0xFF666666),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _viewClassStudents(Map<String, dynamic> c) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Viewing students of ${c['name']}")));
  }

  void _markAttendance(Map<String, dynamic> c) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Marking attendance for ${c['name']}")),
    );
  }
}
