import 'package:flutter/material.dart';
import 'dart:math';
import 'package:main_login/main.dart' as main_login;
import 'teacher-profile.dart';
import 'services/api_service.dart' as api;

// --- Data Models ---

class Class {
  final String id;
  final String grade;
  final String section;
  final List<String> subjects;

  Class(this.id, this.grade, this.section, this.subjects);

  String get name => "$grade - $section";
}

class StudentResult {
  final String id;
  final String name;
  final String rollNumber;
  double marks;
  String percentage;
  String grade;
  String status;

  StudentResult({
    required this.id,
    required this.name,
    required this.rollNumber,
    this.marks = -1, // Use -1 to denote marks not entered
    this.percentage = '-',
    this.grade = '-',
    this.status = '-',
  });
}

class ExamDetails {
  final String classId;
  final String className;
  final String subject;
  final String examType;
  final String examDate;
  final int totalMarks;
  final int passingMarks;

  ExamDetails({
    required this.classId,
    required this.className,
    required this.subject,
    required this.examType,
    required this.examDate,
    required this.totalMarks,
    required this.passingMarks,
  });
}

// --- Main Application ---

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Enter Results - Teacher Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Segoe UI',
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.deepPurple,
        ).copyWith(secondary: const Color(0xFF51cf66)),
        useMaterial3: true,
      ),
      home: const EnterResultsScreen(),
    );
  }
}

class EnterResultsScreen extends StatefulWidget {
  const EnterResultsScreen({super.key});

  @override
  State<EnterResultsScreen> createState() => _EnterResultsScreenState();
}

class _EnterResultsScreenState extends State<EnterResultsScreen> {
  // Real Data
  List<Class> _classes = [];

  // Form State
  String? _selectedClassId;
  String? _selectedGrade;
  String? _selectedSection;
  String? _selectedSubject;
  String? _selectedExamType;
  final TextEditingController _dateController = TextEditingController(
    text: _getTodayDate(),
  );
  final TextEditingController _totalMarksController = TextEditingController(
    text: '100',
  );
  final TextEditingController _passingMarksController = TextEditingController(
    text: '40',
  );
  final _setupFormKey = GlobalKey<FormState>();

  // Results State
  ExamDetails? _currentExamDetails; // Start null for manual selection
  List<StudentResult> _currentStudents = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }
  
  static String _getTodayDate() {
    return DateTime.now().toIso8601String().split('T').first;
  }

  Future<void> _loadClasses() async {
    try {
      final data = await api.ApiService.fetchTeacherClasses();
      setState(() {
        _classes = data.map<Class>((json) {
           // Safely handle id as String
           final id = json['id'].toString(); 
           final grade = json['name']?.toString() ?? 'Class';
           final section = json['section']?.toString() ?? 'A';
           // Use subjects from API if available, else defaults
           List<String> subjs = ['General'];
           if (json['subjects'] != null && (json['subjects'] as List).isNotEmpty) {
              subjs = (json['subjects'] as List).map((e) => e.toString()).toList();
           } else {
             // Fallback subjects
             subjs = ['Mathematics', 'Science', 'English', 'History', 'Geography', 'Physics', 'Chemistry', 'Biology'];
           }
           return Class(id, grade, section, subjs);
        }).toList();
      });
    } catch (e) {
      debugPrint('Error loading classes: $e');
      _showSnackBar('Failed to load classes (Using offline data)', isError: true);
      // Fallback Mock Data for testing/offline usage
      setState(() {
        _classes = [
          Class('1', 'Class 1', 'A', ['Math', 'English']),
          Class('2', 'Class 1', 'B', ['Math', 'English']),
          Class('3', 'Class 2', 'A', ['Science', 'History']),
          Class('4', 'Class 10', 'A', ['Physics', 'Chemistry', 'Math']),
          Class('5', 'Class 10', 'B', ['Physics', 'Chemistry', 'Biology']),
        ];
      });
    }
  }

  // --- Utility Functions ---

  Class? get _selectedClass => _classes.isEmpty ? null : _classes.firstWhere(
    (cls) => cls.id == _selectedClassId,
    orElse: () => _classes.first, // Fallback might need adjustment if logic requires strict matching
  );

  void _updateSelectedClassId() {
    _selectedSubject = null; // Reset subject
    if (_selectedGrade != null && _selectedSection != null) {
      try {
        final cls = _classes.firstWhere(
          (c) => c.grade == _selectedGrade && c.section == _selectedSection
        );
        _selectedClassId = cls.id;
      } catch (e) {
        _selectedClassId = null; // Combination not found
      }
    } else {
      _selectedClassId = null;
    }
  }

  // --- Business Logic ---

  void _loadStudents() async {
    if (!_setupFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _currentStudents = [];
    });

    final selectedClass = _selectedClass;
    if (selectedClass == null) {
      _showSnackBar('Please select a valid class.');
      setState(() => _isLoading = false);
      return;
    }

    _currentExamDetails = ExamDetails(
      classId: _selectedClassId!,
      className: selectedClass.name,
      subject: _selectedSubject ?? 'N/A',
      examType: _selectedExamType ?? 'N/A',
      examDate: _dateController.text,
      totalMarks: int.parse(_totalMarksController.text),
      passingMarks: int.parse(_passingMarksController.text),
    );

    try {
      // Fetch students from API
      // We need to parse the class ID as int if the API expects int
      final classIdInt = int.tryParse(_selectedClassId ?? '') ?? 0;
      final studentsData = await api.ApiService.fetchClassStudents(classIdInt);
      
      List<StudentResult> fetchedStudents = [];
      for (var s in studentsData) {
         // Handle nested structure: class-student object contains 'student' object
         final studentObj = s['student'] ?? s; 
         final name = studentObj['student_name'] ?? studentObj['name'] ?? 'Unknown';
         final id = studentObj['id']?.toString() ?? '0';
         final roll = studentObj['roll_number'] ?? studentObj['student_id'] ?? 'N/A';
         
         fetchedStudents.add(StudentResult(
           id: id,
           name: name,
           rollNumber: roll,
         ));
      }
      
      setState(() {
        _currentStudents = fetchedStudents;
        _isLoading = false;
      });
      
    } catch (e) {
       debugPrint('Error loading students: $e');
       _showSnackBar('Failed to load students', isError: true);
       setState(() => _isLoading = false);
    }
  }

  void _updateStudentResult(String studentId, String value) {
    if (_currentExamDetails == null) return;
    
    final marks = double.tryParse(value);

    if (marks == null || marks < 0 || marks > _currentExamDetails!.totalMarks) {
      setState(() {
        final student = _currentStudents.firstWhere((s) => s.id == studentId);
        student.marks = -1;
        student.percentage = '-';
        student.grade = '-';
        student.status = '-';
      });
      return;
    }

    final totalMarks = _currentExamDetails!.totalMarks;
    final passingMarks = _currentExamDetails!.passingMarks;

    final percentage = (marks / totalMarks) * 100;
    String grade;
    if (percentage >= 90) {
      grade = 'A+';
    } else if (percentage >= 80)
      grade = 'A';
    else if (percentage >= 70)
      grade = 'B+';
    else if (percentage >= 60)
      grade = 'B';
    else if (percentage >= 50)
      grade = 'C+';
    else if (percentage >= 40)
      grade = 'C';
    else
      grade = 'F';

    final status = marks >= passingMarks ? 'Pass' : 'Fail';

    setState(() {
      final student = _currentStudents.firstWhere((s) => s.id == studentId);
      student.marks = marks;
      student.percentage = '${percentage.toStringAsFixed(1)}%';
      student.grade = grade;
      student.status = status;
    });
  }

  void _saveResults() async {
    final studentsWithMarks = _currentStudents
        .where((s) => s.marks >= 0)
        .toList();

    if (studentsWithMarks.isEmpty) {
      _showSnackBar(
        'Please enter marks for at least one student.',
        isError: true,
      );
      return;
    }

    final studentsWithoutMarks = _currentStudents
        .where((s) => s.marks == -1)
        .toList();
    if (studentsWithoutMarks.isNotEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Save'),
          content: Text(
            '${studentsWithoutMarks.length} students do not have marks entered. Do you want to save anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Save Anyway',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    // Simulate saving process
    _showSnackBar('Saving results...');
    await Future.delayed(const Duration(seconds: 2));
    _showSnackBar('Results saved successfully!', isSuccess: true);
  }

  void _clearResults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Clear'),
        content: const Text(
          'Are you sure you want to clear all entered marks?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              setState(() {
                for (var student in _currentStudents) {
                  student.marks = -1;
                }
              });
              _showSnackBar('All marks cleared', isSuccess: true);
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        for (var student in _currentStudents) {
          student
            ..marks = -1
            ..percentage = '-'
            ..grade = '-'
            ..status = '-';
        }
      });
      _showSnackBar('All marks cleared!');
    }
  }

  void _showSnackBar(
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Colors.red
            : (isSuccess ? Colors.green : Colors.blueGrey),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // --- Widget Builders ---

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 900;
    final isResultsLoaded =
        _currentExamDetails != null &&
        !_isLoading &&
        _currentStudents.isNotEmpty; // Check if students are loaded

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) return;
        Navigator.of(context).pop();
      },
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            _buildHeader(context),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: EdgeInsets.all(isLargeScreen ? 40.0 : 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // _buildPageHeader(context) removed

                    const SizedBox(height: 30),
                    _buildSetupSection(isLargeScreen),
                    if (_isLoading) _buildLoadingSpinner(),
                    if (_currentStudents.isEmpty &&
                        !_isLoading &&
                        _currentExamDetails != null)
                      _buildEmptyResultsMessage(),
                    if (isResultsLoaded) _buildResultsSection(isLargeScreen),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildEmptyResultsMessage() {
    return Container(
      margin: const EdgeInsets.only(top: 30),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.orange, width: 2),
      ),
      child: const Center(
        child: Text(
          'No students found for the selected criteria. Please check the class/subject settings.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.orange),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    const Color primaryColor = Color(0xFF667eea);
    const Color secondaryColor = Color(0xFF764ba2);
    final isLargeScreen = MediaQuery.of(context).size.width > 600;

    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.transparent,
      title: const Text('Enter Results', style: TextStyle(color: Colors.white)),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            // Matching the gradient from the image as closely as possible
            colors: [primaryColor, secondaryColor, Color(0xFFf093fb)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 4),
            ),
          ],
        ),
      ),
      // Added back button as per image reference (arrow on left)
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: const [],
    );
  }


  Widget _buildSetupSection(bool isLargeScreen) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Form(
        key: _setupFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚙️ Setup Exam Details',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                // Determine layout columns based on available width
                int crossAxisCount = constraints.maxWidth > 800
                    ? 3
                    : (constraints.maxWidth > 500 ? 2 : 1);

                return Wrap(
                  spacing: 20.0,
                  runSpacing: 20.0,
                  children: [
                    // Class Dropdown
                    SizedBox(
                      width: crossAxisCount > 1
                          ? (constraints.maxWidth / crossAxisCount) - 20
                          : constraints.maxWidth,
                      child: _buildDropdownField(
                        'Select Class',
                        _classes.map((cls) => cls.grade).toSet().toList(),
                        (value) {
                          setState(() {
                            _selectedGrade = value;
                            _selectedSection = null; // Reset section when class changes
                            _updateSelectedClassId();
                          });
                        },
                        _selectedGrade,
                      ),
                    ),
                    // Section Dropdown
                    SizedBox(
                      width: crossAxisCount > 1
                          ? (constraints.maxWidth / crossAxisCount) - 20
                          : constraints.maxWidth,
                      child: _buildDropdownField(
                        'Select Section',
                        _selectedGrade != null
                            ? _classes
                                .where((cls) => cls.grade == _selectedGrade)
                                .map((cls) => cls.section)
                                .toSet()
                                .toList()
                            : [],
                        (value) {
                          setState(() {
                            _selectedSection = value;
                            _updateSelectedClassId();
                          });
                        },
                        _selectedSection,
                        isEnabled: _selectedGrade != null,
                      ),
                    ),
                    // Subject Dropdown
                    SizedBox(
                      width: crossAxisCount > 1
                          ? (constraints.maxWidth / crossAxisCount) - 20
                          : constraints.maxWidth,
                      child: _buildDropdownField(
                        'Select Subject',
                        _selectedClass != null ? _selectedClass!.subjects : [],
                        (value) => setState(() => _selectedSubject = value),
                        _selectedSubject,
                        isEnabled: _selectedClassId != null,
                      ),
                    ),
                    // Exam Type Dropdown
                    SizedBox(
                      width: crossAxisCount > 1
                          ? (constraints.maxWidth / crossAxisCount) - 20
                          : constraints.maxWidth,
                      child: _buildDropdownField(
                        'Exam Type',
                        [
                          'Midterm Exam',
                          'Final Exam',
                          'Quiz',
                          'Assignment',
                          'Project',
                        ],
                        (value) => setState(() => _selectedExamType = value),
                        _selectedExamType,
                      ),
                    ),
                    // Exam Date
                    SizedBox(
                      width: crossAxisCount > 1
                          ? (constraints.maxWidth / crossAxisCount) - 20
                          : constraints.maxWidth,
                      child: _buildDateField('Exam Date', _dateController),
                    ),
                    // Total Marks
                    SizedBox(
                      width: crossAxisCount > 1
                          ? (constraints.maxWidth / crossAxisCount) - 20
                          : constraints.maxWidth,
                      child: _buildNumberField(
                        'Total Marks',
                        _totalMarksController,
                        min: 1,
                        max: 200,
                      ),
                    ),
                    // Passing Marks
                    SizedBox(
                      width: crossAxisCount > 1
                          ? (constraints.maxWidth / crossAxisCount) - 20
                          : constraints.maxWidth,
                      child: _buildNumberField(
                        'Passing Marks',
                        _passingMarksController,
                        min: 1,
                        max: 200,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _loadStudents(),
              icon: const Icon(Icons.list_alt),
              label: Text(_isLoading ? 'Loading Students...' : 'Load Students'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFF51cf66),
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSpinner() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 50.0),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(color: Color(0xFF667eea)),
            SizedBox(height: 20),
            Text(
              'Loading students...',
              style: TextStyle(color: Color(0xFF666666)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection(bool isLargeScreen) {
    return Container(
      margin: const EdgeInsets.only(top: 30),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        // The inner content of the results section (header, details, table, actions)
        // is inside a Column, which is safe since the outer scroll view manages the overall height.
        children: [
          _buildResultsHeader(),
          _buildExamInfoDetails(),
          // The table is where the error occurred. It needs an explicit vertical constraint
          // to prevent it from trying to take infinite height in the scrollable context.
          _buildStudentsTable(isLargeScreen),
          _buildActionsSection(),
        ],
      ),
    );
  }

  Widget _buildResultsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          '📝 Enter Marks',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () => _saveResults(),
              icon: const Icon(Icons.save),
              label: const Text('Save Results'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFF51cf66),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: () => _clearResults(),
              icon: const Icon(Icons.clear),
              label: const Text('Clear All'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFFff6b6b),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExamInfoDetails() {
    final details = _currentExamDetails!;
    return Container(
      margin: const EdgeInsets.only(top: 20, bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFf8f9fa),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFe9ecef)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📋 Exam Information',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              int columns = constraints.maxWidth > 700 ? 3 : 2;
              return Wrap(
                spacing: 20.0,
                runSpacing: 10.0,
                children: [
                  _buildDetailItem(
                    'Class',
                    details.className,
                    columns,
                    constraints.maxWidth,
                  ),
                  _buildDetailItem(
                    'Subject',
                    details.subject,
                    columns,
                    constraints.maxWidth,
                  ),
                  _buildDetailItem(
                    'Exam Type',
                    details.examType,
                    columns,
                    constraints.maxWidth,
                  ),
                  _buildDetailItem(
                    'Exam Date',
                    details.examDate,
                    columns,
                    constraints.maxWidth,
                  ),
                  _buildDetailItem(
                    'Total Marks',
                    details.totalMarks.toString(),
                    columns,
                    constraints.maxWidth,
                  ),
                  _buildDetailItem(
                    'Passing Marks',
                    details.passingMarks.toString(),
                    columns,
                    constraints.maxWidth,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(
    String label,
    String value,
    int columns,
    double maxWidth,
  ) {
    return SizedBox(
      width: (maxWidth / columns) - 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsTable(bool isLargeScreen) {
    // FIX: The DataTable itself does not need to be wrapped in a SingleChildScrollView vertically,
    // but the scrollable container around it often needs a maximum height.
    // However, since this whole screen is scrollable (CustomScrollView -> SliverList),
    // we enforce a reasonable maximum height for the table portion to be good citizens in the scroll view.
    return SizedBox(
      height: 400, // Explicit finite height to prevent BoxConstraints error
      child: Container(
        constraints: const BoxConstraints(minHeight: 200),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFe9ecef)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: max(0.0, MediaQuery.of(context).size.width - 80),
            ),
            child: DataTable(
              columnSpacing: isLargeScreen ? 30 : 15,
              dataRowMinHeight: 60,
              headingRowColor: WidgetStateProperty.resolveWith(
                (states) => const Color(0xFF667eea),
              ),
              columns: const [
                DataColumn(
                  label: Text(
                    'Student',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Roll Number',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Marks Obtained',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Percentage',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Grade',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Status',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              rows: _currentStudents
                  .map((student) => _buildDataRow(student))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  DataRow _buildDataRow(StudentResult student) {
    // Get the input controller associated with the student, or create a new one if needed
    final controller = TextEditingController(
      text: student.marks >= 0 ? student.marks.toString() : '',
    );
    final inputBorderColor = student.marks >= 0
        ? const Color(0xFF51cf66)
        : (controller.text.isNotEmpty
              ? const Color(0xFFff6b6b)
              : const Color(0xFFe9ecef));
    final statusColor = student.status == 'Pass'
        ? const Color(0xFF51cf66)
        : (student.status == 'Fail'
              ? const Color(0xFFff6b6b)
              : const Color(0xFF666666));

    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                ),
                child: Center(
                  child: Text(
                    student.name.substring(0, 1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    student.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'ID: ${student.id}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        DataCell(Text(student.rollNumber)),
        DataCell(
          SizedBox(
            width: 80,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: inputBorderColor, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(
                    color: Color(0xFF667eea),
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: inputBorderColor, width: 2),
                ),
                hintText: '0-${_currentExamDetails?.totalMarks}',
              ),
              onChanged: (value) => _updateStudentResult(student.id, value),
            ),
          ),
        ),
        DataCell(Text(student.percentage)),
        DataCell(Text(student.grade)),
        DataCell(
          Text(
            student.status,
            style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildActionsSection() {
    return Container(
      padding: const EdgeInsets.only(top: 20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFf8f9fa), width: 2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton.icon(
            onPressed: () => _clearResults(),
            icon: const Icon(Icons.delete_sweep),
            label: const Text('Clear All'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: const Color(0xFFff6b6b),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: () => _saveResults(),
            icon: const Icon(Icons.save),
            label: const Text('Save Results'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: const Color(0xFF51cf66),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
          ),
        ],
      ),
    );
  }

  // --- Form Field Helpers ---

  Widget _buildDropdownField(
    String label,
    List<String> items,
    Function(String?) onSelect,
    String? selectedValue, {
    bool isEnabled = true,
  }) {
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
        DropdownButtonFormField<String>(
          initialValue: selectedValue,
          isExpanded: true,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFe9ecef), width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isEnabled
                    ? const Color(0xFFe9ecef)
                    : const Color(0xFFf0f0f0),
                width: 2,
              ),
            ),
            fillColor: isEnabled ? Colors.white : const Color(0xFFf0f0f0),
            filled: true,
          ),
          hint: Text('Choose $label...'),
          items: items.map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
          onChanged: isEnabled ? onSelect : null,
          validator: (value) => value == null ? 'Please select a $label' : null,
        ),
      ],
    );
  }

  Widget _buildDateField(String label, TextEditingController controller) {
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
        TextFormField(
          controller: controller,
          readOnly: true,
          keyboardType: TextInputType.datetime,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFe9ecef), width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFe9ecef), width: 2),
            ),
          ),
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.tryParse(controller.text) ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (picked != null) {
              controller.text = picked.toIso8601String().split('T').first;
            }
          },
          validator: (value) => value!.isEmpty ? 'Please select a date' : null,
        ),
      ],
    );
  }

  Widget _buildNumberField(
    String label,
    TextEditingController controller, {
    int min = 1,
    int max = 100,
  }) {
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
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFe9ecef), width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFe9ecef), width: 2),
            ),
          ),
          validator: (value) {
            if (value!.isEmpty) return 'Required';
            final num = int.tryParse(value);
            if (num == null || num < min || num > max) {
              return 'Range: $min - $max';
            }
            return null;
          },
        ),
      ],
    );
  }
}
