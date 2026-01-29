import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'services/download_service.dart';
import 'package:core/api/auth_service.dart';
import 'package:main_login/main.dart' as main_login;
import 'services/api_service.dart' as api;
import 'package:url_launcher/url_launcher.dart';
import 'package:core/api/auth_service.dart';

// --- UTILITY FUNCTION TO CREATE CUSTOM MATERIAL COLOR ---
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

void main() {
  runApp(const SchoolManagementSystemApp());
}

// -------------------------------------------------------------------------
// 2. THEME AND APP CONTAINER
// -------------------------------------------------------------------------

class SchoolManagementSystemApp extends StatelessWidget {
  const SchoolManagementSystemApp({super.key});

  // Define the custom colors based on the image
  static const Color primaryPurple = Color(0xFF667eea);
  static const Color accentAmber = Color(0xFFFFC107);
  static const Color lightBackground = Color(0xFFF8F9FA);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Academic Calendar - School Management App',
      theme: ThemeData(
        primarySwatch: createMaterialColor(primaryPurple),
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
      home: const StudentProfilePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// -------------------------------------------------------------------------
// 3. DATA MODELS
// -------------------------------------------------------------------------

class StudentData {
  final String name;
  final int? dbId; // Added to store the database PK
  final String id;
  final String grade;
  final String section;
  final String rollNumber;
  final String dob;
  final String age;
  final String gender;
  final String admissionNo;
  final String attendanceRate;
  final String gpa;
  final String classRank;
  final String achievementsCount;
  final String fatherName;
  final String motherName;
  final String phoneNumber;
  final String email;
  final String address;
  final String city;
  final String state;
  final String postalCode;
  final String bloodGroup;
  final String transportMode;
  final String nationality;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String medicalInfo;
  
  // Fees Details
  final double totalFeeAmount;
  final double paidFeeAmount;
  final double dueFeeAmount;
  final String feeStatus;

  // Academics Details
  final String overallScore;
  final String subjects;
  final String performance;
  final String lastExam;

  // Extracurricular Details
  final String extracurricularActivities;
  final String extracurricularLeadership;
  final String extracurricularAchievements;
  final String extracurricularParticipation;

  final List<Map<String, String>> achievementsList;
  final List<Map<String, String>> currentSubjects;
  final List<Map<String, dynamic>> awards;
  final String activities;
  final String leadership;
  final String participation;
  final String otherAchievements;
  final String? profilePhotoUrl;


  StudentData.mock()
    : name = 'John Michael Smith',
      dbId = 0,
      id = 'STU-2024-001',
      grade = 'Class 9',
      section = 'Section A',
      rollNumber = '25',
      dob = 'March 15, 2010',
      age = '14 years',
      gender = 'Male',
      admissionNo = 'ADM-2020-42',
      attendanceRate = '95%',
      gpa = '3.8',
      classRank = '5',
      achievementsCount = '12',
      fatherName = "Michael Smith",
      motherName = "Sarah Smith",
      phoneNumber = "+1 (555) 123-4567",
      email = "smith.family@email.com",
      address = "123 Education Street",
      city = "Learning City",
      state = "Knowledge State",
      postalCode = "12345",
      bloodGroup = "O+",
      transportMode = "School Bus",
      nationality = "Indian",
      emergencyContactName = "Aunt Jane Doe",
      emergencyContactPhone = "+1 (555) 987-6543",
      medicalInfo = "None",
      totalFeeAmount = 50000,
      paidFeeAmount = 30000,
      dueFeeAmount = 20000,
      feeStatus = "Due: ₹20000",
      overallScore = "85%",
      subjects = "Math, Science",
      performance = "Good",
      lastExam = "Midterm",
      extracurricularActivities = "Basketball",
      extracurricularLeadership = "Captain",
      extracurricularAchievements = "Winner",
      extracurricularParticipation = "Active",
      currentSubjects = [
        {'subject': 'Mathematics', 'teacher': 'Mrs. K. Sharma'},
        {'subject': 'Science', 'teacher': 'Mr. D. Patel'},
        {'subject': 'English Lit.', 'teacher': 'Ms. A. Singh'},
        {'subject': 'World History', 'teacher': 'Dr. J. Khan'},
      ],
      achievementsList = [
        {
          'title': 'Academic Excellence Award',
          'date': '2024',
          'description': 'Outstanding performance in Mathematics and Science',
        },
        {
          'title': 'Sports Champion',
          'date': '2023',
          'description': 'First place in inter-school basketball tournament',
        },
        {
          'title': 'Science Fair Winner',
          'date': '2023',
          'description': 'Best project award for renewable energy model',
        },
      ],
      awards = [],
      activities = '',
      leadership = '',
      participation = '',
      otherAchievements = '',
      profilePhotoUrl = null;


  // Constructor to create StudentData from API response
  // studentJson: The basic profile info (likely from student-profile endpoint)
  // detailedJson: The full details from management API (fetchStudentById)
  StudentData.fromJson(Map<String, dynamic> studentJson, Map<String, dynamic> detailedJson)
      : name = _getFullName(studentJson),
        dbId = studentJson['id'] as int?,
        id = _safeString(studentJson['student_id']),
        grade = _safeString(studentJson['class_name']),
        section = _safeString(studentJson['section']),
        rollNumber = _safeString(studentJson['student_id']),
        dob = _formatDate(_safeString(studentJson['date_of_birth'])),
        age = _calculateAge(_safeString(studentJson['date_of_birth'])),
        gender = _safeString(studentJson['gender']),
        admissionNo = _safeString(studentJson['student_id']),
        attendanceRate = '0%', // TODO: Calculate from attendance data
        gpa = '0.0', // TODO: Calculate from grades
        classRank = '0', // TODO: Calculate from class data
        fatherName = _safeString(studentJson['parent_name']),
        motherName = '', // Not available in current schema
        phoneNumber = _safeString(studentJson['parent_phone']),
        email = _getEmail(studentJson),
        address = _safeString(studentJson['address']),
        city = '', // Extract from address if needed
        state = '', // Extract from address if needed
        postalCode = '', // Extract from address if needed
        bloodGroup = _safeString(studentJson['blood_group']),
        transportMode = _safeString(studentJson['bus_route']).isNotEmpty ? _safeString(studentJson['bus_route']) : 'N/A',
        nationality = 'Indian', // Default
        emergencyContactName = _safeString(studentJson['emergency_contact']),
        emergencyContactPhone = '', // Not available in current schema
        // Detailed fields from management API (or fallbacks)
        medicalInfo = _safeString(detailedJson['medical_information'] ?? studentJson['medical_information']),
        
        // Fees
        totalFeeAmount = (detailedJson['total_fee_amount'] as num?)?.toDouble() ?? 0.0,
        paidFeeAmount = (detailedJson['paid_fee_amount'] as num?)?.toDouble() ?? 0.0,
        dueFeeAmount = (detailedJson['due_fee_amount'] as num?)?.toDouble() ?? 0.0,
        feeStatus = _calculateFeeStatus(detailedJson),

        // Academics (placeholder logic or parsing if available)
        overallScore = '0%', // Placeholder
        subjects = '',
        performance = '',
        lastExam = '',

        // Extracurricular
        extracurricularActivities = '',
        extracurricularLeadership = '',
        extracurricularAchievements = '',
        extracurricularParticipation = '',



        currentSubjects = _parseStudentClasses(studentJson['student_classes']), 
        awards = List<Map<String, dynamic>>.from(studentJson['awards'] ?? []),
        achievementsList = _parseAwardsToAchievements(studentJson['awards']),
        achievementsCount = (studentJson['awards'] as List?)?.length.toString() ?? '0',
        activities = _safeString(studentJson['activities']),
        leadership = _safeString(studentJson['leadership']),
        participation = _safeString(studentJson['participation']),
        otherAchievements = _safeString(studentJson['achievements']),
        profilePhotoUrl = _safeString(studentJson['profile_photo_url']).isNotEmpty 
            ? _safeString(studentJson['profile_photo_url']) 
            : (_safeString(studentJson['profile_photo']).isNotEmpty ? _safeString(studentJson['profile_photo']) : null);

  static List<Map<String, String>> _parseStudentClasses(dynamic classesJson) {
     if (classesJson == null || classesJson is! List) return [];
     return classesJson.map((c) {
       if (c is! Map) return {'subject': '', 'teacher': ''};
       return {
         'subject': _safeString(c['subject_name']),
         'teacher': c['teacher_name']?.toString() ?? 'TBA',
       };
     }).toList().cast<Map<String, String>>();
  }

  static String _calculateFeeStatus(Map<String, dynamic> json) {
    final due = (json['due_fee_amount'] as num?)?.toDouble() ?? 0.0;
    if (due > 0) return 'Due: ₹${due.toStringAsFixed(2)}';
    return 'Fees Paid';
  }

  static List<Map<String, String>> _parseAwardsToAchievements(dynamic awardsJson) {
    if (awardsJson == null || awardsJson is! List) return [];
    return awardsJson.map((award) {
      if (award is! Map) return {'title': '', 'date': '', 'description': ''};
      return {
        'title': _safeString(award['title']),
        'date': _safeString(award['date']),
        'description': '${_safeString(award['category'])} - ${_safeString(award['level'])}\n${_safeString(award['description'])}',
      };
    }).toList().cast<Map<String, String>>();
  }

  static List<Map<String, dynamic>> _getSortedAwards(dynamic awardsJson) {
    if (awardsJson == null || awardsJson is! List) return [];
    final list = List<Map<String, dynamic>>.from(awardsJson);
    
    list.sort((a, b) {
      // Primary: ID (Latest addition)
      final idA = int.tryParse(a['id']?.toString() ?? '0') ?? 0;
      final idB = int.tryParse(b['id']?.toString() ?? '0') ?? 0;
      if (idB != idA) return idB.compareTo(idA);
      
      // Secondary: Date
      final dateA = a['date']?.toString() ?? '';
      final dateB = b['date']?.toString() ?? '';
      return dateB.compareTo(dateA);
    });
    
    return list;
  }


  static String _safeString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
  }

  static String _getFullName(Map<String, dynamic> studentJson) {
    try {
      final user = studentJson['user'];
      if (user != null && user is Map) {
        final userMap = user as Map<String, dynamic>;
        final first = _safeString(userMap['first_name']);
        final last = _safeString(userMap['last_name']);
        final fullName = ('$first $last').trim();
        if (fullName.isNotEmpty) {
          return fullName;
        }
      }
      // Fallback for detailed json which might have student_name directly
      if (studentJson['student_name'] != null) {
        return _safeString(studentJson['student_name']);
      }
      final studentId = _safeString(studentJson['student_id']);
      return studentId.isNotEmpty ? studentId : 'Student';
    } catch (e) {
      return 'Student';
    }
  }

  static String _getEmail(Map<String, dynamic> studentJson) {
    // ... existing implementation ...
    try {
      final user = studentJson['user'];
      if (user != null && user is Map) {
        final userMap = user as Map<String, dynamic>;
        return _safeString(userMap['email']);
      }
      return _safeString(studentJson['email']);
    } catch (e) {
      return '';
    }
  }

  static String _formatDate(String? dateStr) {
     if (dateStr == null || dateStr.isEmpty) return '';
    try {
      // Handle "YYYY-MM-DD"
      final date = DateTime.parse(dateStr);
      final months = ['January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  static String _calculateAge(String? dateStr) {
     if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      int age = now.year - date.year;
      if (now.month < date.month || (now.month == date.month && now.day < date.day)) {
        age--;
      }
      return '$age years';
    } catch (e) {
      return '';
    }
  }
}

// -------------------------------------------------------------------------
// 5. GENERIC HELPER METHODS (Static/External)
// -------------------------------------------------------------------------
// ... unchanged ...

// Helper to show snackbar
void _showSnackbar(BuildContext context, String message) {
  if (!context.mounted) return;
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

// In-app certificate viewer (similar to management portal for consistency)
void _showCertificateDialog(BuildContext context, Map<String, dynamic> award, {String? studentId}) {
  String? docUrl;
  
  // 1. Try to find a specific certificate for this student in a team award
  if (studentId != null && award['certificates'] is List) {
    try {
      final certs = award['certificates'] as List;
      final studentCert = certs.firstWhere(
        (c) => c is Map && c['student_id']?.toString() == studentId,
        orElse: () => null,
      );
      if (studentCert != null) {
        docUrl = studentCert['document_url'] ?? studentCert['document'];
      }
    } catch (e) {
      debugPrint("Error finding student specific certificate: $e");
    }
  }

  // 2. Fallback to main award document
  docUrl ??= award['document_url'] ?? award['document'];

  if (docUrl == null || docUrl.toString().isEmpty) {
    _showSnackbar(context, "No certificate document available");
    return;
  }

  // Ensure full URL
  String fullUrl = docUrl.toString();
  if (!fullUrl.startsWith('http')) {
    // If it doesn't start with http, it's a relative path.
    // Try to determine if it needs the /media/ prefix.
    String path = fullUrl;
    if (!path.startsWith('/media/') && !path.startsWith('media/')) {
      path = '/media/${path.startsWith('/') ? path.substring(1) : path}';
    }
    fullUrl = 'http://localhost:8000${path.startsWith('/') ? '' : '/'}$path';
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        "Certificate: ${award['title']}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Image Viewer
              Expanded(
                child: Container(
                  color: Colors.grey[200],
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Center(
                      child: Image.network(
                        fullUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) => Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.broken_image, size: 64, color: Colors.grey),
                            const SizedBox(height: 10),
                            const Text("Could not load certificate image"),
                            TextButton(
                              onPressed: () => launchUrl(Uri.parse(fullUrl)),
                              child: const Text("Open in Browser"),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Footer Actions
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.download, color: Colors.white),
                      label: const Text("Download Certificate", style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF28A745), // Green for download
                      ),
                      onPressed: () async {
                        try {
                          _showSnackbar(context, "Starting download...");
                          final fileName = "Certificate_${award['title']}.png".replaceAll(' ', '_');
                          await DownloadService.downloadCertificate(fullUrl, fileName);
                          _showSnackbar(context, "Download successful!");
                        } catch (e) {
                          _showSnackbar(context, "Download failed: $e");
                        }
                      },
                    ),
                    const SizedBox(width: 10),
                    TextButton.icon(
                      icon: const Icon(Icons.open_in_new),
                      label: const Text("Open in Browser"),
                      onPressed: () => launchUrl(Uri.parse(fullUrl), mode: LaunchMode.externalApplication),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      child: const Text("Close"),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// -------------------------------------------------------------------------
// 4. STUDENT PROFILE PAGE
// -------------------------------------------------------------------------

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  StudentData? _studentData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. Fetch current logged-in student's profile (basic info)
      final basicProfile = await api.ApiService.fetchStudentProfile();
      
      if (basicProfile != null) {
        Map<String, dynamic> detailedInfo = {};
        
        // 2. Try to fetch full details using the ID from basic profile
        if (basicProfile['id'] != null) {
          try {
            // Need to cast to int safely
            final int studentId = basicProfile['id'] is int 
                ? basicProfile['id'] 
                : int.parse(basicProfile['id'].toString());
                
            final fetchedDetails = await api.ApiService.fetchStudentById(studentId);
            if (fetchedDetails != null) {
              detailedInfo = fetchedDetails;
              print('Fetched detailed student info for ID $studentId');
            }
          } catch (e) {
            print('Error fetching detailed student info: $e');
            // Continue with basic info only
          }
        }

        setState(() {
          _studentData = StudentData.fromJson(basicProfile, detailedInfo);
          _isLoading = false;
        });
        return;
      }
      
      setState(() {
        _error = 'No student data found';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load student data: $e';
        _isLoading = false;
      });
    }
  }

  // Generic container for main content blocks (Personal Info, Contact, Achievements)
  Widget _buildInfoContainer(
    BuildContext context,
    Widget title,
    Widget content,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [title, content],
      ),
    );
  }

  Widget _buildProfileSummary(
    BuildContext context,
    StudentData data,
    Color primary,
    Color secondary,
  ) {
    // accentColor extracted from theme if needed for custom styling

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch, // Center for profile photo
        children: [
          // Profile Photo
          GestureDetector(
            onTap: () =>
                _showPictureUpdateModal(context), // 🎯 Linked to update modal
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [primary, secondary]),
              ),
              alignment: Alignment.center,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ClipOval(
                    child: data.profilePhotoUrl != null && data.profilePhotoUrl!.isNotEmpty
                        ? Image.network(
                            data.profilePhotoUrl!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Text(
                              '👨‍🎓',
                              style: TextStyle(fontSize: 40, color: Colors.white),
                            ),
                          )
                        : const Text(
                            '👨‍🎓',
                            style: TextStyle(fontSize: 40, color: Colors.white),
                          ),
                  ),
                  // Edit icon overlay
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.edit, size: 14, color: primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            data.name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          Text(
            data.id,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xff666666), fontSize: 13),
          ),
          const Divider(height: 30),

          // Stats Grid (Horizontal ListView for scrolling stats)
          SizedBox(
            height: 115, // Fixed height for horizontal scrolling
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              children: [
                // Overall GPA (Primary Purple)
                _buildStatCard(
                  Icons.menu_book,
                  data.gpa,
                  'Overall GPA',
                  primary,
                ),
                // Class Rank (Accent Amber/Gold)
                _buildStatCard(
                  Icons.emoji_events,
                  data.classRank,
                  'Class Rank',
                  secondary,
                ),
                // Attendance (Primary Purple)
                _buildStatCard(
                  Icons.show_chart,
                  data.attendanceRate,
                  'Attendance',
                  primary,
                ),
                // Awards (Accent Amber/Gold)
                _buildStatCard(
                  Icons.workspace_premium,
                  data.achievementsCount,
                  'Awards',
                  secondary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Quick Actions
          _buildActionButtons(context, primary, data),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    IconData icon,
    String number,
    String label,
    Color accentColor,
  ) {
    return Container(
      width: 140,
      height: 110, // Matching the requested rectangle look
      margin: const EdgeInsets.only(right: 10),
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
              color: accentColor,
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
                Icon(icon, color: accentColor, size: 28),
                const SizedBox(height: 6),
                Text(
                  number,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
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

  Widget _buildAchievementsSection(BuildContext context, StudentData data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('🏆', 'Achievements & Awards'),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: data.awards.length,
            itemBuilder: (context, index) {
              final award = data.awards[index];
              return _buildDetailedAwardCard(context, award, data.id);
            },
          ),
          if (data.awards.isEmpty && data.achievementsList.isNotEmpty)
             ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data.achievementsList.length,
              itemBuilder: (context, index) {
                final achievement = data.achievementsList[index];
                return GestureDetector(
                  onTap: () => _showAchievementDetailsModal(
                    context,
                    achievement,
                  ), // Modal trigger
                  child: _buildAchievementCard(achievement),
                );
              },
            ),
          if (data.awards.isEmpty && data.achievementsList.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text("No records found", style: TextStyle(color: Colors.grey))),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailedAwardCard(BuildContext context, Map<String, dynamic> award, String studentId) {
    bool hasDoc = award['document'] != null && award['document'].toString().isNotEmpty;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xfff8f9fa),
        borderRadius: BorderRadius.circular(10),
        border: const Border(
          left: BorderSide(color: Color(0xff28a745), width: 4),
        ), // Green border
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  award['title'] ?? 'Award',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  award['level'] ?? 'N/A',
                  style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          Text(
            '${award['date'] ?? 'N/A'} • ${award['category'] ?? 'General'}',
            style: const TextStyle(color: Color(0xff666666), fontSize: 13),
          ),
          if ((award['description'] ?? '').toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                award['description'],
                style: const TextStyle(color: Color(0xff666666), fontSize: 14),
              ),
            ),
          if ((award['presented_by'] ?? '').toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                'Presented by: ${award['presented_by']}',
                style: const TextStyle(color: Color(0xff666666), fontSize: 13, fontStyle: FontStyle.italic),
              ),
            ),
          if (hasDoc) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 32,
              child: TextButton.icon(
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text("View Certificate", style: TextStyle(fontSize: 12)),
                onPressed: () => _showCertificateDialog(context, award, studentId: studentId),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  foregroundColor: Colors.blue[700],
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildAchievementCard(Map<String, String> achievement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xfff8f9fa),
        borderRadius: BorderRadius.circular(10),
        border: const Border(
          left: BorderSide(color: Color(0xff28a745), width: 4),
        ), // Green border
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            achievement['title']!,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          Text(
            achievement['date']!,
            style: const TextStyle(color: Color(0xff666666), fontSize: 13),
          ),
          const SizedBox(height: 5),
          Text(
            achievement['description']!,
            style: const TextStyle(color: Color(0xff666666), fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    Color primary,
    StudentData data,
  ) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () =>
              _showEditProfileModal(context, data), // 🎯 LINKED TO EDIT MODAL
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            minimumSize: const Size(double.infinity, 45),
          ),
          child: const Text(
            'Edit Profile',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 10),
        // 🆕 Download Report button with icon
        ElevatedButton.icon(
          onPressed: () => _showSnackbar(context, "Downloading Report..."),
          icon: const Icon(
            Icons.download_for_offline,
            color: Colors.white,
            size: 20,
          ),
          label: const Text(
            'Download Report',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            minimumSize: const Size(double.infinity, 45),
          ),
        ),
        const SizedBox(height: 10),
        // 🆕 Contact Teacher button with icon
        ElevatedButton.icon(
          onPressed: () => _showSnackbar(context, "Contacting Teacher..."),
          icon: const Icon(Icons.contact_mail, color: Colors.white, size: 20),
          label: const Text(
            'Contact Teacher',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            minimumSize: const Size(double.infinity, 45),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Student Profile',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: primaryColor,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null || _studentData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Student Profile',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: primaryColor,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error ?? 'No student data available',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadStudentData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final data = _studentData!;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Student Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Action Menu Button (replaces direct Logout)
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
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
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Page Header (Now uses external helper)
            _buildPageHeader(context, primaryColor),
            const SizedBox(height: 20),

            // 2. Profile Summary (Photo + SLIDING Stats + Actions)
            _buildProfileSummary(context, data, primaryColor, secondaryColor),
            const SizedBox(height: 20),

            // 3. Personal Information
            _buildInfoContainer(
              context,
              _buildSectionTitle('👤', 'Personal Information'),
              Column(
                children: [
                  _buildInfoCard('Basic Details', [
                    {'label': 'Full Name', 'value': data.name},
                    {'label': 'Date of Birth', 'value': data.dob},
                    {'label': 'Age', 'value': data.age},
                    {'label': 'Gender', 'value': data.gender},
                    {'label': 'Blood Group', 'value': data.bloodGroup},
                    {'label': 'Transport Mode', 'value': data.transportMode},
                    {'label': 'Nationality', 'value': data.nationality},
                  ]),
                  // 🆕 New: Current Subjects List
                  _buildInfoCard(
                    'Current Subjects',
                    data.currentSubjects
                        .map(
                          (s) => {
                            'label': s['subject']!,
                            'value': s['teacher']!,
                          },
                        )
                        .toList(),
                  ),

                  _buildInfoCard('Academic Information', [
                    {'label': 'Class', 'value': data.grade},
                    {'label': 'Section', 'value': data.section},
                    {'label': 'Roll Number', 'value': data.rollNumber},
                    {'label': 'Admission No.', 'value': data.admissionNo},
                  ]),
                  _buildInfoCard('Medical Information', [
                    {'label': 'Medical Notes', 'value': data.medicalInfo},
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 4. Contact Information
            _buildInfoContainer(
              context,
              _buildSectionTitle('📞', 'Contact Information'),
              Column(
                children: [
                  _buildInfoCard("Parent/Guardian Details", [
                    {'label': "Father's Name", 'value': data.fatherName},
                    {'label': "Mother's Name", 'value': data.motherName},
                    {'label': 'Phone Number', 'value': data.phoneNumber},
                    {'label': 'Email', 'value': data.email},
                  ]),
                  // 🆕 Added Emergency Contact
                  _buildInfoCard("Emergency Contact", [
                    {
                      'label': 'Contact Name',
                      'value': data.emergencyContactName,
                    },
                    {'label': 'Phone', 'value': data.emergencyContactPhone},
                  ]),
                  _buildInfoCard("Address", [
                    {'label': 'Address', 'value': data.address},
                    {'label': 'City', 'value': data.city},
                    {'label': 'State', 'value': data.state},
                    {'label': 'Postal Code', 'value': data.postalCode},
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 🆕 Fees Information
            _buildInfoContainer(
              context,
              _buildSectionTitle('💰', 'Fees Information'),
              Column(
                children: [
                  _buildInfoCard('Fee Details', [
                    {'label': 'Total Fees', 'value': '₹${data.totalFeeAmount.toStringAsFixed(0)}'},
                    {'label': 'Paid Amount', 'value': '₹${data.paidFeeAmount.toStringAsFixed(0)}'},
                    {'label': 'Due Amount', 'value': '₹${data.dueFeeAmount.toStringAsFixed(0)}'},
                    {'label': 'Status', 'value': data.feeStatus},
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 🆕 Academics Information
            _buildInfoContainer(
              context,
              _buildSectionTitle('📚', 'Academics'),
              Column(
                children: [
                  _buildInfoCard('Performance', [
                    {'label': 'Overall Score', 'value': data.overallScore},
                    {'label': 'Performance', 'value': data.performance},
                    {'label': 'Last Exam', 'value': data.lastExam},
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 🆕 Extracurriculars
            if (data.extracurricularActivities.isNotEmpty) ...[
                _buildInfoContainer(
                context,
                _buildSectionTitle('⚽', 'Extracurriculars'),
                Column(
                    children: [
                    _buildInfoCard('Activities', [
                        {'label': 'Activities', 'value': data.extracurricularActivities},
                        {'label': 'Leadership', 'value': data.extracurricularLeadership},
                        {'label': 'Achievements', 'value': data.extracurricularAchievements},
                    ]),
                    ],
                ),
                ),
                const SizedBox(height: 20),
            ],
            const SizedBox(height: 20),

            // 5. Achievements
            _buildAchievementsSection(context, data),
            const SizedBox(height: 20),

            // 6. Extracurricular & Leadership
            if (data.activities.isNotEmpty || data.leadership.isNotEmpty || data.participation.isNotEmpty || data.otherAchievements.isNotEmpty)
              _buildInfoContainer(
                context,
                _buildSectionTitle('🌟', 'Extracurricular & Leadership'),
                Column(
                  children: [
                    if (data.activities.isNotEmpty)
                      _buildInfoCard('Activities', [
                        {'label': 'Details', 'value': data.activities},
                      ]),
                    if (data.leadership.isNotEmpty)
                      _buildInfoCard('Leadership', [
                        {'label': 'Roles', 'value': data.leadership},
                      ]),
                    if (data.participation.isNotEmpty)
                      _buildInfoCard('Participation', [
                        {'label': 'Record', 'value': data.participation},
                      ]),
                    if (data.otherAchievements.isNotEmpty)
                      _buildInfoCard('Other Achievements', [
                        {'label': 'Records', 'value': data.otherAchievements},
                      ]),
                  ],
                ),
              ),
            
            const SizedBox(height: 20),
            
            // Security Section
            _buildInfoContainer(
              context,
              _buildSectionTitle('🔒', 'Security'),
              Column(
                children: [
                  _buildSecurityTile(
                    'Change Password',
                    Icons.lock,
                    () => _showChangePasswordDialog(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Missing Helper Methods (Restored) ---

  Widget _buildSectionTitle(String emoji, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xff333333),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Map<String, String>> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff666666),
                ),
              ),
            ),
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      item['label']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Color(0xff444444),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item['value']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xff222222),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPageHeader(BuildContext context, Color primaryColor) {
     return Row(
      children: [
        const Text(
          'My Profile',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
      ],
    );
  }

  void _showPictureUpdateModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 200,
          child: Column(
            children: [
              const Text(
                'Update Profile Picture',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        child: const Icon(Icons.camera_alt, color: Colors.blue),
                      ),
                      const SizedBox(height: 8),
                      const Text('Camera'),
                    ],
                  ),
                  Column(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.purple.withOpacity(0.1),
                        child: const Icon(Icons.photo_library, color: Colors.purple),
                      ),
                      const SizedBox(height: 8),
                      const Text('Gallery'),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditProfileModal(BuildContext context, StudentData data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: const Text('Profile editing is currently disabled by administration.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }



  void _showAchievementDetailsModal(BuildContext context, Map<String, String> achievement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(achievement['title'] ?? 'Achievement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text('Date: ${achievement['date']}'),
             const SizedBox(height: 10),
             Text(achievement['description'] ?? ''),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTile(String title, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF667eea).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF667eea)),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  String? _validatePasswordStrength(String password) {
    if (password.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter (A-Z)';
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter (a-z)';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number (0-9)';
    }
    if (!password.contains(RegExp(r'[@#$%&*!^()_+=\-\[\]{}|;:,.<>?/~`]'))) {
      return 'Password must contain at least one special character (@, #, \$, %, &, etc.)';
    }
    return null;
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (sbContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Change Password',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Enter your current password and choose a new one',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: oldPasswordController,
                  obscureText: obscureOld,
                  enabled: !isLoading,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(obscureOld ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setDialogState(() => obscureOld = !obscureOld),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: obscureNew,
                  enabled: !isLoading,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirm,
                  enabled: !isLoading,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(sbContext),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (oldPasswordController.text.isEmpty) {
                        if (!mounted) return;
                        showDialog(
                          context: sbContext,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Validation Error'),
                            content: const Text('Please enter your current password'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                        return;
                      }
                      
                      // Password strength validation
                      final passwordError = _validatePasswordStrength(newPasswordController.text);
                      if (passwordError != null) {
                        if (!mounted) return;
                        showDialog(
                          context: sbContext,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Weak Password'),
                            content: Text(passwordError),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                        return;
                      }
                      
                      if (newPasswordController.text != confirmPasswordController.text) {
                        if (!mounted) return;
                        showDialog(
                          context: sbContext,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Validation Error'),
                            content: const Text('Passwords do not match'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isLoading = true);

                      final authService = AuthService();
                      final result = await authService.changePassword(
                        oldPassword: oldPasswordController.text,
                        newPassword: newPasswordController.text,
                      );

                      setDialogState(() => isLoading = false);

                      if (sbContext.mounted) {
                        Navigator.pop(sbContext);
                        if (result['success']) {
                          if (this.context.mounted) {
                            // Show success message using Dialog
                            showDialog(
                              context: this.context,
                              barrierDismissible: false,
                              builder: (successCtx) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.green, size: 60),
                                    const SizedBox(height: 20),
                                    const Text(
                                      'Success',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 10),
                                    const Text('Password changed successfully! Logging out...'),
                                  ],
                                ),
                              ),
                            );
                            
                            // Wait for 2 seconds then logout and redirect
                            Future.delayed(const Duration(seconds: 2), () async {
                              await AuthService().logout();
                              if (mounted) {
                                Navigator.of(this.context, rootNavigator: true).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (_) => const main_login.LoginScreen(),
                                  ),
                                  (_) => false,
                                );
                              }
                            });
                          }
                        } else {
                          if (!mounted) return;
                          showDialog(
                            context: this.context,
                            builder: (errCtx) => AlertDialog(
                              title: const Row(
                                children: [
                                  Icon(Icons.error, color: Colors.red, size: 28),
                                  SizedBox(width: 10),
                                  Text('Error'),
                                ],
                              ),
                              content: Text(result['message'] ?? 'Failed to change password'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(errCtx),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                minimumSize: const Size(120, 45),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Change Password'),
            ),
          ],
        ),
      ),
    );
  }
}
