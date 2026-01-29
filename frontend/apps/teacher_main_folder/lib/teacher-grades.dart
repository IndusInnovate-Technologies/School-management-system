import 'package:flutter/material.dart';
import 'dart:math';
import 'teacher-profile.dart';

// --- NEW DATA INCLUSION ---
const List<String> allSubjects = [
  'Mathematics',
  'General Science',
  'Social Studies',
  'Language I/II/III',
  'Physics',
  'Chemistry',
  'Biology',
  'English Core',
  'Computer Science',
  'History/Civics/Geography',
  'English Language/Literature',
  'Psychology',
  'Economics',
  'Art',
  'Music',
  'History',
];

const Map<String, List<String>> mockSections = {
  'Nursery': ['Teddy Bears', 'Tiny Tots'],
  'LKG': ['Little Stars', 'Sunshine'],
  'UKG': ['Rising Stars', 'Bright Buds'],
  'I': ['A - Fredo Fighters', 'B - Galileo', 'C - Newton'],
  'II': ['A - Fredo Fighters', 'B - Galileo', 'C - Newton'],
  'III': ['A - Fredo Fighters', 'B - Galileo', 'C - Newton'],
  'IV': ['A - Fredo Fighters', 'B - Galileo', 'C - Newton'],
  'V': ['A - Fredo Fighters', 'B - Galileo', 'C - Newton'],
  'VI': ['A - Fredo Fighters', 'B - Galileo', 'C - Newton'],
  'VII': ['A - Fredo Fighters', 'B - Galileo', 'C - Newton'],
  'VIII': ['A - Fredo Fighters', 'B - Galileo', 'C - Newton'],
  'IX': ['A - Fredo Fighters', 'B - Galileo', 'C - Newton'],
  'X': ['A - Fredo Fighters', 'B - Galileo', 'C - Newton'],
  'XI': ['Science - A', 'Commerce - B', 'Arts - C'],
  'XII': ['Science - A', 'Commerce - B', 'Arts - C'],
};

const List<String> allClasses = [
  'Nursery',
  'LKG',
  'UKG',
  'I',
  'II',
  'III',
  'IV',
  'V',
  'VI',
  'VII',
  'VIII',
  'IX',
  'X',
  'XI',
  'XII',
];
// --- END NEW DATA INCLUSION ---

void main() {
  runApp(const GradesManagementApp());
}

// --- Data Models (Unchanged) ---
class StudentGrade {
  final int id;
  final String name;
  final String rollNo;
  final String avatar;
  int grade;
  int percentage;
  String status;
  String remarks;

  StudentGrade({
    required this.id,
    required this.name,
    required this.rollNo,
    required this.avatar,
    required this.grade,
    required this.percentage,
    required this.status,
    required this.remarks,
  });

  // Method to update status based on grade
  void updateStatus() {
    percentage = grade;
    status = _getGradeStatus(grade);
  }

  String _getGradeStatus(int grade) {
    if (grade >= 90) return 'A';
    if (grade >= 80) return 'B';
    if (grade >= 70) return 'C';
    if (grade >= 60) return 'D';
    return 'F';
  }
}

class GradesManagementApp extends StatelessWidget {
  const GradesManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Grades Management - Teacher Dashboard',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blueGrey)
            .copyWith(
              primary: const Color(0xFF1E3A8A), // Primary for headers/accents
              surface: const Color(0xFFF3F4F6), // Very light grey background
            ),
        scaffoldBackgroundColor: const Color(0xFFF3F4F6),
        cardTheme: CardThemeData(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E3A8A),
          elevation: 0,
          foregroundColor: Colors.white,
        ),
      ),
      home: const GradesDashboard(),
    );
  }
}

// --- Main Dashboard Widget ---
class GradesDashboard extends StatefulWidget {
  const GradesDashboard({super.key});

  @override
  State<GradesDashboard> createState() => _GradesDashboardState();
}

class _GradesDashboardState extends State<GradesDashboard> {
  // Mock Student Data
  final Map<String, List<StudentGrade>> mockStudents = {
    'X': [
      StudentGrade(
        id: 1,
        name: 'Sarah Johnson',
        rollNo: '10A001',
        avatar: 'SJ',
        grade: 95,
        percentage: 95,
        status: 'A',
        remarks: 'Excellent work',
      ),
      StudentGrade(
        id: 2,
        name: 'Mike Chen',
        rollNo: '10A002',
        avatar: 'MC',
        grade: 87,
        percentage: 87,
        status: 'B',
        remarks: 'Good performance',
      ),
      StudentGrade(
        id: 3,
        name: 'Emma Davis',
        rollNo: '10A003',
        avatar: 'ED',
        grade: 92,
        percentage: 92,
        status: 'A',
        remarks: 'Very good',
      ),
      StudentGrade(
        id: 4,
        name: 'Alex Brown',
        rollNo: '10A004',
        avatar: 'AB',
        grade: 78,
        percentage: 78,
        status: 'C',
        remarks: 'Needs improvement',
      ),
      StudentGrade(
        id: 5,
        name: 'Lisa Wang',
        rollNo: '10A005',
        avatar: 'LW',
        grade: 89,
        percentage: 89,
        status: 'B',
        remarks: 'Good effort',
      ),
    ],
    'XI': [
      StudentGrade(
        id: 11,
        name: 'Rachel Green',
        rollNo: '11A001',
        avatar: 'RG',
        grade: 94,
        percentage: 94,
        status: 'A',
        remarks: 'Excellent',
      ),
      StudentGrade(
        id: 12,
        name: 'Kevin Patel',
        rollNo: '11A002',
        avatar: 'KP',
        grade: 86,
        percentage: 86,
        status: 'B',
        remarks: 'Good',
      ),
      StudentGrade(
        id: 13,
        name: 'Sophie Turner',
        rollNo: '11A003',
        avatar: 'ST',
        grade: 79,
        percentage: 79,
        status: 'C',
        remarks: 'Needs work',
      ),
      StudentGrade(
        id: 14,
        name: 'Ryan Miller',
        rollNo: '11A004',
        avatar: 'RM',
        grade: 90,
        percentage: 90,
        status: 'A',
        remarks: 'Very good',
      ),
      StudentGrade(
        id: 15,
        name: 'Nina Rodriguez',
        rollNo: '11A005',
        avatar: 'NR',
        grade: 83,
        percentage: 83,
        status: 'B',
        remarks: 'Satisfactory',
      ),
    ],
  };

  // State variables for filters
  String? selectedClass = 'X'; // Default to 'X'
  String? selectedSection; // New state for section
  String? selectedSubject = allSubjects.first;
  String? selectedAssignment = 'midterm';

  List<StudentGrade> currentStudents = [];
  double averageGrade = 85.2;
  int highestGrade = 98;
  int lowestGrade = 72;
  int totalStudents = 25;
  Map<String, int> gradeDistribution = {'A': 0, 'B': 0, 'C': 0, 'D': 0, 'F': 0};

  // Using provided data for options
  final List<String> classOptions = allClasses; // All classes list
  final List<String> subjectOptions = allSubjects; // All subjects list

  // Assignment options map (programmatic key to display label)
  final Map<String, String> assignmentOptions = {
    'midterm': 'Mid-Term Exam',
    'final': 'Final Exam',
    'quiz1': 'Quiz 1',
    'quiz2': 'Quiz 2',
    'project': 'Project',
    'homework': 'Homework',
  };

  @override
  void initState() {
    super.initState();
    // Initialize section based on default class
    selectedSection = mockSections[selectedClass]?.first;
    _loadGrades();
  }

  void _loadGrades() {
    if (selectedClass == null ||
        selectedSection == null ||
        selectedSubject == null ||
        selectedAssignment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select Class, Section, Subject, and Assignment.',
          ),
        ),
      );
      return;
    }

    // Fetch students based on the selected class (using 'X' or 'XI' keys for mock data)
    final mockKey = ['X', 'XI'].contains(selectedClass) ? selectedClass : 'X';

    setState(() {
      currentStudents = mockStudents[mockKey] ?? [];
      _updateGradeStats();
    });
  }

  void _updateGrade(int studentId, int newGrade) {
    setState(() {
      final student = currentStudents.firstWhere((s) => s.id == studentId);
      student.grade = max(0, min(100, newGrade));
      student.updateStatus();
      _updateGradeStats();
    });
  }

  void _updateGradeStats() {
    if (currentStudents.isEmpty) {
      averageGrade = 0;
      highestGrade = 0;
      lowestGrade = 0;
      totalStudents = 0;
      gradeDistribution = {'A': 0, 'B': 0, 'C': 0, 'D': 0, 'F': 0};
      return;
    }

    final grades = currentStudents.map((s) => s.grade).toList();
    averageGrade = grades.reduce((a, b) => a + b) / grades.length;
    highestGrade = grades.reduce(max);
    lowestGrade = grades.reduce(min);
    totalStudents = currentStudents.length;

    gradeDistribution = {'A': 0, 'B': 0, 'C': 0, 'D': 0, 'F': 0};
    for (var student in currentStudents) {
      student.updateStatus();
      gradeDistribution[student.status] =
          (gradeDistribution[student.status] ?? 0) + 1;
    }
  }

  // --- UI Helpers ---

  // Refreshed AppBar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: kToolbarHeight,
      flexibleSpace: Container(
        // === Gradient background matching the image ===
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF8B47E6), // Purple start (approximated)
              Color(0xFFC764A9), // Pink end (approximated)
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: SafeArea(
          child: Builder(
            builder: (context) {
              return Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                child: Row(
                  children: [
                    // === Back Arrow Icon ===
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),

                    // === Title: Grades Management ===
                    const Expanded(
                      child: Text(
                        'Grades Management',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    // === Refresh Icon ===
                    IconButton(
                      icon: const Icon(
                        Icons.refresh,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () {
                        setState(() {
                          _loadGrades();
                        });
                      },
                    ),

                    // === Profile/User Icon ===
                    IconButton(
                      icon: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const TeacherProfilePage()),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Refreshed Stat Card (MODIFIED to include UNIFORM BLUE TOP BORDER)
  Widget _buildStatCard(
    String label,
    String value,
    Color
    color, // This color affects the icon and value text, but NOT the border
    IconData icon,
  ) {
    // Define the uniform blue color for the top border
    const Color uniformBlueBorderColor = Color(0xFF3B82F6); // Royal Blue

    // Fixed width for horizontal scrolling
    return SizedBox(
      width: 175,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: const Border(
            // FIXED BLUE TOP BORDER
            top: BorderSide(color: uniformBlueBorderColor, width: 5.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: Colors.transparent, // Use Container color
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 25,
                      color: color,
                    ), // Icon uses dynamic color
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: color, // Value text uses dynamic color
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Filter Dropdown Helper (Generic)
  Widget _buildDropdown<T>(
    String label,
    List<DropdownMenuItem<T>> items,
    T? currentValue,
    Function(T?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 310, // Increased width for better subject visibility
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonFormField<T>(
            initialValue: currentValue,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              isDense: true,
            ),
            isExpanded: true,
            hint: Text('Choose $label...'),
            items: items,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  // Grade Input Field
  Widget _buildGradeInput(StudentGrade student, Color accentColor) {
    return SizedBox(
      width: 80,
      child: TextFormField(
        initialValue: student.grade.toString(),
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: accentColor, width: 2),
          ),
        ),
        onFieldSubmitted: (value) {
          final grade = int.tryParse(value) ?? 0;
          _updateGrade(student.id, grade);
        },
        onChanged: (value) {
          final grade = int.tryParse(value) ?? 0;
          if (grade >= 0 && grade <= 100) {
            student.grade = grade;
            student.updateStatus();
            _updateGradeStats();
          }
        },
      ),
    );
  }

  // Grade Status Display Colors
  Color _getStatusColor(String status) {
    switch (status) {
      case 'A':
        return const Color(0xFF10B981); // Emerald Green
      case 'B':
        return const Color(0xFF3B82F6); // Royal Blue
      case 'C':
        return const Color(0xFFFBBF24); // Amber Yellow
      case 'D':
        return const Color(0xFFF87171); // Red
      default:
        return const Color(0xFF6B7280); // Grey
    }
  }

  Widget _buildGradeStatus(String status) {
    final color = _getStatusColor(status);
    final isLight = status == 'C';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: isLight ? Colors.black87 : Colors.white,
          fontSize: 14,
        ),
      ),
    );
  }

  // --- Main Render ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 700;

    // Create Dropdown Menu Items
    final classMenuItems = classOptions
        .map((v) => DropdownMenuItem<String>(value: v, child: Text(v)))
        .toList();
    final subjectMenuItems = subjectOptions
        .map((v) => DropdownMenuItem<String>(value: v, child: Text(v)))
        .toList();
    final assignmentMenuItems = assignmentOptions.entries.map((entry) {
      return DropdownMenuItem<String>(
        value: entry.key,
        child: Text(entry.value),
      );
    }).toList();

    // Dynamically get section options based on the selected class
    final sectionOptions = mockSections[selectedClass] ?? [];
    final sectionMenuItems = sectionOptions
        .map((v) => DropdownMenuItem<String>(value: v, child: Text(v)))
        .toList();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: _buildAppBar(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // **MODIFIED: Horizontal Sliding Stats**
            _buildSlidingStats(),
            const SizedBox(height: 30),

            // Filters Section
            _buildFiltersSection(
              classMenuItems,
              sectionMenuItems,
              subjectMenuItems,
              assignmentMenuItems,
              theme.colorScheme.primary,
            ),
            const SizedBox(height: 30),

            // Grades Table Section (Conditional Display)
            if (currentStudents.isNotEmpty)
              _buildGradesSection(isMobile, theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }

  // *** NEW Widget: Horizontal Sliding Stats ***
  Widget _buildSlidingStats() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatCard(
            'Class Average',
            averageGrade.toStringAsFixed(1),
            const Color(0xFF3B82F6), // Royal Blue
            Icons.trending_up,
          ),
          const SizedBox(width: 6), // Space between cards
          _buildStatCard(
            'Highest Grade',
            highestGrade.toString(),
            const Color(0xFF10B981), // Emerald Green
            Icons.stars,
          ),
          const SizedBox(width: 6), // Space between cards
          _buildStatCard(
            'Lowest Grade',
            lowestGrade.toString(),
            const Color(0xFFF87171), // Red
            Icons.warning_amber,
          ),
          const SizedBox(width: 6), // Space between cards
          _buildStatCard(
            'Total Students',
            totalStudents.toString(),
            const Color(0xFF1E3A8A), // Dark Blue (Primary)
            Icons.groups,
          ),
          // Add extra separation for the scroll edge
          const SizedBox(width: 10),
        ],
      ),
    );
  }
  // *** END NEW Widget ***

  Widget _buildFiltersSection(
    List<DropdownMenuItem<String>> classItems,
    List<DropdownMenuItem<String>> sectionItems,
    List<DropdownMenuItem<String>> subjectItems,
    List<DropdownMenuItem<String>> assignmentItems,
    Color accentColor,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [
            _buildDropdown('Class', classItems, selectedClass, (newValue) {
              setState(() {
                selectedClass = newValue;
                // Reset section when class changes and set new default
                selectedSection = mockSections[selectedClass]?.first;
              });
            }),
            _buildDropdown('Section', sectionItems, selectedSection, (
              newValue,
            ) {
              setState(() => selectedSection = newValue);
            }),
            _buildDropdown('Subject', subjectItems, selectedSubject, (
              newValue,
            ) {
              setState(() => selectedSubject = newValue);
            }),
            _buildDropdown('Assignment', assignmentItems, selectedAssignment, (
              newValue,
            ) {
              setState(() => selectedAssignment = newValue);
            }),
            Container(
              alignment: Alignment.bottomLeft,
              height: 58,
              child: ElevatedButton.icon(
                onPressed: _loadGrades,
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text(
                  'Load Data',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(150, 48),
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradesSection(bool isMobile, Color accentColor) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Student Roster',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                ElevatedButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Grades saved successfully!')),
                  ),
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text(
                    'Save Changes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xFF10B981,
                    ), // Green save button
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Grades Table (Ensured Horizontal Scrollability)
            SizedBox(
              width: double.infinity,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    const Color(0xFFF3F4F6),
                  ),
                  columns: const [
                    DataColumn(
                      label: Text(
                        'Student Name',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Roll No',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Grade',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Status',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Remarks',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  rows: currentStudents
                      .map(
                        (s) => DataRow(
                          cells: [
                            DataCell(
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: accentColor.withValues(
                                      alpha: 0.1,
                                    ),
                                    child: Text(
                                      s.avatar,
                                      style: TextStyle(
                                        color: accentColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    s.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(Text(s.rollNo)),
                            DataCell(_buildGradeInput(s, accentColor)),
                            DataCell(_buildGradeStatus(s.status)),
                            DataCell(
                              SizedBox(
                                width: 150,
                                child: TextFormField(
                                  initialValue: s.remarks,
                                  onChanged: (v) => s.remarks = v,
                                  decoration: InputDecoration(
                                    hintText: 'Add remarks...',
                                    isDense: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Grade Distribution
            _buildGradeDistribution(isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeDistribution(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Grade Distribution',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 15),
        GridView.count(
          crossAxisCount: isMobile ? 3 : 5,
          shrinkWrap: true,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 1,
          physics: const NeverScrollableScrollPhysics(),
          children: gradeDistribution.entries.map((entry) {
            final grade = entry.key;
            final count = entry.value;
            return Card(
              elevation: 2,
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Grade $grade',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      count.toString(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: _getStatusColor(grade),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
