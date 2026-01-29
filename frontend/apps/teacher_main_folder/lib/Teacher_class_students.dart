import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'dart:math';
import 'package:main_login/main.dart' as main_login;

// --- Data Structures ---
class ClassInfo {
  final String name;
  final String subject;
  final int totalStudents;
  final int attendance;

  ClassInfo({
    required this.name,
    required this.subject,
    required this.totalStudents,
    required this.attendance,
  });

  static ClassInfo get mock => ClassInfo(
    name: 'Class 10A',
    subject: 'Advanced Mathematics',
    totalStudents: 32,
    attendance: 92,
  );
}

class Student {
  final String id;
  final String name;
  int attendance;
  double grade;
  String status;

  Student({
    required this.id,
    required this.name,
    required this.attendance,
    required this.grade,
    required this.status,
  });
}

// --- Main App ---
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Teacher Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF4F4F6),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            color: Color(0xFF111111),
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
      home: const StudentDashboardScreen(),
    );
  }
}

// --- Dashboard Screen ---
class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  ClassInfo classInfo = ClassInfo.mock;
  List<Student> allStudents = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    await Future.delayed(const Duration(milliseconds: 800));
    allStudents = _generateMockStudents(classInfo.totalStudents);
    setState(() {
      isLoading = false;
    });
  }

  List<Student> _generateMockStudents(int count) {
    final List<String> firstNames = [
      'Jane',
      'Robert',
      'Michael',
      'Emily',
      'David',
      'Sarah',
      'James',
      'Emma',
      'John',
      'Olivia',
    ];
    final List<String> lastNames = [
      'Smith',
      'Rodriguez',
      'Williams',
      'Davis',
      'Brown',
      'Johnson',
      'Miller',
      'Garcia',
      'Martinez',
      'Jones',
    ];
    final Random random = Random();
    final List<Student> students = [];

    for (int i = 0; i < count; i++) {
      final String firstName = firstNames[random.nextInt(firstNames.length)];
      final String lastName = lastNames[random.nextInt(lastNames.length)];
      final String studentId = 'STU${(i + 1).toString().padLeft(4, '0')}';

      students.add(
        Student(
          id: studentId,
          name: '$firstName $lastName',
          attendance: random.nextInt(7) + 93,
          grade: (random.nextDouble() * 10 + 70),
          status: random.nextDouble() > 0.1 ? 'present' : 'absent',
        ),
      );
    }
    return students;
  }

  void _showStudentDetails(BuildContext context, Student student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          student.name,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF111111),
          ),
        ),
        content: Text(
          'ID: ${student.id}\nAttendance: ${student.attendance}%\nGrade: ${student.grade.toStringAsFixed(1)}%',
          style: const TextStyle(color: Color(0xFF222222)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Close',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF667eea),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addGrade(BuildContext context, Student student) {
    double newGrade = (Random().nextDouble() * 5 + 85);
    setState(() {
      student.grade = newGrade;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Grade updated for ${student.name}: ${newGrade.toStringAsFixed(1)}%',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _goBack() {
    Navigator.of(context).pop();
  }

  void _logout() {
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
  }

  Widget _buildClassDetailItem(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF222222),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: Color(0xFF000000),
              ),
            ),
          ],
        ),
      ),
    );
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
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(75),
          child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4C5FD7), Color(0xFF6A11CB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 10.0,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: _goBack,
                    tooltip: 'Back',
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Teacher Class Students',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(1, 1),
                              blurRadius: 2,
                              color: Colors.black38,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox.shrink(),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Class Students',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111111),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _goBack,
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text(
                    'Back to Classes',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A11CB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            // --- Class Info ---
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 5),
                ],
                border: const Border(
                  left: BorderSide(color: Color(0xFF6A11CB), width: 5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    classInfo.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111111),
                    ),
                  ),
                  Text(
                    classInfo.subject,
                    style: const TextStyle(
                      color: Color(0xFF6A11CB),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      _buildClassDetailItem(
                        'Total Students',
                        '${classInfo.totalStudents}',
                      ),
                      const SizedBox(width: 12),
                      _buildClassDetailItem(
                        'Average Attendance',
                        '${classInfo.attendance}%',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // --- Student Cards ---
            if (isLoading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF6A11CB),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Loading students...',
                      style: TextStyle(color: Color(0xFF555555), fontSize: 14),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: allStudents.length,
                itemBuilder: (context, index) {
                  final student = allStudents[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: StudentCard(
                      student: student,
                      onViewDetails: () =>
                          _showStudentDetails(context, student),
                      onAddGrade: () => _addGrade(context, student),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
      ),
    );
  }
}

// --- Student Card ---
class StudentCard extends StatelessWidget {
  final Student student;
  final VoidCallback onViewDetails;
  final VoidCallback onAddGrade;

  const StudentCard({
    super.key,
    required this.student,
    required this.onViewDetails,
    required this.onAddGrade,
  });

  Widget _buildDetailItem(
    String label,
    String value,
    Color labelColor, {
    Color? valueColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: labelColor.withValues(alpha: 0.9),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: valueColor ?? const Color(0xFF000000),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color statusColor = student.status == 'present'
        ? Colors.green
        : Colors.red;
    final String statusText = student.status == 'present'
        ? 'Present'
        : 'Absent';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9FB),
          borderRadius: BorderRadius.circular(15),
          border: Border(left: BorderSide(color: statusColor, width: 5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              student.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111111),
              ),
            ),
            Text(
              student.id,
              style: const TextStyle(
                color: Color(0xFF6A11CB),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                _buildDetailItem(
                  'Attendance',
                  '${student.attendance}%',
                  const Color(0xFF555555),
                ),
                const SizedBox(width: 10),
                _buildDetailItem(
                  'Grade',
                  student.grade.toStringAsFixed(1),
                  const Color(0xFF555555),
                ),
                const SizedBox(width: 10),
                _buildDetailItem(
                  'Status',
                  statusText,
                  const Color(0xFF555555),
                  valueColor: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                _buildActionButton(
                  'View',
                  const Color(0xFF6A11CB),
                  onViewDetails,
                ),
                const SizedBox(width: 10),
                _buildActionButton('Add', Colors.green, onAddGrade),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String text,
    Color baseColor,
    VoidCallback onPressed,
  ) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: baseColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
    );
  }
}
