import 'package:flutter/material.dart';

void main() {
  runApp(const ParentPortalApp());
}

class ParentPortalApp extends StatelessWidget {
  const ParentPortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parent Portal - Results',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        primaryColor: const Color(0xFF6A67FC),
        fontFamily: 'Roboto',
      ),
      home: const ResultsPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// --- Data Models and Constants (Restored details for dialog) ---

const List<Map<String, dynamic>> ALL_RESULTS = [
  {
    "subject": "Mathematics",
    "examType": "Mid-Term",
    "score": 92,
    "grade": "A",
    "date": "2024-12-01",
    "teacher": "Mr.vamshi",
    "classAverage": 88,
    "feedback":
        "Excellent performance on algebraic concepts. Great attention to detail and zero careless errors.",
    "status": "completed",
  },
  {
    "subject": "Science",
    "examType": "Unit Test",
    "score": 95,
    "grade": "A+",
    "date": "2024-11-28",
    "teacher": "Dr. Johnson",
    "classAverage": 90,
    "feedback":
        "Mastery of the renewable energy unit. Keep up the high standard in the lab reports.",
    "status": "completed",
  },
  {
    "subject": "English",
    "examType": "Final Exam",
    "score": 87,
    "grade": "B+",
    "date": "2024-11-25",
    "teacher": "Ms. Davis",
    "classAverage": 82,
    "feedback":
        "Strong literary analysis, but the grammar section needs minor revision before the next exam.",
    "status": "completed",
  },
  {
    "subject": "History",
    "examType": "Project",
    "score": 89,
    "grade": "A-",
    "date": "2024-11-20",
    "teacher": "Mr. Thompson",
    "classAverage": 85,
    "feedback":
        "Project well-researched, but presentation lacked structured argumentation.",
    "status": "completed",
  },
  {
    "subject": "Geography",
    "examType": "Quiz",
    "score": 91,
    "grade": "A",
    "date": "2024-11-18",
    "teacher": "Mr. Thompson",
    "classAverage": 91,
    "feedback": "Solid understanding of global physical geography.",
    "status": "completed",
  },
];

class ResultsPage extends StatelessWidget {
  const ResultsPage({super.key});

  // --- Mock Data ---
  final stats = const [
    {
      "icon": Icons.auto_stories,
      "iconColor": Color(0xFF7246d9),
      "value": "3.8",
      "label": "Overall GPA",
    },
    {
      "icon": Icons.emoji_events,
      "iconColor": Colors.amber,
      "value": "5th",
      "label": "Class Rank",
    },
    {
      "icon": Icons.show_chart,
      "iconColor": Colors.indigo,
      "value": "95%",
      "label": "Attendance",
    },
    {
      "icon": Icons.collections,
      "iconColor": Colors.teal,
      "value": "6",
      "label": "Total Subjects",
    },
  ];

  final performance = const {
    "Mathematics": 92,
    "Science": 95,
    "English": 87,
    "History": 89,
    "Geography": 35,
  };
  // ------------------------------------

  // Helper function for conditional color mapping (for performance bars and dialogs)
  Color _getScoreColor(int score) {
    if (score >= 90) return const Color(0xff27dfa2);
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  // Helper function for simulated action
  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }

  // --- ADDED: Details Dialog Function ---
  void _showResultDetailsDialog(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text("${data["subject"]} - ${data["examType"]}"),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogDetailRow(
                  context,
                  "Score",
                  "${data["score"]}%",
                  color: _getScoreColor(data["score"] as int),
                ),
                _buildDialogDetailRow(
                  context,
                  "Grade",
                  data["grade"].toString(),
                  color: const Color(0xFF7246d9),
                ),
                _buildDialogDetailRow(
                  context,
                  "Class Avg",
                  "${data["classAverage"]}%",
                ),
                _buildDialogDetailRow(context, "Date", data["date"].toString()),
                _buildDialogDetailRow(
                  context,
                  "Teacher",
                  data["teacher"].toString(),
                ),
                const Divider(height: 20),
                const Text(
                  "Teacher Feedback:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(data["feedback"].toString()),
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

  Widget _buildDialogDetailRow(
    BuildContext context,
    String label,
    String value, {
    Color color = Colors.black87,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const appBarColor = Color(0xFF6A67FC);

    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),

      // 1. Fixed AppBar (Matching the Image Style)
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: appBarColor,
        elevation: 0,
        toolbarHeight: 60,

        // Back Button
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),

        // Title (Matching the blurred white text from the image)
        title: const Text(
          "Results Dashboard",
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: false,

        // Actions (Refresh and Profile Icons from the image)
        actions: const [],
      ),

      body: SingleChildScrollView(
        // Reduced bottom padding now that quick actions are part of the scrollable content
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 2. Horizontal Scrolling Stats Cards
            _buildStatsCards(),

            // 3. Performance Overview
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: _buildPerformanceOverview(),
            ),

            // 4. Recent Results List (Updated to use InkWell and show dialog)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 25, 16, 0),
              child: _buildRecentResultsList(context),
            ),

            // --- Insert Quick Actions here so they scroll after results ---
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
              child: _QuickActionsPanel(
                onAction: (label) => _showSnackbar(context, label),
              ),
            ),
          ],
        ),
      ),

      // Removed bottomNavigationBar so quick actions are part of scrollable content
      // ...existing code...
    );
  }

  Widget _buildStatsCards() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      child: Row(
        children: stats
            .map(
              (s) => _StatCard(
                icon: s["icon"] as IconData,
                iconColor: s["iconColor"] as Color,
                value: s["value"].toString(),
                label: s["label"].toString(),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildPerformanceOverview() {
    return Container(
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
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "📊 Subject Performance",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xFF34376a),
            ),
          ),
          const Divider(height: 25, thickness: 1),
          ...performance.entries.map((e) {
            return _PerformanceBar(
              subject: e.key,
              score: e.value,
              scoreColor: _getScoreColor(e.value), // Color mapping
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecentResultsList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "📋 Recent Results",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF34376a),
          ),
        ),
        const SizedBox(height: 15),
        // Use the onTap property to trigger the details dialog
        ...ALL_RESULTS.map(
          (r) => _ResultTile(
            data: r,
            onTap: () => _showResultDetailsDialog(
              context,
              r,
            ), // Taps now open the dialog
          ),
        ),
      ],
    );
  }
}

// --- Custom Mobile Widgets (Refactored) ---

class _StatCard extends StatelessWidget {
  final IconData icon;
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
      width: 140,
      height: 110, // Matching the requested rectangle look
      margin: const EdgeInsets.symmetric(horizontal: 6),
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
              color: iconColor,
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
                Icon(icon, color: iconColor, size: 28),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF34376a),
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

class _PerformanceBar extends StatelessWidget {
  final String subject;
  final int score;
  final Color scoreColor;

  const _PerformanceBar({
    required this.subject,
    required this.score,
    required this.scoreColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                subject,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                  color: Color(0xFF353967),
                ),
              ),
              Text(
                "$score%",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: scoreColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 12,
              value: score / 100,
              backgroundColor: const Color(0xFFf0f1f7),
              valueColor: AlwaysStoppedAnimation(scoreColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap; // Added onTap for the dialog

  const _ResultTile({required this.data, required this.onTap});

  Color _getGradeColor(String grade) {
    if (grade.contains('+') || grade.startsWith('A') || grade.startsWith('B')) {
      return const Color(0xFF7246d9);
    }
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap, // Handled onTap event
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data["subject"].toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.5,
                        color: Color(0xFF34376a),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${data["examType"]} • ${data["date"]}",
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xff27dfa2).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${data["score"]}%",
                  style: const TextStyle(
                    color: Color(0xff27dfa2),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getGradeColor(data["grade"].toString()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  data["grade"].toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Add Quick Actions widget (placed near other widgets/classes)
class _QuickActionsPanel extends StatelessWidget {
  final void Function(String) onAction;
  const _QuickActionsPanel({required this.onAction});

  Widget _actionButton(String label, IconData icon, Color start, Color end) {
    return InkWell(
      onTap: () => onAction(label),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [start, end]),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: end.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Colors chosen to match the purple gradient look from the image
    const Color gStart = Color(0xFF7A63F5);
    const Color gEnd = Color(0xFF6A46D9);

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              " Quick Actions",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF34376a),
              ),
            ),
            const SizedBox(height: 10),

            // Buttons stacked vertically (matches the image)
            _actionButton("Download Report", Icons.download, gStart, gEnd),
            const SizedBox(height: 8),
            _actionButton("View Transcript", Icons.description, gStart, gEnd),
            const SizedBox(height: 8),
            _actionButton("Contact Teacher", Icons.contact_mail, gStart, gEnd),
            const SizedBox(height: 8),
            _actionButton("Schedule Meeting", Icons.event, gStart, gEnd),
          ],
        ),
      ),
    );
  }
}
