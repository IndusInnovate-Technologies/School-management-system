import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:io';
import 'services/api_service.dart' as api;
import 'package:core/api/api_service.dart' as core_api;
import 'package:core/api/auth_service.dart';
import 'package:main_login/main.dart' as main_login;
// image_picker removed for emulator/demo builds. Image picking is simulated.

void main() {
  runApp(const TeacherProfileApp());
}

class TeacherProfileApp extends StatelessWidget {
  const TeacherProfileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Teacher Profile',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F9FE), // Soft blue-grey background
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6A1B9A)),
        // === BOLDNESS/SHARPNESS INCREASED HERE ===
        textTheme: const TextTheme(
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
          bodyMedium: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          bodySmall: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
          titleMedium: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
          headlineSmall: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
        // ==========================================
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Colors.black, width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
        ),
      ),
      home: const TeacherProfilePage(),
    );
  }
}

// ============================================================================
// MAIN PAGE
// ============================================================================
class TeacherProfilePage extends StatefulWidget {
  const TeacherProfilePage({super.key});

  @override
  State<TeacherProfilePage> createState() => _TeacherProfilePageState();
}

class _TeacherProfilePageState extends State<TeacherProfilePage> {


  // ====================== METADATA VARIABLES ==========================
  // NOTE: These are made mutable for demonstration, but should typically remain read-only in a production environment.
  late String teacherId;
  late String schoolId;
  late String userId;
  late String createdBy;
  late String createdAt;
  late String updatedAt;

  // Personal Info
  late String employeeNo;
  late String firstName;
  late String middleName;
  late String lastName;
  late String profileName;
  late String email;
  late String mobile;
  late String dateOfBirth;
  late String gender;
  late String religion;
  late String subCaste;
  late String bloodGroup;
  late String nationality;
  late String addressFull;
  late String addressCity;
  late String addressState;
  late String addressCountry;
  late String postalCode;
  late String profilePhotoId;
  String? profilePhotoUrl; // Added for remote image
  File? _profileImage;

  // Professional
  late String qualification;
  late List<String> subjectsSpecialization;
  late String department;
  late String departmentId;
  late String designation;
  late String joiningDate;
  late String employmentStatus;
  late bool isClassTeacher;
  late String classTeacherOfSectionId;
  late String primaryRoomId;
  late String availableFrom;
  late String availableTo;
  late List<int> workDays;

  // Emergency
  late String emergencyContactName;
  late String emergencyContactRelation;
  late String emergencyContactPhone;

  // Other
  late String notes;
  late bool isActive;

  // Notifications
  late bool assignmentsEnabled;
  late bool examsEnabled;
  late bool parentMessagesEnabled;
  late bool attendanceAlertsEnabled;
  late bool gradeUpdatesEnabled;
  
  // Password Change State
  String _currentPassword = '';
  String _newPassword = '';
  String _confirmPassword = '';
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  final TextEditingController _subjectController = TextEditingController();
  // image_picker plugin removed in demo; simulate pick behavior instead

  bool _isLoading = true;
  String? _error;

  Future<void> _loadTeacherData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final teacherData = await api.ApiService.fetchTeacherProfile();
      if (teacherData != null) {
        _populateDataFromApi(teacherData);
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      setState(() {
        _error = 'No teacher data found';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load teacher data: $e';
        _isLoading = false;
      });
      // Fallback to default data if API fails
      _initializeData();
    }
  }

  void _populateDataFromApi(Map<String, dynamic> data) {
    teacherId = data['teacher_id']?.toString() ?? 'N/A';
    employeeNo = data['employee_no'] ?? '';
    firstName = data['first_name'] ?? '';
    lastName = data['last_name'] ?? '';
    profileName = '$firstName $lastName'.trim();
    email = data['email'] ?? '';
    mobile = data['mobile_no'] ?? '';
    dateOfBirth = data['dob'] ?? '';
    gender = data['gender'] ?? '';
    bloodGroup = data['blood_group'] ?? '';
    nationality = data['nationality'] ?? '';
    addressFull = data['address'] ?? '';
    qualification = data['qualification'] ?? '';
    designation = data['designation'] ?? '';
    joiningDate = data['joining_date'] ?? '';
    department = data['department_name'] ?? '';
    departmentId = data['department']?.toString() ?? '';
    primaryRoomId = data['primary_room_id'] ?? '';
    classTeacherOfSectionId = data['class_teacher_section_id'] ?? '';
      if (data['profile_photo'] is Map) {
        final photo = data['profile_photo'] as Map<String, dynamic>;
        profilePhotoUrl = photo['file_url'] as String?;
      } else if (data['profile_photo'] is String && (data['profile_photo'] as String).isNotEmpty) {
        profilePhotoUrl = data['profile_photo'] as String;
      }
    
    
    final specialization = data['subject_specialization'] ?? '';
    if (specialization is String && specialization.isNotEmpty) {
      subjectsSpecialization = specialization.split(',').map((s) => s.trim()).toList();
    } else {
      subjectsSpecialization = [];
    }
    
    // Set defaults for missing fields
    middleName = '';
    religion = '';
    subCaste = '';
    addressCity = '';
    addressState = '';
    addressCountry = '';
    postalCode = '';
    profilePhotoId = '';
    schoolId = '';
    userId = data['user']?['user_id']?.toString() ?? '';
    createdBy = '';
    createdAt = data['created_at'] ?? '';
    updatedAt = data['updated_at'] ?? '';
    employmentStatus = isActive ? 'active' : 'inactive';
    isClassTeacher = classTeacherOfSectionId.isNotEmpty;
    availableFrom = '09:00';
    availableTo = '16:00';
    workDays = [1, 2, 3, 4, 5];
    notes = '';
    assignmentsEnabled = true;
    examsEnabled = true;
    parentMessagesEnabled = false;
    attendanceAlertsEnabled = true;
    gradeUpdatesEnabled = false;
  }

  void _initializeData() {
    teacherId = 'TID-0001';
    schoolId = 'SCH-01';
    userId = 'UID-100';
    createdBy = 'ADM-001';
    createdAt = '2024-01-01T12:00:00Z';
    updatedAt = '2024-06-10T15:30:00Z';

    employeeNo = 'TCH001';
    firstName = 'John';
    middleName = 'A.';
    lastName = 'Smith';
    profileName = 'John A. Smith';
    email = 'john.smith@school.edu';
    mobile = '+1 (555) 123-4567';
    dateOfBirth = '1985-03-15';
    gender = 'Male';
    religion = 'None';
    subCaste = '';
    bloodGroup = 'O+';
    nationality = 'American';
    addressFull = '123 Education Street, Learning City';
    addressCity = 'Learning City';
    addressState = 'LC State';
    addressCountry = 'United States';
    postalCode = '12345';
    profilePhotoId = 'PPH-5555';
    profilePhotoUrl = null;

    qualification = 'M.Ed Mathematics';
    subjectsSpecialization = ['Advanced Mathematics', 'Calculus'];
    department = 'Mathematics';
    departmentId = 'DEPT-MATH';
    designation = 'Teacher';
    joiningDate = '2016-06-01';
    employmentStatus = 'active';
    isClassTeacher = false;
    classTeacherOfSectionId = 'SEC-4A';
    primaryRoomId = 'RM-222';
    availableFrom = '09:00';
    availableTo = '16:00';
    workDays = [1, 2, 3, 4, 5];

    emergencyContactName = 'Jane Smith';
    emergencyContactRelation = 'Spouse';
    emergencyContactPhone = '+1 (555) 987-6543';

    notes = '';
    isActive = true;

    assignmentsEnabled = true;
    examsEnabled = true;
    parentMessagesEnabled = false;
    attendanceAlertsEnabled = true;
    gradeUpdatesEnabled = false;
  }

  @override
  void initState() {
    super.initState();
    _initializeData(); // Set defaults first
    _loadTeacherData(); // Then load from API
  }

  @override
  void dispose() {
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    // In emulator/demo builds we don't use the native image picker plugin.
    // Show a dialog to simulate image selection.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Simulate Image Pick'),
        content: const Text('Select a sample profile image (simulated).'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Use Sample'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() {
        _profileImage = null; // keep null but indicate selection via snackbar
      });
      _show('Sample image selected (simulated).');
    } else {
      _show('No image selected.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          toolbarHeight: 60,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF8B47E6), Color(0xFFC764A9)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          title: const Text(
            'Teacher Profile',
            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          toolbarHeight: 60,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF8B47E6), Color(0xFFC764A9)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          title: const Text(
            'Teacher Profile',
            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error ?? 'Error loading profile'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadTeacherData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 60,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF8B47E6), Color(0xFFC764A9)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Teacher Profile',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        elevation: 0,
      ),
      body: Container(
        color: const Color(0xFFF0F2F5),
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  // -------------------- COLORFUL HERO HEADER --------------------
                  _buildColorfulHeroHeader(),
                  
                  const SizedBox(height: 32),
  
                  // -------------------- UNIFIED CONTENT SECTION --------------------
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.08),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Column(
                          children: [
                            _buildSectionWrapper(
                              icon: Icons.person_rounded,
                              title: 'Personal Info',
                              color: const Color(0xFFEEF2FF),
                              accentColor: const Color(0xFF6366F1),
                              child: _buildPersonalSection(isMobile),
                            ),
                            const Divider(height: 1, color: Color(0xFFF1F4F9)),
                            _buildSectionWrapper(
                              icon: Icons.school_rounded,
                              title: 'Professional',
                              color: const Color(0xFFF5F3FF),
                              accentColor: const Color(0xFF8B5CF6),
                              child: _buildProfessionalSection(isMobile),
                            ),
                            const Divider(height: 1, color: Color(0xFFF1F4F9)),
                            _buildSectionWrapper(
                              icon: Icons.notifications_active_rounded,
                              title: 'Alerts & Tips',
                              color: const Color(0xFFFFF1F2),
                              accentColor: const Color(0xFFF43F5E),
                              child: _buildNotificationsTab(),
                            ),
                            const Divider(height: 1, color: Color(0xFFF1F4F9)),
                            _buildSectionWrapper(
                              icon: Icons.admin_panel_settings_rounded,
                              title: 'Security',
                              color: const Color(0xFFECFDF5),
                              accentColor: const Color(0xFF10B981),
                              child: _buildSecurityTab(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
  
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: _buildFloatingAction(),
            ),
          ],
        ),
      ),
    );
  }

  // _buildNavItem removed as sidebar is gone

  // Sections are now built directly within the scroll view

  // ============================================================================
  // PERSONAL TAB — ALL FIELDS EDITABLE
  // ============================================================================
  Widget _buildPersonalSection(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _row(isMobile, [
          _input('First Name', firstName, (v) => firstName = v),
          _input('Middle Name', middleName, (v) => middleName = v),
          _input('Last Name', lastName, (v) => lastName = v),
          _input('Employee Number', employeeNo, (v) => employeeNo = v),
        ]),
        _row(isMobile, [
          _input('Date of Birth (YYYY-MM-DD)', dateOfBirth, (v) => dateOfBirth = v),
          _input('Gender', gender, (v) => gender = v),
          _input('Blood Group', bloodGroup, (v) => bloodGroup = v),
          _input('Nationality', nationality, (v) => nationality = v),
        ]),
        const SizedBox(height: 20),
        const Text('Contact & Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        _row(isMobile, [
          _input('Email', email, (v) => email = v),
          _input('Mobile', mobile, (v) => mobile = v),
        ]),
        _row(isMobile, [
          _input('City', addressCity, (v) => addressCity = v),
          _input('State', addressState, (v) => addressState = v),
          _input('Country', addressCountry, (v) => addressCountry = v),
          _input('Postal Code', postalCode, (v) => postalCode = v),
        ]),
        _inputArea('Full Address', addressFull, (v) => addressFull = v),

        // Added from gudisa: Religious/Caste Details
        const SizedBox(height: 20),
        const Text('Religious/Caste Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        _row(isMobile, [
          _input('Religion', religion, (v) => religion = v),
          _input('Sub Caste', subCaste, (v) => subCaste = v),
        ]),

        const SizedBox(height: 20),
        // Security check applied to the save button
        if (core_api.ApiService().userRole != 'financial')
          _saveButton(() => _show('Personal Info Saved!')),
      ],
    );
  }

  // ============================================================================
  // PROFESSIONAL TAB — ALL FIELDS EDITABLE
  // ============================================================================
  Widget _buildProfessionalSection(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _row(isMobile, [
          _input('Department', department, (v) => department = v),
          _input('Designation', designation, (v) => designation = v),
          _input('Qualification', qualification, (v) => qualification = v),
         _input('Joining Date (YYYY-MM-DD)', joiningDate, (v) => joiningDate = v),
        ]),
        const SizedBox(height: 20),
        const Text('System Assignment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        _row(isMobile, [
          _input('Primary Room ID', primaryRoomId, (v) => primaryRoomId = v),
          _input('Class Teacher Section ID', classTeacherOfSectionId, (v) => classTeacherOfSectionId = v),
          _input('Department ID', departmentId, (v) => departmentId = v),
          _input('Employment Status', employmentStatus, (v) => employmentStatus = v),
        ]),
        // Added System IDs from gudisa
        const SizedBox(height: 10),
        _row(isMobile, [
           _input('Teacher ID', teacherId, (v) => teacherId = v),
           _input('User ID', userId, (v) => userId = v),
           _input('Account Active (True/False)', isActive.toString(), (v) => isActive = (v.toLowerCase() == 'true')),
        ]),

        const SizedBox(height: 20),
        const Text('Subjects Specialization', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: [
            for (int i = 0; i < subjectsSpecialization.length; i++)
              Chip(
                label: Text(subjectsSpecialization[i], style: const TextStyle(fontWeight: FontWeight.w700)),
                onDeleted: () => setState(() => subjectsSpecialization.removeAt(i)),
              ),
          ],
        ),
        TextField(
          controller: _subjectController,
          decoration: const InputDecoration(hintText: 'Add subject'),
          onSubmitted: (v) {
            if (v.trim().isNotEmpty) {
              setState(() => subjectsSpecialization.add(v.trim()));
              _subjectController.clear();
            }
          },
        ),
        const SizedBox(height: 20),
        const Text('Work Schedule & Emergency', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        _row(isMobile, [
          _input('Available From', availableFrom, (v) => availableFrom = v),
          _input('Available To', availableTo, (v) => availableTo = v),
          // Used gudisa's more descriptive label
          _input('Active Work Days (List:Monday...Saturday)', workDays.join(', '), (v) {
            try { workDays = v.split(',').map((s) => int.parse(s.trim())).toList(); } catch (_) {}
          }),
          _input('Is Class Teacher (Yes/No)', isClassTeacher ? 'Yes' : 'No', (v) => isClassTeacher = (v.toLowerCase() == 'yes')),
        ]),
        _row(isMobile, [
          _input('Emergency Contact', emergencyContactName, (v) => emergencyContactName = v),
          _input('Relation', emergencyContactRelation, (v) => emergencyContactRelation = v),
          _input('Phone', emergencyContactPhone, (v) => emergencyContactPhone = v),
        ]),
        const SizedBox(height: 20),
        _inputArea('Notes', notes, (v) => notes = v),
        const SizedBox(height: 10),
        
        // Security check applied to the save button
        if (core_api.ApiService().userRole != 'financial')
          _saveButton(() => _show('Professional Details Saved!')),
      ],
    );
  }

  // ============================================================================
  // NOTIFICATIONS TAB
  // ============================================================================
  Widget _buildNotificationsTab() {
    return _buildSectionCard(
      title: 'Alert Preferences',
      children: [
        _notifyTile(
          'Assignment Submissions',
          assignmentsEnabled,
          (v) => setState(() => assignmentsEnabled = v),
        ),
        _notifyTile(
          'Exam Reminders',
          examsEnabled,
          (v) => setState(() => examsEnabled = v),
        ),
        _notifyTile(
          'Parent Messages',
          parentMessagesEnabled,
          (v) => setState(() => parentMessagesEnabled = v),
        ),
        _notifyTile(
          'Attendance Alerts',
          attendanceAlertsEnabled,
          (v) => setState(() => attendanceAlertsEnabled = v),
        ),
        _notifyTile(
          'Grade Updates',
          gradeUpdatesEnabled,
          (v) => setState(() => gradeUpdatesEnabled = v),
        ),

        const SizedBox(height: 20),
        _saveButton(() => _show('Notification Preferences Saved!')),
      ],
    );
  }

  // ============================================================================
  // SECURITY TAB — System fields moved to Professional tab, security actions remain.
  // ============================================================================
  Widget _buildSecurityTab() {
    return _buildSectionCard(
      title: 'Account & Security',
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            'Account Status (Metadata)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ),
        _readonly('School ID', schoolId),
        _readonly('Created By', createdBy),
        _readonly('Created At', createdAt),
        _readonly('Last Updated At', updatedAt),

        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            'Credentials and Sessions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ),
        _securityTile(
          'Change Password',
          Icons.lock,
          () => _showChangePasswordDialog(),
        ),
        _securityTile(
          'Enable Two-Factor Authentication',
          Icons.security,
          () => _show('2FA Setup'),
        ),
        _securityTile(
          'Manage Active Sessions',
          Icons.devices,
          () => _show('Sessions Management'),
        ),
      ],
    );
  }

  Widget _buildColorfulHeroHeader() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFFA855F7), Color(0xFFEC4899)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.4),
                    blurRadius: 25,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: const Color(0xFFF8FAFC),
                  backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                  child: _profileImage == null
                      ? const Icon(Icons.person_outline_rounded, color: Color(0xFF6366F1), size: 50)
                      : null,
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5)]),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10),
                  ],
                ),
                child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          profileName,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.8),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _heroBadge(department, const Color(0xFFE0E7FF), const Color(0xFF4338CA)),
            const SizedBox(width: 8),
            _heroBadge(designation, const Color(0xFFFDF2F8), const Color(0xFFBE185D)),
          ],
        ),
      ],
    );
  }

  Widget _heroBadge(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: textCol.withOpacity(0.1))),
      child: Text(text, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: textCol)),
    );
  }

  Widget _buildSectionWrapper({required IconData icon, required String title, required Color color, required Color accentColor, required Widget child}) {
    return Container(
      color: color.withOpacity(0.3),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: accentColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          title: Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black.withOpacity(0.85)),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: child,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingAction() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _show('Vibrant Profile Saved!'),
          borderRadius: BorderRadius.circular(20),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 12),
                Text(
                  'SAVE CHANGES',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // -------------------------- UI HELPERS --------------------------------------
  // ============================================================================

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2D3142),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 24),
          ],
          ...children,
        ],
      ),
    );
  }

  Widget _row(bool mobile, List<Widget> items) {
    if (mobile) {
      return Column(
        children: items.map((e) => Padding(padding: const EdgeInsets.only(bottom: 16), child: e)).toList(),
      );
    }
    return Wrap(
      spacing: 20,
      runSpacing: 20,
      children: items.map((e) => SizedBox(width: 300, child: e)).toList(),
    );
  }

  Widget _input(String label, String value, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: value,
          onChanged: (v) => setState(() => onChanged(v)),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF5F7FA),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none, // Clean look
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF8B47E6), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _readonly(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _inputArea(String label, String value, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.blueGrey),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: value,
            maxLines: 3,
            onChanged: (v) => setState(() => onChanged(v)),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ],
      ),
    );
  }





  Widget _passwordField(String label, Function(String) onChanged, bool obscure, VoidCallback onToggle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          // initialValue removed as it was undefined
          maxLines: 3,
          onChanged: (v) => setState(() => onChanged(v)),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF5F7FA),
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF8B47E6), width: 1.5),
            ),
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
              onPressed: onToggle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _notifyTile(String title, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
       color: value ? const Color(0xFFF3E5F5) : const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
        border: value ? Border.all(color: const Color(0xFF8B47E6).withOpacity(0.3)) : null,
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: value ? const Color(0xFF6A1B9A) : Colors.black87,
          ),
        ),
        value: value,
        activeColor: const Color(0xFF8B47E6),
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _securityTile(String title, IconData i, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF8B47E6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(i, color: const Color(0xFF8B47E6), size: 20),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _title(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Color(0xFF2D3142),
      ), 
    ),
  );

  Widget _saveButton(VoidCallback f) {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton.icon(
        onPressed: f,
        icon: const Icon(Icons.check_circle_outline, size: 20),
        label: const Text('Save Changes'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2D3142),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }



  void _show(String msg) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
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

  void _showChangePasswordDialog() {
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
                      // Validate
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

                      // Assuming AuthService is imported and available
                      // import 'package:your_app_name/services/auth_service.dart';
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
                backgroundColor: const Color(0xFF8B47E6),
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
