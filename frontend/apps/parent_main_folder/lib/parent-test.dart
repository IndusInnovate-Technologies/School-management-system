import 'package:flutter/material.dart';

void main() {
  runApp(const ParentPortalApp());
}

class ParentPortalApp extends StatelessWidget {
  const ParentPortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Management - Parent Portal',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        primaryColor: const Color(0xFF6A67FC),
        fontFamily: 'Roboto',
      ),
      home: const TestManagementPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TestManagementPage extends StatelessWidget {
  final String? studentId;

  const TestManagementPage({super.key, this.studentId});

  // --- Mock Data (Unchanged) ---
  static final mockTests = [
    {
      "title": "Mathematics Mid-Term",
      "subject": "Mathematics",
      "date": "2024-12-15",
      "time": "10:00 AM",
      "duration": "2 hours",
      "status": "upcoming",
      "description":
          "Covers Algebra and Geometry chapters 1-5. Requires calculator and protractor.",
      "teacher": "Mrs. Johnson",
      "room": "Room 201",
    },
    {
      "title": "Science Unit Test",
      "subject": "Science",
      "date": "2024-12-12",
      "time": "2:00 PM",
      "duration": "1 hour",
      "status": "upcoming",
      "description":
          "Chemistry unit test on atomic structure and bonding. Review diagrams.",
      "teacher": "Mr. Smith",
      "room": "Lab 105",
    },
    {
      "title": "English Literature",
      "subject": "English",
      "date": "2024-12-10",
      "time": "9:00 AM",
      "duration": "1.5 hours",
      "status": "completed",
      "description":
          "Essay writing on Shakespeare's plays: Character analysis focus.",
      "teacher": "Ms. Davis",
      "room": "Room 103",
    },
    {
      "title": "History Final",
      "subject": "History",
      "date": "2024-12-18",
      "time": "11:00 AM",
      "duration": "2.5 hours",
      "status": "upcoming",
      "description":
          "Comprehensive final exam covering World War II, major battles and treaties.",
      "teacher": "Mr. Wilson",
      "room": "Room 205",
    },
    {
      "title": "Art History Quiz",
      "subject": "Art",
      "date": "2024-12-05",
      "time": "1:00 PM",
      "duration": "30 mins",
      "status": "completed",
      "description": "Quiz on Renaissance artists and their key works.",
      "teacher": "Ms. Lin",
      "room": "Art Studio",
    },
  ];

  void _showAction(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // --- Status and Icon Mapping (Unchanged) ---
  Map<String, dynamic> _getStatusStyle(String status) {
    if (status == 'upcoming') {
      return {
        'color': Colors.orange,
        'icon': Icons.schedule,
        'label': 'Upcoming',
        'badgeBg': Colors.orange.withValues(alpha: 0.15),
        'badgeFg': Colors.orange.darken(0.3),
      };
    }
    return {
      'color': Colors.green,
      'icon': Icons.check_circle_outline,
      'label': 'Completed',
      'badgeBg': Colors.green.withValues(alpha: 0.15),
      'badgeFg': Colors.green.darken(0.3),
    };
  }

  // --- Main Build Method ---
  @override
  Widget build(BuildContext context) {
    final totalTests = mockTests.length;
    final upcomingTests = mockTests
        .where((t) => t['status'] == 'upcoming')
        .length;
    final completedTests = mockTests
        .where((t) => t['status'] == 'completed')
        .length;

    // Days to Next Test (Simulated: find the earliest upcoming date)
    int daysToNextTest = 0;
    try {
      final upcomingDates = mockTests
          .where((t) => t['status'] == 'upcoming')
          .map((t) => DateTime.parse(t['date']!))
          .toList();
      upcomingDates.sort();
      if (upcomingDates.isNotEmpty) {
        daysToNextTest =
            upcomingDates.first.difference(DateTime.now()).inDays + 1;
        if (daysToNextTest < 0) daysToNextTest = 0;
      }
    } catch (_) {
      daysToNextTest = 0;
    }

    final currentTests = mockTests
        .where((t) => t['status'] == 'upcoming')
        .toList();

    return Scaffold(
      backgroundColor: const Color(
        0xfff5f6fa,
      ), // Light background color from previous code
      // 1. Mobile AppBar (Matching Image)
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF6A67FC),
        elevation: 0,
        toolbarHeight: 60,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),

        title: const Text(
          "Test Dashboard",
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: false,

        actions: const [],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 2. Stats Cards (Horizontal Scroll) - UPDATED TO MATCH IMAGE
            _buildStatsRow(
              totalTests,
              upcomingTests,
              completedTests,
              daysToNextTest,
            ),

            const SizedBox(height: 25),

            // 3. Upcoming Tests Section (Unchanged)
            _buildUpcomingTestsSection(context, currentTests),

            const SizedBox(height: 25),

            // 4. Quick Actions (Unchanged)
            _buildQuickActionsSection(context),
          ],
        ),
      ),
    );
  }

  // --- Widget Builders ---

  Widget _buildStatsRow(
    int total,
    int upcoming,
    int completed,
    int daysToNext,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Total Tests
          _StatCard(
            icon: Icons.collections_bookmark,
            iconColor: Colors.teal, // color used only for top border
            value: total.toString(),
            label: "Total Tests",
          ),
          const SizedBox(width: 10),
          // Upcoming
          _StatCard(
            icon: Icons.hourglass_top,
            iconColor: const Color(0xFF7A63F5),
            value: upcoming.toString(),
            label: "Upcoming",
          ),
          const SizedBox(width: 10),
          // Completed
          _StatCard(
            icon: Icons.check_box,
            iconColor: const Color(0xFF27DFA2),
            value: completed.toString(),
            label: "Completed",
          ),
          const SizedBox(width: 10),
          // Days to Next
          _StatCard(
            icon: Icons.calendar_today,
            iconColor: Colors.redAccent,
            value: daysToNext.toString(),
            label: "Days to Next",
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingTestsSection(
    BuildContext context,
    List<Map> currentTests,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "📅 Upcoming & Recent Tests",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 15),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: mockTests.length,
          itemBuilder: (context, index) {
            final test = mockTests[index];
            return _TestItemCard(
              test: test,
              style: _getStatusStyle(test['status'] as String),
              onTap: () => _showTestDetailsDialog(context, test),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "⚡ Quick Actions",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const Divider(height: 20),
          _ActionRow(
            icon: Icons.menu_book,
            label: "View Syllabus",
            onPressed: () => _showAction(context, "Syllabus requested."),
          ),
          _ActionRow(
            icon: Icons.download,
            label: "Download Materials",
            onPressed: () =>
                _showAction(context, "Materials download simulated."),
          ),
          _ActionRow(
            icon: Icons.chat,
            label: "Contact Teacher",
            onPressed: () => _showAction(context, "Opening chat with teacher."),
          ),
          _ActionRow(
            icon: Icons.help,
            label: "Request Clarification",
            onPressed: () => _showAction(context, "Clarification form opened."),
          ),
        ],
      ),
    );
  }

  void _showTestDetailsDialog(BuildContext context, Map test) {
    final style = _getStatusStyle(test['status'] as String);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            test["title"] as String,
            style: TextStyle(color: style['color'] as Color),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow("Subject", test["subject"]),
                _detailRow("Teacher", test["teacher"]),
                _detailRow("Room", test["room"]),
                _detailRow("Date", test["date"]),
                _detailRow("Time", test["time"]),
                _detailRow("Duration", test["duration"]),
                const Divider(),
                const Text(
                  "Description:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(test["description"] as String),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Text(
        "$label: $value",
        style: const TextStyle(fontSize: 15.5, color: Colors.black87),
      ),
    );
  }
}

// --- Reusable Component Widgets ---

class _StatCard extends StatelessWidget {
  final IconData icon; // Changed from String emoji to IconData
  final Color iconColor;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120, // slightly wider for label clarity
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        // color only applied to the top border as requested
        border: Border(top: BorderSide(color: iconColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon kept neutral; color emphasis remains on the top border only
          Icon(icon, color: Colors.grey[700], size: 26),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 24,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _TestItemCard extends StatelessWidget {
  final Map test;
  final Map style;
  final VoidCallback onTap;

  const _TestItemCard({
    required this.test,
    required this.style,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(color: style['color'] as Color, width: 5),
            ),
          ),
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    test["title"] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.5,
                      color: Color(0xFF333333),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: style['badgeBg'] as Color,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    child: Text(
                      style['label'] as String,
                      style: TextStyle(
                        color: style['badgeFg'] as Color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "📅 ${test["date"]} at ${test["time"]} | ${test["subject"]}",
                style: const TextStyle(fontSize: 13.5, color: Colors.black87),
              ),
              Text(
                "👨‍🏫 ${test["teacher"]} in ${test["room"]} (${test["duration"]})",
                style: const TextStyle(fontSize: 13.5, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                "Info: ${test["description"]}",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: Color(0xFF555555)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Theme.of(context).primaryColor),
        label: Text(label, style: const TextStyle(fontSize: 15)),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          alignment: Alignment.centerLeft,
          foregroundColor: const Color(0xFF333333),
          side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 15),
        ),
      ),
    );
  }
}

// Extension to darken colors slightly for contrast
extension on Color {
  Color darken(double amount) {
    final hsl = HSLColor.fromColor(this);
    final newLightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(newLightness).toColor();
  }
}
