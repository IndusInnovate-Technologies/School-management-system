import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:main_login/main.dart' as main_login;
import 'package:http/http.dart' as http;
import 'dart:convert';
// Navigation imports
import 'teacher-assignment.dart';
import 'teacher-attendance.dart';
import 'teacher-exam.dart';
import 'teacher-grades.dart';
import 'teacher-profile.dart';
import 'teacher-studymaterial.dart' as study_material;
import 'teacher-timetable.dart' as timetable;
import 'Teacher_classes.dart';
import 'Teacher_class_students.dart';
import 'Teacher_Communication.dart';
import 'Teacher_Results.dart';
import 'Teacher_Projects.dart';
import 'Teacher_Tasks.dart';
import 'teacher_homework.dart'; // Added this
import 'services/api_service.dart' as api;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/fcm_service.dart';
// Removed: import 'screens/stat_detail.dart';
// Definition for StatDetailScreen added below main file.

// --- MOCK DATA STRUCTURES ---
class DashboardData {
  final int totalStudents;
  final int totalClasses;
  final int upcomingExams;
  final int pendingAssignments;
  final int totalResults;
  // Metrics corresponding to the file list
  final int totalAttendanceRecords;
  final int totalStudyMaterials;
  final int totalGradesPending;
  final int totalCommunication;
  final int totalTimetableSlots;
  final int projectsCount;
  final int tasksCount;
  final int homeworkCount; // Added this
  final int profileCompleteness; // New: Profile completeness percentage

  final String attendanceRate;
  final String avgGrade;
  final List<ClassData> classes;

  DashboardData({
    required this.totalStudents,
    required this.totalClasses,
    required this.upcomingExams,
    required this.pendingAssignments,
    required this.totalResults,
    required this.attendanceRate,
    required this.avgGrade,
    required this.classes,
    required this.totalAttendanceRecords,
    required this.totalStudyMaterials,
    required this.totalGradesPending,
    required this.totalCommunication,
    required this.totalTimetableSlots,
    required this.projectsCount,
    required this.tasksCount,
    required this.homeworkCount, // Added this
    this.profileCompleteness = 85, // Default 85% complete
  });
}

class ClassData {
  final String name;
  final int students;
  final List<String> subjects;

  ClassData({
    required this.name,
    required this.students,
    required this.subjects,
  });
}

class ChartData {
  final String day;
  final int present;
  final int absent;
  final int late;

  ChartData({
    required this.day,
    required this.present,
    required this.absent,
    required this.late,
  });
}

class SubjectData {
  final String subject;
  final int average;

  SubjectData({required this.subject, required this.average});
}

class ChatMessage {
  final String text;
  final String sender; // 'user', 'teacher', or 'system'
  final String time;
  final String? senderName; // Teacher name for individual chats
  final String? avatarEmoji;

  ChatMessage({
    required this.text,
    required this.sender,
    required this.time,
    this.senderName,
    this.avatarEmoji,
  });
}

class Teacher {
  final String id;
  final String name;
  final String subject;
  final String avatar;
  final bool isOnline;
  final String?
  className; // For students: their class, for teachers: assigned class
  final String? grade; // For students: their grade

  Teacher({
    required this.id,
    required this.name,
    required this.subject,
    required this.avatar,
    required this.isOnline,
    this.className,
    this.grade,
  });
}

class GroupChat {
  final String id;
  final String name;
  final String description;

  final List<Teacher> members;
  final String avatar;
  final int unreadCount;

  GroupChat({
    required this.id,
    required this.name,
    required this.description,
    required this.members,
    required this.avatar,
    required this.unreadCount,
  });
}

// --- API DATA IMPLEMENTATION ---
Future<DashboardData> fetchDashboardData() async {
  try {
    debugPrint('DASHBOARD: Fetching stats from teacher/dashboard-stats/');
    final response = await api.ApiService.authenticatedRequest('teacher/dashboard-stats/', method: 'GET');
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      
      // Parse classes
      List<ClassData> classesList = [];
      if (data['classes'] is List) {
        classesList = (data['classes'] as List).map((cls) {
          return ClassData(
            name: cls['name']?.toString() ?? 'Unknown Class',
            students: cls['students'] is int ? cls['students'] : int.tryParse(cls['students'].toString()) ?? 0,
            subjects: (cls['subjects'] is List) 
                ? (cls['subjects'] as List).map((s) => s.toString()).toList() 
                : [],
          );
        }).toList();
      }

      return DashboardData(
        totalStudents: data['totalStudents'] ?? 0,
        totalClasses: data['totalClasses'] ?? 0,
        upcomingExams: data['upcomingExams'] ?? 0,
        pendingAssignments: data['pendingAssignments'] ?? 0,
        totalResults: data['totalResults'] ?? 0,
        attendanceRate: data['attendanceRate']?.toString() ?? '0%',
        avgGrade: data['avgGrade']?.toString() ?? 'N/A',
        classes: classesList,
        totalAttendanceRecords: data['totalAttendanceRecords'] ?? 0,
        totalStudyMaterials: data['totalStudyMaterials'] ?? 0,
        totalGradesPending: data['totalGradesPending'] ?? 0,
        totalCommunication: data['totalCommunication'] ?? 0,
        totalTimetableSlots: data['totalTimetableSlots'] ?? 0,
        projectsCount: data['projectsCount'] ?? 0,
        tasksCount: data['tasksCount'] ?? 0,
        homeworkCount: data['homeworkCount'] ?? 0, // Added this
      );
    } else {
      debugPrint('DASHBOARD: Failed to fetch stats: ${response.statusCode}');
      // Fallback or rethrow? Let's return zeros to avoid crash
      return _emptyDashboardData();
    }
  } catch (e, stack) {
    debugPrint('DASHBOARD ERROR: $e\n$stack');
    return _emptyDashboardData();
  }
}

DashboardData _emptyDashboardData() {
  return DashboardData(
    totalStudents: 0,
    totalClasses: 0,
    upcomingExams: 0,
    pendingAssignments: 0,
    totalResults: 0,
    attendanceRate: '0%',
    avgGrade: 'N/A',
    classes: [],
    totalAttendanceRecords: 0,
    totalStudyMaterials: 0,
    totalGradesPending: 0,
    totalCommunication: 0,
    totalTimetableSlots: 0,
    projectsCount: 0,
    tasksCount: 0,
    homeworkCount: 0, // Added this
  );
}

// --- MAIN WIDGET ---
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase init (optional): $e');
  }
  runApp(const TeacherDashboardApp());
}

class TeacherDashboardApp extends StatelessWidget {
  const TeacherDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Teacher Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        fontFamily: 'Segoe UI',
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<DashboardData> _dashboardData;
  DateTime _currentDate = DateTime.now();
  String _selectedAttendancePeriod =
      'Weekly'; // Separate for Attendance Performance
  String _selectedProgressPeriod =
      'Weekly'; // Separate for Class Progress Overview

  // Teacher profile (kept for potential use in dashboard)
  String? _currentTeacherUsername;
  String? _currentTeacherUserId;
  String? _schoolName;
  String? _schoolId;
  String? _logoUrl; // Added logo URL
  int _notificationUnreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCachedSchoolDetails();
    _dashboardData = fetchDashboardData();
    _loadTeacherProfile();
    _initFcm();
    _loadNotificationCount();
  }

  Future<void> _loadNotificationCount() async {
    try {
      final data = await api.ApiService.getMyPushNotifications();
      if (mounted) setState(() => _notificationUnreadCount = data['unread_count'] as int? ?? 0);
    } catch (_) {}
  }

  void _openNotificationsPanel() async {
    await api.ApiService.markMyPushNotificationsRead();
    if (mounted) setState(() => _notificationUnreadCount = 0);
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => _TeacherNotificationsPanel(
        onClose: () => Navigator.pop(ctx),
      ),
    );
  }

  Future<void> _initFcm() async {
    try {
      await FcmService.requestPermission();
      FcmService.setupHandlers();
      await FcmService.registerTokenIfNeeded();
    } catch (e) {
      debugPrint('FCM init: $e');
    }
  }

  Future<void> _loadTeacherProfile() async {
    try {
      final teacherProfile = await api.ApiService.fetchTeacherProfile();
      if (teacherProfile != null) {
        final user = teacherProfile['user'] as Map<String, dynamic>?;
        _currentTeacherUsername = user?['username'] as String?;
        _currentTeacherUserId = user?['user_id']?.toString();

        // Extract school_id and school_name from profile
        _schoolId =
            teacherProfile['school_id']?.toString() ??
            teacherProfile['department']?['school']?['school_id']?.toString();
        _schoolName = teacherProfile['school_name']?.toString();
        _logoUrl = teacherProfile['logo_url']?.toString();

        debugPrint('Teacher username loaded: $_currentTeacherUsername');
        debugPrint('Teacher user_id loaded: $_currentTeacherUserId');
        debugPrint('School ID loaded: $_schoolId');
        debugPrint('School Name loaded: $_schoolName');
        debugPrint('School Logo loaded: $_logoUrl');

        if (mounted) {
          setState(() {});
          _saveSchoolDetailsToCache(_schoolName, _logoUrl);
        }

        // Fetch School Details (including Logo) in background for sync
        _loadSchoolDetails(); 

        if ((_schoolName == null || _schoolName!.isEmpty) && 
            (_schoolId != null && _schoolId!.isNotEmpty)) {
          // Fallback: try to load school name if still not available
          _loadSchoolName();
        }
      } else {
        debugPrint('Teacher profile is null');
      }
    } catch (e) {
      debugPrint('Failed to load teacher profile: $e');
    }
  }

  // New method to fetch school details including logo
  Future<void> _loadSchoolDetails() async {
    try {
      final headers = await api.ApiService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${api.ApiService.baseUrl}/teacher/school-details/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map) {
          setState(() {
            _schoolName = data['school_name']?.toString() ?? _schoolName;
            _logoUrl = data['logo_url']?.toString();
          });
          _saveSchoolDetailsToCache(_schoolName, _logoUrl);
          debugPrint('Loaded School Details - Name: $_schoolName, Logo: $_logoUrl');
        }
      } else {
        debugPrint('Failed to load school details: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error loading school details: $e');
    }
  }

  Future<void> _loadCachedSchoolDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedName = prefs.getString('school_name');
      final cachedLogo = prefs.getString('logo_url');
      
      if (cachedName != null || cachedLogo != null) {
        if (mounted) {
          setState(() {
            if (cachedName != null) _schoolName = cachedName;
            if (cachedLogo != null) _logoUrl = cachedLogo;
          });
          debugPrint('Loaded Cached Details - Name: $_schoolName, Logo: $_logoUrl');
        }
      }
    } catch (e) {
      debugPrint('Error loading cached details: $e');
    }
  }

  Future<void> _saveSchoolDetailsToCache(String? name, String? logo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (name != null) await prefs.setString('school_name', name);
      if (logo != null) await prefs.setString('logo_url', logo);
    } catch (e) {
      debugPrint('Error saving to cache: $e');
    }
  }

  Future<void> _loadSchoolName() async {
    try {
      if (_schoolId == null || _schoolId!.isEmpty) return;

      final headers = await api.ApiService.getAuthHeaders();

      // Try super-admin endpoint to get school by school_id
      final response = await http
          .get(
            Uri.parse(
              'http://localhost:8000/api/super-admin/schools/$_schoolId/',
            ),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map) {
          setState(() {
            _schoolName = data['school_name']?.toString() ?? 'School';
            if (_logoUrl == null) {
               _logoUrl = data['logo_url']?.toString();
            }
          });
          return;
        }
      }

      // Fallback: try to extract from teacher profile if department.school is available
      try {
        final teacherProfile = await api.ApiService.fetchTeacherProfile();
        if (teacherProfile != null) {
          final department = teacherProfile['department'];
          if (department is Map) {
            final school = department['school'];
            if (school is Map && school['school_name'] != null) {
              setState(() {
                _schoolName = school['school_name']?.toString() ?? 'School';
              });
              return;
            }
          }
        }
      } catch (e) {
        debugPrint('Failed to extract school from profile: $e');
      }

      setState(() {
        _schoolName = 'School';
      });
    } catch (e) {
      debugPrint('Failed to load school name: $e');
      setState(() {
        _schoolName = 'School';
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Chat functionality has been moved to TeacherCommunicationScreen

  // --- Core Functions ---

  // Navigation function to handle routing to different screens
  void _navigateToScreen(String label) {
    switch (label.toLowerCase()) {
      case 'add-assignment':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AssignmentDashboardScreen(),
          ),
        );
        break;
      case 'attendance':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AttendanceDashboard()),
        );
        break;
      case 'class-students':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const StudentDashboardScreen(),
          ),
        );
        break;
      case 'classes':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MyClassesPage()),
        );
        break;
      case 'communication':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TeacherCommunicationScreen(
              onToggleTheme: () {},
              initialThemeMode: ThemeMode.light,
            ),
          ),
        );
        break;
      case 'exam':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TeacherDashboard()),
        );
        break;
      case 'grades':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const GradesDashboard()),
        );
        break;
      case 'profile':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TeacherProfilePage()),
        );
        break;
      case 'results':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const EnterResultsScreen()),
        );
        break;
      case 'study materials':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const study_material.DashboardScreen(),
          ),
        );
        break;
      case 'time-table':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const timetable.TeacherTimetableScreen(),
          ),
        );
        break;
      case 'projects':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TeacherProjectsScreen(),
          ),
        );
        break;
      case 'tasks':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TeacherTasksScreen(),
          ),
        );
        break;
      case 'homework': // Added this
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeworkDashboardScreen(),
          ),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Navigation to $label not implemented')),
        );
    }
  }

  // Get attendance data based on selected period
  Map<String, String> _getAttendanceData(String period) {
    final data = {
      'Weekly': {'attendance': '92.5%', 'grade': 'B+'},
      'Monthly': {'attendance': '88.3%', 'grade': 'A-'},
      'Quarterly': {'attendance': '85.7%', 'grade': 'B'},
      'Yearly': {'attendance': '87.2%', 'grade': 'A'},
    };
    return data[period] ?? data['Weekly']!;
  }

  // Get progress chart data based on selected period
  List<SubjectData> _getProgressChartData(String period) {
    final dataMap = {
      'Weekly': [
        SubjectData(subject: 'Math', average: 85),
        SubjectData(subject: 'Science', average: 78),
        SubjectData(subject: 'English', average: 92),
        SubjectData(subject: 'History', average: 81),
      ],
      'Monthly': [
        SubjectData(subject: 'Math', average: 88),
        SubjectData(subject: 'Science', average: 82),
        SubjectData(subject: 'English', average: 90),
        SubjectData(subject: 'History', average: 85),
      ],
      'Quarterly': [
        SubjectData(subject: 'Math', average: 80),
        SubjectData(subject: 'Science', average: 75),
        SubjectData(subject: 'English', average: 87),
        SubjectData(subject: 'History', average: 78),
      ],
      'Yearly': [
        SubjectData(subject: 'Math', average: 86),
        SubjectData(subject: 'Science', average: 81),
        SubjectData(subject: 'English', average: 91),
        SubjectData(subject: 'History', average: 82),
      ],
    };
    return dataMap[period] ?? dataMap['Weekly']!;
  }

  // This is a complex mock function based on the JS logic.
  Map<String, dynamic> _generateAttendanceData(DateTime date) {
    final day = date.weekday;
    final isWeekend = day == DateTime.saturday || day == DateTime.sunday;

    if (isWeekend) {
      return {
        'present': 0,
        'absent': 0,
        'late': 0,
        'total': 0,
        'attendanceRate': 0,
        'classes': [],
      };
    }

    final classes = [
      {'name': 'Class 10A', 'subject': 'Mathematics'},
      {'name': 'Class 11B', 'subject': 'Physics'},
      {'name': 'Class 9C', 'subject': 'English'},
      {'name': 'Class 12A', 'subject': 'Chemistry'},
    ];

    int totalPresent = 0;
    int totalAbsent = 0;
    int totalLate = 0;
    int totalStudents = 0;

    // Using a seeded Random based on the date to make the mock data semi-consistent
    final random = Random(date.millisecondsSinceEpoch);

    final classData = classes.map((cls) {
      final totalClassStudents = random.nextInt(16) + 20; // 20-35 students
      final present =
          random.nextInt((totalClassStudents * 0.3).round()) +
          (totalClassStudents * 0.6).round(); // 60-90% present
      final late = random.nextInt(5) + 1; // 1-5 late
      final absent = max(0, totalClassStudents - present - late);
      final rate = ((present + late) / totalClassStudents * 100).round();

      totalPresent += present;
      totalAbsent += absent;
      totalLate += late;
      totalStudents += totalClassStudents;

      return {
        ...cls,
        'present': present,
        'absent': absent,
        'late': late,
        'rate': rate,
      };
    }).toList();

    final attendanceRate = totalStudents > 0
        ? (((totalPresent + totalLate) / totalStudents) * 100).round()
        : 0;

    return {
      'present': totalPresent,
      'absent': totalAbsent,
      'late': totalLate,
      'total': totalStudents,
      'attendanceRate': attendanceRate,
      'classes': classData,
    };
  }

  // --- UI Builders ---

  String _safeNumber(Object? v) {
    try {
      if (v == null) return '0';
      return v.toString();
    } catch (e) {
      return '0';
    }
  }

  Widget _buildStatCard(
    String icon,
    String number,
    String label, {
    VoidCallback? onTap,
    bool showCreateButton = false,
    VoidCallback? onCreateTap,
  }) {
    return Container(
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
            decoration: const BoxDecoration(
              color: Color(0xFF667eea),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                InkWell(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(icon, style: const TextStyle(fontSize: 24)),
                          const SizedBox(height: 6),
                          Text(
                            number,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF333333),
                            ),
                            textAlign: TextAlign.center,
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
                  ),
                ),
                // Create button overlay
                if (showCreateButton && onCreateTap != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onCreateTap,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF667eea).withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard(ClassData classItem) {
    return Container(
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
          Container(
            height: 4,
            decoration: const BoxDecoration(
              color: Color(0xFF667eea),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  classItem.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _buildClassStat(
                        classItem.students.toString(),
                        'Students',
                        const Color(0xFF667eea),
                      ),
                    ),
                    Expanded(
                      child: _buildClassStat(
                        classItem.subjects.length.toString(),
                        'Subjects',
                        const Color(0xFF667eea),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: classItem.subjects
                      .map((subject) => _buildSubjectTag(subject))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassStat(String number, String label, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          number,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSubjectTag(String subject) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        subject,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // Create Project Dialog
  void _showCreateProjectDialog() async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController classController = TextEditingController();
    final TextEditingController sectionController = TextEditingController();
    final TextEditingController submissionDateController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.folder, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Create New Project',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Project Title',
                    hintText: 'Enter project title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter project description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.description),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: classController,
                        decoration: InputDecoration(
                          labelText: 'Class',
                          hintText: 'e.g., Class 10',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.class_),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: sectionController,
                        decoration: InputDecoration(
                          labelText: 'Section',
                          hintText: 'e.g., A, B, C',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.group),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: submissionDateController,
                  decoration: InputDecoration(
                    labelText: 'Submission Date',
                    hintText: 'Select submission date',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      submissionDateController.text = DateFormat('yyyy-MM-dd').format(picked);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty) {
                  try {
                    // Get or create class first
                    int? classId;
                    if (classController.text.isNotEmpty && sectionController.text.isNotEmpty) {
                      try {
                        // Try to find existing class
                        final classResponse = await api.ApiService.authenticatedRequest(
                          'teacher/classes/?name=${classController.text}&section=${sectionController.text}',
                          method: 'GET',
                        );
                        
                        if (classResponse.statusCode == 200) {
                          final classList = json.decode(classResponse.body);
                          if (classList is List && classList.isNotEmpty) {
                            classId = classList[0]['id'];
                          }
                        }
                      } catch (e) {
                        debugPrint('Error finding class: $e');
                      }
                    }

                    // Prepare project data matching backend expectations
                    final Map<String, dynamic> projectData = {
                      'title': titleController.text,
                      'description': descriptionController.text,
                      'subject': classController.text.isNotEmpty 
                          ? '${classController.text} ${sectionController.text}'.trim() 
                          : 'General',
                      'due_date': submissionDateController.text.isNotEmpty 
                          ? '${submissionDateController.text}T23:59:59Z'
                          : DateTime.now().add(const Duration(days: 7)).toIso8601String(),
                    };

                    // Add class_obj if we found one
                    if (classId != null) {
                      projectData['class_obj'] = classId;
                    }

                    debugPrint('Creating project with data: $projectData');

                    // Make API call to create project
                    final response = await api.ApiService.authenticatedRequest(
                      'teacher/projects/',
                      method: 'POST',
                      body: projectData,
                    );

                    debugPrint('Project creation response: ${response.statusCode} - ${response.body}');

                    if (response.statusCode == 201 || response.statusCode == 200) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Project "${titleController.text}" created successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.of(context).pop();
                        // Refresh dashboard data
                        setState(() {
                          _dashboardData = fetchDashboardData();
                        });
                      }
                    } else {
                      if (context.mounted) {
                        final errorBody = response.body;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to create project: $errorBody'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    debugPrint('Exception creating project: $e');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error creating project: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a project title'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }


  // Create Task Dialog
  void _showCreateTaskDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController classController = TextEditingController();
    final TextEditingController sectionController = TextEditingController();
    final TextEditingController submissionDateController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.task_alt, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Create New Task',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Task Title',
                    hintText: 'Enter task title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter task description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.description),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: classController,
                        decoration: InputDecoration(
                          labelText: 'Class',
                          hintText: 'e.g., Class 10A',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.class_),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: sectionController,
                        decoration: InputDecoration(
                          labelText: 'Section',
                          hintText: 'e.g., A, B, C',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.group),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: submissionDateController,
                  decoration: InputDecoration(
                    labelText: 'Submission Date',
                    hintText: 'Select submission date',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      submissionDateController.text = DateFormat('yyyy-MM-dd').format(picked);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty) {
                  try {
                    // Get or create class first
                    int? classId;
                    if (classController.text.isNotEmpty && sectionController.text.isNotEmpty) {
                      try {
                        // Try to find existing class
                        final classResponse = await api.ApiService.authenticatedRequest(
                          'teacher/classes/?name=${classController.text}&section=${sectionController.text}',
                          method: 'GET',
                        );
                        
                        if (classResponse.statusCode == 200) {
                          final classList = json.decode(classResponse.body);
                          if (classList is List && classList.isNotEmpty) {
                            classId = classList[0]['id'];
                          }
                        }
                      } catch (e) {
                        debugPrint('Error finding class: $e');
                      }
                    }

                    // Prepare task data matching backend expectations
                    final Map<String, dynamic> taskData = {
                      'title': titleController.text,
                      'description': descriptionController.text,
                      'subject': classController.text.isNotEmpty 
                          ? '${classController.text} ${sectionController.text}'.trim() 
                          : 'General',
                      'category': 'homework',
                      'priority': 'medium',
                      'due_date': submissionDateController.text.isNotEmpty 
                          ? submissionDateController.text
                          : DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 7))),
                    };

                    // Add class_obj if we found one
                    if (classId != null) {
                      taskData['class_obj'] = classId;
                    }

                    debugPrint('Creating task with data: $taskData');

                    // Make API call to create task
                    final response = await api.ApiService.authenticatedRequest(
                      'teacher/tasks/',
                      method: 'POST',
                      body: taskData,
                    );

                    debugPrint('Task creation response: ${response.statusCode} - ${response.body}');

                    if (response.statusCode == 201 || response.statusCode == 200) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Task "${titleController.text}" created successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.of(context).pop();
                        // Refresh dashboard data
                        setState(() {
                          _dashboardData = fetchDashboardData();
                        });
                      }
                    } else {
                      if (context.mounted) {
                        final errorBody = response.body;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to create task: $errorBody'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    debugPrint('Exception creating task: $e');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error creating task: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a task title'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }


  void _showAttendanceModal(DateTime date) {
    final data = _generateAttendanceData(date);
    final dateString = DateFormat('EEEE, MMMM d, yyyy').format(date);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          content: Container(
            width: MediaQuery.of(context).size.width > 600
                ? 800
                : MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxWidth: 800,
              maxHeight: max(50.0, MediaQuery.of(context).size.height * 0.85),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20).copyWith(left: 30),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    ),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(15),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Attendance Details - $dateString',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildAttendanceSummaryGrid(data),
                        const SizedBox(height: 25),
                        _buildAttendanceRateCircle(
                          data['attendanceRate'] as int,
                        ),
                        const SizedBox(height: 25),
                        const Text(
                          'Class-wise Breakdown',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const Divider(height: 20),
                        ...((data['classes'] as List<Map<String, dynamic>>)
                            .map((cls) => _buildClassAttendanceItem(cls))
                            .toList()),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttendanceSummaryGrid(Map<String, dynamic> data) {
    // FIX: Safely retrieve and cast integers, providing a default of 0 if null.
    final present = (data['present'] as int?) ?? 0;
    final absent = (data['absent'] as int?) ?? 0;
    final late = (data['late'] as int?) ?? 0;
    final total = (data['total'] as int?) ?? 0;

    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      childAspectRatio: 1.1,
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildSummaryCard(
          present,
          'Present',
          '✅',
          const Color(0xFF28a745),
          const Color(0xFFd4edda),
        ),
        _buildSummaryCard(
          absent,
          'Absent',
          '❌',
          const Color(0xFFdc3545),
          const Color(0xFFf8d7da),
        ),
        _buildSummaryCard(
          late,
          'Late',
          '⏰',
          const Color(0xFFffc107),
          const Color(0xFFfff3cd),
        ),
        _buildSummaryCard(
          total,
          'Total',
          '👥',
          const Color(0xFF667eea),
          const Color(0xFFe3f2fd),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    int number,
    String label,
    String icon,
    Color borderColor,
    Color backgroundColor,
  ) {
    return Container(
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
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: borderColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(icon, style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 4),
                Text(
                  number.toString(),
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

  Widget _buildAttendanceRateCircle(int rate) {
    return Center(
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          color: const Color(0xFFf0f4ff),
          border: Border.all(color: const Color(0xFF667eea), width: 3),
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667eea).withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$rate%',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Color(0xFF667eea),
              ),
            ),
            const Text(
              'Attendance Rate',
              style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassAttendanceItem(Map<String, dynamic> cls) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFf8f9fa),
        borderRadius: BorderRadius.circular(10),
        border: const Border(
          left: BorderSide(color: Color(0xFF667eea), width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cls['name'].toString(),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          Text(
            cls['subject'].toString(),
            style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 20,
            runSpacing: 10,
            children: [
              _buildStatDetail(
                'Present',
                cls['present'].toString(),
                const Color(0xFF28a745),
              ),
              _buildStatDetail(
                'Absent',
                cls['absent'].toString(),
                const Color(0xFFdc3545),
              ),
              _buildStatDetail(
                'Late',
                cls['late'].toString(),
                const Color(0xFFffc107),
              ),
              _buildStatDetail(
                'Rate',
                '${cls['rate']}%',
                const Color(0xFF667eea),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatDetail(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
        ),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }

  // --- Chart CustomPainter Widgets ---

  Widget _buildTimePeriodButton(String period, String sectionType) {
    final isSelected = sectionType == 'attendance'
        ? _selectedAttendancePeriod == period
        : _selectedProgressPeriod == period;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (sectionType == 'attendance') {
            _selectedAttendancePeriod = period;
          } else {
            _selectedProgressPeriod = period;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF667eea) : Colors.white,
          border: Border.all(color: const Color(0xFF667eea), width: 1.5),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          period,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF667eea),
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // Removed: Chat UI methods moved to TeacherCommunicationScreen

  // --- Main Layout Build ---

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final isTablet = MediaQuery.of(context).size.width > 600;
    final statCardCount = isTablet ? 3 : 2;
    final classesGridCount = isTablet ? 2 : 1;
    final horizontalPadding = isDesktop ? 20.0 : 10.0;

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) return;
        Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(100.0),
          child: _buildHeader(),
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 20,
              ),
              child: FutureBuilder<DashboardData>(
                future: _dashboardData,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingIndicator();
                  } else if (snapshot.hasError) {
                    return _buildErrorWidget(snapshot.error.toString());
                  } else if (snapshot.hasData) {
                    final data = snapshot.data!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Calendar Section (At the Top)
                        _buildCalendarSection(context),
                        const SizedBox(height: 40),

                        // Stats Grid (Responsive)
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: isDesktop ? 5 : statCardCount,
                                crossAxisSpacing: 20,
                                mainAxisSpacing: 20,
                                childAspectRatio: 1.2,
                              ),
                          itemCount:
                              14, // FIX: Increased to 14 for all modules + Profile + Homework
                          itemBuilder: (context, index) {
                            // Build stats defensively to avoid runtime null errors
                            List<Map<String, String>> stats;
                            try {
                              final dyn = data as dynamic;
                              // Build stats with exact labels requested by the user
                              stats = [
                                {
                                  'icon': '📝',
                                  'number': _safeNumber(dyn.pendingAssignments),
                                  'label': 'Add-Assignment',
                                },
                                {
                                  'icon': '✅',
                                  'number': _safeNumber(
                                    dyn.totalAttendanceRecords,
                                  ),
                                  'label': 'Attendance',
                                },
                                {
                                  'icon': '👨‍🎓',
                                  'number': _safeNumber(dyn.totalStudents),
                                  'label': 'Class-students',
                                },
                                {
                                  'icon': '🏫',
                                  'number': _safeNumber(dyn.totalClasses),
                                  'label': 'classes',
                                },
                                {
                                  'icon': '💬',
                                  'number': _safeNumber(dyn.totalCommunication),
                                  'label': 'communication',
                                },
                                {
                                  'icon': '📅',
                                  'number': _safeNumber(dyn.upcomingExams),
                                  'label': 'exam',
                                },
                                {
                                  'icon': '📊',
                                  'number': _safeNumber(dyn.totalGradesPending),
                                  'label': 'grades',
                                },
                                {
                                  'icon': '👤',
                                  'number': _safeNumber(
                                    dyn.profileCompleteness,
                                  ),
                                  'label': 'profile',
                                },
                                {
                                  'icon': '📈',
                                  'number': _safeNumber(dyn.totalResults),
                                  'label': 'results',
                                },
                                {
                                  'icon': '📖',
                                  'number': _safeNumber(
                                    dyn.totalStudyMaterials,
                                  ),
                                  'label': 'study materials',
                                },
                                {
                                  'icon': '⏰',
                                  'number': _safeNumber(
                                    dyn.totalTimetableSlots,
                                  ),
                                  'label': 'time-table',
                                },
                                {
                                  'icon': '🔮',
                                  'number': _safeNumber(dyn.projectsCount),
                                  'label': 'projects',
                                },
                                {
                                  'icon': '✅',
                                  'number': _safeNumber(dyn.tasksCount),
                                  'label': 'tasks',
                                },
                                {
                                  'icon': '📚',
                                  'number': _safeNumber(dyn.homeworkCount),
                                  'label': 'homework',
                                },
                              ];
                            } catch (e) {
                              stats = List.generate(
                                13,
                                (i) => {
                                  'icon': 'ℹ️',
                                  'number': '0',
                                  'label': 'N/A',
                                },
                              );
                            }
                            
                            // Determine if this card should have a create button
                            final label = stats[index]['label']!;
                            final bool shouldShowCreateButton = 
                                label.toLowerCase() == 'projects' || 
                                label.toLowerCase() == 'tasks';
                            
                            VoidCallback? createCallback;
                            if (label.toLowerCase() == 'projects') {
                              createCallback = _showCreateProjectDialog;
                            } else if (label.toLowerCase() == 'tasks') {
                              createCallback = _showCreateTaskDialog;
                            }
                            
                            return _buildStatCard(
                              stats[index]['icon']!,
                              stats[index]['number']!,
                              stats[index]['label']!,
                              onTap: () =>
                                  _navigateToScreen(stats[index]['label']!),
                              showCreateButton: shouldShowCreateButton,
                              onCreateTap: createCallback,
                            );
                          },
                        ),
                        const SizedBox(height: 40),

                        // Main Content Grid (2 Columns Desktop, 1 Column Mobile)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (isDesktop) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: _buildMainSection(
                                      data,
                                      classesGridCount,
                                    ),
                                  ),
                                  const SizedBox(width: 30),
                                  Expanded(
                                    flex: 1,
                                    child: _buildSidebarSection(),
                                  ),
                                ],
                              );
                            } else {
                              return Column(
                                children: [
                                  _buildMainSection(data, classesGridCount),
                                  const SizedBox(height: 30),
                                  _buildSidebarSection(),
                                ],
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  }
                  return Container();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Sub-Section Builders ---

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2), Color(0xFFf093fb)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.only(top: 20, bottom: 12, left: 24, right: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo and School Name
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final double side = (constraints.maxHeight * 0.9).clamp(
                      60.0,
                      120.0,
                    );
                    return Container(
                      decoration: BoxDecoration(
                        // border: Border.all(color: const Color(0xFFFFD700), width: 1.5), // Removed border
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26, 
                            blurRadius: 4, 
                            offset: Offset(0, 2)
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _logoUrl != null && _logoUrl!.isNotEmpty
                            ? Image.network(
                                _logoUrl!,
                                fit: BoxFit.cover,
                                width: side,
                                height: side,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: Icon(
                                      Icons.school,
                                      size: side * 0.5,
                                      color: Colors.grey[600],
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.grey[200],
                                child: Icon(
                                  Icons.school,
                                  size: side * 0.5,
                                  color: Colors.grey[600],
                                ),
                              ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Text(
                    _schoolName ?? 'School Name',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
          
          // User Info and Logout
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Notification icon (last right before avatar)
              IconButton(
                onPressed: _openNotificationsPanel,
                icon: Badge(
                  isLabelVisible: _notificationUnreadCount > 0,
                  label: Text('$_notificationUnreadCount'),
                  child: const Icon(Icons.notifications_none, color: Colors.white, size: 26),
                ),
              ),
              const SizedBox(width: 20),
              
              // Logout Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext dialogContext) {
                        return AlertDialog(
                          title: const Text('Logout'),
                          content: const Text(
                            'Are you sure you want to logout?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(dialogContext).pop(),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () async {
                                // Clear cache
                                try {
                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.remove('school_name');
                                  await prefs.remove('logo_url');
                                } catch (e) {
                                  debugPrint('Error clearing cache: $e');
                                }

                                if (dialogContext.mounted) {
                                  Navigator.of(dialogContext).pop();
                                }
                                
                                if (context.mounted) {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const main_login.LoginScreen(),
                                    ),
                                    (route) => false,
                                  );
                                }
                              },
                              child: const Text(
                                'Logout',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF8A80), Color(0xFFF48FB1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.logout, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Teacher Dashboard',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            foreground: Paint()
              ..shader = const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
          ),
        ),
        const Text(
          'Academic management and student progress',
          style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(50.0),
        child: Column(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
            ),
            SizedBox(height: 20),
            Text(
              'Loading dashboard data...',
              style: TextStyle(color: Color(0xFF666666)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFff6b6b), Color(0xFFee5a52)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Error: $error',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarSection(BuildContext context) {
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(_currentDate.year, _currentDate.month, 1);
    final daysInMonth = DateTime(
      _currentDate.year,
      _currentDate.month + 1,
      0,
    ).day;
    final weekdayOfFirstDay =
        firstDayOfMonth.weekday % 7; // Convert to 0=Sun, 1=Mon...

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Attendance Calendar',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const Spacer(),
                // Month controls: allow the month label to shrink on small widths
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_left,
                        color: Color(0xFF667eea),
                      ),
                      onPressed: () {
                        setState(() {
                          _currentDate = DateTime(
                            _currentDate.year,
                            _currentDate.month - 1,
                            1,
                          );
                        });
                      },
                    ),
                    // Constrain the month label and scale it down when necessary
                    SizedBox(
                      width: 120,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4.0),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              DateFormat('MMM yyyy').format(_currentDate),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 1,
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_right,
                        color: Color(0xFF667eea),
                      ),
                      onPressed: () {
                        setState(() {
                          _currentDate = DateTime(
                            _currentDate.year,
                            _currentDate.month + 1,
                            1,
                          );
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                // adapt columns on very narrow screens so items don't overflow
                final availableWidth = constraints.maxWidth;
                int crossAxisCount = 7;
                if (availableWidth < 420) {
                  crossAxisCount =
                      7; // keep weekdays but reduce spacing via styles
                }

                // Responsive sizing tweaks
                final cellPadding = availableWidth < 420 ? 1.0 : 3.0;
                final headerFontSize = availableWidth < 420 ? 8.0 : 10.0;
                final dayFontSize = availableWidth < 420 ? 10.0 : 12.0;
                final spacing = availableWidth < 420 ? 1.0 : 2.0;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: 7 + 42, // Headers + 6 rows of days
                  itemBuilder: (context, index) {
                    if (index < 7) {
                      // Day Headers
                      return Container(
                        alignment: Alignment.center,
                        padding: EdgeInsets.symmetric(
                          vertical: cellPadding,
                          horizontal: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFf8f9fa), Color(0xFFe9ecef)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          days[index],
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF667eea),
                            fontSize: headerFontSize,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    final dayIndex = index - 7;
                    final dayOfMonth =
                        dayIndex -
                        (weekdayOfFirstDay == 0 ? 6 : weekdayOfFirstDay - 1) +
                        1; // 0=Mon, 6=Sun in Flutter

                    if (dayOfMonth < 1 || dayOfMonth > daysInMonth) {
                      return Container(); // Empty filler
                    }

                    final date = DateTime(
                      _currentDate.year,
                      _currentDate.month,
                      dayOfMonth,
                    );
                    final isToday =
                        date.day == now.day &&
                        date.month == now.month &&
                        date.year == now.year;
                    final hasAttendance =
                        date.weekday != DateTime.sunday &&
                        date.weekday != DateTime.saturday;

                    Color bgColor = Colors.transparent;
                    Color textColor = const Color(0xFF333333);
                    List<BoxShadow> shadows = [];

                    if (isToday) {
                      bgColor = const Color(0xFF51cf66);
                      textColor = Colors.white;
                    } else if (hasAttendance && date.isBefore(now)) {
                      bgColor = const Color(0xFF667eea);
                      textColor = Colors.white;
                    }

                    return InkWell(
                      onTap: hasAttendance
                          ? () => _showAttendanceModal(date)
                          : null,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: shadows,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            dayOfMonth.toString(),
                            style: TextStyle(
                              color: textColor,
                              fontWeight: isToday
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              fontSize: dayFontSize,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainSection(DashboardData data, int classesGridCount) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: const Text(
                '📚 My Classes',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            const Divider(height: 30),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: classesGridCount,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1.2,
              ),
              itemCount: data.classes.length,
              itemBuilder: (context, index) =>
                  _buildClassCard(data.classes[index]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarSection() {
    return Column(
      children: [
        // Logo - Fixed at top (same as management sidebar)
        // Logo Container removed as per request
        // Performance & Charts (Moved to Top)
        Card(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '📈 Attendance Performance',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF667eea),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Time period toggle buttons
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTimePeriodButton('Weekly', 'attendance'),
                      const SizedBox(width: 8),
                      _buildTimePeriodButton('Monthly', 'attendance'),
                      const SizedBox(width: 8),
                      _buildTimePeriodButton('Quarterly', 'attendance'),
                      const SizedBox(width: 8),
                      _buildTimePeriodButton('Yearly', 'attendance'),
                    ],
                  ),
                ),
                const Divider(height: 20),
                // Average Stats - using dynamic data based on selected period
                Builder(
                  builder: (context) {
                    final attendanceData = _getAttendanceData(
                      _selectedAttendancePeriod,
                    );
                    return Column(
                      children: [
                        _buildPerformanceStat(
                          attendanceData['attendance']!,
                          'Average Attendance',
                          const Color(0xFF667eea),
                        ),
                        const SizedBox(height: 15),
                        _buildPerformanceStat(
                          attendanceData['grade']!,
                          'Average Grade',
                          const Color(0xFF51cf66),
                        ),
                      ],
                    );
                  },
                ),
                const Divider(height: 30),

                // (Attendance chart removed as requested)

                // Progress Overview Chart (Bar Chart - Fixed Visibility)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '📈 Class Progress Overview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF667eea),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Time period toggle buttons
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTimePeriodButton('Weekly', 'progress'),
                      const SizedBox(width: 8),
                      _buildTimePeriodButton('Monthly', 'progress'),
                      const SizedBox(width: 8),
                      _buildTimePeriodButton('Quarterly', 'progress'),
                      const SizedBox(width: 8),
                      _buildTimePeriodButton('Yearly', 'progress'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(15),
                  height: 280,
                  decoration: BoxDecoration(
                    color: const Color(0xFFf8f9fa),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF667eea),
                      width: 2,
                    ),
                    boxShadow: [
                      const BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomPaint(
                          painter: BarChartPainter(
                            _getProgressChartData(_selectedProgressPeriod),
                          ),
                          size: Size.infinite,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    'Subject-wise Performance',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color.fromARGB(255, 224, 19, 19),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),

        // Upcoming Section
        Card(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📅 Upcoming',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF667eea),
                  ),
                ),
                const Divider(height: 20),
                _buildUpcomingItem(
                  'Mathematics Test',
                  'Class 10A • Tomorrow • 2 hours',
                ),
                _buildUpcomingItem(
                  'Physics Assignment Due',
                  'Class 11B • Feb 1st • Lab Report',
                ),
                _buildUpcomingItem(
                  'Parent Meeting',
                  'Class 10A • Feb 5th • 3:00 PM',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),

        // Quick Actions (Moved to Bottom)
        Card(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '⚡ Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 20),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 2.5,
                  children: [
                    _buildActionButton(
                      '📝 Create Assignment',
                      Icons.assignment_outlined,
                    ),
                    _buildActionButton(
                      '📋 Schedule Exam',
                      Icons.event_note_outlined,
                    ),
                    _buildActionButton(
                      '📈 View Grades',
                      Icons.leaderboard_outlined,
                    ),
                    _buildActionButton(
                      '📊 View Results',
                      Icons.bar_chart_outlined,
                    ),
                    _buildActionButton(
                      '📅 My Timetable',
                      Icons.calendar_today_outlined,
                    ),
                    _buildActionButton('👤 My Profile', Icons.person_outline),
                    _buildActionButton(
                      '💬 Communication',
                      Icons.message_outlined,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon, {
    VoidCallback? onPressed,
  }) {
    return ElevatedButton(
      onPressed:
          onPressed ??
          () {
            // Default navigation based on label
            if (label.contains('Assignment')) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AssignmentDashboardScreen(),
                ),
              );
            } else if (label.contains('Exam')) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TeacherDashboard(),
                ),
              );
            } else if (label.contains('Grades')) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GradesDashboard(),
                ),
              );
            } else if (label.contains('Results')) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EnterResultsScreen(),
                ),
              );
            } else if (label.contains('Timetable')) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const timetable.TeacherTimetableScreen(),
                ),
              );
            } else if (label.contains('Profile')) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TeacherProfilePage(),
                ),
              );
            } else if (label.contains('Communication')) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TeacherCommunicationScreen(
                    onToggleTheme: () {},
                    initialThemeMode: ThemeMode.light,
                  ),
                ),
              );
            }
          },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(15),
        backgroundColor: const Color(0xFF667eea),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    offset: Offset(0, 1),
                    blurRadius: 1,
                  ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingItem(String title, String details) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      constraints: const BoxConstraints(minHeight: 64),
      decoration: BoxDecoration(
        color: const Color(0xFFffffff),
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: Color(0xFF667eea), width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
            softWrap: true,
            overflow: TextOverflow.visible,
            maxLines: 2,
          ),
          const SizedBox(height: 6),
          Text(
            details,
            style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
            softWrap: true,
            overflow: TextOverflow.visible,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceStat(String value, String label, Color color) {
    return Container(
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
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Removed: Chat methods moved to TeacherCommunicationScreen
}

// Notifications panel (push notifications from management)
class _TeacherNotificationsPanel extends StatefulWidget {
  final VoidCallback onClose;

  const _TeacherNotificationsPanel({required this.onClose});

  @override
  State<_TeacherNotificationsPanel> createState() => _TeacherNotificationsPanelState();
}

class _TeacherNotificationsPanelState extends State<_TeacherNotificationsPanel> {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await api.ApiService.getMyPushNotifications();
    if (mounted) {
      setState(() {
        _notifications = data['notifications'] as List<Map<String, dynamic>>;
        _loading = false;
      });
    }
  }

  static String _formatTime(dynamic value) {
    if (value == null) return '—';
    if (value is String) {
      try {
        final d = DateTime.tryParse(value);
        if (d != null) {
          final now = DateTime.now();
          final diff = now.difference(d);
          if (diff.inDays > 0) return '${diff.inDays}d ago';
          if (diff.inHours > 0) return '${diff.inHours}h ago';
          if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
          return 'Just now';
        }
      } catch (_) {}
    }
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    const fixedHeight = 420.0;
    final maxH = MediaQuery.of(context).size.height * 0.85;
    final height = fixedHeight > maxH ? maxH : fixedHeight;
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(maxWidth: 400, maxHeight: height),
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Notifications', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: _loading
                    ? const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                    : _notifications.isEmpty
                        ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No notifications yet')))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _notifications.length,
                            itemBuilder: (context, index) {
                              final n = _notifications[index];
                              final title = n['title'] as String? ?? '—';
                              final body = n['body'] as String? ?? '';
                              final createdAt = _formatTime(n['created_at']);
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: const CircleAvatar(child: Icon(Icons.notifications, color: Colors.white), backgroundColor: Color(0xFF667eea)),
                                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: Text('${body.isNotEmpty ? body : ''}\n$createdAt', maxLines: 2, overflow: TextOverflow.ellipsis),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- CUSTOM PAINTERS FOR CHARTS ---

// Removed LineChartPainter as it was unused and marked for removal previously.

class BarChartPainter extends CustomPainter {
  final List<SubjectData> data;
  BarChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    const padding = 20.0;
    final chartWidth = width - 2 * padding;
    final chartHeight = height - 2 * padding;

    // Use a 0-10 scale for display; source data is 0-100 so convert by /10
    const maxScale = 10.0;
    final yScale = chartHeight / maxScale;
    final barGroupWidth = chartWidth / data.length;
    final barWidth = barGroupWidth * 0.3;
    // A list of distinct colors to use for different subject bars
    final barColors = [
      const Color(0xFF1E88E5), // blue
      const Color(0xFF51cf66), // green
      const Color(0xFFff6b6b), // red
      const Color(0xFF764ba2), // purple
      const Color(0xFF00BCD4), // cyan
      const Color(0xFF3949AB), // indigo
    ];

    // Draw bars
    for (int i = 0; i < data.length; i++) {
      final subjectData = data[i];
      // Center the bar inside its group
      final startX =
          padding + i * barGroupWidth + (barGroupWidth - barWidth) / 2;
      // Source data 0-100 -> convert to 0-10 scale
      final avgScaleValue = subjectData.average / 10.0;

      // Draw Average Bar
      final avgHeight = avgScaleValue * yScale;
      final avgY = height - padding - avgHeight;
      // Choose color for this subject
      final color = barColors[i % barColors.length];
      final avgPaint = Paint()..color = color;

      final avgRect = Rect.fromLTWH(startX, avgY, barWidth, avgHeight);
      canvas.drawRect(avgRect, avgPaint);

      // Draw average label above average bar (show actual average value 0-100)
      final avgLabel = subjectData.average.toString();
      // Always use black color for average numbers
      final textStyle = const TextStyle(
        color: Colors.black,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      );
      final tp = TextPainter(
        text: TextSpan(text: avgLabel, style: textStyle),
        textDirection: ui.TextDirection.ltr,
        textAlign: TextAlign.center,
        maxLines: 1,
      );
      // Limit the avg label width to the bar width so it's centered over the bar
      tp.layout(minWidth: 0, maxWidth: barWidth);
      final labelX = avgRect.left + (avgRect.width - tp.width) / 2;
      final labelY = (avgRect.top - tp.height - 4).clamp(4.0, double.infinity);

      // Draw white background behind text for better visibility
      final bgRect = Rect.fromLTWH(
        labelX - 2,
        labelY - 1,
        tp.width + 4,
        tp.height + 2,
      );
      final bgPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(bgRect, const Radius.circular(3)),
        bgPaint,
      );

      // Draw the black text
      tp.paint(canvas, Offset(labelX, labelY));

      // (Target bars removed as requested)
    }

    // Draw subject labels below each bar group
    final labelStyle = TextStyle(color: const Color(0xFF333333), fontSize: 12);
    for (int i = 0; i < data.length; i++) {
      final subject = data[i].subject;
      // center under the bar group and allow the label to take up the whole group
      final groupLeft = padding + i * barGroupWidth;
      final tp = TextPainter(
        text: TextSpan(text: subject, style: labelStyle),
        textDirection: ui.TextDirection.ltr,
        textAlign: TextAlign.center,
        maxLines: 2,
      );
      // Give the label the full group width so it stays centered under the bar
      tp.layout(minWidth: barGroupWidth, maxWidth: barGroupWidth);
      final labelX = groupLeft + (barGroupWidth - tp.width) / 2;
      final labelY = height - padding + 6; // slightly below the chart area
      tp.paint(canvas, Offset(labelX, labelY));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- STAT DETAIL SCREEN DEFINITION (To resolve missing file error) ---
class StatDetailScreen extends StatelessWidget {
  final String title;
  final String value;

  const StatDetailScreen({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) return;
        Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('$title Details'),
          backgroundColor: const Color(0xFF667eea),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Current Value: $value',
                style: const TextStyle(fontSize: 24, color: Color(0xFF667eea)),
              ),
              const SizedBox(height: 40),
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'This screen would typically show detailed analytics, historical trends, and management tools for this specific metric.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF764ba2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                ),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
