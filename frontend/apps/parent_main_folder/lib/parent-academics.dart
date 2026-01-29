import 'package:flutter/material.dart';
import 'services/api_service.dart' as api;
// Needed for SystemMouseCursors

// -------------------------------------------------------------------------
// 0. UTILITY FUNCTION TO CREATE CUSTOM MATERIAL COLOR
// -------------------------------------------------------------------------
MaterialColor createMaterialColor(Color color) {
  List strengths = <double>[.05, .1, .2, .3, .4, .5, .6, .7, .8, .9];
  Map<int, Color> swatch = {};
  final int r = color.red, g = color.green, b = color.blue;

  for (int i = 0; i < 10; i++) {
    int strengthKey = (strengths[i] * 1000).round();
    if (strengthKey < 100) strengthKey = 50;
    swatch[strengthKey] = Color.fromRGBO(r, g, b, strengths[i]);
  }
  return MaterialColor(color.value, swatch);
}

// -------------------------------------------------------------------------
// 1. VOID MAIN (THE ENTRY POINT)
// -------------------------------------------------------------------------

void main() => runApp(const SchoolManagementSystemApp());

// -------------------------------------------------------------------------
// 2. THEME AND APP CONTAINER
// -------------------------------------------------------------------------

class SchoolManagementSystemApp extends StatelessWidget {
  const SchoolManagementSystemApp({super.key});

  static const Color primaryPurple = Color(0xFF667eea);
  static const Color accentAmber = Color(0xFFFFC107);
  static const Color lightBackground = Color(0xFFF8F9FA);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Academic Performance Dashboard',
      theme: ThemeData(
        primarySwatch: createMaterialColor(primaryPurple),
        primaryColor: primaryPurple,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryPurple,
          primary: primaryPurple,
          secondary: accentAmber,
          background: lightBackground,
          onPrimary: Colors.white,
        ),
        fontFamily: 'Segoe UI',
        useMaterial3: true,
        scaffoldBackgroundColor: lightBackground,
      ),
      home: const AcademicsPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// -------------------------------------------------------------------------
// 3. DATA MODELS
// -------------------------------------------------------------------------

class Subject {
  final String name;
  final String grade;
  final int score;
  final int progress;
  final String teacher;
  final String lastExam;
  final String nextExam;
  final String email;
  final String phone;
  final String office;
  final String schedule;
  final int assignments;
  final int completed;
  final int attendance;
  final List<String> topics;
  final List<String> resources;

  Subject({
    required this.name,
    required this.grade,
    required this.score,
    required this.progress,
    required this.teacher,
    required this.lastExam,
    required this.nextExam,
    required this.email,
    required this.phone,
    required this.office,
    required this.schedule,
    required this.assignments,
    required this.completed,
    required this.attendance,
    required this.topics,
    required this.resources,
  });
}

class Exam {
  final String subject;
  final String examType;
  final int score;
  final String grade;
  final String date;
  final String status;

  Exam({
    required this.subject,
    required this.examType,
    required this.score,
    required this.grade,
    required this.date,
    required this.status,
  });
}

class AcademicGoal {
  final String title;
  final String target;
  final String current;
  final String deadline;
  final String status;

  AcademicGoal({
    required this.title,
    required this.target,
    required this.current,
    required this.deadline,
    required this.status,
  });
}

// -------------------------------------------------------------------------
// 4. MOCK DATA INITIALIZATION
// -------------------------------------------------------------------------

final List<Subject> mockSubjects = [
  Subject(
    name: 'Mathematics',
    grade: 'A',
    score: 92,
    progress: 92,
    teacher: 'Mr. Johnson',
    lastExam: 'Mid-Term (92%)',
    nextExam: 'Final Exam (Dec 20)',
    email: 'johnson@school.edu',
    phone: '+1-555-0123',
    office: 'Room 201',
    schedule: 'Mon, Wed, Fri 9:00 AM',
    assignments: 8,
    completed: 7,
    attendance: 95,
    topics: ['Algebra', 'Geometry', 'Calculus'],
    resources: ['Textbook', 'Online Practice', 'Study Group'],
  ),
  Subject(
    name: 'Science',
    grade: 'A+',
    score: 95,
    progress: 95,
    teacher: 'Ms. Davis',
    lastExam: 'Unit Test (95%)',
    nextExam: 'Project (Dec 15)',
    email: 'davis@school.edu',
    phone: '+1-555-0124',
    office: 'Room 105',
    schedule: 'Tue, Thu 10:30 AM',
    assignments: 6,
    completed: 6,
    attendance: 98,
    topics: ['Physics', 'Chemistry', 'Biology'],
    resources: ['Lab Manual', 'Virtual Labs', 'Research Papers'],
  ),
  Subject(
    name: 'English',
    grade: 'B+',
    score: 87,
    progress: 87,
    teacher: 'Mrs. Wilson',
    lastExam: 'Essay (87%)',
    nextExam: 'Literature Test (Dec 18)',
    email: 'wilson@school.edu',
    phone: '+1-555-0125',
    office: 'Room 302',
    schedule: 'Mon, Wed 2:00 PM',
    assignments: 5,
    completed: 4,
    attendance: 92,
    topics: ['Literature', 'Grammar', 'Writing'],
    resources: ['Novels', 'Grammar Guide', 'Writing Center'],
  ),
  Subject(
    name: 'History',
    grade: 'A-',
    score: 89,
    progress: 89,
    teacher: 'Mr. Brown',
    lastExam: 'Chapter Test (89%)',
    nextExam: 'Research Paper (Dec 22)',
    email: 'brown@school.edu',
    phone: '+1-555-0126',
    office: 'Room 208',
    schedule: 'Tue, Thu 1:00 PM',
    assignments: 4,
    completed: 4,
    attendance: 94,
    topics: ['World History', 'American History', 'Geography'],
    resources: ['Textbook', 'Primary Sources', 'Maps'],
  ),
  Subject(
    name: 'Computer Science',
    grade: 'A',
    score: 93,
    progress: 90,
    teacher: 'Dr. Patel',
    lastExam: 'Practical (93%)',
    nextExam: 'Algorithms Test (Dec 19)',
    email: 'patel@school.edu',
    phone: '+1-555-0127',
    office: 'Room 410',
    schedule: 'Mon, Wed 11:00 AM',
    assignments: 7,
    completed: 6,
    attendance: 96,
    topics: ['Algorithms', 'Data Structures', 'Databases'],
    resources: ['Lecture Notes', 'Course Materials', 'Practice Problems'],
  ),
];

final List<Exam> mockExams = [
  Exam(
    subject: 'Mathematics',
    examType: 'Mid-Term',
    score: 92,
    grade: 'A',
    date: '2024-12-01',
    status: 'completed',
  ),
  Exam(
    subject: 'Science',
    examType: 'Unit Test',
    score: 95,
    grade: 'A+',
    date: '2024-11-28',
    status: 'completed',
  ),
  Exam(
    subject: 'English',
    examType: 'Essay',
    score: 87,
    grade: 'B+',
    date: '2024-11-25',
    status: 'completed',
  ),
];

final List<AcademicGoal> mockGoals = [
  AcademicGoal(
    title: 'Achieve 4.0 GPA',
    target: '4.0',
    current: '3.8',
    deadline: 'End of Semester',
    status: 'ongoing',
  ),
  AcademicGoal(
    title: 'Improve Mathematics Score',
    target: '95%',
    current: '92%',
    deadline: 'Next Month',
    status: 'ongoing',
  ),
  AcademicGoal(
    title: 'Complete Research Paper',
    target: 'A Grade',
    current: 'In Progress',
    deadline: 'Dec 15',
    status: 'ongoing',
  ),
];

// -------------------------------------------------------------------------
// 5. STUDENT PROJECTS PAGE (THE WIDGET)
// -------------------------------------------------------------------------

class AcademicsPage extends StatefulWidget {
  final String? studentId;
  const AcademicsPage({super.key, this.studentId});

  @override
  State<AcademicsPage> createState() => _AcademicsPageState();
}

class _AcademicsPageState extends State<AcademicsPage> {
  Subject selectedSubject = mockSubjects.first;
  List<Exam> _exams = [];
  bool _isLoadingExams = true;

  @override
  void initState() {
    super.initState();
    _fetchExams();
  }

  Future<void> _fetchExams() async {
    if (widget.studentId == null) {
      setState(() {
        _isLoadingExams = false;
        // Keep mock exams if no studentId provided? Or clear them?
        // User wants to remove dummy data.
        _exams = []; 
      });
      return;
    }

    try {
      final data = await api.ApiService.fetchStudentExams(studentId: widget.studentId!);
      if (data != null) {
        final List<Exam> fetchedExams = data.map((e) => Exam(
          subject: e['subject'] ?? 'Unknown',
          examType: e['examType'] ?? 'Exam',
          score: (e['score'] is int) ? e['score'] : (double.tryParse(e['score'].toString())?.toInt() ?? 0),
          grade: e['grade'] ?? '-',
          date: e['date'] ?? '',
          status: e['status'] ?? 'pending',
        )).toList();
        
        if (mounted) {
          setState(() {
            _exams = fetchedExams;
            _isLoadingExams = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingExams = false);
      }
    } catch (e) {
      debugPrint("Error fetching exams: $e");
      if (mounted) setState(() => _isLoadingExams = false);
    }
  }

  // --- UTILITIES ---
  Color _getGradeColor(String grade) {
    String cleanGrade = grade
        .replaceAll('+', '')
        .replaceAll('-', '')
        .toLowerCase();
    switch (cleanGrade) {
      case 'a':
        return const Color(0xff40c057);
      case 'b':
        return const Color(0xff4dabf7);
      case 'c':
        return const Color(0xffffc419);
      default:
        return Colors.grey;
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return const Color(0xff40c057);
    if (score >= 80) return const Color(0xff4dabf7);
    return const Color(0xffffc419);
  }

  void _showSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
      );
    }
  }

  Widget _detailTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, Color color) {
    return ElevatedButton.icon(
      onPressed: () => _showSnackbar("Action: $label"),
      icon: Icon(icon, size: 18, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(fontSize: 13, color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
    );
  }

  // -------------------------------------------------------------------------
  // 7. DETAIL MODALS
  // -------------------------------------------------------------------------

  void _showSubjectDetailsModal(Subject subject) {
    Color badgeColor = _getGradeColor(subject.grade);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with subject name and grade badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      subject.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${subject.grade} (${subject.score}%)',
                        style: TextStyle(
                          color: badgeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // 3-column grid layout matching screenshot
                GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 3.2,
                  ),
                  children: [
                    _detailTile('Current Grade', subject.grade),
                    _detailTile('Score', '${subject.score}%'),
                    _detailTile('Progress', '${subject.progress}%'),
                    _detailTile('Teacher', subject.teacher),
                    _detailTile('Email', subject.email),
                    _detailTile('Phone', subject.phone),
                    _detailTile('Office', subject.office),
                    _detailTile('Schedule', subject.schedule),
                    _detailTile('Attendance', '${subject.attendance}%'),
                    _detailTile(
                      'Assignments',
                      '${subject.completed}/${subject.assignments}',
                    ),
                    _detailTile('Last Exam', subject.lastExam),
                    _detailTile('Next Exam', subject.nextExam),
                    _detailTile('Topics Covered', subject.topics.join(', ')),
                    _detailTile('Resources', subject.resources.join(', ')),
                  ],
                ),
                const SizedBox(height: 22),

                // Action buttons
                Wrap(
                  spacing: 10,
                  children: [
                    _actionButton(
                      'Contact Teacher',
                      Icons.person,
                      const Color(0xFF4F46E5),
                    ),
                    _actionButton(
                      'View Assignments',
                      Icons.assignment,
                      const Color(0xFF6366F1),
                    ),
                    _actionButton(
                      'Schedule Meeting',
                      Icons.calendar_today,
                      const Color(0xFF64748B),
                    ),
                    _actionButton(
                      'View Resources',
                      Icons.link,
                      const Color(0xFF22C55E),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showExamDetailsModal(Exam exam) {
    Color scoreColor = _getScoreColor(exam.score);
    Color gradeColor = _getGradeColor(exam.grade);

    Widget buildModalDetailRow(String label, String value, IconData icon) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: Theme.of(context).primaryColor.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(color: Color(0xff666666))),
            const Spacer(),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '📝 ${exam.subject} - ${exam.examType}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20),

            // Grade and Score
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Score:', style: TextStyle(color: Colors.grey[600])),
                Text(
                  '${exam.score}%',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: scoreColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Grade:', style: TextStyle(color: Colors.grey[600])),
                Text(
                  exam.grade,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: gradeColor,
                  ),
                ),
              ],
            ),
            const Divider(height: 25),

            buildModalDetailRow("Date Taken", exam.date, Icons.calendar_today),
            buildModalDetailRow(
              "Status",
              exam.status.toUpperCase(),
              Icons.check_circle_outline,
            ),
            buildModalDetailRow(
              "Subject Teacher",
              mockSubjects.firstWhere((s) => s.name == exam.subject).teacher,
              Icons.person,
            ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showSnackbar("Viewing detailed breakdown for ${exam.subject}"),
                icon: const Icon(Icons.analytics, color: Colors.white),
                label: const Text(
                  'View Detailed Breakdown',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGoalDetailsModal(AcademicGoal goal) {
    Color statusColor = goal.status == 'completed' ? Colors.green : Colors.blue;

    Widget buildModalDetailRow(String label, String value, IconData icon) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: Theme.of(context).primaryColor.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(color: Color(0xff666666))),
            const Spacer(),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🎯 ${goal.title}',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            const Divider(height: 20),

            buildModalDetailRow(
              "Current Status",
              goal.status.toUpperCase(),
              Icons.timeline,
            ),
            buildModalDetailRow("Target Goal", goal.target, Icons.arrow_upward),
            buildModalDetailRow(
              "Current Progress",
              goal.current,
              Icons.bar_chart,
            ),
            buildModalDetailRow(
              "Deadline",
              goal.deadline,
              Icons.calendar_month,
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    _showSnackbar('Editing goal for ${goal.title}'),
                icon: const Icon(Icons.edit, color: Colors.white),
                label: const Text(
                  'Modify Goal',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(backgroundColor: statusColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // 6. WIDGET BUILDERS
  // -------------------------------------------------------------------------

  Widget _buildSectionHeader(String emoji, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(
        '$emoji $title',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xff333333),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    const totalGPA = '3.8';
    const classRank = '5';
    const attendance = '95%';
    final subjectsCount = mockSubjects.length.toString();
    final primaryColor = Theme.of(context).primaryColor;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    final stats = [
      {
        'emoji': '📊',
        'value': totalGPA,
        'label': 'Overall GPA',
        'color': Colors.blue,
        'borderColor': primaryColor,
      },
      {
        'emoji': '🏆',
        'value': classRank,
        'label': 'Class Rank',
        'color': secondaryColor,
        'borderColor': secondaryColor,
      },
      {
        'emoji': '✅',
        'value': attendance,
        'label': 'Attendance',
        'color': Colors.green,
        'borderColor': primaryColor,
      },
      {
        'emoji': '📚',
        'value': subjectsCount,
        'label': 'Subjects',
        'color': Colors.orange,
        'borderColor': secondaryColor,
      },
    ];

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: stats.length,
        padding: const EdgeInsets.only(right: 16),
        itemBuilder: (context, index) {
          final stat = stats[index];
          return Container(
            margin: EdgeInsets.only(right: index < stats.length - 1 ? 16 : 0),
            child: _statCard(
              stat['emoji'] as String,
              stat['value'] as String,
              stat['label'] as String,
              stat['color'] as Color,
              stat['borderColor'] as Color,
            ),
          );
        },
      ),
    );
  }

  Widget _statCard(
    String emoji,
    String number,
    String label,
    Color accentColor,
    Color borderColor,
  ) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border(top: BorderSide(color: borderColor, width: 4)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28, height: 1.0)),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                number,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xff666666),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectPerformanceList() {
    return ListView.builder(
      // Corrected settings for nesting ListView:
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: mockSubjects.length,
      itemBuilder: (context, index) {
        final subject = mockSubjects[index];
        return _subjectCard(subject);
      },
    );
  }

  Widget _subjectCard(Subject subject) {
    Color gradeColor = _getGradeColor(subject.grade);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
                    onTap: () => _showSubjectDetailsModal(subject),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      subject.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [gradeColor.withValues(alpha: 0.9), gradeColor],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      subject.grade,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Score: ${subject.score}% • Teacher: ${subject.teacher}',
                style: const TextStyle(color: Color(0xff666666), fontSize: 14),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Color(0xff666666),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Next Exam: ${subject.nextExam}',
                      style: const TextStyle(
                        color: Color(0xff666666),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: subject.progress / 100.0,
                  backgroundColor: const Color(0xffe9ecef),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF6A67FC)),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExamList() {
    if (_isLoadingExams) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_exams.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Center(child: Text("No exams data available")),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _exams.length,
      itemBuilder: (context, index) {
        final exam = _exams[index];
        final scoreColor = _getScoreColor(exam.score);

        return MouseRegion(
          cursor: SystemMouseCursors.click,
            child: InkWell(
            onTap: () => _showExamDetailsModal(exam),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: const Border(
                  left: BorderSide(color: Color(0xff28a745), width: 4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${exam.subject} - ${exam.examType}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Color(0xff666666),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Grade: ${exam.grade} • ${exam.date}',
                              style: const TextStyle(
                                color: Color(0xff666666),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [scoreColor.withValues(alpha: 0.9), scoreColor],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${exam.score}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGoalsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: mockGoals.length,
      itemBuilder: (context, index) {
        final goal = mockGoals[index];
        final bool isCompleted = goal.status == 'completed';
        final Color statusColor = isCompleted ? Colors.green : Colors.blue;

        return MouseRegion(
          cursor: SystemMouseCursors.click,
            child: InkWell(
            onTap: () => _showGoalDetailsModal(goal),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border(left: BorderSide(color: statusColor, width: 4)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          goal.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          goal.status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.track_changes,
                        size: 14,
                        color: Color(0xff666666),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Target: ${goal.target} | Current: ${goal.current}',
                          style: const TextStyle(
                            color: Color(0xff666666),
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Color(0xff666666),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Deadline: ${goal.deadline}',
                          style: const TextStyle(
                            color: Color(0xff666666),
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- NEW: Inline Subject Details tab (placed under Academic Goals) ---
  Widget _buildSubjectDetailsTab() {
    final subject = selectedSubject;
    final badgeColor = _getGradeColor(subject.grade);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('📘', 'Subject Details'),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE6EAF8)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      subject.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${subject.grade} (${subject.score}%)',
                      style: TextStyle(
                        color: badgeColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Responsive tiles: use Wrap so items reflow on narrow widths
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final int columns = width > 780 ? 3 : (width > 520 ? 2 : 1);
                  final double gap = 12.0;
                  final tileWidth = (width - (columns - 1) * gap) / columns;

                  final tiles = [
                    _detailTile('Teacher', subject.teacher),
                    _detailTile('Email', subject.email),
                    _detailTile('Phone', subject.phone),
                    _detailTile('Office', subject.office),
                    _detailTile('Schedule', subject.schedule),
                    _detailTile(
                      'Assignments',
                      '${subject.completed}/${subject.assignments}',
                    ),
                    _detailTile('Attendance', '${subject.attendance}%'),
                    _detailTile('Last Exam', subject.lastExam),
                    _detailTile('Next Exam', subject.nextExam),
                    _detailTile('Topics Covered', subject.topics.join(', ')),
                    _detailTile('Resources', subject.resources.join(', ')),
                    _detailTile('Progress', '${subject.progress}%'),
                  ];

                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: tiles
                        .map((w) => SizedBox(width: tileWidth, child: w))
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _actionButton(
                    'Contact Teacher',
                    Icons.person,
                    const Color(0xFF4F46E5),
                  ),
                  _actionButton(
                    'View Assignments',
                    Icons.assignment,
                    const Color(0xFF6366F1),
                  ),
                  _actionButton(
                    'Schedule Meeting',
                    Icons.calendar_today,
                    const Color(0xFF64748B),
                  ),
                  _actionButton(
                    'View Resources',
                    Icons.link,
                    const Color(0xFF22C55E),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- NEW: Performance Summary widget (placed above Quick Actions) ---
  Widget _buildPerformanceSummary() {
    const Color start = Color(0xFF7A8EFF);
    const Color end = Color(0xFF667eea);
    const double fraction = 3.8 / 4.0; // Current Term 3.8 / 4.0

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE6E9F8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.bar_chart, color: Color(0xFF667eea)),
              SizedBox(width: 10),
              Text(
                'Performance Summary',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Inner card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xfff6f8ff),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Overall Performance',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Excellent',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Current Term: 3.8/4.0 GPA',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Previous Term: 3.6/4.0 GPA',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Improvement: +0.2 GPA',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 10),

                // Progress bar with gradient fill
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final filled = width * fraction;
                    return Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xffe9edf9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              width: filled,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(colors: [start, end]),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  bottomLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                  bottomRight: Radius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- UPDATED: Use provided icon param (do not derive from text) ---
  Widget _buildVerticalActionButton(
    IconData icon,
    String text,
    VoidCallback onPressed,
  ) {
    const Color startColor = Color(0xFF7A8EFF);
    const Color endColor = Color(0xFF667eea);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        width: double.infinity,
        height: 55,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [startColor, endColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: endColor.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(icon, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      text,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- UPDATED QUICK ACTIONS: use options from the image ---
  Widget _buildQuickActions() {
    final actions = [
      {
        'text': 'Download Report',
        'icon': Icons.download,
        'onPressed': () => _showSnackbar('Downloading report...'),
      },
      {
        'text': 'Contact Teacher',
        'icon': Icons.contact_mail,
        'onPressed': () => _showSnackbar('Contacting teacher...'),
      },
      {
        'text': 'Schedule Meeting',
        'icon': Icons.event,
        'onPressed': () => _showSnackbar('Scheduling meeting...'),
      },
      {
        'text': 'View Timetable',
        'icon': Icons.schedule,
        'onPressed': () => _showSnackbar('Opening timetable...'),
      },
    ];

    return Column(
      children: actions.map((action) {
        return _buildVerticalActionButton(
          action['icon'] as IconData,
          action['text'] as String,
          action['onPressed'] as VoidCallback,
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebDesktop = screenWidth > 600;
    final maxContentWidth = isWebDesktop ? 600.0 : screenWidth;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6A67FC),
        elevation: 0,
        toolbarHeight: 60,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
          iconSize: 24,
        ),
        title: const Text(
          "Academics Dashboard",
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: false,
        actions: const [
          SizedBox(width: 8),
        ],
      ),

      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWebDesktop ? 24 : 16,
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📚 Student Academics',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6A67FC),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 4.0, bottom: 16.0),
                  child: Text(
                    'Comprehensive academic performance overview',
                    style: TextStyle(color: Color(0xff666666), fontSize: 15),
                  ),
                ),
                _buildStatsGrid(),
                const SizedBox(height: 25),

                _buildSectionHeader('📖', 'Subject Performance'),
                _buildSubjectPerformanceList(),
                const SizedBox(height: 30),

                _buildSectionHeader('📝', 'Recent Exam Results'),
                _buildExamList(),
                const SizedBox(height: 30),

                _buildSectionHeader('🎯', 'Academic Goals'),
                _buildGoalsList(),
                const SizedBox(height: 20),
                _buildSubjectDetailsTab(),
                const SizedBox(height: 30),

                // INSERT Performance Summary + Quick Actions here (replacing previous quick actions)
                _buildPerformanceSummary(),
                const SizedBox(height: 16),
                _buildSectionHeader('⚡', 'Quick Actions'),
                _buildQuickActions(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
