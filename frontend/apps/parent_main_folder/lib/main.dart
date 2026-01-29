import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math; // Used for random data generation
import 'package:intl/intl.dart' as intl;
import 'package:main_login/main.dart' as main_login;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'parent-profile.dart';
import 'parent-academics.dart';
import 'parent-bus.dart';
import 'parent-calendar.dart';
import 'parent-daily-task.dart';
import 'parent-Activities.dart' as activities;
import 'parent-Extracurricular.dart';
import 'parent-gallery.dart';
import 'parent-homework.dart';
import 'parent-projects.dart';
import 'parent-results.dart';
import 'parent-test.dart';
import 'parent_fees.dart';
import 'services/api_service.dart' as api;
import 'services/realtime_chat_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'Student_Communication.dart';



// -------------------------------------------------------------------------
// 1. UTILITY FUNCTIONS & DATA MODELS
// -------------------------------------------------------------------------

/// Utility function to create a MaterialColor from a single color value.
MaterialColor createMaterialColor(Color color) {
  List<double> strengths = <double>[.05, .1, .2, .3, .4, .5, .6, .7, .8, .9];
  Map<int, Color> swatch = {};
  final int r = color.red, g = color.green, b = color.blue;

  swatch[50] = Color.fromRGBO(r, g, b, 0.05);

  for (int i = 0; i < 9; i++) {
    int key = (i + 1) * 100;
    if (i + 1 < strengths.length) {
      swatch[key] = Color.fromRGBO(r, g, b, strengths[i + 1]);
    } else {
      swatch[key] = Color.fromRGBO(r, g, b, 1.0);
    }
  }

  return MaterialColor(color.value, swatch);
}

class DashboardData {
  // Dashboard data will be fetched from API, no dummy data
  final String userName;
  final String totalHomework;
  final String upcomingTests;
  final String totalResults;
  final String academicsScore;
  final String extracurricularCount;
  final String feesStatus;
  final Map<String, dynamic> busDetails;
  final List<Map<String, String>> homework;
  final List<Map<String, String>> tests;
  final List<Map<String, dynamic>> results;

  DashboardData({
    this.userName = '',
    this.totalHomework = '0',
    this.upcomingTests = '0',
    this.totalResults = '0',
    this.academicsScore = '0%',
    this.extracurricularCount = '0',
    this.feesStatus = 'Unknown',
    Map<String, dynamic>? busDetails,
    List<Map<String, String>>? homework,
    List<Map<String, String>>? tests,
    List<Map<String, dynamic>>? results,
    List<Map<String, dynamic>>? recentEvents,
  })  : busDetails = busDetails ?? {},
        homework = homework ?? [],
        tests = tests ?? [],
        results = results ?? [],
        recentEvents = recentEvents ?? [];
        
  List<Map<String, dynamic>> attendanceHistory = [];
  List<Map<String, dynamic>> recentEvents = [];
}

// -------------------------------------------------------------------------
// 2. MAIN APP SETUP & CONSTANTS
// -------------------------------------------------------------------------

void main() {
  runApp(const SchoolManagementSystemApp());
}

class SchoolManagementSystemApp extends StatelessWidget {
  const SchoolManagementSystemApp({super.key});

  // Sharpened primary color for better contrast
  static const Color primaryPurple = Color(
    0xFF5A67C4,
  ); // Darker than 0xFF667eea
  static const Color lightBackground = Color(0xFFF8F9FA);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Academic Performance Dashboard',
      theme: ThemeData(
        // Using createMaterialColor requires calling the function
        primarySwatch: createMaterialColor(primaryPurple),
        primaryColor: primaryPurple,
        fontFamily: 'Segoe UI',
        useMaterial3: true,
        scaffoldBackgroundColor: lightBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryPurple,
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold, // Bolder title
          ),
        ),
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// -------------------------------------------------------------------------
// 3. HOME SCREEN (STATEFUL WIDGET)
// -------------------------------------------------------------------------

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DashboardData mockData = DashboardData();
  final math.Random _random = math.Random();

  // Initialize state variables for Calendar
  int currentMonth = DateTime.now().month - 1; // 0-indexed for month names
  int currentYear = DateTime.now().year;

  String _overallScore = '84%';
  String _attendanceRate = '0%';
  String _classRank = '7th';
  String _selectedGradePeriod = 'Monthly'; // For grades period selection
  String _selectedAttendancePeriod = 'Monthly'; // For attendance period selection
  String? _schoolName;
  String? _schoolId;
  String? _logoUrl;
  String? _studentId; // Added to store the current student ID

  @override
  void initState() {
    super.initState();
    _loadCachedSchoolDetails();
    _loadParentProfile(); // This will trigger _fetchAttendance after getting student ID
  }

  Future<void> _fetchAttendance({String? studentId}) async {
    try {
      final idToUse = studentId ?? _studentId;
      debugPrint('DEBUG_ATT: Fetching attendance. Provided: $studentId, Member: $_studentId, Using: $idToUse');
      
      final data = await api.ApiService.fetchAttendanceHistory(studentId: idToUse);
      debugPrint('DEBUG_ATT: Raw Response: ${jsonEncode(data)}');
      debugPrint('DEBUG_ATT: API Response keys: ${data?.keys}');
      
      if (data != null && mounted) {
        setState(() {
          // Update history list
          if (data['history'] != null) {
            mockData.attendanceHistory = List<Map<String, dynamic>>.from(data['history']);
            debugPrint('DEBUG_ATT: Loaded ${mockData.attendanceHistory.length} records');
          }
          
          // Update stats
          if (data['stats'] != null) {
            String newRate = '${data['stats']['percentage']}%';
            _attendanceRate = newRate;
            debugPrint('DEBUG_ATT: Rate updated: $_attendanceRate');
          }
          
          if (studentId != null || _studentId != null) {
              _showSnackBar('Fetched attendance for Student ID: ${idToUse ?? "Unknown"}');
          }
        });
      }
    } catch (e) {
      debugPrint('DEBUG_ATT: Error: $e');
    }
  }

  Future<void> _fetchHomework({String? studentId}) async {
    try {
      final idToUse = studentId ?? _studentId;
      debugPrint('Fetching homework for dashboard. ID: $idToUse');
      final homework = await api.ApiService.fetchHomework(studentId: idToUse);
      
      if (homework != null && mounted) {
        setState(() {
          final currentAttendanceHistory = mockData.attendanceHistory;
          final currentRecentEvents = mockData.recentEvents;
          
          List<Map<String, String>> homeworkData = [];
          for (var item in homework) {
            homeworkData.add({
              'id': item['id'].toString(),
              'title': item['title'] ?? '',
              'subject': item['subject'] ?? '',
              'dueDate': item['dueDate'] ?? '',
              'status': item['status'] ?? 'pending',
            });
          }

          mockData = DashboardData(
            userName: mockData.userName,
            totalHomework: homeworkData.length.toString(),
            upcomingTests: mockData.upcomingTests,
            totalResults: mockData.totalResults,
            academicsScore: mockData.academicsScore,
            extracurricularCount: mockData.extracurricularCount,
            feesStatus: mockData.feesStatus,
            busDetails: mockData.busDetails,
            homework: homeworkData,
            tests: mockData.tests,
            results: mockData.results,
            recentEvents: mockData.recentEvents, // Correctly preserve
          );
          mockData.attendanceHistory = currentAttendanceHistory; // Correctly restore
        });
      }
    } catch (e) {
      debugPrint('Error fetching homework for dashboard: $e');
    }
  }

  Future<void> _fetchExams({String? studentId}) async {
    try {
      final idToUse = studentId ?? _studentId;
      // If logic: if idToUse is null, we proceed (api handles it by user token), 
      // OR we return if we want to be strict. Here we want to be permissive for student logins.
      
      debugPrint('Fetching exams. ID provided/cached: $idToUse');
      final exams = await api.ApiService.fetchStudentExams(studentId: idToUse);
      final allExams = await api.ApiService.fetchAllExams(studentId: idToUse);
      
      if (exams != null && mounted) {
        setState(() {
          // Fix for Exam Count: User wants accurate total count (Past + Upcoming)
          // Previously this was filtering for only 'upcoming'
          // Now we use the total length of fetched exams
          int upcomingCount = allExams?.length ?? exams.length;
          
          
          // CRITICAL FIX: Preserve existing attendance history before overwriting mockData
          final currentAttendanceHistory = mockData.attendanceHistory;
          
          mockData = DashboardData(
            userName: mockData.userName,
            totalHomework: mockData.totalHomework,
            upcomingTests: upcomingCount.toString(),
            totalResults: mockData.totalResults,
            academicsScore: mockData.academicsScore,
            extracurricularCount: mockData.extracurricularCount,
            feesStatus: mockData.feesStatus,
            busDetails: mockData.busDetails,
            homework: mockData.homework,
            tests: mockData.tests,
            results: mockData.results,
          );
          // Restore attendance history
          mockData.attendanceHistory = currentAttendanceHistory;
        });
      }
    } catch (e) {
      debugPrint('Error fetching exams: $e');
    }
  }

  Future<void> _fetchRecentEvents({String? studentId}) async {
    try {
      final idToUse = studentId ?? _studentId;
      debugPrint('Step: _fetchRecentEvents called. Using ID: $idToUse');
      
      final events = await api.ApiService.fetchRecentEvents(studentId: idToUse);
      
      if (events != null && mounted) {
        setState(() {
          // Update recent events without overwriting other data
          final currentAttendanceHistory = mockData.attendanceHistory;
          final currentEvents = List<Map<String, dynamic>>.from(events);
          
          mockData = DashboardData(
            userName: mockData.userName,
            totalHomework: mockData.totalHomework,
            upcomingTests: mockData.upcomingTests,
            totalResults: mockData.totalResults,
            academicsScore: mockData.academicsScore,
            extracurricularCount: mockData.extracurricularCount,
            feesStatus: mockData.feesStatus,
            busDetails: mockData.busDetails,
            homework: mockData.homework,
            tests: mockData.tests,
            results: mockData.results,
            recentEvents: currentEvents,
          );
          mockData.attendanceHistory = currentAttendanceHistory;
        });
      }
    } catch (e) {
      debugPrint('Error fetching recent events: $e');
    }
  }

  Future<void> _fetchActivities({String? studentId}) async {
    try {
      final idToUse = studentId ?? _studentId;
      
      // Fetch both Activities and All Events to get accurate counts
      final activities = await api.ApiService.fetchActivities(studentId: idToUse);
      final allEvents = await api.ApiService.fetchAllEvents(studentId: idToUse);
      
      if (mounted) {
        setState(() {
          // Update activities count without overwriting other data
          final currentAttendanceHistory = mockData.attendanceHistory;
          final currentRecentEvents = mockData.recentEvents;
          
          // Count both activities and ALL events (not just the recent 4)
          final activityCount = activities?.length ?? 0;
          final eventCount = allEvents?.length ?? 0;
          final totalCount = activityCount + eventCount;

          mockData = DashboardData(
            userName: mockData.userName,
            totalHomework: mockData.totalHomework,
            upcomingTests: mockData.upcomingTests,
            totalResults: mockData.totalResults,
            academicsScore: mockData.academicsScore,
            extracurricularCount: totalCount.toString(),
            feesStatus: mockData.feesStatus,
            busDetails: mockData.busDetails,
            homework: mockData.homework,
            tests: mockData.tests,
            results: mockData.results,
            recentEvents: currentRecentEvents,
          );
          mockData.attendanceHistory = currentAttendanceHistory;
        });
      }
    } catch (e) {
      debugPrint('Error fetching activities/events count: $e');
    }
  }

  Future<void> _loadParentProfile() async {
    try {
      final parentData = await api.ApiService.fetchParentProfile();
      if (parentData != null) {
        // ... (Existing parent logic) ...
        _schoolId = parentData['school_id']?.toString();
        _schoolName = parentData['school_name']?.toString();
        _logoUrl = parentData['logo_url']?.toString();
        
        // Save to cache immediately if available
        if (_logoUrl != null || _schoolName != null) {
          _saveSchoolDetailsToCache(_schoolName, _logoUrl);
        }
        
        debugPrint('Parent profile - school_id: $_schoolId, school_name: $_schoolName, logo_url: $_logoUrl');
        
        // Check for null, empty, or 'null' string values
        final isSchoolIdEmpty = _schoolId == null || _schoolId!.isEmpty || _schoolId == 'null';
        final isSchoolNameEmpty = _schoolName == null || _schoolName!.isEmpty || _schoolName == 'null';
        
        if (isSchoolIdEmpty || isSchoolNameEmpty) {
          final students = parentData['students'];
          if (students is List && students.isNotEmpty) {
            for (var student in students) {
              if (student is Map) {
                if (_studentId == null) {
                   if (student['student_id'] != null) {
                      _studentId = student['student_id'].toString();
                   } else if (student['id'] != null) {
                      _studentId = student['id'].toString();
                   }
                   if (_studentId != null) debugPrint('Found student ID: $_studentId');
                }
                
                // ... (Existing extraction logic) ...
                if (isSchoolIdEmpty) {
                   final extractedSchoolId = student['school_id']?.toString() ?? 
                                           student['school']?['school_id']?.toString();
                   if (extractedSchoolId != null && extractedSchoolId.isNotEmpty && extractedSchoolId != 'null') {
                     _schoolId = extractedSchoolId;
                   }
                }
                if (isSchoolNameEmpty) {
                   final extractedSchoolName = student['school_name']?.toString() ?? 
                                              student['school']?['school_name']?.toString() ??
                                              student['school']?['name']?.toString();
                   if (extractedSchoolName != null && extractedSchoolName.isNotEmpty && extractedSchoolName != 'null') {
                     _schoolName = extractedSchoolName;
                   }
                }
                if ((_schoolId != null && _schoolId!.isNotEmpty && _schoolId != 'null') &&
                    (_schoolName != null && _schoolName!.isNotEmpty && _schoolName != 'null')) {
                  break;
                }
              }
            }
          }
        }
      } else {
         // Parent data is null, try Student Profile fallback
         debugPrint('Parent profile null, trying Student profile...');
         final studentData = await api.ApiService.fetchStudentProfile();
         if (studentData != null) {
             debugPrint('Student profile found: $studentData');
             // Extract ID. Use student_id string or id if available
             // Student profile usually has 'student_id' key
             if (studentData['student_id'] != null) {
                 _studentId = studentData['student_id'].toString();
             } else if (studentData['id'] != null) {
                 _studentId = studentData['id'].toString();
             }
             
             // Extract school info
             if (studentData['school'] != null && studentData['school'] is Map) {
                _schoolId = studentData['school']['school_id']?.toString();
                _schoolName = studentData['school']['school_name']?.toString();
             }
         }
      }
      
      // Update UI
      if (mounted) {
        setState(() {});
        // PERSIST: Save student ID to SharedPreferences so child screens can find it
        if (_studentId != null) {
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('selected_student_id', _studentId!);
            debugPrint('Step: Persisted selected_student_id: $_studentId');
          } catch (e) {
            debugPrint('Error persisting student ID: $e');
          }
        }
      }
      
      // If school name or logo is missing, try to load it
      // Wrap in try-catch so it doesn't fail the whole profile load
      try {
        if (((_schoolName == null || _schoolName!.isEmpty) || (_logoUrl == null || _logoUrl!.isEmpty)) && 
            _schoolId != null && _schoolId!.isNotEmpty && _schoolId != 'null') {
          await _loadSchoolName();
        }
      } catch (e) {
         debugPrint('Error loading school name details: $e');
      }

      // Fetch data
      bool dataFetched = false;
      if (_studentId != null) {
        // We have a student ID, fetch specific data
        debugPrint('Fetching specific data for student: $_studentId');
        await _fetchAttendance(studentId: _studentId);
        await _fetchExams(studentId: _studentId);
        await _fetchHomework(studentId: _studentId); // Added
        await _fetchRecentEvents(studentId: _studentId);
        await _fetchActivities(studentId: _studentId);
        dataFetched = true;
      } else {
         debugPrint('No student ID found, attempting fetch without ID (Student user context)');
         await _fetchAttendance(); 
         await _fetchExams();
         await _fetchHomework(); // Added
         await _fetchRecentEvents();
         await _fetchActivities();
         dataFetched = true; 
      }
    } catch (e) {
      debugPrint('Failed to load profile (Parent/Student): $e');
      // If profile fails strictly, try to fetch generic (only if we haven't tried yet)
      // This checking prevents overwriting good data with bad data if a minor error occurred above
      if (_studentId == null) {
          debugPrint('Retrying fetch in catch block...');
          _fetchAttendance();
          _fetchExams();
          _fetchRecentEvents();
          _fetchActivities();
      }
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
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/super-admin/schools/$_schoolId/'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map) {
          setState(() {
            _schoolName = data['school_name']?.toString() ?? 'School';
            _logoUrl = data['logo_url']?.toString();
          });
          _saveSchoolDetailsToCache(_schoolName, _logoUrl);
          return;
        }
      }
      
      // Fallback: try to extract from parent profile if student.school is available
      try {
        final parentData = await api.ApiService.fetchParentProfile();
        if (parentData != null) {
          final students = parentData['students'];
          if (students is List && students.isNotEmpty) {
            final student = students[0];
            if (student is Map) {
              final school = student['school'];
              if (school is Map && school['school_name'] != null) {
                setState(() {
                  _schoolName = school['school_name']?.toString() ?? 'School';
                });
                return;
              }
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

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
      );
    }
  }

  Future<void> _refreshPerformanceStats() async {
    _showSnackBar('Refreshing data...');
    try {
      if (_studentId != null) {
          await _fetchAttendance(studentId: _studentId);
          await _fetchExams(studentId: _studentId);
          await _fetchHomework(studentId: _studentId); // Added
          await _fetchRecentEvents(studentId: _studentId);
          await _fetchActivities(studentId: _studentId);
      } else {
          await _fetchAttendance();
          await _fetchExams();
          await _fetchHomework(); // Added
          await _fetchRecentEvents();
          await _fetchActivities();
      }
      // Re-load school details too just in case
      await _loadSchoolName();
      
      _showSnackBar('Performance data updated!');
    } catch (e) {
      _showSnackBar('Failed to refresh data.');
    }
  }

  String _getOrdinalSuffix(int n) {
    if (n >= 11 && n <= 13) return 'th';
    switch (n % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  // --- Calendar Control Methods ---
  void previousMonth() {
    setState(() {
      currentMonth--;
      if (currentMonth < 0) {
        currentMonth = 11;
        currentYear--;
      }
    });
  }

  void nextMonth() {
    setState(() {
      currentMonth++;
      if (currentMonth > 11) {
        currentMonth = 0;
        currentYear++;
      }
    });
  }

  // --- WIDGET BUILDERS ---

  Widget _buildStatsGrid() {
    final stats = [
      {
        'icon': Icons.person,
        'number': 'Profile',
        'label': 'Student Profile',
        'color': const Color(0xFF5A67C4), // Primary
        'action': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const StudentProfilePage()),
        ),
      },
      {
        'icon': Icons.directions_bus,
        'number': (mockData.busDetails['busNumber'] as String?) ?? 'N/A',
        'label': 'Bus Details',
        'color': const Color(0xFF17a2b8),
        'action': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BusDetailsPage()),
        ),
      },
      {
        'icon': Icons.science,
        'number': 'Projects',
        'label': 'Student Projects',
        'color': const Color(0xFF6f42c1),
        'action': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const StudentProjectsPage()),
        ),
      },
      {
        'icon': Icons.check_circle_outline,
        'number': 'Tasks',
        'label': 'Daily Tasks',
        'color': const Color(0xFF20c997),
        'action': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DailyTasksPage()),
        ),
      },
      {
        'icon': Icons.assessment,
        'number': mockData.upcomingTests,
        'label': 'Exams',
        'color': const Color(0xFFf093fb),
        'action': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TestManagementPage(studentId: _studentId)),
        ),
      },
      {
        'icon': Icons.bar_chart,
        'number': mockData.totalResults,
        'label': 'Results',
        'color': const Color(0xFF28a745),
        'action': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ResultsPage()),
        ),
      },
      {
        'icon': Icons.assignment,
        'number': mockData.totalHomework,
        'label': 'Homework',
        'color': const Color(0xFF764ba2),
        'action': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HomeworkDashboardScreen()),
        ),
      },
      {
        'icon': Icons.school,
        'number': mockData.academicsScore,
        'label': 'Academics',
        'color': const Color(0xFF5A67C4), // Primary
        'action': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AcademicsPage(studentId: _studentId)),
        ),
      },
      {
        'icon': Icons.sports_soccer,
        'number': mockData.extracurricularCount,
        'label': 'Activities',
        'color': const Color(0xFFFFC107),
        'action': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => activities.ActivityScreen(studentId: _studentId)),
        ),
      },
      {
        'icon': Icons.house,
        'number': 'Gallery',
        'label': 'School Gallery',
        'color': const Color(0xFFfd7e14),
        'action': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SchoolGalleryPage()),
        ),
      },
      {
        'icon': Icons.payment,
        'number': mockData.feesStatus,
        'label': 'Fees',
        'color': const Color(0xFF20c997),
        'action': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const StudentFeesPage()),
        ),
      },
      {
        'icon': Icons.message,
        'number': 'Contact',
        'label': 'Teacher',
        'color': const Color(0xFFe83e8c),
        'action': () => _showChatDialog(context),
      },
      {
        'icon': Icons.calendar_month,
        'number': 'Calendar',
        'label': 'Academic Calendar',
        'color': const Color(0xFF6c757d),
        'action': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AcademicCalendarPage()),
        ),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width < 600
            ? 2
            : (MediaQuery.of(context).size.width < 900 ? 3 : 4),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final item = stats[index];
        return _StatCard(
          icon: item['icon'] as IconData,
          number: item['number'] as String,
          label: item['label'] as String,
          color: item['color'] as Color,
          onTap: item['action'] as VoidCallback,
        );
      },
    );
  }

  Widget _buildPerformanceStats() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use responsive sizing based on available width
        final isNarrow = constraints.maxWidth < 600;

        if (isNarrow) {
          // For narrow screens, use scrollable horizontal list
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SizedBox(
                  width: 160,
                  child: _PerformanceStatItem(
                    label: 'Overall Score',
                    value: _overallScore,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 160,
                  child: _PerformanceStatItem(
                    label: 'Attendance',
                    value: _attendanceRate,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 160,
                  child: _PerformanceStatItem(
                    label: 'Class Rank',
                    value: _classRank,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
          );
        } else {
          // For wider screens, use flexible row
          return Row(
            children: [
              Expanded(
                child: _PerformanceStatItem(
                  label: 'Overall Score',
                  value: _overallScore,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PerformanceStatItem(
                  label: 'Attendance',
                  value: _attendanceRate,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PerformanceStatItem(
                  label: 'Class Rank',
                  value: _classRank,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildPerformanceOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '📊 Student Performance Overview',
                  // Increased font size and contrast for the title
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade900,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _refreshPerformanceStats,
                icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
                label: const Text(
                  'Refresh',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF28A745),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 25),

          // Grades Chart
          _buildGradesChart(),
          const SizedBox(height: 20),

          // Attendance Chart
          _buildAttendanceChart(),
          const SizedBox(height: 30),

          // Performance Stats Grid
          _buildPerformanceStats(),
        ],
      ),
    );
  }

  Widget _buildGradesChart() {
    // Data for different periods
    Map<String, Map<String, dynamic>> periodData = {
      'Monthly': {
        'labels': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
        'percentages': [93, 94, 86, 90, 89, 86],
      },
      'Quarterly': {
        'labels': ['Q1', 'Q2', 'Q3', 'Q4'],
        'percentages': [91, 89, 92, 88],
      },
      'Half-Yearly': {
        'labels': ['H1 2024', 'H2 2024'],
        'percentages': [90, 90],
      },
      'Annually': {
        'labels': ['2022', '2023', '2024'],
        'percentages': [88, 91, 90],
      },
    };

    final currentData = periodData[_selectedGradePeriod]!;
    final labels = currentData['labels'] as List<String>;
    final percentages = currentData['percentages'] as List<int>;
    final maxPercentage = 100;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.show_chart,
                      color: Color(0xFF5A67C4),
                      size: 22, // Increased icon size
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '$_selectedGradePeriod Grades Performance',
                        style: const TextStyle(
                          fontSize: 17, // Increased font size
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF333333),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Period Selector Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Monthly', 'Quarterly', 'Half-Yearly', 'Annually'].map(
                (period) {
                  final isSelected = _selectedGradePeriod == period;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedGradePeriod = period;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF5A67C4) // Sharpened color
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          period,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Bar Chart
          // FIX: Increased height from 200 to 220 to prevent overflow in the chart column
          SizedBox(
            height: 220,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(labels.length, (index) {
                final percentage = percentages[index];
                // Base bar height scaled down from the new total height (220 - padding/labels)
                final barHeight = (percentage / maxPercentage) * 160;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Percentage label
                        Text(
                          '$percentage%',
                          style: const TextStyle(
                            fontSize: 14, // Increased size
                            fontWeight: FontWeight.w700, // Increased boldness
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Bar
                        Container(
                          width: double.infinity,
                          height: barHeight,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF5A67C4), Color(0xFF764BA2)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Label
                        Text(
                          labels[index],
                          style: const TextStyle(
                            fontSize: 13, // Increased size
                            color: Color(0xFF666666),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ), // Extra space to prevent overflow
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.bar_chart, color: Color(0xFF5A67C4), size: 14),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Column Chart: Monthly grade percentages showing academic performance',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceChart() {
    // Data for different periods
    Map<String, Map<String, dynamic>> periodData = {
      'Monthly': {
        'labels': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
        'percentages': [85, 89, 93, 90, 93, 90],
      },
      'Quarterly': {
        'labels': ['Q1', 'Q2', 'Q3', 'Q4'],
        'percentages': [89, 91, 92, 90],
      },
      'Half-Yearly': {
        'labels': ['H1 2024', 'H2 2024'],
        'percentages': [90, 91],
      },
      'Annually': {
        'labels': ['2022', '2023', '2024'],
        'percentages': [87, 90, 91],
      },
    };

    final currentData = periodData[_selectedAttendancePeriod]!;
    final months = currentData['labels'] as List<String>;
    final percentages = currentData['percentages'] as List<int>;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.insert_chart,
                      color: Color(0xFF4CAF50), // Sharper green
                      size: 22, // Increased icon size
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '$_selectedAttendancePeriod Attendance Performance',
                        style: const TextStyle(
                          fontSize: 17, // Increased font size
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF333333),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Period Selector Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Monthly', 'Quarterly', 'Half-Yearly', 'Annually'].map(
                (period) {
                  final isSelected = _selectedAttendancePeriod == period;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedAttendancePeriod = period;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF4CAF50) // Sharper green
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          period,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Line Chart
          // FIX: Increased height from 180 to 200 for safe rendering of labels
          SizedBox(
            height: 200,
            child: CustomPaint(
              painter: _LineChartPainter(
                months: months,
                percentages: percentages,
              ),
              child: Container(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.show_chart, color: Color(0xFF4CAF50), size: 14),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Line Chart: Monthly attendance percentages showing attendance trends',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCalendar() {
    // Get month name
    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    // Safety check for index
    final monthName = (currentMonth >= 0 && currentMonth < 12)
        ? monthNames[currentMonth]
        : 'Invalid Month';

    // Calculate days in current month
    final daysInMonth = DateTime(currentYear, currentMonth + 2, 0).day;
    final firstDayOfMonth = DateTime(currentYear, currentMonth + 1, 1);
    final firstWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday

    // Real attendance data processing
    final Set<int> presentDays = {};
    final Set<int> absentDays = {};
    
    int processedCount = 0;
    for (var record in mockData.attendanceHistory) {
      if (record['date'] != null && record['status'] != null) {
        try {
          String dateStr = record['date'].toString();
          DateTime date;
          if (dateStr.contains('T')) {
            date = DateTime.parse(dateStr);
          } else {
            final parts = dateStr.split('-');
            if (parts.length == 3) {
              date = DateTime(
                int.parse(parts[0]), 
                int.parse(parts[1]), 
                int.parse(parts[2])
              );
            } else {
              date = DateTime.parse(dateStr);
            }
          }

          if (date.month == currentMonth + 1 && date.year == currentYear) {
            final status = record['status'].toString().toLowerCase().trim();
            if (status == 'present') {
              presentDays.add(date.day);
            } else if (status == 'absent') {
              absentDays.add(date.day);
            } else if (status == 'late') {
              presentDays.add(date.day);
            }
            processedCount++;
          }
        } catch (e) {
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_month,
                      color: Color(0xFF5A67C4),
                      size: 24, // Increased icon size
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Student Calendar',
                        style: TextStyle(
                          fontSize: 20, // Increased font size for title
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade900,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.chevron_left,
                      color: Color(0xFF5A67C4),
                    ),
                    onPressed: previousMonth,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5A67C4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$monthName $currentYear',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14, // Increased font size
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF5A67C4),
                    ),
                    onPressed: nextMonth,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Calendar Grid
          Column(
            children: [
              // Weekday headers
              Row(
                children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map(
                  (day) {
                    return Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700, // Bolder
                            color: Color(0xFF5A67C4), // Primary color
                            fontSize: 15, // Increased size
                          ),
                        ),
                      ),
                    );
                  },
                ).toList(),
              ),
              const SizedBox(height: 10),

              // Calendar days
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemCount: firstWeekday + daysInMonth, // Total cells needed
                itemBuilder: (context, index) {
                  final dayNumber = index - firstWeekday + 1;

                  if (dayNumber < 1 || dayNumber > daysInMonth) {
                    // Empty cell for days outside current month
                    return Container();
                  }

                  final now = DateTime.now();
                  final isPresent = presentDays.contains(dayNumber);
                  final isAbsent = absentDays.contains(dayNumber);
                  final isToday =
                      dayNumber == now.day &&
                      currentMonth == now.month - 1 &&
                      currentYear == now.year;

                  Color bgColor = Colors.white; // Default background (Not given attendance)
                  Color textColor = Colors.black87;
                  String? statusText;

                  if (isPresent) {
                    bgColor = const Color(0xFF4CAF50).withOpacity(0.9);
                    textColor = Colors.white;
                    statusText = 'P';
                  } else if (isAbsent) {
                    bgColor = const Color(0xFFEF5350).withOpacity(0.9);
                    textColor = Colors.white;
                    statusText = 'A';
                  }

                  return InkWell(
                    onTap: () => _showDateDetails(
                      context,
                      dayNumber,
                      isPresent,
                      isAbsent,
                    ),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(6),
                        border: isToday
                            ? Border.all(
                                color: const Color(0xFF5A67C4),
                                width: 3, // Thicker border for Today
                              )
                            : Border.all(
                                color: Colors.black, // Specified black color border
                                width: 1,
                              ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsets.all(
                            4.0,
                          ), // Increased padding
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$dayNumber',
                                style: TextStyle(
                                  fontSize: 16, // Increased font size
                                  fontWeight: FontWeight.w800, // Extra bold
                                  color: textColor,
                                ),
                              ),
                              if (statusText != null) ...[
                                const SizedBox(height: 1),
                                Text(
                                  statusText,
                                  style: TextStyle(
                                    fontSize: 10, // Increased font size
                                    color: textColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 15),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(const Color(0xFF4CAF50), 'Present'),
              const SizedBox(width: 20),
              _buildLegendItem(const Color(0xFFEF5350), 'Absent'),
              const SizedBox(width: 20),
              _buildLegendItem(
                Colors.grey.shade100, // Use the actual default cell color
                'No Record',
                hasBorder: true,
                borderColor: Colors.black,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, {bool hasBorder = false, Color? borderColor}) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: hasBorder 
                ? Border.all(color: borderColor ?? Colors.grey.shade400) 
                : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ],
    );
  }

  // Method to show date details dialog
  void _showDateDetails(
    BuildContext context,
    int day,
    bool isPresent,
    bool isAbsent,
  ) {
    // Construct DateTime object for the API
    // currentMonth is 0-indexed in the list, so +1 for DateTime
    final date = DateTime(currentYear, currentMonth + 1, day);
    
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final dateString = '${monthNames[currentMonth]} $day, $currentYear';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DayDetailsDialog(
          date: date,
          studentId: _studentId,
          dateString: dateString,
          isPresent: isPresent,
          isAbsent: isAbsent,
        );
      },
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18, // Increased size
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildRecentEvents() {
    if (mockData.recentEvents.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
             children: [
               Icon(Icons.event_note, color: Theme.of(context).primaryColor),
               const SizedBox(width: 10),
               Text(
                'Recent Activities',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
              ),
             ]
          ),
          const SizedBox(height: 15),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: mockData.recentEvents.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final event = mockData.recentEvents[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Icon(Icons.event, color: Theme.of(context).primaryColor),
                ),
                title: Text(
                  event['title'] ?? 'No Title',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (event['description'] != null && event['description'].isNotEmpty)
                       Text(event['description'], maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(
                      '${event['date']} ${event['time'] ?? ''}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    event['category'] ?? 'General',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

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
                                      color: Colors.white,
                                      width: side,
                                      height: side,
                                      child: const Icon(
                                        Icons.school,
                                        size: 40,
                                        color: Color(0xFF667eea),
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  color: Colors.white,
                                  width: side,
                                  height: side,
                                  child: const Icon(
                                    Icons.school,
                                    size: 40,
                                    color: Color(0xFF667eea),
                                  ),
                                ),
                        ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Text(
                    _schoolName ?? 'School',
                    style: const TextStyle(
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
              // Avatar with Navigation
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StudentProfilePage(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                    ),
                    child: const CircleAvatar(
                      radius: 20,
                      backgroundColor: Color(0xFFE1BEE7),
                      child: Text('👨‍👩‍👧', style: TextStyle(fontSize: 22)),
                    ),
                  ),
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
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const main_login.LoginScreen(),
                                  ),
                                  (route) => false,
                                );
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
                        colors: [Color(0xFFFF8A80), Color(0xFFFF5252)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100.0), // Matching Teacher App size
        child: _buildHeader(),
      ),
      // Add Floating Action Button for Chat
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dashboard Title Section (Gradient Text simulated with ShaderMask)
            ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  colors: <Color>[
                    SchoolManagementSystemApp.primaryPurple,
                    Color(0xFF764ba2),
                  ],
                  tileMode: TileMode.mirror,
                ).createShader(bounds);
              },
              child: const Text(
                'Parent Dashboard',
                style: TextStyle(
                  fontSize: 34, // Increased size
                  fontWeight: FontWeight.w800, // Extra bold
                  color: Colors.white, // Color is overridden by the shader
                ),
              ),
            ),
            const Text(
              'Student progress and information',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 30),

            // Student Calendar Section (moved to top)
            _buildAttendanceCalendar(),
            const SizedBox(height: 30),

            // Stats Grid
            _buildStatsGrid(),
            const SizedBox(height: 30),

            // Performance Overview Section
            _buildPerformanceOverview(),
            const SizedBox(height: 30),

            // Recent Events Section (Added)
            _buildRecentEvents(),
            const SizedBox(height: 30),
            const SizedBox(height: 30),

            // Recent Homework Section
            _SectionCard(
              title: '📚 Recent Homework',
              child: _HomeworkList(homework: mockData.homework),
            ),
            const SizedBox(height: 30),

            // Upcoming Tests Section
            _SectionCard(
              title: '📋 Upcoming Tests',
              child: _TestsList(tests: mockData.tests),
            ),
            const SizedBox(height: 30),

            // Recent Results Section
            _SectionCard(
              title: '📊 Recent Results',
              child: _ResultsList(results: mockData.results),
            ),
            const SizedBox(height: 30),

            // Bus Details Section
            _SectionCard(
              title: '🚌 Bus Details',
              child: _BusDetailsCard(details: mockData.busDetails),
            ),
            const SizedBox(height: 100), // Space for floating button
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showChatDialog(context),
        backgroundColor: Colors
            .lightBlueAccent
            .shade700, // Using blue for chat FAB as requested
        // UPDATED: Changed icon to chat bubble outline for visual flair
        icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
        label: const Text('Chat', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  // WhatsApp-like chat dialog
  void _showChatDialog(BuildContext context) {
    // Open Student Communication screen
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const StudentCommunicationScreen())
    );
  }
}

// -------------------------------------------------------------------------
// 4. REUSABLE COMPONENTS
// -------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20, // Increased size
                fontWeight: FontWeight.bold,
                color: Color(0xFF5A67C4), // Sharper color
              ),
            ),
            const Divider(),
            child,
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String number;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.icon,
    required this.number,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext classContext) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: color, size: 28),
                    const SizedBox(height: 4),
                    Text(
                      number,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: color.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                      ),
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
}

class _PerformanceStatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _PerformanceStatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110, // Matching the requested rectangle look
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
              color: color,
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
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
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

class _BusDetailsCard extends StatelessWidget {
  final Map<String, dynamic> details;

  const _BusDetailsCard({required this.details});

  String _safeGet(String key, [String defaultValue = 'N/A']) {
    final value = details[key];
    if (value == null) return defaultValue;
    if (value is String) return value;
    return value.toString();
  }

  Widget _buildDetailRow(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800, // Bolder
              color: Color(0xFF5A67C4),
              fontSize: 18, // Increased size
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ), // Increased size
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.directions_bus,
                color: Color(0xFF5A67C4),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Bus ${_safeGet('busNumber', 'N/A')}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDetailRow('Route', _safeGet('route')),
              _buildDetailRow('Driver', _safeGet('driver')),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDetailRow('Pickup Time', _safeGet('pickupTime')),
              _buildDetailRow('Drop Time', _safeGet('dropTime')),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeworkList extends StatelessWidget {
  final List<Map<String, String>> homework;

  const _HomeworkList({required this.homework});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: homework.length,
      itemBuilder: (context, index) {
        final item = homework[index];
        final isPending = item['status'] == 'pending';
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(10),
            border: Border(
              left: BorderSide(
                color: isPending ? Colors.orange : Colors.green,
                width: 4,
              ),
            ),
          ),
          child: ListTile(
            title: Text(
              item['title']!,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ), // Bolder
            ),
            subtitle: Text(
              '${item['subject']!} - Due: ${item['dueDate']!}',
              style: const TextStyle(fontSize: 13), // Adjusted size
            ),
            trailing: Chip(
              label: Text(
                item['status']!,
                style: TextStyle(
                  color: isPending ? Colors.black87 : Colors.white,
                  fontWeight: FontWeight.w600, // Bolder chip text
                ),
              ),
              backgroundColor: isPending
                  ? const Color(0xFFFFC107).withOpacity(0.5)
                  : const Color(0xFF40c057),
            ),
          ),
        );
      },
    );
  }
}

class _TestsList extends StatelessWidget {
  final List<Map<String, String>> tests;

  const _TestsList({required this.tests});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tests.length,
      itemBuilder: (context, index) {
        final item = tests[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(10),
            border: const Border(
              left: BorderSide(color: Color(0xFFf093fb), width: 4),
            ),
          ),
          child: ListTile(
            title: Text(
              '${item['subject']!} Test',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ), // Bolder
            ),
            subtitle: Text(
              'Date: ${item['date']!} • Duration: ${item['duration']!}',
              style: const TextStyle(fontSize: 13), // Adjusted size
            ),
            trailing: Chip(
              label: const Text(
                'Upcoming',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: const Color(0xFFf093fb).withOpacity(0.5),
            ),
          ),
        );
      },
    );
  }
}

class _ResultsList extends StatelessWidget {
  final List<Map<String, dynamic>> results;

  const _ResultsList({required this.results});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(10),
            border: const Border(
              left: BorderSide(color: Color(0xFF28a745), width: 4),
            ),
          ),
          child: ListTile(
            title: Text(
              '${item['subject']} - ${item['examType']}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ), // Bolder
            ),
            subtitle: Text(
              'Score: ${item['score']}% • Grade: ${item['grade']} • Date: ${item['date']}',
              style: const TextStyle(fontSize: 13), // Adjusted size
            ),
            trailing: const Chip(
              label: Text(
                'Completed',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: Color(0xFF40c057),
            ),
          ),
        );
      },
    );
  }
}

// Line Chart Painter for Attendance Performance
class _LineChartPainter extends CustomPainter {
  final List<String> months;
  final List<int> percentages;

  _LineChartPainter({required this.months, required this.percentages});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color =
          const Color(0xFF4CAF50) // Sharper green line
      ..strokeWidth =
          3.5 // Thicker line
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color =
          const Color(0xFF4CAF50) // Sharper green point
      ..style = PaintingStyle.fill;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Calculate positions
    // Chart height is based on the container size defined in _buildAttendanceChart (200)
    final chartHeight = size.height - 60;
    final chartWidth = size.width - 40;

    // Check for empty data to prevent division by zero
    if (months.length <= 1) return;

    final xSpacing = chartWidth / (months.length - 1);

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = 20 + (chartHeight / 4) * i;
      canvas.drawLine(Offset(20, y), Offset(size.width - 20, y), gridPaint);
    }

    // Draw line
    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < percentages.length; i++) {
      final x = 20 + (i * xSpacing);
      // Normalize values from 100-0 to fit chart area
      final normalizedValue = (100 - percentages[i]) / 100;
      final y = 20 + (normalizedValue * chartHeight);

      points.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Draw points and labels
    for (int i = 0; i < points.length; i++) {
      final point = points[i];

      // Draw point
      canvas.drawCircle(point, 6, pointPaint); // Larger point
      canvas.drawCircle(point, 3, Paint()..color = Colors.white);

      // Draw percentage label
      textPainter.text = TextSpan(
        text: '${percentages[i]}%',
        style: const TextStyle(
          color: Color(0xFF4CAF50), // Sharper color for label
          fontSize: 12, // Slightly larger font
          fontWeight: FontWeight.w700,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(point.dx - textPainter.width / 2, point.dy - 20),
      );

      // Draw month label
      textPainter.text = TextSpan(
        text: months[i],
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 13,
        ), // Sharper month label
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(point.dx - textPainter.width / 2, size.height - 25),
      );
    }

    // Draw Y-axis labels
    for (int i = 0; i <= 4; i++) {
      final percentage = 100 - (i * 25);
      final y = 20 + (chartHeight / 4) * i;

      textPainter.text = TextSpan(
        text: '$percentage%',
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 11,
        ), // Sharper Y-axis label
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - 5));
    }
  }

  // Set shouldRepaint to true if the data is dynamic (it is, based on _selectedPeriod)
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// -------------------------------------------------------------------------
// WhatsApp-Like Chat Dialog
// -------------------------------------------------------------------------

class _WhatsAppChatDialog extends StatefulWidget {
  @override
  State<_WhatsAppChatDialog> createState() => _WhatsAppChatDialogState();
}

class _WhatsAppChatDialogState extends State<_WhatsAppChatDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _groups = [];
  bool _loadingTeachers = false;
  String? _schoolId; // Parent's school_id for filtering
  final Map<String, int> _unreadCounts = {}; // Track unread messages per teacher
  
  // Added missing state variables
  StreamSubscription? _globalChatSubscription;
  RealtimeChatService? _globalChatService;
  final Map<String, List<Map<String, dynamic>>> _teacherMessages = {};
  String? _currentUserId; // To identify sent messages for read receipts

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
    _loadParentSchoolId();
    _loadTeachers();
    _loadGroups();
    _initializeGlobalChatListener();
  }
  
  @override
  void dispose() {
    _globalChatSubscription?.cancel();
    _globalChatService?.disconnect();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  // Initialize global chat listener to track unread counts
  Future<void> _initializeGlobalChatListener() async {
    try {
      // Get student info for room ID
      final parentData = await api.ApiService.fetchParentProfile();
      if (parentData == null) return;
      
      final students = parentData['students'];
      if (students is! List || students.isEmpty) return;
      
      final student = students[0] as Map<String, dynamic>?;
      if (student == null) return;
      
      final studentName = student['student_name']?.toString() ?? 
                         student['name']?.toString() ?? '';
      if (studentName.isEmpty) return;
      
      // Connect to a general room to listen for all messages
      // We'll filter messages by recipient in the listener
      // Connect to personal user channel for all updates (Groups & Direct)
      _globalChatService = RealtimeChatService(baseWsUrl: 'ws://localhost:8000');
      
      // Use user_{id} format which matches backend consumer
      final userId = parentData['user_id']?.toString() ?? parentData['id']?.toString();
      if (userId == null) return;
      
      await _globalChatService!.connect(roomId: userId, chatType: 'user');
      
      _globalChatSubscription = _globalChatService!.stream?.listen((event) {
        try {
          final data = event is String ? jsonDecode(event) : event;
          if (data is Map) {
            final messageType = data['type']?.toString() ?? 'message';
            if (messageType == 'message') {
              final recipient = data['recipient']?.toString() ?? '';
              final recipientUsername = data['recipient_username']?.toString() ?? recipient;
              final sender = data['sender']?.toString() ?? '';
              final senderUsername = data['sender_username']?.toString() ?? sender;
              
              // Check if message is for this student (from any teacher)
              final isForThisStudent = (
                recipient == studentName ||
                recipientUsername == studentName ||
                recipient.toLowerCase().replaceAll(' ', '_') == studentName.toLowerCase().replaceAll(' ', '_')
              );
              
              // Check if sender is a teacher (not the student)
              final isFromTeacher = sender != studentName && 
                                   senderUsername != studentName &&
                                   sender.toLowerCase().replaceAll(' ', '_') != studentName.toLowerCase().replaceAll(' ', '_');
              
              // Check for group message
              final groupId = data['group_id']?.toString();
              
              if (groupId != null) {
                // Handle Group Message
                int groupIndex = -1;
                for (int i = 0; i < _groups.length; i++) {
                  if (_groups[i]['id'] == groupId) {
                    groupIndex = i;
                    break;
                  }
                }
                
                if (groupIndex != -1) {
                  // Update existing group
                  if (mounted) {
                    setState(() {
                      final group = _groups.removeAt(groupIndex);
                      group['lastMessage'] = data['message'] ?? data['message_text'] ?? 'New message';
                      group['time'] = _formatConversationTime(DateTime.now().toIso8601String());
                      group['unread'] = (group['unread'] ?? 0) + 1;
                      group['raw_time'] = DateTime.now().millisecondsSinceEpoch; // For sorting
                       _groups.insert(0, group); // Move to top
                    });
                  }
                } else {
                  // New group discovered (student added to group)
                  _loadGroups();
                }
                
              } else if (isForThisStudent && isFromTeacher) {
                // Handle 1-on-1 Message
                // Find the teacher in our list and increment unread count
                // Try to match by name first, then by username
                String? matchedTeacherName;
                int? matchedTeacherIndex;
                
                // First try to find exact match by name
                for (int i = 0; i < _teachers.length; i++) {
                  final teacher = _teachers[i];
                  final tName = teacher['name']?.toString() ?? '';
                  final tUser = teacher['user'] as Map<String, dynamic>?;
                  final tUsername = tUser?['username']?.toString() ?? '';
                  final tEmail = tUser?['email']?.toString() ?? '';
                  
                  if (sender == tName || 
                      senderUsername == tName ||
                      sender == tUsername ||
                      senderUsername == tUsername ||
                      sender == tEmail ||
                      senderUsername == tEmail ||
                      sender.toLowerCase().contains(tName.toLowerCase()) ||
                      tName.toLowerCase().contains(sender.toLowerCase())) {
                    matchedTeacherName = tName;
                    matchedTeacherIndex = i;
                    break;
                  }
                }
                
                // If no match found, use sender as teacher name
                final finalTeacherName = (matchedTeacherName != null && matchedTeacherName.isNotEmpty)
                    ? matchedTeacherName
                    : (sender.isNotEmpty ? sender : (senderUsername.isNotEmpty ? senderUsername : 'Unknown'));
                
                if (finalTeacherName.isNotEmpty && finalTeacherName != 'Unknown') {
                  final messageText = data['message']?.toString() ?? '';
                  final timestamp = data['timestamp']?.toString() ?? DateTime.now().toUtc().toIso8601String();
                  final messageId = data['message_id']?.toString() ?? '';
                  
                  setState(() {
                    // Update unread count
                    _unreadCounts[finalTeacherName] = (_unreadCounts[finalTeacherName] ?? 0) + 1;
                    
                    // Store message for this teacher
                    _teacherMessages[finalTeacherName] ??= [];
                    
                    // Check for duplicates
                    final isDuplicate = _teacherMessages[finalTeacherName]!.any((msg) => 
                      msg['message_id'] == messageId || 
                      (msg['text'] == messageText && msg['timestamp'] == timestamp)
                    );
                    
                    if (!isDuplicate && messageText.isNotEmpty) {
                      _teacherMessages[finalTeacherName]!.add({
                        'text': messageText,
                        'timestamp': timestamp,
                        'message_id': messageId,
                        'isTeacher': true,
                      });
                      
                      // Keep only last 50 messages per teacher for performance
                      if (_teacherMessages[finalTeacherName]!.length > 50) {
                        _teacherMessages[finalTeacherName]!.removeAt(0);
                      }
                    }
                    
                    // Update the teacher in the list
                    final teacherIndex = matchedTeacherIndex ?? _teachers.indexWhere((t) => t['name'] == finalTeacherName);
                    if (teacherIndex != -1) {
                      _teachers[teacherIndex]['unread'] = _unreadCounts[finalTeacherName] ?? 0;
                      
                      // Update last message and time
                      if (_teacherMessages[finalTeacherName]!.isNotEmpty) {
                        final lastMsg = _teacherMessages[finalTeacherName]!.last;
                        _teachers[teacherIndex]['lastMessage'] = lastMsg['text'] ?? '';
                        try {
                          final msgTime = DateTime.parse(lastMsg['timestamp'] ?? timestamp);
                          final now = DateTime.now();
                          final difference = now.difference(msgTime);
                          
                          if (difference.inDays == 0) {
                            _teachers[teacherIndex]['time'] = intl.DateFormat('hh:mm a').format(msgTime);
                          } else if (difference.inDays == 1) {
                            _teachers[teacherIndex]['time'] = 'Yesterday';
                          } else if (difference.inDays < 7) {
                            _teachers[teacherIndex]['time'] = intl.DateFormat('EEE').format(msgTime);
                          } else {
                            _teachers[teacherIndex]['time'] = intl.DateFormat('MMM d').format(msgTime);
                          }
                        } catch (e) {
                          _teachers[teacherIndex]['time'] = '';
                        }
                      }
                    }
                  });
                  debugPrint('✓ Unread count updated for $finalTeacherName: ${_unreadCounts[finalTeacherName]}');
                } else {
                  debugPrint('⚠️ Could not match teacher for unread count: sender=$sender, senderUsername=$senderUsername');
                }
              }
            }
          }
        } catch (e) {
          debugPrint('Error in global chat listener: $e');
        }
      });
    } catch (e) {
      debugPrint('Failed to initialize global chat listener: $e');
    }
  }

  Future<void> _loadParentSchoolId() async {
    try {
      final parentData = await api.ApiService.fetchParentProfile();
      if (parentData != null) {
        _schoolId = parentData['school_id']?.toString();
        final user = parentData['user'] as Map<String, dynamic>?;
        _currentUserId = user?['user_id']?.toString() ?? user?['id']?.toString();
        
        // Try to get from students if not in parent profile
        if ((_schoolId == null || _schoolId!.isEmpty || _schoolId == 'null')) {
          final students = parentData['students'];
          if (students is List && students.isNotEmpty) {
            final student = students[0];
            if (student is Map) {
              _schoolId = student['school_id']?.toString() ?? 
                         student['school']?['school_id']?.toString();
            }
          }
        }
        debugPrint('Parent school_id: $_schoolId, current user ID: $_currentUserId');
      }
    } catch (e) {
      debugPrint('Failed to load parent school_id: $e');
    }
  }



  List<Map<String, dynamic>> get _filteredTeachers {
    if (_loadingTeachers) return [];
    
    // First filter by school_id match (if parent has school_id)
    var filtered = _teachers;
    if (_schoolId != null && _schoolId!.isNotEmpty) {
      filtered = _teachers.where((teacher) {
        final teacherSchoolId = teacher['school_id']?.toString();
        return teacherSchoolId == null || teacherSchoolId == _schoolId;
      }).toList();
    }
    
    // Then apply search filter
    if (_searchQuery.isEmpty) return filtered;
    return filtered
        .where(
          (teacher) =>
              teacher['name'].toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              teacher['subject'].toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
        )
        .toList();
  }

  List<Map<String, dynamic>> get _filteredGroups {
    if (_loadingTeachers) return [];
    if (_searchQuery.isEmpty) return _groups;
    return _groups
        .where(
          (group) =>
              group['name'].toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  Future<void> _loadTeachers() async {
    setState(() => _loadingTeachers = true);
    try {
      final data = await api.ApiService.fetchTeachers();
      final mapped = data.map<Map<String, dynamic>>((t) {
        final user = t['user'] as Map<String, dynamic>? ?? {};
        final first = (user['first_name'] as String? ?? '').trim();
        final last = (user['last_name'] as String? ?? '').trim();
        final fullName = ('$first $last').trim();
        final designation = t['designation'] as String? ?? '';
        final userId = user['user_id']?.toString() ?? '';
        
        return {
          'name': fullName.isNotEmpty ? fullName : 'Teacher',
          'subject': designation,
          'online': false,
          'unread': 0,
          'lastMessage': '',
          'time': '',
          'avatar': _buildInitials(fullName.isNotEmpty ? fullName : 'T'),
          'user_id': userId, // Store user_id for conversation matching
        };
      }).toList();
      
      // Fetch conversations to populate last messages and unread counts
      debugPrint('Fetching conversations for parent...');
      try {
        final conversations = await api.ApiService.fetchConversations();
        debugPrint('Fetched ${conversations.length} active conversations for parent');
        
        for (var conv in conversations) {
          try {
            debugPrint('Processing conversation: ${conv.toString()}');
            final contactData = conv['contact'] as Map<String, dynamic>?;
            if (contactData == null) {
              debugPrint('WARNING: contact data is null in conversation');
              continue;
            }
            
            final lastMsgData = conv['last_message'] as Map<String, dynamic>?;
            final unreadCount = conv['unread_count'] as int? ?? 0;
            
            // Try multiple possible ID fields from backend
            final contactUserId = contactData['id']?.toString().trim() ?? 
                                 contactData['user_id']?.toString().trim() ?? '';
            
            debugPrint('Conversation contact - userId: $contactUserId');
            
            if (contactUserId.isEmpty) {
              debugPrint('WARNING: userId is empty for contact: ${contactData.toString()}');
              continue;
            }
            
            // Find matching teacher by user_id
            final teacherIndex = mapped.indexWhere((t) => t['user_id'] == contactUserId);
            
            if (teacherIndex != -1) {
              // Update existing teacher with conversation data
              if (lastMsgData != null) {
                final lastMsgText = lastMsgData['message_text']?.toString() ?? 
                                   (lastMsgData['attachment'] != null ? '📎 Attachment' : 
                                    (lastMsgData['message'] != null ? lastMsgData['message'].toString() : ''));
                final timestamp = lastMsgData['created_at']?.toString() ?? '';
                
                mapped[teacherIndex]['lastMessage'] = lastMsgText;
                mapped[teacherIndex]['time'] = _formatConversationTime(timestamp);
                mapped[teacherIndex]['unread'] = unreadCount;
                
                debugPrint('Updated teacher ${mapped[teacherIndex]['name']} with last message: $lastMsgText');
              }
            } else {
              // Contact might be a teacher not in the list, add them
              final username = contactData['username'] as String? ?? '';
              final firstName = contactData['first_name'] as String? ?? '';
              final lastName = contactData['last_name'] as String? ?? '';
              final name = '$firstName $lastName'.trim();
              final role = contactData['role'] as String? ?? '';
              
              if (lastMsgData != null) {
                final lastMsgText = lastMsgData['message_text']?.toString() ?? 
                                   (lastMsgData['attachment'] != null ? '📎 Attachment' : 
                                    (lastMsgData['message'] != null ? lastMsgData['message'].toString() : ''));
                final timestamp = lastMsgData['created_at']?.toString() ?? '';
                
                mapped.add({
                  'name': name.isNotEmpty ? name : username,
                  'subject': role,
                  'online': false,
                  'unread': unreadCount,
                  'lastMessage': lastMsgText,
                  'time': _formatConversationTime(timestamp),
                  'avatar': _buildInitials(name.isNotEmpty ? name : username),
                  'user_id': contactUserId,
                });
                
                debugPrint('Added new contact from conversation: ${name} ($contactUserId)');
              }
            }
          } catch (e) {
            debugPrint('Error processing conversation item: $e');
          }
        }
        debugPrint('Finished processing conversations. Total teachers: ${mapped.length}');
      } catch (e) {
        debugPrint('Error fetching conversations: $e');
      }
      
      setState(() {
        _teachers = mapped;
        // Groups will be loaded from API instead of hardcoded
      });
    } catch (e) {
      debugPrint('Failed to load teachers: $e');
    } finally {
      if (mounted) setState(() => _loadingTeachers = false);
    }
  }
  
  Future<void> _loadGroups() async {
    try {
      final groups = await api.ApiService.fetchGroups();
      if (mounted) {
        setState(() {
          _groups = groups.map<Map<String, dynamic>>((g) {
            return {
              'id': g['id']?.toString() ?? '',
              'name': g['name']?.toString() ?? 'Group',
              'lastMessage': g['last_message']?.toString() ?? '',
              'time': _formatConversationTime(g['created_at']?.toString() ?? ''),
              'raw_time': DateTime.parse(g['created_at']?.toString() ?? DateTime.now().toIso8601String()).millisecondsSinceEpoch,
              'unread': 0,
              'avatar': '👥',
            };
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Failed to load groups: $e');
    }
  }
  
  String _formatConversationTime(String timestamp) {
    if (timestamp.isEmpty) return '';
    try {
      final dt = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(dt);
      
      if (diff.inDays == 0) {
        return intl.DateFormat('HH:mm').format(dt);
      } else if (diff.inDays == 1) {
        return 'Yesterday';
      } else if (diff.inDays < 7) {
        return intl.DateFormat('EEE').format(dt);
      } else {
        return intl.DateFormat('dd/MM/yy').format(dt);
      }
    } catch (e) {
      return '';
    }
  }

  String _buildInitials(String name) {
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '👤';
    final initials = parts.take(2).map((p) => p[0]).join();
    return initials;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    SchoolManagementSystemApp.primaryPurple,
                    Color(0xFF764BA2),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          // Chat icon (kept the new trending icon)
                          Icon(
                            Icons.send_time_extension,
                            color: Colors.white,
                            size: 28,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'School Chat',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // REMOVED: Icons.more_vert (three dots) button here
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Search teachers, groups...',
                        hintStyle: TextStyle(color: Colors.white70),
                        prefixIcon: Icon(Icons.search, color: Colors.white),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Tabs
            Container(
              color: Colors.grey.shade100,
              child: TabBar(
                controller: _tabController,
                labelColor: SchoolManagementSystemApp.primaryPurple,
                unselectedLabelColor: Colors.grey,
                indicatorColor: SchoolManagementSystemApp.primaryPurple,
                indicatorWeight: 3,
                tabs: const [
                  Tab(icon: Icon(Icons.chat), text: 'Chats'),
                  Tab(icon: Icon(Icons.group), text: 'Groups'),
                ],
              ),
            ),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildChatsTab(), _buildGroupsTab()],
              ),
            ),
            // New chat button
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: () => _showNewChatDialog(context),
                backgroundColor: const Color(0xFF667eea),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Start New Chat',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatsTab() {
    return _filteredTeachers.isEmpty
        ? const Center(child: Text('No teachers found'))
        : ListView.builder(
            itemCount: _filteredTeachers.length,
            itemBuilder: (context, index) {
              final teacher = _filteredTeachers[index];
              return _buildChatTile(
                avatar: teacher['avatar'],
                name: teacher['name'],
                subtitle: (teacher['lastMessage'] != null && teacher['lastMessage'].toString().isNotEmpty)
                    ? teacher['lastMessage']
                    : (teacher['subject'] ?? 'Teacher'),
                time: teacher['time'],
                unread: teacher['unread'],
                online: teacher['online'],
                isSentByMe: teacher['isLastMessageSentByMe'] == true,
                isRead: teacher['isLastMessageRead'] == true,
                onTap: () => _openChatWithTeacher(context, teacher),
              );
            },
          );
  }

  Widget _buildGroupsTab() {
    return _filteredGroups.isEmpty
        ? const Center(child: Text('No groups found'))
        : ListView.builder(
            itemCount: _filteredGroups.length,
            itemBuilder: (context, index) {
              final group = _filteredGroups[index];
              return _buildChatTile(
                avatar: group['avatar'],
                name: group['name'],
                subtitle: group['lastMessage'],
                time: group['time'],
                unread: group['unread'],
                isGroup: true,
                members: group['members'],
                onTap: () => _openGroup(context, group),
              );
            },
          );
  }

  Widget _buildChatTile({
    required String avatar,
    required String name,
    required String subtitle,
    required String time,
    int unread = 0,
    bool online = false,
    bool isGroup = false,
    int members = 0,
    bool isSentByMe = false,
    bool isRead = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Profile picture
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey[300],
              child: Text(
                avatar,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (isSentByMe) ...[
                        Icon(
                          isRead ? Icons.done_all : Icons.done,
                          size: 14,
                          color: isRead ? const Color(0xFF34B7F1) : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          isGroup ? '$members members · $subtitle' : subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: unread > 0 ? Colors.black87 : Colors.grey[600],
                            fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal,
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
            // Time and unread count
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (time.isNotEmpty)
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                if (unread > 0) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: const BoxDecoration(
                      color: Color(0xFF667eea),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$unread',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openChatWithTeacher(
    BuildContext context,
    Map<String, dynamic> teacher,
  ) {
    // Reset unread count when opening chat
    final teacherName = teacher['name'] as String;
    final teacherId = teacher['user']?['user_id']?.toString() ?? 
                      teacher['user']?['id']?.toString();
                      
    setState(() {
      if ((_unreadCounts[teacherName] ?? 0) > 0 && teacherId != null) {
        api.ApiService.markConversationRead(teacherId);
      }
      _unreadCounts[teacherName] = 0;
      // Update the teacher in the list
      final teacherIndex = _teachers.indexWhere((t) => t['name'] == teacherName);
      if (teacherIndex != -1) {
        _teachers[teacherIndex]['unread'] = 0;
      }
    });
    
    // Close the parent dialog, then open the teacher chat as a full-screen route
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _UnifiedChatScreen(
          contact: teacher,
          isGroup: false,
          onUnreadCountUpdate: (name, count) {
            setState(() {
              _unreadCounts[name] = count;
              final teacherIndex = _teachers.indexWhere((t) => t['name'] == name);
              if (teacherIndex != -1) {
                _teachers[teacherIndex]['unread'] = count;
              }
            });
          },
        ),
      ),
    ).then((_) {
      // When returning from chat, refresh the list to show updated unread counts and sorting
      setState(() {
        // Force UI update to reflect new message order
      });
    });
  }
  
  // Method to update unread count (can be called from chat screen)
  void _updateUnreadCount(String teacherName, {bool increment = true}) {
    setState(() {
      if (increment) {
        _unreadCounts[teacherName] = (_unreadCounts[teacherName] ?? 0) + 1;
      } else {
        _unreadCounts[teacherName] = 0; // Reset when chat is opened
      }
      
      // Update the teacher in the list
      final teacherIndex = _teachers.indexWhere((t) => t['name'] == teacherName);
      if (teacherIndex != -1) {
        _teachers[teacherIndex]['unread'] = _unreadCounts[teacherName] ?? 0;
      }
    });
  }

  void _openGroup(BuildContext context, Map<String, dynamic> group) {
    // Close the parent dialog, then open the group chat as a full-screen route
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _UnifiedChatScreen(
          contact: group,
          isGroup: true,
          onLastMessageUpdate: (name, lastMsg, timestamp, isSentByMe, isRead) {
            setState(() {
              final groupIndex = _groups.indexWhere((g) => g['name'] == name);
              if (groupIndex != -1) {
                _groups[groupIndex]['lastMessage'] = lastMsg;
                _groups[groupIndex]['raw_timestamp'] = timestamp;
                _groups[groupIndex]['time'] = formatChatTime(timestamp);
              }
            });
          },
        )
      ),
    ).then((_) {
       if (mounted) _loadGroups();
    });
  }

  void _showNewChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start New Chat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select a teacher:'),
            const SizedBox(height: 8),
            ..._teachers.map(
              (teacher) => ListTile(
                leading: Text(
                  teacher['avatar'],
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(
                  teacher['name'],
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(teacher['subject']),
                onTap: () {
                  Navigator.of(context).pop();
                  _openChatWithTeacher(context, teacher);
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // Implementation removed as requested in the prompt
  // _showOptions and local _showSnackBar were unused; removed to avoid
  // analyzer warnings about unused private declarations.
}

// Full-screen chat screen (uses a Scaffold) — opened from the FAB
class _WhatsAppChatScreen extends StatefulWidget {
  @override
  State<_WhatsAppChatScreen> createState() => _WhatsAppChatScreenState();
}

class _WhatsAppChatScreenState extends State<_WhatsAppChatScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _groups = [];
  bool _loadingTeachers = false;
  String? _schoolId; // Parent's school_id for filtering
  final Map<String, int> _unreadCounts = {}; // Track unread messages per teacher

  String? _currentStudentName; // Student's display name for global room ID
  RealtimeChatService? _globalChatService;
  StreamSubscription? _globalChatSubscription;
  String? _currentUserId; // To identify sent messages for read receipts

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadParentSchoolId();
    _loadTeachers();
    _loadGroups();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _globalChatSubscription?.cancel();
    _globalChatService?.disconnect();
    super.dispose();
  }

  // Helper function to normalize names for room IDs
  String normalizeNameForRoomId(String name) {
    if (name.isEmpty) return '';
    return name
        .toLowerCase()
        .trim()
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }

  Future<void> _loadParentSchoolId() async {
    try {
      final parentData = await api.ApiService.fetchParentProfile();
      if (parentData != null) {
        _schoolId = parentData['school_id']?.toString();
        final user = parentData['user'] as Map<String, dynamic>?;
        _currentUserId = user?['user_id']?.toString() ?? user?['id']?.toString();
        debugPrint('Parent school_id: $_schoolId, current user ID: $_currentUserId');
        
        // Extract student name logic (simplified from TeacherChatScreen)
        String foundName = '';
        if (parentData['student_name'] != null) {
           foundName = parentData['student_name'].toString().trim();
        }
        
        if (foundName.isEmpty || foundName == 'null') {
           final students = parentData['students'];
           if (students is List && students.isNotEmpty) {
             final student = students[0];
             if (student is Map) {
               // Try extracting school_id if not found yet
               if (_schoolId == null || _schoolId!.isEmpty || _schoolId == 'null') {
                  _schoolId = student['school_id']?.toString() ?? 
                             student['school']?['school_id']?.toString();
               }
               
               // Extract name
               foundName = student['student_name']?.toString() ?? '';
               if (foundName.isEmpty || foundName == 'null') {
                 foundName = student['name']?.toString() ?? '';
               }
               if (foundName.isEmpty || foundName == 'null') {
                 final user = student['user'];
                 if (user is Map) {
                   foundName = '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
                 }
               }
             }
           }
        }
        
        if (foundName.isNotEmpty && foundName != 'null') {
          _currentStudentName = foundName;
          debugPrint('Defined current student name: $_currentStudentName');
          _initializeGlobalChatListener();
        }
        
        debugPrint('Parent school_id for filtering: $_schoolId');
      }
    } catch (e) {
      debugPrint('Failed to load parent school_id: $e');
    }
  }

  Future<void> _initializeGlobalChatListener() async {
    try {
       if (_currentStudentName == null || _currentStudentName!.isEmpty) return;
       
       final normalizedName = normalizeNameForRoomId(_currentStudentName!);
       if (normalizedName.isEmpty) return;
       
       debugPrint('Connecting to global student chat: student_$normalizedName');
       
       _globalChatService = RealtimeChatService(baseWsUrl: 'ws://localhost:8000');
       // Connect to student's personal channel
       await _globalChatService!.connect(roomId: 'student_$normalizedName', chatType: 'teacher-student');
       
       _globalChatSubscription = _globalChatService!.stream?.listen((event) {
         try {
           final data = event is String ? jsonDecode(event) : event;
           if (data is Map && data['type'] == 'message') {
             final sender = data['sender']?.toString() ?? '';
             final senderUsername = data['sender_username']?.toString() ?? sender;
             final messageText = data['message']?.toString() ?? '';
             final timestamp = data['timestamp']?.toString() ?? DateTime.now().toUtc().toIso8601String();
             final groupId = data['group_id']?.toString();
             final groupName = data['group_name']?.toString();
             
             if (messageText.isEmpty) return;
             
             // 1. Check for group message
             if (groupId != null) {
               if (mounted) {
                 setState(() {
                   final targetName = groupName ?? groupId;
                   _unreadCounts[targetName] = (_unreadCounts[targetName] ?? 0) + 1;
                   final gIndex = _groups.indexWhere((g) => g['id'] == groupId || g['name'] == groupName);
                   if (gIndex != -1) {
                     _groups[gIndex]['unread'] = _unreadCounts[targetName];
                     _groups[gIndex]['lastMessage'] = messageText;
                     _groups[gIndex]['raw_timestamp'] = timestamp;
                     _groups[gIndex]['time'] = formatChatTime(timestamp);
                   }
                 });
               }
               return;
             }

             // 2. Individual message update
             int index = -1;
             for (int i = 0; i < _teachers.length; i++) {
               final t = _teachers[i];
               final tUsername = t['user']?['username']?.toString() ?? '';
               final tName = t['name']?.toString() ?? '';
               if (senderUsername == tUsername || sender == tName) {
                 index = i;
                 break;
               }
             }
             
             if (index != -1 && mounted) {
               setState(() {
                 final teacher = _teachers[index];
                 teacher['lastMessage'] = messageText;
                 teacher['unread'] = (teacher['unread'] ?? 0) + 1;
                 teacher['isLastMessageRead'] = false;
                 teacher['isLastMessageSentByMe'] = (data['sender_id']?.toString() ?? data['sender']?.toString()) == _currentUserId;
                 teacher['time'] = formatChatTime(timestamp);
                 teacher['raw_timestamp'] = timestamp;
                 
                 _teachers.sort((a, b) {
                   final tA = a['raw_timestamp'] as String? ?? '';
                   final tB = b['raw_timestamp'] as String? ?? '';
                   if (tA.isNotEmpty && tB.isNotEmpty) return tB.compareTo(tA);
                   return (a['name'] as String).compareTo(b['name'] as String);
                 });
               });
             }
           }
         } catch (e) {
           debugPrint('Error in global chat listener: $e');
         }
       });
    } catch (e) {
      debugPrint('Error initializing global chat: $e');
    }
  }

  String _buildInitials(String name) {
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '👤';
    final initials = parts.take(2).map((p) => p[0]).join();
    return initials;
  }

  Future<void> _loadTeachers() async {
    setState(() => _loadingTeachers = true);
    try {
      // 1. Fetch all available teachers (directory)
      final teachersData = await api.ApiService.fetchTeachers();
      
      // 2. Fetch active conversations (recent chats)
      final conversations = await api.ApiService.fetchConversations();
      
      // Map to store unique teachers/contacts
      // Key: unique identifier (e.g. name or ID)
      final Map<String, Map<String, dynamic>> contactMap = {};
      
      // Helper to build initial teacher object from directory
      void addFromDirectory(Map<String, dynamic> t) {
        final user = t['user'] as Map<String, dynamic>? ?? {};
        final first = (user['first_name'] as String? ?? '').trim();
        final last = (user['last_name'] as String? ?? '').trim();
        final fullName = ('$first $last').trim();
        final designation = t['designation'] as String? ?? 'Teacher';
        final teacherSchoolId = t['school_id']?.toString();
        // Use name as key since old chat used names
        // But backend conversations usually use ID. Only use name for mapping if ID match fails or for legacy
        final teacherName = fullName.isNotEmpty ? fullName : (user['username'] as String? ?? 'Teacher');
        final teacherUsername = user['username'] as String? ?? '';
        final teacherEmail = user['email'] as String? ?? '';
        
        // Filter by school if parent school is known
        if (_schoolId != null && _schoolId!.isNotEmpty) {
           final matches = teacherSchoolId == null || teacherSchoolId == _schoolId;
           if (!matches) return;
        }

        contactMap[teacherName] = {
          'name': teacherName,
          'username': teacherUsername,
          'email': teacherEmail,
          'subject': designation,
          'school_id': teacherSchoolId,
          'online': false,
          'unread': 0,
          'lastMessage': '',
          'time': '',
          'avatar': _buildInitials(teacherName),
          'user': user, // Keep user object for later matching
          'raw_data': t // Keep raw data
        };
      }
      
      // Populate with directory teachers
      for (var t in teachersData) {
        addFromDirectory(Map<String, dynamic>.from(t));
      }
      
      // 3. Process conversations and update/add contacts
      for (var conv in conversations) {
        try {
          final contact = conv['contact'] as Map<String, dynamic>;
          final lastMsg = conv['last_message'] as Map<String, dynamic>?;
          final unreadCount = conv['unread_count'] as int? ?? 0;
          final timestamp = conv['timestamp'] as String? ?? '';
          
          final firstName = contact['first_name'] as String? ?? '';
          final lastName = contact['last_name'] as String? ?? '';
          final fullName = '$firstName $lastName'.trim();
          final username = contact['username'] as String? ?? '';
          final email = contact['email'] as String? ?? '';
          final displayName = fullName.isNotEmpty ? fullName : username;
          
          // Find existing contact (by name) or create new
          // Note: Ideally use IDs, but existing frontend heavily relies on names
          
          if (!contactMap.containsKey(displayName)) {
             // If not in directory but in conversations, add it
             contactMap[displayName] = {
               'name': displayName,
               'username': username,
               'email': email,
               'subject': 'Teacher', // Default
               'school_id': null,
               'online': false,
               'unread': 0,
               'lastMessage': '',
               'time': '',
               'avatar': _buildInitials(displayName),
               'user': contact, // Construct user-like object
             };
          } else {
             // Update existing contact with username/email if missing
             if ((contactMap[displayName]!['username'] as String? ?? '').isEmpty) {
                contactMap[displayName]!['username'] = username;
             }
             if ((contactMap[displayName]!['email'] as String? ?? '').isEmpty) {
                contactMap[displayName]!['email'] = email;
             }
          }
           
          // Update stats
          contactMap[displayName]!['unread'] = unreadCount;
          _unreadCounts[displayName] = unreadCount; // Sync global tracker
          
          if (lastMsg != null) {
            String msgText = lastMsg['message_text']?.toString() ?? 
                             (lastMsg['attachment'] != null ? '📎 Attachment' : '');
            if (msgText.isEmpty && lastMsg['message'] != null) msgText = lastMsg['message'].toString();
            
            contactMap[displayName]!['lastMessage'] = msgText;
            contactMap[displayName]!['isLastMessageRead'] = lastMsg['is_read'] == true;
            contactMap[displayName]!['isLastMessageSentByMe'] = (lastMsg['sender'] as Map?)?['user_id']?.toString() == _currentUserId;
            
             if (timestamp.isNotEmpty) {
               try {
                 String timeToParse = timestamp;
                 
                 final timeStr = formatChatTime(timestamp);
                 contactMap[displayName]!['time'] = timeStr;
                 contactMap[displayName]!['raw_timestamp'] = timestamp;
               } catch (e) {
                 debugPrint('Timestamp error: $e');
               }
             }
          }
          
        } catch (e) {
          debugPrint('Error processing conversation item: $e');
        }
      }
      
      final finalList = contactMap.values.toList();
      
      // Sort: Active chats (with timestamp) first, then alphabetical
      finalList.sort((a, b) {
        final tA = a['raw_timestamp'] as String? ?? '';
        final tB = b['raw_timestamp'] as String? ?? '';
        
        if (tA.isNotEmpty && tB.isNotEmpty) {
          return tB.compareTo(tA); // Newest first
        } else if (tA.isNotEmpty) {
          return -1; // A has messages, comes first
        } else if (tB.isNotEmpty) {
          return 1; // B has messages, comes first
        } else {
          // Alphabetical fallback
          return (a['name'] as String).compareTo(b['name'] as String);
        }
      });
      
      if (mounted) {
        setState(() {
          _teachers = finalList;
          // Groups will be loaded from API instead of hardcoded
        });
      }
    } catch (e) {
      debugPrint('Failed to load teachers/conversations: $e');
    } finally {
      if (mounted) setState(() => _loadingTeachers = false);
    }
  }

  Future<void> _loadGroups() async {
    try {
      final groupsData = await api.ApiService.fetchGroups();
      final List<Map<String, dynamic>> processedGroups = [];
      
      for (var g in groupsData) {
        final groupId = g['group_id']?.toString() ?? '';
        final groupName = g['name']?.toString() ?? 'Unnamed Group';
        
        processedGroups.add({
          'id': groupId,
          'name': groupName,
          'avatar': '👥',
          'members': (g['members'] as List?)?.length ?? 0,
          'unread': _unreadCounts[groupName] ?? 0,
          'lastMessage': '',
          'time': '',
        });
      }
      
      if (mounted) {
        setState(() {
          _groups = processedGroups;
        });
      }
    } catch (e) {
      debugPrint('Error loading groups: $e');
    }
  }


  List<Map<String, dynamic>> get _filteredTeachers {
    if (_loadingTeachers) return [];
    
    // First filter by school_id match (if parent has school_id)
    var filtered = _teachers;
    if (_schoolId != null && _schoolId!.isNotEmpty) {
      filtered = _teachers.where((teacher) {
        final teacherSchoolId = teacher['school_id']?.toString();
        return teacherSchoolId == null || teacherSchoolId == _schoolId;
      }).toList();
    }
    
    // Then apply search filter
    if (_searchQuery.isEmpty) return filtered;
    return filtered
        .where(
          (teacher) =>
              teacher['name'].toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              teacher['subject'].toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
        )
        .toList();
  }

  List<Map<String, dynamic>> get _filteredGroups {
    if (_loadingTeachers) return [];
    if (_searchQuery.isEmpty) return _groups;
    return _groups
        .where(
          (group) =>
              group['name'].toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF667eea),
        title: const Text(
          'School Chat',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
          ),
        ],
      ),
      body: _loadingTeachers
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search and filters
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by name...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: (value) => setState(() => _searchQuery = value),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        color: Colors.grey.shade100,
                        child: TabBar(
                          controller: _tabController,
                          labelColor: const Color(0xFF667eea),
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: const Color(0xFF667eea),
                          indicatorWeight: 3,
                          tabs: const [
                            Tab(icon: Icon(Icons.chat), text: 'Chats'),
                            Tab(icon: Icon(Icons.group), text: 'Groups'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Contacts list
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [_buildChatsTab(), _buildGroupsTab()],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildChatsTab() {
    return Container(
      color: Colors.grey.shade50,
      child: _filteredTeachers.isEmpty
          ? const Center(
              child: Text(
                'No teachers found',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: _filteredTeachers.length,
              itemBuilder: (context, index) {
                final teacher = _filteredTeachers[index];
                return _buildChatTile(
                  avatar: teacher['avatar'],
                  name: teacher['name'],
                  subtitle: (teacher['lastMessage'] != null && teacher['lastMessage'].toString().isNotEmpty)
                      ? teacher['lastMessage']
                      : (teacher['subject'] ?? 'Teacher'),
                  time: teacher['time'],
                  unread: teacher['unread'],
                  online: teacher['online'],
                  isSentByMe: teacher['isLastMessageSentByMe'] == true,
                  isRead: teacher['isLastMessageRead'] == true,
                  onTap: () => _openChatWithTeacher(context, teacher),
                );
              },
            ),
    );
  }

  Widget _buildGroupsTab() {
    return Container(
      color: Colors.grey.shade50,
      child: _filteredGroups.isEmpty
          ? const Center(
              child: Text(
                'No groups found',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: _filteredGroups.length,
              itemBuilder: (context, index) {
                final group = _filteredGroups[index];
                return _buildChatTile(
                  avatar: group['avatar'],
                  name: group['name'],
                  subtitle: group['lastMessage'],
                  time: group['time'],
                  unread: group['unread'],
                  isGroup: true,
                  members: group['members'],
                  onTap: () => _openGroup(context, group),
                );
              },
            ),
    );
  }

  // Reuse helper methods from the dialog version by copying the same names
  Widget _buildChatTile({
    required String avatar,
    required String name,
    required String subtitle,
    required String time,
    int unread = 0,
    bool online = false,
    bool isGroup = false,
    int members = 0,
    bool isSentByMe = false,
    bool isRead = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Profile picture
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey[300],
              child: Text(
                avatar,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (isSentByMe) ...[
                        Icon(
                          isRead ? Icons.done_all : Icons.done,
                          size: 14,
                          color: isRead ? const Color(0xFF34B7F1) : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          isGroup ? '$members members · $subtitle' : subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: unread > 0 ? Colors.black87 : Colors.grey[600],
                            fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal,
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
            // Time and unread count
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (time.isNotEmpty)
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                if (unread > 0) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: const BoxDecoration(
                      color: Color(0xFF667eea),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$unread',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openChatWithTeacher(
    BuildContext context,
    Map<String, dynamic> teacher,
  ) {
    // Reset unread count when opening chat
    final teacherName = teacher['name'] as String;
    final teacherId = teacher['user']?['user_id']?.toString() ?? 
                      teacher['user']?['id']?.toString();
                      
    setState(() {
      if ((_unreadCounts[teacherName] ?? 0) > 0 && teacherId != null) {
        api.ApiService.markConversationRead(teacherId);
      }
      _unreadCounts[teacherName] = 0;
      // Update the teacher in the list
      final teacherIndex = _teachers.indexWhere((t) => t['name'] == teacherName);
      if (teacherIndex != -1) {
        _teachers[teacherIndex]['unread'] = 0;
      }
    });
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _UnifiedChatScreen(
          contact: teacher,
          isGroup: false,
          onUnreadCountUpdate: (name, count) {
            setState(() {
              _unreadCounts[name] = count;
              final teacherIndex = _teachers.indexWhere((t) => t['name'] == name);
              if (teacherIndex != -1) {
                _teachers[teacherIndex]['unread'] = count;
              }
            });
          },
          onLastMessageUpdate: (name, lastMsg, timestamp, isSentByMe, isRead) {
            setState(() {
              final teacherIndex = _teachers.indexWhere((t) => t['name'] == name);
              if (teacherIndex != -1) {
                _teachers[teacherIndex]['lastMessage'] = lastMsg;
                _teachers[teacherIndex]['raw_timestamp'] = timestamp;
                _teachers[teacherIndex]['isLastMessageSentByMe'] = isSentByMe;
                _teachers[teacherIndex]['isLastMessageRead'] = isRead;
                // Update formatted time
                try {
                  String timeToParse = timestamp;
                  
                  final timeStr = formatChatTime(timestamp);
                  _teachers[teacherIndex]['time'] = timeStr;
                } catch (_) {}
              }
            });
          },
        ),
      ),
    ).then((_) async {
      // Reload teacher list when returning from chat to refresh timestamps and message previews
      if (mounted) {
        await _loadTeachers();
        await _loadGroups();
      }
    });
  }

  void _openGroup(BuildContext context, Map<String, dynamic> group) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _UnifiedChatScreen(
          contact: group,
          isGroup: true,
          onLastMessageUpdate: (name, lastMsg, timestamp, isSentByMe, isRead) {
            setState(() {
              final groupIndex = _groups.indexWhere((g) => g['name'] == name);
              if (groupIndex != -1) {
                _groups[groupIndex]['lastMessage'] = lastMsg;
                _groups[groupIndex]['raw_timestamp'] = timestamp;
                _groups[groupIndex]['time'] = formatChatTime(timestamp);
              }
            });
          },
        )
      ),
    ).then((_) {
      if (mounted) _loadGroups();
    });
  }

  void _showNewChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start New Chat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select a teacher:'),
            const SizedBox(height: 8),
            ..._teachers.map(
              (teacher) => ListTile(
                leading: Text(
                  teacher['avatar'],
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(
                  teacher['name'],
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(teacher['subject']),
                onTap: () {
                  Navigator.of(context).pop();
                  _openChatWithTeacher(context, teacher);
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // (no local _showSnackBar needed here)
}

// -------------------------------------------------------------------------
// Teacher Chat Screen
// -------------------------------------------------------------------------

class _UnifiedChatScreen extends StatefulWidget {
  final Map<String, dynamic> contact;
  final bool isGroup;
  final List<Map<String, dynamic>> initialMessages;
  final Function(String name, int count)? onUnreadCountUpdate;
  final Function(String name, String lastMessage, String timestamp, bool isSentByMe, bool isRead)? onLastMessageUpdate;
  const _UnifiedChatScreen({
    required this.contact,
    this.isGroup = false,
    this.initialMessages = const [],
    this.onUnreadCountUpdate,
    this.onLastMessageUpdate,
  });

  @override
  State<_UnifiedChatScreen> createState() => _UnifiedChatScreenState();
}

class _UnifiedChatScreenState extends State<_UnifiedChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isRemovedFromGroup = false;
  String? _groupRemovalMessage;
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoadingMessages = true;

  // State variable to track if text field is empty
  bool _isTextFieldEmpty = true;
  RealtimeChatService? _chatService;
  StreamSubscription? _chatSubscription;
  String? _chatRoomId;
  String? _studentUsername; // Display name (used for room ID)
  String? _teacherUsername; // Display name (used for room ID)
  String? _studentEmail; // Student email/username for API calls and message saving
  String? _teacherEmail; // Teacher email/username for API calls and message saving
  final Set<String> _messageIds = {}; // Track message IDs to prevent duplicates
  
  // Attachment support
  List<File> _selectedFiles = [];
  List<String> _selectedFileNames = [];

  // Parent and student info
  String? _parentEmail;
  String? _parentUsername;
  
  // Helper function to normalize names for room IDs
  String normalizeNameForRoomId(String name) {
    if (name.isEmpty) return '';
    // Convert to lowercase, replace spaces with underscores, remove special characters
    return name
        .toLowerCase()
        .trim()
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), ''); // Keep only alphanumeric and underscore
  }

  @override
  void initState() {
    super.initState();
    // Use initial messages if provided
    _messages = List<Map<String, dynamic>>.from(widget.initialMessages);
    _isLoadingMessages = _messages.isEmpty;
    
    _messageController.addListener(_updateTextFieldState);
    // Reset unread count when opening chat - defer to after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final contactName = widget.contact['name'] as String? ?? '';
      if (contactName.isNotEmpty && widget.onUnreadCountUpdate != null) {
        widget.onUnreadCountUpdate!(contactName, 0);
      }
    });
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.removeListener(_updateTextFieldState);
    _messageController.dispose();
    _scrollController.dispose();
    _chatSubscription?.cancel();
    _chatService?.disconnect();
    super.dispose();
  }
  
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Attachment methods
  Future<void> _pickAttachment() async {
    final ImagePicker picker = ImagePicker();
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF667eea)),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final List<XFile> images = await picker.pickMultiImage();
                if (images.isNotEmpty) {
                  setState(() {
                    for (var image in images) {
                      _selectedFiles.add(File(image.path));
                      _selectedFileNames.add(image.name);
                    }
                    _isTextFieldEmpty = false;
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF667eea)),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                _openCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.description, color: Color(0xFF667eea)),
              title: const Text('Choose Document'),
              onTap: () async {
                Navigator.pop(context);
                FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);
                if (result != null) {
                  setState(() {
                    for (var file in result.files) {
                      if (file.path != null) {
                        _selectedFiles.add(File(file.path!));
                        _selectedFileNames.add(file.name);
                      }
                    }
                    _isTextFieldEmpty = false;
                  });
                }
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _openCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      if (!mounted) return;
      
      final bool? shouldSend = await showDialog<bool>(
        context: context,
        builder: (context) => Dialog.fullscreen(
          child: Container(
            color: Colors.black,
            child: Stack(
              children: [
                Center(
                  child: kIsWeb ? Image.network(image.path) : Image.file(File(image.path)),
                ),
                Positioned(
                  top: 40,
                  left: 20,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ),
                Positioned(
                  bottom: 30,
                  right: 20,
                  child: FloatingActionButton(
                    backgroundColor: const Color(0xFF075E54),
                    child: const Icon(Icons.send, color: Colors.white),
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      if (shouldSend == true) {
        setState(() {
          _selectedFiles.add(File(image.path));
          _selectedFileNames.add(image.name);
        });
        _sendMessage();
      }
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
      _selectedFileNames.removeAt(index);
      _updateTextFieldState();
    });
  }

  void _updateTextFieldState() {
    final isEmpty = _messageController.text.isEmpty && _selectedFiles.isEmpty;
    if (_isTextFieldEmpty != isEmpty) {
      setState(() {
        _isTextFieldEmpty = isEmpty;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && _selectedFiles.isEmpty) return;
    
    if (_studentUsername == null || _studentUsername!.isEmpty) {
      debugPrint('Cannot send message: student name not initialized');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait, initializing chat...')),
      );
      _initializeChat();
      return;
    }
    
    if (widget.contact['name'] == null) {
      debugPrint('Cannot send message: teacher name not available');
      return;
    }
    
    final List<File> filesToSend = List.from(_selectedFiles);
    final List<String> fileNamesToSend = List.from(_selectedFileNames);
    
    _messageController.clear();
    setState(() {
      _selectedFiles.clear();
      _selectedFileNames.clear();
      _isTextFieldEmpty = true;
    });

    String? groupId = widget.isGroup ? widget.contact['id']?.toString() : null;

    if (text.isNotEmpty && filesToSend.isEmpty) {
      await _sendSingleMessage(text: text, groupId: groupId);
    } else if (filesToSend.isNotEmpty) {
      for (int i = 0; i < filesToSend.length; i++) {
        final file = filesToSend[i];
        final fileName = fileNamesToSend[i];
        final caption = (i == 0 && text.isNotEmpty) ? text : null;
        await _sendSingleMessage(text: caption, file: file, fileName: fileName, groupId: groupId);
      }
    }
  }

  Future<void> _sendSingleMessage({String? text, File? file, String? fileName, String? groupId}) async {
    final messageText = text ?? (file != null ? '📎 $fileName' : '');
    if (messageText.isEmpty && file == null) return;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}_${messageText.hashCode}';
    final tempTimestamp = DateTime.now().toUtc().toIso8601String();
    
    setState(() {
      _messageIds.add(tempId);
      _messages.add(Map<String, dynamic>.from({
        'text': messageText,
        'isTeacher': false,
        'time': intl.DateFormat('hh:mm a').format(DateTime.now()),
        'message_id': tempId,
        'timestamp': tempTimestamp,
        'attachment': file?.path,
        'attachment_name': fileName,
      }));
      
      widget.onLastMessageUpdate?.call(
        widget.contact['name'] ?? 'Contact',
        messageText,
        tempTimestamp,
        true,
        false,
      );
    });
    
    _scrollToBottom();
    
    // Read file bytes for web platform
    List<int>? fileBytes;
    if (file != null && kIsWeb) {
      try {
        fileBytes = await file.readAsBytes();
      } catch (e) {
        debugPrint('Error reading file bytes: $e');
      }
    }

    try {
      if (file != null || text != null) {
        final recipientForApi = _teacherEmail ?? _teacherUsername ?? '';
        final response = await api.ApiService.sendMessageWithAttachment(
          recipient: widget.isGroup ? '' : (_teacherEmail ?? _teacherUsername ?? ''),
          messageText: text,
          filePath: kIsWeb ? null : file?.path,
          fileBytes: fileBytes,
          fileName: fileName,
          messageType: file != null ? 
            (file.path.toLowerCase().endsWith('.jpg') || 
             file.path.toLowerCase().endsWith('.jpeg') || 
             file.path.toLowerCase().endsWith('.png') ? 'image' : 'file') : 'text',
          groupId: groupId,
        );
        
        if (response != null && mounted) {
          final realId = response['message_id'].toString();
          setState(() {
            final idx = _messages.indexWhere((m) => m['message_id'] == tempId);
            if (idx != -1) {
              _messages[idx]['message_id'] = realId;
              _messages[idx]['attachment_url'] = response['attachment_url'];
              _messages[idx]['attachment_name'] = response['attachment_name'] ?? fileName;
              _messageIds.remove(tempId);
              _messageIds.add(realId);
            }
          });
        } else if (file != null) {
           throw Exception("Failed to upload attachment");
        } else {
           // Fallback to WS if REST fails for text only (unlikely but safe)
           _sendWsFallback(text!);
        }
      }
    } catch (error) {
      debugPrint('Error sending message: $error');
      if (mounted) {
        setState(() {
          _messages.removeWhere((msg) => msg['message_id'] == tempId);
          _messageIds.remove(tempId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $error')),
        );
      }
    }
  }

  void _sendWsFallback(String text) {
     if (_chatService != null && _chatService!.isConnected) {
        final senderForWs = _studentEmail ?? _studentUsername!;
        final recipientForWs = _teacherEmail ?? _teacherUsername ?? '';
        _chatService!.sendMessage(
          sender: senderForWs,
          recipient: recipientForWs,
          message: text,
        );
     }
  }

  void _sendVoiceMessage() {
    _showSnackBar("Recording voice message...");
    // Implement actual recording logic here (start/stop)
  }

  Future<void> _initializeChat() async {
    try {
      // FOR GROUPS: Simple initialization
      if (widget.isGroup) {
        _chatRoomId = widget.contact['id']?.toString();
        _studentUsername = 'Parent/Student'; // We'll get real name if needed from profile
        
        // Still need parent profile for sender info
        Map<String, dynamic>? profile = await api.ApiService.fetchParentProfile();
        if (profile != null) {
           final user = profile['user'] as Map?;
           _studentEmail = user?['username']?.toString() ?? user?['email']?.toString();
           _studentUsername = '${user?['first_name'] ?? ''} ${user?['last_name'] ?? ''}'.trim();
           if (_studentUsername!.isEmpty) _studentUsername = user?['username']?.toString() ?? 'Parent/Student';
        }

        await _loadExistingMessages();
        _initializeRealtimeChat();
        setState(() => _isLoadingMessages = false);
        return;
      }

      // FOR INDIVIDUALS: Complex identity resolution
      // Fetch parent profile to get student data
      Map<String, dynamic>? parentData = await api.ApiService.fetchParentProfile();
      debugPrint('Parent data received: ${parentData?.keys}');
      
      // If parent profile is null, try to fetch student profile as fallback
      // (since parent and student are in same portal)
      if (parentData == null) {
        debugPrint('Parent profile is null, trying student profile as fallback...');
        try {
          final studentData = await api.ApiService.fetchStudentProfile();
          if (studentData != null) {
            debugPrint('Found student profile, converting to parent-like structure');
            debugPrint('Student data keys: ${studentData.keys}');
            debugPrint('Student name from profile: ${studentData['student_name']}');
            
            // Convert student data to parent-like structure
            parentData = {
              'user': studentData['user'],
              'students': [studentData], // Wrap student in students array
              'school_id': studentData['school_id'],
              'school_name': studentData['school_name'],
              // Add student_name at top level for easier access
              'student_name': studentData['student_name'],
            };
            debugPrint('Converted student profile to parent-like structure');
            debugPrint('Student name in converted data: ${parentData['student_name']}');
          } else {
            debugPrint('Student profile is also null');
          }
        } catch (e) {
          debugPrint('Failed to fetch student profile as fallback: $e');
        }
      }
      
      if (parentData != null) {
        // First, try to get student_name directly from parentData (for student profile fallback)
        if (parentData.containsKey('student_name')) {
          final studentNameValue = parentData['student_name'];
          final directStudentName = studentNameValue?.toString().trim();
          if (directStudentName != null && directStudentName.isNotEmpty && directStudentName != 'null') {
            debugPrint('✓ Found student_name directly in parentData: $directStudentName');
            _studentUsername = directStudentName;
            
            // Also extract username/email for room ID
        final students = parentData['students'];
        if (students is List && students.isNotEmpty) {
              final firstStudent = students[0] as Map<String, dynamic>?;
              if (firstStudent != null) {
                // Room ID will use student name (no email needed)
                debugPrint('  Student name for room ID: $_studentUsername');
              }
            }
          }
        }
        
        final students = parentData['students'];
        debugPrint('Students in parent data: ${students is List ? students.length : 'not a list'}');
        
        if (students is List && students.isNotEmpty) {
          // Iterate through all students to find one with valid name
          Map<String, dynamic>? validStudentData;
          String? extractedStudentName;
          
          debugPrint('Processing ${students.length} students from parent profile...');
          
          for (var studentItem in students) {
            if (studentItem is Map<String, dynamic>) {
              debugPrint('Student item keys: ${studentItem.keys}');
              final studentUser = studentItem['user'] as Map<String, dynamic>?;
              
              // Try to get student name - check multiple fields
              String studentName = '';
              
              // Priority 1: student_name field (MOST IMPORTANT - this is the actual student name like "rakesh")
              if (studentItem['student_name'] != null) {
                final studentNameValue = studentItem['student_name'].toString().trim();
                if (studentNameValue.isNotEmpty && studentNameValue != 'null' && studentNameValue.toLowerCase() != 'null') {
                  studentName = studentNameValue;
                  debugPrint('✓ Found student_name: $studentName');
                }
              }
              
              // Priority 2: name field
              if (studentName.isEmpty && studentItem['name'] != null) {
                final nameValue = studentItem['name'].toString().trim();
                if (nameValue.isNotEmpty && nameValue != 'null') {
                  studentName = nameValue;
                  debugPrint('Found name field: $studentName');
                }
              }
              
              // Priority 3: user's first_name + last_name
              if (studentName.isEmpty && studentUser != null) {
                final firstName = (studentUser['first_name'] as String? ?? '').trim();
                final lastName = (studentUser['last_name'] as String? ?? '').trim();
                if (firstName.isNotEmpty || lastName.isNotEmpty) {
                  studentName = '$firstName $lastName'.trim();
                  debugPrint('Found name from user: $studentName');
                }
              }
              
              // Use the first student with a valid name
              if (studentName.isNotEmpty) {
                validStudentData = studentItem;
                extractedStudentName = studentName;
                debugPrint('✓ Selected student: $studentName');
                break;
              } else {
                debugPrint('✗ Skipped student - no valid name found');
              }
            } else {
              debugPrint('✗ Student item is not a Map: ${studentItem.runtimeType}');
            }
          }
          
          if (validStudentData != null && extractedStudentName != null) {
            _studentUsername = extractedStudentName;
            
            // Get teacher username/name/email
            final teacherUser = widget.contact['user'] as Map<String, dynamic>?;
            String teacherFirstName = '';
            String teacherLastName = '';
            String teacherEmail = '';
            String teacherUsername = '';
            if (teacherUser != null) {
              teacherFirstName = (teacherUser['first_name'] as String? ?? '').trim();
              teacherLastName = (teacherUser['last_name'] as String? ?? '').trim();
              teacherEmail = teacherUser['email'] as String? ?? '';
              teacherUsername = teacherUser['username'] as String? ?? '';
            }
            final teacherFullName = '$teacherFirstName $teacherLastName'.trim();
            final teacherName = (widget.contact['name'] as String? ?? '').trim();
            final finalTeacherName = teacherName.isNotEmpty ? teacherName : teacherFullName;
            
            _teacherUsername = finalTeacherName.isNotEmpty 
                ? finalTeacherName 
                : 'Teacher';
            
            // Store emails/usernames for API calls and message saving
            final studentUser = validStudentData['user'] as Map<String, dynamic>?;
            final studentEmailValue = validStudentData['email']?.toString() ?? 
                                     studentUser?['email']?.toString() ?? '';
            final studentUsernameValue = studentUser?['username']?.toString();
            _studentEmail = studentUsernameValue ?? 
                          (studentEmailValue.isNotEmpty ? studentEmailValue : '');
            
            _teacherEmail = teacherUsername.isNotEmpty ? teacherUsername : 
                          (teacherEmail.isNotEmpty ? teacherEmail : '');
            
            // If still empty, use the teacher's name as fallback (backend can look it up)
            if (_teacherEmail == null || _teacherEmail!.isEmpty) {
              _teacherEmail = _teacherUsername; // Fallback to name, backend will try to resolve it
            }
            
            debugPrint('Student name set: $_studentUsername, Teacher: $_teacherUsername');
            debugPrint('Student email/username for API: $_studentEmail, Teacher email/username: $_teacherEmail');
            
            // Create room ID using names only (no email fallback)
            if ((_studentUsername != null && _studentUsername!.isNotEmpty) &&
                (_teacherUsername != null && _teacherUsername!.isNotEmpty)) {
              final normalizedStudentName = normalizeNameForRoomId(_studentUsername!);
              final normalizedTeacherName = normalizeNameForRoomId(_teacherUsername!);
              
              if (normalizedStudentName.isNotEmpty && normalizedTeacherName.isNotEmpty) {
                final identifiers = [normalizedStudentName, normalizedTeacherName]..sort();
                _chatRoomId = identifiers.join('_');
                debugPrint('Room ID using names - Student: $_studentUsername -> $normalizedStudentName');
                debugPrint('  Teacher: $_teacherUsername -> $normalizedTeacherName');
                debugPrint('  Final room ID: $_chatRoomId');
            } else {
                debugPrint('ERROR: Normalized names are empty (student: $normalizedStudentName, teacher: $normalizedTeacherName)');
                _chatRoomId = null;
              }
            } else {
              debugPrint('ERROR: Student or teacher name is missing (student: $_studentUsername, teacher: $_teacherUsername)');
              _chatRoomId = null;
            }
            
            debugPrint('Chat initialized - student: $_studentUsername, teacher: $_teacherUsername, room: $_chatRoomId');
            
            // Load existing messages from API
            await _loadExistingMessages();
            
            // Initialize real-time chat
            _initializeRealtimeChat();
            
            setState(() {
              _isLoadingMessages = false;
            });
            return;
          } else {
            debugPrint('No valid student found with name in students list');
        }
        } else {
          debugPrint('No students found in parent profile. Students: $students');
          
          // Try to find student data in a different structure or retry with better extraction
          // Check if students might be in a different format
          if (students == null || (students is List && students.isEmpty)) {
            debugPrint('Students list is empty or null, checking alternative data structures...');
            
            // Try to get student from any available source
            Map<String, dynamic>? alternativeStudentData;
            
            // Check if there's student data elsewhere in parentData
            if (parentData.containsKey('student')) {
              alternativeStudentData = parentData['student'] as Map<String, dynamic>?;
              debugPrint('Found student data in parentData[\'student\']');
            }
            
            // If still no student found, use parent as last resort but try to get student name from elsewhere
            if (alternativeStudentData == null) {
              debugPrint('No alternative student data found, will use parent info but prefer student name if available');
            } else {
              // Process alternative student data
              final studentUser = alternativeStudentData['user'] as Map<String, dynamic>?;
              String studentName = '';
              if (alternativeStudentData['student_name'] != null && 
                  alternativeStudentData['student_name'].toString().trim().isNotEmpty) {
                studentName = alternativeStudentData['student_name'].toString().trim();
              } else if (studentUser != null) {
                final firstName = (studentUser['first_name'] as String? ?? '').trim();
                final lastName = (studentUser['last_name'] as String? ?? '').trim();
                studentName = '$firstName $lastName'.trim();
              }
              
              if (studentName.isNotEmpty) {
                _studentUsername = studentName;
                
                // Get student email/username for API calls
                final studentEmailValue = alternativeStudentData['email']?.toString() ?? 
                                         studentUser?['email']?.toString() ?? '';
                final studentUsernameValue = studentUser?['username']?.toString();
                _studentEmail = studentUsernameValue ?? 
                              (studentEmailValue.isNotEmpty ? studentEmailValue : '');
                
                // Get teacher info
                final teacherUser = widget.contact['user'] as Map<String, dynamic>?;
                String teacherFirstName = '';
                String teacherLastName = '';
                String teacherEmail = '';
                String teacherUsername = '';
                if (teacherUser != null) {
                  teacherFirstName = (teacherUser['first_name'] as String? ?? '').trim();
                  teacherLastName = (teacherUser['last_name'] as String? ?? '').trim();
                  teacherEmail = teacherUser['email'] as String? ?? '';
                  teacherUsername = teacherUser['username'] as String? ?? '';
                }
                final teacherFullName = '$teacherFirstName $teacherLastName'.trim();
                final teacherName = (widget.contact['name'] as String? ?? '').trim();
                final finalTeacherName = teacherName.isNotEmpty ? teacherName : teacherFullName;
                
                _teacherUsername = finalTeacherName.isNotEmpty 
                    ? finalTeacherName 
                    : 'Teacher';
                
                _teacherEmail = teacherUsername.isNotEmpty ? teacherUsername : 
                              (teacherEmail.isNotEmpty ? teacherEmail : '');
                
                // If still empty, use the teacher's name as fallback
                if (_teacherEmail == null || _teacherEmail!.isEmpty) {
                  _teacherEmail = _teacherUsername;
                }
                
                // Create room ID using names only (no email fallback)
                if ((_studentUsername != null && _studentUsername!.isNotEmpty) &&
                    (_teacherUsername != null && _teacherUsername!.isNotEmpty)) {
                  final normalizedStudentName = normalizeNameForRoomId(_studentUsername!);
                  final normalizedTeacherName = normalizeNameForRoomId(_teacherUsername!);
                  
                  if (normalizedStudentName.isNotEmpty && normalizedTeacherName.isNotEmpty) {
                    final identifiers = [normalizedStudentName, normalizedTeacherName]..sort();
                    _chatRoomId = identifiers.join('_');
                  } else {
                    _chatRoomId = null;
                  }
                  
                  debugPrint('Using alternative student data - student: $_studentUsername, teacher: $_teacherUsername');
                  debugPrint('Room ID: $_chatRoomId');
                  await _loadExistingMessages();
      _initializeRealtimeChat();
      setState(() {
        _isLoadingMessages = false;
      });
                  return;
                }
              }
            }
          }
          
          // Since parent and student are in same portal, try to use parent user as fallback
          // But first, try to extract student name from any available source
          final parentUser = parentData['user'] as Map<String, dynamic>?;
          final parentEmail = parentUser?['email']?.toString() ?? '';
          final parentFirstName = parentUser?['first_name']?.toString() ?? '';
          final parentLastName = parentUser?['last_name']?.toString() ?? '';
          final parentName = '$parentFirstName $parentLastName'.trim();
          
          // Try to get student name from parent profile if available
          String? studentNameFromParent;
          if (parentData.containsKey('student_name')) {
            studentNameFromParent = (parentData['student_name'] as String?)?.trim();
            if (studentNameFromParent != null && studentNameFromParent.isNotEmpty) {
              debugPrint('Found student_name in parent profile: $studentNameFromParent');
            }
          }
          
          if (parentEmail.isNotEmpty || parentName.isNotEmpty) {
            // Use student name if found, otherwise use parent name, but never use "Parent" as default
            _studentUsername = studentNameFromParent ?? (parentName.isNotEmpty ? parentName : 'Student');
            
            final teacherUser = widget.contact['user'] as Map<String, dynamic>?;
            String teacherFirstName = '';
            String teacherLastName = '';
            if (teacherUser != null) {
              teacherFirstName = (teacherUser['first_name'] as String? ?? '').trim();
              teacherLastName = (teacherUser['last_name'] as String? ?? '').trim();
            }
            final teacherFullName = '$teacherFirstName $teacherLastName'.trim();
            final teacherName = (widget.contact['name'] as String? ?? '').trim();
            final finalTeacherName = teacherName.isNotEmpty ? teacherName : teacherFullName;
            
            _teacherUsername = finalTeacherName.isNotEmpty 
                ? finalTeacherName 
                : 'Teacher';
            
            // Create room ID using names only (no email fallback)
            if ((_studentUsername != null && _studentUsername!.isNotEmpty) &&
                (_teacherUsername != null && _teacherUsername!.isNotEmpty)) {
              final normalizedStudentName = normalizeNameForRoomId(_studentUsername!);
              final normalizedTeacherName = normalizeNameForRoomId(_teacherUsername!);
              
              if (normalizedStudentName.isNotEmpty && normalizedTeacherName.isNotEmpty) {
                final identifiers = [normalizedStudentName, normalizedTeacherName]..sort();
                _chatRoomId = identifiers.join('_');
              } else {
                _chatRoomId = null;
              }
              
              debugPrint('Using parent as fallback - student: $_studentUsername, teacher: $_teacherUsername');
              await _loadExistingMessages();
              _initializeRealtimeChat();
              setState(() {
                _isLoadingMessages = false;
              });
              return;
            }
          }
        }
      } else {
        debugPrint('Parent data is null');
      }
      
      // Final fallback: retry student extraction with more thorough checking
      debugPrint('Using final fallback for chat initialization - retrying student extraction');
      try {
        Map<String, dynamic>? parentData = await api.ApiService.fetchParentProfile();
        
        // If parent profile is null, try student profile as fallback
        if (parentData == null) {
          debugPrint('Parent profile is null in final fallback, trying student profile...');
          try {
            final studentData = await api.ApiService.fetchStudentProfile();
            if (studentData != null) {
              debugPrint('Found student profile in final fallback');
              debugPrint('Student name from profile: ${studentData['student_name']}');
              debugPrint('Student email: ${studentData['email']}');
              
              parentData = {
                'user': studentData['user'],
                'students': [studentData],
                'school_id': studentData['school_id'],
                'school_name': studentData['school_name'],
                'student_name': studentData['student_name'], // Add for direct access
              };
              
              // Immediately try to extract student name from the converted data
              if (studentData['student_name'] != null) {
                final name = studentData['student_name'].toString().trim();
                if (name.isNotEmpty && name != 'null') {
                  _studentUsername = name;
                  debugPrint('✓ Set student name from student profile: $_studentUsername');
                  
                  debugPrint('  Student name for room ID: $_studentUsername');
                }
              }
            }
    } catch (e) {
            debugPrint('Failed to fetch student profile in final fallback: $e');
          }
        }
        
        if (parentData != null) {
          // Retry students extraction with more thorough checking
          final students = parentData['students'];
          debugPrint('Final fallback - Students type: ${students.runtimeType}, is List: ${students is List}');
          
          if (students is List && students.isNotEmpty) {
            debugPrint('Final fallback - Found ${students.length} students, retrying extraction...');
            
            for (var studentItem in students) {
              if (studentItem is Map<String, dynamic>) {
                debugPrint('Final fallback - Student keys: ${studentItem.keys}');
                final studentUser = studentItem['user'] as Map<String, dynamic>?;
                
                // Try multiple ways to get student name
                String studentName = '';
                
                // Check student_name (MOST IMPORTANT - actual student name like "rakesh")
                if (studentItem['student_name'] != null) {
                  final val = studentItem['student_name'].toString().trim();
                  if (val.isNotEmpty && val != 'null' && val.toLowerCase() != 'null') {
                    studentName = val;
                    debugPrint('✓ Final fallback - Found student_name: $studentName');
                  }
                }
                
                // Check name field
                if (studentName.isEmpty && studentItem['name'] != null) {
                  final val = studentItem['name'].toString().trim();
                  if (val.isNotEmpty && val != 'null') studentName = val;
                }
                
                // Check user first_name + last_name
                if (studentName.isEmpty && studentUser != null) {
                  final firstName = (studentUser['first_name'] as String? ?? '').trim();
                  final lastName = (studentUser['last_name'] as String? ?? '').trim();
                  if (firstName.isNotEmpty || lastName.isNotEmpty) {
                    studentName = '$firstName $lastName'.trim();
                  }
                }
                
                if (studentName.isNotEmpty) {
                  _studentUsername = studentName;
                  debugPrint('✓ Final fallback - Found student: $_studentUsername');
                  break;
                }
              }
            }
          }
          
          // If still no student name found, check if parent profile has student_name directly
          if ((_studentUsername == null || _studentUsername!.isEmpty) && parentData.containsKey('student_name')) {
            final studentNameFromProfile = (parentData['student_name'] as String?)?.trim();
            if (studentNameFromProfile != null && studentNameFromProfile.isNotEmpty && studentNameFromProfile != 'null') {
              _studentUsername = studentNameFromProfile;
              debugPrint('✓ Found student_name in parent profile: $_studentUsername');
            }
          }
          
          // Last resort: use parent name but log warning
          if (_studentUsername == null || _studentUsername!.isEmpty) {
            final parentUser = parentData['user'] as Map<String, dynamic>?;
            if (parentUser != null) {
              final parentFirstName = (parentUser['first_name'] as String? ?? '').trim();
              final parentLastName = (parentUser['last_name'] as String? ?? '').trim();
              final parentName = '$parentFirstName $parentLastName'.trim();
              _studentUsername = parentName.isNotEmpty ? parentName : 'Student';
              debugPrint('⚠ WARNING: Using parent name as student name: $_studentUsername');
            } else {
              _studentUsername = 'Student';
            }
          }
        } else {
          _studentUsername = 'Student';
        }
      } catch (e) {
        debugPrint('Error in final fallback: $e');
        _studentUsername = 'Student';
      }
      
      // Get teacher info for final fallback
      // Get teacher info for final fallback
      final teacherUser = widget.contact['user'] as Map<String, dynamic>?;
      String teacherFirstName = '';
      String teacherLastName = '';
      String teacherUsername = widget.contact['username'] as String? ?? '';
      String teacherEmail = widget.contact['email'] as String? ?? '';
      
      if (teacherUser != null) {
        teacherFirstName = (teacherUser['first_name'] as String? ?? '').trim();
        teacherLastName = (teacherUser['last_name'] as String? ?? '').trim();
        if (teacherUsername.isEmpty) teacherUsername = teacherUser['username'] as String? ?? '';
        if (teacherEmail.isEmpty) teacherEmail = teacherUser['email'] as String? ?? '';
      }
      
      final teacherFullName = '$teacherFirstName $teacherLastName'.trim();
      final teacherName = (widget.contact['name'] as String? ?? '').trim();
      final finalTeacherName = teacherName.isNotEmpty ? teacherName : (teacherFullName.isNotEmpty ? teacherFullName : 'Teacher');
      _teacherUsername = finalTeacherName;
      
      // Set teacher email/username for API calls (prioritize username)
      _teacherEmail = teacherUsername.isNotEmpty ? teacherUsername : (teacherEmail.isNotEmpty ? teacherEmail : finalTeacherName);
      
      // Ensure student email is set if we have student data
      if (_studentEmail == null || _studentEmail!.isEmpty) {
         if (parentData != null && parentData.containsKey('students')) {
            final studentsList = parentData['students'];
            if (studentsList is List && studentsList.isNotEmpty) {
               final s = studentsList[0];
               if (s is Map) {
                  final u = s['user'];
                  if (u is Map) {
                     _studentEmail = u['username']?.toString() ?? u['email']?.toString();
                  }
                  if (_studentEmail == null || _studentEmail!.isEmpty) {
                     _studentEmail = s['email']?.toString();
                  }
               }
            }
         }
         // Fallback to name if still empty
         if (_studentEmail == null || _studentEmail!.isEmpty) {
            _studentEmail = _studentUsername;
         }
      }
      
      // Create room ID using names only (no email fallback)
      if ((_studentUsername != null && _studentUsername!.isNotEmpty) &&
          (_teacherUsername != null && _teacherUsername!.isNotEmpty)) {
        final normalizedStudentName = normalizeNameForRoomId(_studentUsername!);
        final normalizedTeacherName = normalizeNameForRoomId(_teacherUsername!);
        
        if (normalizedStudentName.isNotEmpty && normalizedTeacherName.isNotEmpty) {
          final identifiers = [normalizedStudentName, normalizedTeacherName]..sort();
          _chatRoomId = identifiers.join('_');
          debugPrint('Final fallback room ID: $_chatRoomId');
          debugPrint('  Student: $_studentUsername -> $normalizedStudentName');
          debugPrint('  Teacher: $_teacherUsername -> $normalizedTeacherName');
        } else {
          _chatRoomId = null;
          debugPrint('ERROR: Normalized names are empty (student: $normalizedStudentName, teacher: $normalizedTeacherName)');
        }
      } else {
        _chatRoomId = null;
        debugPrint('ERROR: Student or teacher name is missing (student: $_studentUsername, teacher: $_teacherUsername)');
      }
      
      _initializeRealtimeChat();
      // Load history after data is initialized
      _loadExistingMessages();
    } catch (e, stackTrace) {
      debugPrint('Error initializing chat: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _isLoadingMessages = false;
      });
    }
  }

  Future<void> _loadExistingMessages() async {
    if (_studentEmail == null || _teacherEmail == null) {
      debugPrint('Cannot load messages: missing email/username (student: $_studentEmail, teacher: $_teacherEmail)');
      return;
    }
    
    // Use teacher ID from parent if available for more reliable identification
    final teacherId = widget.contact['id']?.toString() ?? widget.contact['user_id']?.toString();
    
    setState(() => _isLoadingMessages = true);
    try {
      // Fetch messages using the new ChatMessage API endpoint (WhatsApp/Telegram-like)
      final messages = await api.ApiService.fetchChatMessages(
        widget.isGroup ? '' : _studentEmail!, 
        widget.isGroup ? '' : _teacherEmail!,
        otherUserId: widget.isGroup ? null : (widget.contact['id']?.toString() ?? widget.contact['user_id']?.toString()),
        groupId: widget.isGroup ? widget.contact['id']?.toString() : null,
      );
      
      debugPrint('Loaded ${messages.length} existing chat messages');
      
      if (mounted) {
        setState(() {
          // Process messages from backend
          final List<Map<String, dynamic>> history = messages.map((msg) {
            final sender = msg['sender'] is Map ? Map<String, dynamic>.from(msg['sender'] as Map) : null;
            final senderUsername = sender?['username']?.toString() ?? '';
            final senderEmail = sender?['email']?.toString() ?? '';
            final senderFirstName = sender?['first_name']?.toString() ?? '';
            final senderLastName = sender?['last_name']?.toString() ?? '';
            final senderName = '$senderFirstName $senderLastName'.trim();
            
            final isTeacher = senderUsername == _teacherUsername || 
                             senderEmail == _teacherUsername ||
                             senderName == _teacherUsername ||
                             (widget.contact['user'] != null && 
                              (widget.contact['user'] is Map && 
                               (Map<String, dynamic>.from(widget.contact['user'] as Map))['username']?.toString() == senderUsername));
            
            final messageText = msg['message_text']?.toString() ?? 
                               msg['message']?.toString() ?? 
                               msg['subject']?.toString() ?? '';
            
            final messageId = msg['message_id']?.toString() ?? 
                             msg['id']?.toString() ?? 
                             DateTime.now().toUtc().millisecondsSinceEpoch.toString();
            
            return Map<String, dynamic>.from({
              'text': messageText,
              'isTeacher': isTeacher,
              'time': _formatMessageTime(msg['created_at']?.toString()),
              'message_id': messageId,
              'is_read': msg['is_read'] ?? false,
              'timestamp': msg['created_at']?.toString() ?? DateTime.now().toUtc().toIso8601String(),
              'attachment_url': msg['attachment_url'],
            });
          }).toList().reversed.toList();
          
          // Merge history safely
          // 1. Identify existing IDs
          final existingIds = _messages.map((m) => m['message_id']?.toString()).toSet();
          
          // 2. Identify text of outgoing messages in history
          final historySentTexts = history.where((h) => !(h['isTeacher'] as bool)).map((h) => h['text'] as String).toSet();
          
          // 3. Remove temp messages matched in history
          _messages.removeWhere((m) => m['message_id']?.toString().startsWith('temp_') == true && historySentTexts.contains(m['text']));
          
          // 4. Add only new messages from history
          for (final msg in history) {
            if (!existingIds.contains(msg['message_id']?.toString())) {
               _messages.add(msg);
               existingIds.add(msg['message_id']?.toString());
            }
          }
          
          // 5. Sort and ID sync
          _messages.sort((a, b) {
            final tA = a['timestamp']?.toString() ?? '';
            final tB = b['timestamp']?.toString() ?? '';
            return tA.compareTo(tB);
          });
          
          _messageIds.clear();
          _messageIds.addAll(_messages.map((m) => m['message_id'].toString()));
          
          _isLoadingMessages = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Failed to load existing messages: $e');
      // Fallback to old Communication API if ChatMessage API fails
      try {
        debugPrint('Falling back to Communication API...');
        final messages = await api.ApiService.fetchCommunications(_studentEmail!, _teacherEmail!);
        debugPrint('Loaded ${messages.length} messages from Communication API (fallback)');
        
        setState(() {
          // Clear existing messages and message IDs to prevent duplicates
          _messages.clear();
          _messageIds.clear();
          
          _messages = messages.map((msg) {
            final sender = msg['sender'] is Map ? Map<String, dynamic>.from(msg['sender'] as Map) : null;
            final senderUsername = sender?['username']?.toString() ?? '';
            final senderEmail = sender?['email']?.toString() ?? '';
            final senderFirstName = sender?['first_name']?.toString() ?? '';
            final senderLastName = sender?['last_name']?.toString() ?? '';
            final senderName = '$senderFirstName $senderLastName'.trim();
            
            final isTeacher = senderUsername == _teacherUsername || 
                             senderEmail == _teacherUsername ||
                             senderName == _teacherUsername ||
                             (widget.contact['user'] != null && 
                              (widget.contact['user'] is Map && 
                               (Map<String, dynamic>.from(widget.contact['user'] as Map))['username']?.toString() == senderUsername));
            
            final messageId = msg['message_id']?.toString() ?? 
                             msg['id']?.toString() ?? 
                             DateTime.now().millisecondsSinceEpoch.toString();
            
            _messageIds.add(messageId);
            
            return Map<String, dynamic>.from({
              'text': msg['message']?.toString() ?? msg['subject']?.toString() ?? '',
              'isTeacher': isTeacher,
              'time': _formatMessageTime(msg['created_at']?.toString()),
              'message_id': messageId,
              'timestamp': msg['created_at']?.toString() ?? DateTime.now().toUtc().toIso8601String(),
            });
          }).toList();
        });
      } catch (fallbackError) {
        debugPrint('Fallback also failed: $fallbackError');
      }
    }
  }

  String _formatMessageTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) {
      return intl.DateFormat('h:mm a').format(DateTime.now());
    }
    try {
      // Ensure timestamp is treated as UTC
      String timeToParse = timeStr;
      if (!timeStr.endsWith('Z') && !timeStr.contains('+')) {
        timeToParse += 'Z';
      }
      final dateTime = DateTime.parse(timeToParse).toLocal();
      return intl.DateFormat('h:mm a').format(dateTime);
    } catch (e) {
      return intl.DateFormat('h:mm a').format(DateTime.now());
    }
  }

  Future<void> _initializeRealtimeChat() async {
    if (_chatRoomId == null || _studentUsername == null || _teacherUsername == null) return;
    
    try {
      debugPrint('=== ${widget.isGroup ? "Group" : "Student"} Chat Connection ===');
      debugPrint('Room ID: $_chatRoomId');
      debugPrint('Sender: $_studentUsername');
      debugPrint('Chat type: ${widget.isGroup ? "group" : "teacher-student"}');
      
      _chatService = RealtimeChatService(baseWsUrl: 'ws://localhost:8000'); // Use localhost for web
      await _chatService!.connect(
        roomId: _chatRoomId!, 
        chatType: widget.isGroup ? 'group' : 'teacher-student'
      );
      _chatSubscription = _chatService!.stream?.listen((event) {
        try {
          final payload = event is String ? event : event.toString();
          final decoded = jsonDecode(payload) as Map<String, dynamic>;
          
          final messageType = decoded['type']?.toString() ?? 'message';
          
          // Handle connection messages
          if (messageType == 'connection') {
            debugPrint('Connected to chat: ${decoded['user']}');
            return;
          }
          
          // Only process actual messages
          if (messageType == 'message') {
            final messageText = decoded['message']?.toString() ?? '';
            if (messageText.isEmpty) return;
            
            final sender = decoded['sender']?.toString() ?? '';
            
            // Determine if sender is teacher by comparing with teacher's username/email
            final teacherUser = widget.contact['user'] as Map<String, dynamic>?;
            final teacherUsername = teacherUser?['username']?.toString() ?? '';
            final teacherEmail = teacherUser?['email']?.toString() ?? '';
            final teacherName = widget.contact['name']?.toString() ?? '';
            
            // Get sender and recipient IDs for proper filtering
            final senderUsername = decoded['sender_username']?.toString() ?? sender;
            final senderId = decoded['sender_id']?.toString() ?? '';
            final recipient = decoded['recipient']?.toString() ?? '';
            final recipientId = decoded['recipient_id']?.toString() ?? '';
            final timestamp = decoded['timestamp']?.toString() ?? DateTime.now().toUtc().toIso8601String();
            
            // Normalize names for better matching
            final normalizedTeacherName = normalizeNameForRoomId(teacherName);
            final normalizedStudentName = normalizeNameForRoomId(_studentUsername ?? '');
            final normalizedSender = normalizeNameForRoomId(sender);
            final normalizedRecipient = normalizeNameForRoomId(recipient);
            
            // IMPORTANT: Only process messages for the current conversation
            // Check if this message is between the current student and the teacher
            // More lenient matching to catch all variations
            
            // Check if sender is teacher (multiple ways to match)
            final isFromCurrentTeacher = (
              senderUsername == teacherUsername ||
              senderUsername == teacherEmail ||
              sender == teacherUsername ||
              sender == teacherEmail ||
              sender == teacherName ||
              normalizedSender == normalizedTeacherName ||
              sender == _teacherUsername ||
              senderId == teacherUser?['user_id']?.toString() ||
              (teacherName.isNotEmpty && sender.toLowerCase().contains(teacherName.toLowerCase())) ||
              (teacherName.isNotEmpty && normalizedSender.contains(normalizedTeacherName))
            );
            
            // Check if recipient is teacher
            final isToCurrentTeacher = (
              recipient == teacherUsername ||
              recipient == teacherEmail ||
              recipient == teacherName ||
              normalizedRecipient == normalizedTeacherName ||
              recipient == _teacherUsername ||
              recipientId == teacherUser?['user_id']?.toString() ||
              (teacherName.isNotEmpty && recipient.toLowerCase().contains(teacherName.toLowerCase()))
            );
            
            // Check if sender is student (multiple ways to match)
            final isFromCurrentStudent = (
              senderUsername == _studentEmail ||
              senderUsername == _studentUsername ||
              sender == _studentEmail ||
              sender == _studentUsername ||
              normalizedSender == normalizedStudentName ||
              (normalizedStudentName.isNotEmpty && normalizedSender.contains(normalizedStudentName))
            );
            
            // Check if recipient is student (multiple ways to match)
            final isToCurrentStudent = (
              recipient == _studentEmail ||
              recipient == _studentUsername ||
              normalizedRecipient == normalizedStudentName ||
              (normalizedStudentName.isNotEmpty && normalizedRecipient.contains(normalizedStudentName))
            );
            
            // Message is for this conversation if:
            // 1. From teacher to student, OR
            // 2. From student to teacher
            final isForThisConversation = (
              (isFromCurrentTeacher && isToCurrentStudent) ||
              (isFromCurrentStudent && isToCurrentTeacher)
            );
            
            debugPrint('=== Message Routing Check ===');
            debugPrint('Sender: $sender (username: $senderUsername, normalized: $normalizedSender)');
            debugPrint('Recipient: $recipient (normalized: $normalizedRecipient)');
            debugPrint('Teacher: $teacherName (username: $teacherUsername, email: $teacherEmail, normalized: $normalizedTeacherName)');
            debugPrint('Student: $_studentUsername (email: $_studentEmail, normalized: $normalizedStudentName)');
            debugPrint('isFromCurrentTeacher: $isFromCurrentTeacher');
            debugPrint('isToCurrentStudent: $isToCurrentStudent');
            debugPrint('isFromCurrentStudent: $isFromCurrentStudent');
            debugPrint('isToCurrentTeacher: $isToCurrentTeacher');
            debugPrint('isForThisConversation: $isForThisConversation');
            
            if (!isForThisConversation) {
              debugPrint('⚠️ Ignoring message not for this conversation');
              return;
            }
            
            debugPrint('✓ Message is for this conversation - processing...');
            
            // Determine if sender is teacher
            final isTeacher = isFromCurrentTeacher;
            
            debugPrint('Received message from: $sender (isTeacher: $isTeacher, message: $messageText)');
            
            // Check for duplicate messages using message_id (most reliable)
            final messageId = decoded['message_id']?.toString() ?? '';
            
            // Prevent duplicate messages - check both messageId and content
            if (_messageIds.contains(messageId)) {
              debugPrint('Duplicate message ignored (ID): $messageId');
              return;
            }
            
            // Also check for duplicate by content and timestamp (within 2 seconds)
            final isDuplicateContent = _messages.any((msg) {
              if (msg['text'] == messageText && msg['isTeacher'] == isTeacher) {
                try {
                  final msgTimestamp = msg['timestamp']?.toString() ?? msg['time']?.toString() ?? '';
                  if (msgTimestamp.isNotEmpty) {
                    final msgTime = DateTime.tryParse(msgTimestamp) ?? 
                                   (msg['time'] != null ? DateTime.tryParse(msg['time']) : null);
                    final newTime = DateTime.tryParse(timestamp);
                    if (msgTime != null && newTime != null) {
                      final diff = newTime.difference(msgTime).abs();
                      if (diff.inSeconds < 2) {
                        return true;
                      }
                    } else if (msgTimestamp == timestamp) {
                      return true;
                    }
                  }
                } catch (e) {
                  // If timestamp parsing fails, just check text
                  return true;
                }
              }
              return false;
            });
            
            if (isDuplicateContent) {
              debugPrint('Duplicate message ignored (content): $messageText');
              return;
            }
            
            // If message is from teacher and we have a temp message with same text, update it
            if (isTeacher && messageId.isNotEmpty) {
              final now = DateTime.now();
              final existingIndex = _messages.lastIndexWhere((msg) {
                if (msg['isTeacher'] != false || msg['text'] != messageText) return false;
                if (msg['message_id']?.toString().startsWith('temp_') == true) {
                  try {
                    final msgTimestamp = msg['timestamp']?.toString() ?? '';
                    if (msgTimestamp.isNotEmpty) {
                      final msgTime = DateTime.tryParse(msgTimestamp);
                      if (msgTime != null) {
                        final diff = now.difference(msgTime).abs();
                        return diff.inSeconds < 5;
                      }
                    }
                  } catch (e) {
                    return false;
                  }
                }
                return false;
              });
              
              if (existingIndex != -1) {
                // Update existing temp message with real ID
                setState(() {
                  _messages[existingIndex] = Map<String, dynamic>.from({
                    'text': messageText,
                    'isTeacher': isTeacher,
                    'time': _formatMessageTime(timestamp),
                    'isSent': !isTeacher,
                    'message_id': messageId,
                    'timestamp': timestamp,
                    'attachment_url': decoded['attachment_url'],
                  });
                  _messageIds.add(messageId);
                });
                debugPrint('Updated temp message with real ID: $messageId');
                return;
              }
            }
            
            // Check if message with this ID already exists
            final alreadyExists = _messages.any((msg) => msg['message_id'] == messageId);
            if (!alreadyExists) {
              setState(() {
                _messageIds.add(messageId.isNotEmpty ? messageId : DateTime.now().millisecondsSinceEpoch.toString());
                _messages.add(Map<String, dynamic>.from({
                  'text': messageText,
                  'isTeacher': isTeacher,
                  'time': _formatMessageTime(timestamp),
                  'isSent': !isTeacher, // Received messages from teacher are not sent by student
                  'message_id': messageId.isNotEmpty ? messageId : DateTime.now().millisecondsSinceEpoch.toString(),
                  'timestamp': timestamp,
                  'attachment_url': decoded['attachment_url'],
                }));
              });
              _scrollToBottom();
              debugPrint('Added new message to list (total: ${_messages.length})');
              
              // Update the home screen's chat list
              widget.onLastMessageUpdate?.call(
                widget.contact['name'] ?? (widget.isGroup ? 'Group' : 'Teacher'),
                messageText,
                timestamp,
                !isTeacher, // isSentByMe
                false, // isRead
              );
              // Update unread count if message is from teacher (when chat is open, it's already read)
              // Note: Unread count is managed by parent widget, so we don't need to track it here
              // The parent widget will handle unread counts when chat is not open
            } else {
              debugPrint('Duplicate message ignored (ID: $messageId, text: $messageText)');
            }
            if (messageType == 'group_removal') {
              final rid = decoded['group_id']?.toString();
              if (rid == (widget.contact['id']?.toString() ?? widget.contact['group_id']?.toString())) {
                if (mounted) {
                  setState(() {
                    _isRemovedFromGroup = true;
                    _groupRemovalMessage = decoded['message'] ?? 'You have been removed from this group';
                  });
                }
              }
              return;
            }
            debugPrint('Chat error: ${decoded['message']}');
          }
        } catch (error) {
          debugPrint('Realtime chat parse error: $error');
        }
      });
    } catch (e) {
      debugPrint('Failed to initialize realtime chat: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF667eea),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            // Profile picture
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              child: Text(
                widget.contact['avatar'] ?? (widget.isGroup ? '👥' : 'T'),
                style: const TextStyle(
                  color: Color(0xFF667eea),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.contact['name'] ?? (widget.isGroup ? 'Group' : 'Teacher'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.contact['subject'] ?? (widget.isGroup ? 'Group Chat' : 'Teacher'),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Info icon for groups
            if (widget.isGroup)
            IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.white),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => GroupInfoDialog(
                    groupId: widget.contact['id']?.toString() ?? '',
                    groupName: widget.contact['name'] ?? 'Group Info',
                    onNameUpdated: (newName) {
                      // Logic to update name in parent if needed
                    },
                    isReadOnly: true,
                  ),
                );
              },
            ),
            // Three dots menu
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: () {
                // Add menu functionality here
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: (_isLoadingMessages && _messages.isEmpty)
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Container(
                        color: Colors.grey[100],
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No messages yet',
                                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start the conversation!',
                                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[100],
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            final bool showDateHeader = index == 0 || !_isSameDay(_messages[index - 1]['timestamp'] ?? '', message['timestamp'] ?? '');
                            
                            if (showDateHeader) {
                              return Column(
                                children: [
                                  _buildDateSeparator(message['timestamp'] ?? ''),
                                  _buildMessage(message),
                                ],
                              );
                            }
                            return _buildMessage(message);
                          },
                        ),
                      ),
          ),
          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -2),
                  blurRadius: 5,
                ),
              ],
            ),
            child: _isRemovedFromGroup
              ? Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border(top: BorderSide(color: Colors.red[100]!)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _groupRemovalMessage ?? 'You are no longer a participant in this group',
                          style: TextStyle(color: Colors.red[700], fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_selectedFileNames.isNotEmpty)
                  Container(
                    height: 50,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedFileNames.length,
                      itemBuilder: (context, index) {
                        final name = _selectedFileNames[index];
                        final isImage = name.toLowerCase().endsWith('.jpg') || 
                                        name.toLowerCase().endsWith('.jpeg') || 
                                        name.toLowerCase().endsWith('.png');
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(isImage ? Icons.image : Icons.attach_file, 
                                   size: 16, color: const Color(0xFF667eea)),
                              const SizedBox(width: 4),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 120),
                                child: Text(
                                  name,
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () => _removeAttachment(index),
                                child: const Icon(Icons.close, size: 16, color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.attach_file, color: Colors.grey),
                      onPressed: _pickAttachment,
                    ),
                    IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.grey),
                      onPressed: _openCamera,
                      tooltip: 'Camera',
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: _selectedFileNames.isNotEmpty ? 'Add a caption...' : 'Type a message...',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            hintStyle: TextStyle(color: Colors.grey[500]),
                          ),
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Send button
                    Container(
                      decoration: BoxDecoration(
                        color: _isTextFieldEmpty ? Colors.grey : const Color(0xFF667eea),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _isTextFieldEmpty ? null : _sendMessage,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(String timestamp) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE1F5FE),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            _formatChatHeaderDate(timestamp),
            style: const TextStyle(
              color: Color(0xFF0288D1),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }


  Future<void> _downloadAttachment(String? urlStr, String? name) async {
    if (urlStr == null || urlStr.isEmpty) return;
    
    final url = urlStr;
    final fileName = name ?? url.split('/').last;

    if (!url.startsWith('http')) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('File is local'),
        duration: Duration(seconds: 1),
      ));
      return;
    }
    
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
         final downloadDir = await getDownloadsDirectory();
         if (downloadDir != null) {
           final savePath = '${downloadDir.path}\\$fileName';
           if (File(savePath).existsSync()) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('File exists: $savePath')));
              await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication); 
             return; 
           }
           
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloading...')));
           await Dio().download(url, savePath);
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to $savePath')));
           await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
         } else {
           await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
         }
      } else {
        if (['.jpg', '.jpeg', '.png'].any((ext) => url.toLowerCase().endsWith(ext))) {
           var response = await Dio().get(url, options: Options(responseType: ResponseType.bytes));
           final result = await ImageGallerySaver.saveImage(
             Uint8List.fromList(response.data),
             quality: 100, 
             name: fileName
           );
           if (result != null && result['isSuccess']) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image saved to Gallery')));
           }
        } else {
           if (await canLaunchUrl(Uri.parse(url))) {
             await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
           }
        }
      }
    } catch (e) {
      debugPrint('Download error: $e');
       try {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } catch (e2) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Download failed: $e')));
      }
    }
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    final String text = message['text'] ?? '';
    final bool isTeacher = message['isTeacher'] ?? false;
    final String time = message['time'] ?? '';
    final bool isRead = message['is_read'] == true;
    final String? attachmentUrl = message['attachment_url'] ?? message['attachment'];
    final String? attachmentName = message['attachment_name'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isTeacher ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Profile picture for received messages (left side)
          if (isTeacher) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: Text(
                widget.contact['avatar'] ?? (widget.isGroup ? '👥' : 'T'),
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Message bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.65,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isTeacher 
                    ? Colors.white
                    : const Color(0xFFD9FDD3), // Light green for sender
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isTeacher ? 4 : 18),
                  bottomRight: Radius.circular(isTeacher ? 18 : 4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (attachmentUrl != null)
                    (attachmentUrl.toLowerCase().endsWith('.jpg') ||
                            attachmentUrl.toLowerCase().endsWith('.png') ||
                            attachmentUrl.toLowerCase().endsWith('.jpeg'))
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: GestureDetector(
                              onTap: () => _downloadAttachment(
                                  attachmentUrl, attachmentName),
                              child: attachmentUrl.startsWith('http')
                                  ? Image.network(
                                      attachmentUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          height: 100,
                                          width: 100,
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.broken_image,
                                              size: 50, color: Colors.red),
                                        );
                                      },
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          height: 150,
                                          width: 150,
                                          alignment: Alignment.center,
                                          child: CircularProgressIndicator(
                                            value: loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                                : null,
                                          ),
                                        );
                                      },
                                    )
                                  : Image.file(
                                      File(attachmentUrl),
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(Icons.broken_image,
                                                  size: 50),
                                    ),
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.insert_drive_file, size: 20),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    attachmentName ?? 'Document',
                                    style: const TextStyle(fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  if (attachmentUrl != null && text.isNotEmpty)
                    const SizedBox(height: 8),
                  if (text.isNotEmpty)
                    Text(
                      text,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        time,
                        style: TextStyle(
                          color: isTeacher ? Colors.grey[600] : Colors.black54,
                          fontSize: 11,
                        ),
                      ),
                      if (!isTeacher) ...[
                        const SizedBox(width: 4),
                        Icon(
                          isRead ? Icons.done_all : Icons.done,
                          size: 14,
                          color: isRead ? const Color(0xFF34B7F1) : Colors.black54,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

// -------------------------------------------------------------------------
// Group Info Dialog
// -------------------------------------------------------------------------

class GroupInfoDialog extends StatefulWidget {
  final String groupId;
  final String groupName;
  final Function(String) onNameUpdated;
  final bool isReadOnly;

  const GroupInfoDialog({
    Key? key,
    required this.groupId,
    required this.groupName,
    required this.onNameUpdated,
    this.isReadOnly = false,
  }) : super(key: key);

  @override
  State<GroupInfoDialog> createState() => _GroupInfoDialogState();
}

class _GroupInfoDialogState extends State<GroupInfoDialog> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _members = [];
  String _currentName = '';

  @override
  void initState() {
    super.initState();
    _currentName = widget.groupName;
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    setState(() => _isLoading = true);
    try {
      final data = await api.ApiService.getGroupMembers(widget.groupId);
      if (data.isNotEmpty) {
        setState(() {
          _members = List<Map<String, dynamic>>.from(data['members'] ?? []);
          _currentName = data['group_name'] ?? _currentName;
        });
      }
    } catch (e) {
      debugPrint('Error fetching group members: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        height: 600,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Group Info',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF667eea),
                    child: const Icon(Icons.group, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_members.length} participants',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Participants',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF667eea),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _members.length,
                      itemBuilder: (context, index) {
                        final member = _members[index];
                        final name = member['full_name'] ?? member['username'];
                        final className = member['class_name'];
                        final section = member['section'];
                        final grade = member['grade'];
                        
                        String sub = '';
                        if (className != null && className.toString().toLowerCase() != 'null') {
                          sub = 'Class $className';
                          if (section != null && section.toString().toLowerCase() != 'null') sub += '-$section';
                        }
                        if (grade != null && grade.toString().toLowerCase() != 'null') {
                          if (sub.isNotEmpty) sub += ' • ';
                          sub += 'Grade $grade';
                        }
                        
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey[300],
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(color: Colors.black87),
                            ),
                          ),
                          title: Text(name),
                          subtitle: sub.isNotEmpty ? Text(sub) : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

String formatChatTime(String timestamp) {
  if (timestamp.isEmpty) return '';
  try {
    String timeToParse = timestamp;
    
    final dt = DateTime.parse(timeToParse).toLocal();
    final now = DateTime.now();
    
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(dt.year, dt.month, dt.day);

    if (msgDate == today) {
      return intl.DateFormat('h:mm a').format(dt);
    } else if (msgDate == yesterday) {
      return 'Yesterday';
    } else if (today.difference(msgDate).inDays < 7) {
      return intl.DateFormat('EEEE').format(dt);
    } else {
      return intl.DateFormat('MMM d').format(dt);
    }
  } catch (e) {
    return timestamp;
  }
}

bool _isSameDay(String ts1, String ts2) {
  try {
    String timeToParse1 = ts1;
    
    String timeToParse2 = ts2;
    
    
    final d1 = DateTime.parse(timeToParse1).toLocal();
    final d2 = DateTime.parse(timeToParse2).toLocal();
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  } catch (_) {
    return false;
  }
}

String _formatChatHeaderDate(String timestamp) {
  if (timestamp.isEmpty) return '';
  try {
    String timeToParse = timestamp;
    
    final dt = DateTime.parse(timeToParse).toLocal();
    final now = DateTime.now();
    
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(dt.year, dt.month, dt.day);

    if (msgDate == today) {
      return 'Today';
    } else if (msgDate == yesterday) {
      return 'Yesterday';
    } else {
      return intl.DateFormat('MMMM d, yyyy').format(dt);
    }
  } catch (e) {
    return timestamp;
  }
}

class DayDetailsDialog extends StatefulWidget {
  final DateTime date;
  final String? studentId;
  final String dateString;
  final bool isPresent;
  final bool isAbsent;

  const DayDetailsDialog({
    super.key,
    required this.date,
    this.studentId,
    required this.dateString,
    this.isPresent = false,
    this.isAbsent = false,
  });

  @override
  State<DayDetailsDialog> createState() => _DayDetailsDialogState();
}

class _DayDetailsDialogState extends State<DayDetailsDialog> {
  bool _isLoading = true;
  List<dynamic> _exams = [];
  List<dynamic> _events = [];

  @override
  void initState() {
    super.initState();
    _fetchDayData();
  }

  Future<void> _fetchDayData() async {
    try {
      final exams = await api.ApiService.fetchStudentExams(
        studentId: widget.studentId,
      );
      
      // Filter exams for the specific date
      final targetDateStr = intl.DateFormat('yyyy-MM-dd').format(widget.date);
      final dayExams = exams?.where((e) => e['date'] == targetDateStr).toList() ?? [];

      // Fetch events (mock or real)
      final allEvents = await api.ApiService.fetchAllEvents(
        studentId: widget.studentId,
      );
      final dayEvents = allEvents?.where((e) {
        final eventDate = e['date'] ?? e['start_date'] ?? '';
        return eventDate.toString().startsWith(targetDateStr);
      }).toList() ?? [];

      if (mounted) {
        setState(() {
          _exams = dayExams;
          _events = dayEvents;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching day details: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.dateString),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAttendanceSection(),
              const Divider(),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                _buildListSection('📝 Exams', _exams, 'No exams scheduled'),
                const SizedBox(height: 10),
                _buildListSection('🌟 Events', _events, 'No events today'),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildAttendanceSection() {
    String status = 'No Record';
    Color color = Colors.grey;
    if (widget.isPresent) {
      status = 'Present';
      color = Colors.green;
    } else if (widget.isAbsent) {
      status = 'Absent';
      color = Colors.red;
    }
    return Row(
      children: [
        const Text('Attendance: ', style: TextStyle(fontWeight: FontWeight.bold)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildListSection(String title, List<dynamic> items, String emptyMsg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 5),
        if (items.isEmpty)
          Text(emptyMsg, style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
        else
          ...items.map((item) => Card(
            margin: const EdgeInsets.only(bottom: 4),
            child: ListTile(
              dense: true,
              title: Text(item['title'] ?? item['subject'] ?? item['name'] ?? 'Detail'),
              subtitle: Text(item['description'] ?? item['time'] ?? ''),
            ),
          )),
      ],
    );
  }
}

