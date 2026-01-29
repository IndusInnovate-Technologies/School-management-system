import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// --- CONSTANTS ---
// Based on user request: Class 1 to 10
const List<String> allClasses = [
  'Nursery', 'LKG', 'UKG',
  'Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5', 
  'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10',
  'Class 11', 'Class 12'
];

// Based on user request: Grades A, B, C, D (treated as sections)
const List<String> allSections = ['A', 'B', 'C', 'D'];

// --- MODELS ---

class Student {
  final dynamic id; // Can be int or String (backend uses strings/UUIDs often)
  final String name;
  final String rollNo;
  final String avatarInitials;

  Student({
    required this.id,
    required this.name,
    required this.rollNo,
    required this.avatarInitials,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      name: json['name'] ?? 'Unknown',
      rollNo: json['rollNo'] ?? 'N/A',
      avatarInitials: json['avatarInitials'] ?? '?',
    );
  }
}

enum AttendanceStatus { present, absent, late }

extension AttendanceStatusExtension on AttendanceStatus {
  String get displayName {
    switch (this) {
      case AttendanceStatus.present: return 'Present';
      case AttendanceStatus.absent: return 'Absent';
      case AttendanceStatus.late: return 'Late';
    }
  }

  Color get color {
    switch (this) {
      case AttendanceStatus.present: return Colors.green.shade700;
      case AttendanceStatus.absent: return Colors.red.shade700;
      case AttendanceStatus.late: return Colors.orange.shade700;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case AttendanceStatus.present: return Colors.green.shade100;
      case AttendanceStatus.absent: return Colors.red.shade100; // Fixed: consistent with others
      case AttendanceStatus.late: return Colors.orange.shade100; // Fixed
    }
  }
}

// --- THEME COLORS ---
const Color primaryColor = Color(0xFF1565C0);
const Color accentColor = Color(0xFFFFC107);
const Color backgroundColor = Color(0xFFEEEEEE);

// --- MAIN APPLICATION ---
void main() {
  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: primaryColor,
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue).copyWith(
          secondary: accentColor,
          primary: primaryColor,
          surface: Colors.white,
        ),
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: backgroundColor,
        useMaterial3: true,
      ),
      home: const AttendanceDashboard(),
    );
  }
}

// --- DASHBOARD SCREEN ---

class AttendanceDashboard extends StatefulWidget {
  const AttendanceDashboard({super.key});

  @override
  State<AttendanceDashboard> createState() => _AttendanceDashboardState();
}

class _AttendanceDashboardState extends State<AttendanceDashboard> {
  // State
  String? _selectedClass;
  String? _selectedSection;
  DateTime _selectedDate = DateTime.now();
  
  // Helper to check if selected date is today
  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year && 
           _selectedDate.month == now.month && 
           _selectedDate.day == now.day;
  }
  
  // Restriction logic: Today only and 1 hour window
  bool get _isEditable {
    if (!_isToday) return false;
    
    final now = DateTime.now();
    // 1-hour window logic: Using 11:00 AM cutoff as a proxy for "1 hour after school start"
    if (now.hour >= 11) return false; 
    
    return true;
  }
  
  int? _currentClassId; // To store the class ID returned by backend for saving
  
  List<Student> _students = [];
  final Map<dynamic, AttendanceStatus> _attendanceRecords = {};
  final Map<dynamic, String> _remarks = {};
  bool _isLoading = false;
  // _isClassLocked removed
  
  // API Config
  final String _baseUrl = 'http://127.0.0.1:8000/api/teacher';

  @override
  void initState() {
    super.initState();
    // Initialize with null to force user selection
    _selectedClass = null;
    _selectedSection = null;
    _fetchTeacherProfile(); // Check for assigned class
    // _fetchStudents(); // Don't fetch until selection is made
  }

  Future<void> _fetchTeacherProfile() async {
    setState(() => _isLoading = true);
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/profile/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        // Profile fetched successfully. 
        // We no longer auto-fill class/section here to allow manual selection.
      }
    } catch (e) {
      print('Error fetching profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> _fetchStudents() async {
    if (_selectedClass == null || _selectedSection == null) return;

    setState(() => _isLoading = true);
    
    try {
      final headers = await _getAuthHeaders();
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      
      final  uri = Uri.parse('$_baseUrl/attendance/get_students_for_attendance/').replace(
        queryParameters: {
          'class_name': _selectedClass,
          'section': _selectedSection,
          'date': dateStr,
        }
      );

      final response = await http.get(uri, headers: headers);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentClassId = data['class_id'];
        final List<dynamic> studentsJson = data['students'];
        
        setState(() {
          _students = studentsJson.map((json) => Student.fromJson(json)).toList();
          
          // Clear and repopulate local state
          _attendanceRecords.clear();
          _remarks.clear();
          
          for (var json in studentsJson) {
            final id = json['id'];
            // Map backend status string to Enum
            AttendanceStatus status = AttendanceStatus.present;
            if (json['status'] == 'absent') status = AttendanceStatus.absent;
            if (json['status'] == 'late') status = AttendanceStatus.late;
            
            _attendanceRecords[id] = status;
            _remarks[id] = json['remarks'] ?? ''; 
          }
        });
      } else {
        _showError('Failed to fetch students: ${response.body}');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAttendance() async {
    if (_currentClassId == null) return;
    
    setState(() => _isLoading = true);
    try {
      final headers = await _getAuthHeaders();
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      
      final List<Map<String, dynamic>> records = [];
      _attendanceRecords.forEach((studentId, status) {
        records.add({
          'student_id': studentId,
          'status': status.name, // 'present', 'absent', 'late'
          'remarks': _remarks[studentId] ?? '',
        });
      });

      final body = {
        'class_id': _currentClassId,
        'date': dateStr,
        'records': records,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/attendance/bulk_save_attendance/'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        setState(() {
          _selectedClass = null;
          _selectedSection = null;
          _students = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance saved successfully!'),
            backgroundColor: primaryColor,
          ),
        );
      } else {
        _showError('Failed to save: ${response.body}');
      }
    } catch (e) {
      _showError('Error saving attendance: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _updateAttendance(dynamic studentId, AttendanceStatus status) {
    setState(() {
      _attendanceRecords[studentId] = status;
    });
  }

  Map<String, int> _getAttendanceStats() {
    int present = 0;
    int absent = 0;
    int late = 0;

    for (var student in _students) {
      final status = _attendanceRecords[student.id] ?? AttendanceStatus.present;
      if (status == AttendanceStatus.present) present++;
      else if (status == AttendanceStatus.absent) absent++;
      else if (status == AttendanceStatus.late) late++;
    }
    return {
      'total': _students.length,
      'present': present,
      'absent': absent,
      'late': late,
    };
  }

  void _showEditRemarkDialog(Student student) {
    String currentRemark = _remarks[student.id] ?? '';
    final TextEditingController controller = TextEditingController(text: currentRemark);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Remarks for ${student.name}'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notes',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _remarks[student.id] = controller.text.trim();
                });
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Attendance', style: TextStyle(color: Colors.white)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildControlsCard(context),
            const SizedBox(height: 20),
            _isLoading 
              ? const CircularProgressIndicator()
              : _buildMainContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_selectedClass == null || _selectedSection == null) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Icon(Icons.touch_app_outlined, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Select your class section and date to mark attendance',
              style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildStatsGrid(),
        _buildAttendanceList(),
      ],
    );
  }

  Widget _buildControlsCard(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Class Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
            ),
            const Divider(),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                // Class Dropdown
                SizedBox(
                  width: isWide ? 150 : (MediaQuery.of(context).size.width / 2 - 32),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Class', border: OutlineInputBorder()),
                    value: _selectedClass,
                    items: allClasses.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedClass = val;
                        // Don't reset section, keep it if possible or reset if needed
                        _fetchStudents();
                      });
                    },
                    style: const TextStyle(color: Colors.black),
                    disabledHint: null, // Removed
                  ),
                ),
                // Section Dropdown
                SizedBox(
                  width: isWide ? 150 : (MediaQuery.of(context).size.width / 2 - 32),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Section', border: OutlineInputBorder()),
                    value: _selectedSection,
                    items: allSections.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedSection = val;
                        _fetchStudents();
                      });
                    },
                    style: const TextStyle(color: Colors.black),
                    disabledHint: null, // Removed
                  ),
                ),
                // Date Picker
                SizedBox(
                  width: isWide ? 180 : double.infinity,
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(), // Block future dates
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDate = picked;
                          _fetchStudents();
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        suffixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    if (_students.isEmpty) return const SizedBox.shrink();
    final stats = _getAttendanceStats();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        children: [
          Expanded(child: _buildStatCard('Total Students', stats['total'] ?? 0, Colors.blue)),
          const SizedBox(width: 8),
          Expanded(child: _buildStatCard('Present', stats['present'] ?? 0, Colors.green)),
          const SizedBox(width: 8),
          Expanded(child: _buildStatCard('Absent', stats['absent'] ?? 0, Colors.red)),
          const SizedBox(width: 8),
          Expanded(child: _buildStatCard('Late', stats['late'] ?? 0, Colors.orange)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 11,
              color: Colors.grey.shade600,
              overflow: TextOverflow.ellipsis,
            ),
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 22,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList() {
    if (_students.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Text('No students found for selected criteria.'),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Student Records',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (_isEditable)
              ElevatedButton.icon(
                onPressed: _saveAttendance,
                icon: const Icon(Icons.save, color: Colors.white, size: 20),
                label: const Text('Save All', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _isToday ? Colors.red.shade100 : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _isToday ? Colors.red : Colors.orange),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isToday ? Icons.timer_off : Icons.history, 
                      color: _isToday ? Colors.red.shade800 : Colors.orange.shade800, 
                      size: 20
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isToday ? 'Today (Expired - 1hr over)' : 'Viewing History',
                      style: TextStyle(
                        color: _isToday ? Colors.red.shade800 : Colors.orange.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _students.length,
          itemBuilder: (context, index) {
            final student = _students[index];
            final status = _attendanceRecords[student.id]!;
            return _buildStudentCard(student, status);
          },
        ),
      ],
    );
  }

  Widget _buildStudentCard(Student student, AttendanceStatus currentStatus) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [
           BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.green.shade50,
                  child: Text(
                    student.avatarInitials,
                    style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Roll No: ${student.rollNo}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_note, color: Colors.blue),
                  onPressed: _isEditable ? () => _showEditRemarkDialog(student) : null,
                  tooltip: _isEditable ? 'Edit Remarks' : 'Locked',
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: currentStatus.color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    currentStatus.displayName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Change Status:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildStatusButton(student, AttendanceStatus.present, 'Present', Colors.green)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildStatusButton(student, AttendanceStatus.absent, 'Absent', Colors.red)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildStatusButton(student, AttendanceStatus.late, 'Late', Colors.orange)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton(Student student, AttendanceStatus status, String label, Color color) {
    final isSelected = _attendanceRecords[student.id] == status;
    return InkWell(
      onTap: _isEditable ? () => _updateAttendance(student.id, status) : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 0 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
