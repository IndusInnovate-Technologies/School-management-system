import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:core/api/api_service.dart';
import 'package:core/api/endpoints.dart';
import 'main.dart' as app;
import 'dashboard.dart';
import 'admissions.dart';
import 'widgets/school_profile_header.dart';
import 'widgets/management_sidebar.dart';

class StudentAcademics {
  final String overallScore;
  final String subjects;
  final String performance;
  final String lastExam;

  const StudentAcademics({
    required this.overallScore,
    required this.subjects,
    required this.performance,
    required this.lastExam,
  });
}

class StudentExtracurricular {
  final String activities;
  final String leadership;
  final String achievements;
  final String participation;

  const StudentExtracurricular({
    required this.activities,
    required this.leadership,
    required this.achievements,
    required this.participation,
  });
}

class StudentFees {
  final String total;
  final String paid;
  final String due;
  final String status;

  const StudentFees({
    required this.total,
    required this.paid,
    required this.due,
    required this.status,
  });
}

class Student {
  final int id;
  final String name;
  final String studentClass;
  final String section;
  final String bloodGroup;
  final String initials;
  final String parentsName;
  final String contact;
  final String email;
  final String address;
  final String admissionDate;
  final String studentId;
  final double attendance;
  final String busRoute;
  final String busNumber;
  final String emergencyContact;
  final String medicalInfo;
  final String status;
  final StudentAcademics academics;
  final StudentExtracurricular extracurricular;
  final StudentFees fees;
  final String? profilePhotoUrl;
  final List<Map<String, dynamic>> awards;

  Student({
    required this.id,
    required this.name,
    required this.studentClass,
    required this.section,
    required this.bloodGroup,
    required this.initials,
    required this.parentsName,
    required this.contact,
    required this.email,
    required this.address,
    required this.admissionDate,
    required this.studentId,
    required this.attendance,
    required this.busRoute,
    required this.busNumber,
    required this.emergencyContact,
    required this.medicalInfo,
    required this.status,
    required this.academics,
    required this.extracurricular,
    required this.fees,
    this.profilePhotoUrl,
    this.awards = const [],
  });

  // Factory constructor to parse from JSON (database response)
  factory Student.fromJson(Map<String, dynamic> json) {
    final firstName = json['user']?['first_name'] as String? ?? '';
    final lastName = json['user']?['last_name'] as String? ?? '';
    final fullName = '$firstName $lastName'.trim();

    // Parse fee amounts from API
    final totalFeeAmount = (json['total_fee_amount'] as num?)?.toDouble() ?? 0.0;
    final paidFeeAmount = (json['paid_fee_amount'] as num?)?.toDouble() ?? 0.0;
    final dueFeeAmount = (json['due_fee_amount'] as num?)?.toDouble() ?? 0.0;
    
    // Determine fee status
    String feeStatus = '';
    if (dueFeeAmount > 0) {
      feeStatus = 'Due: ₹${dueFeeAmount.toStringAsFixed(0)}';
    } else if (totalFeeAmount > 0) {
      feeStatus = 'Paid';
    } else {
      feeStatus = 'No Fees';
    }

    // Get profile photo URL
    String? profilePhotoUrl;
    if (json['profile_photo_url'] != null) {
      profilePhotoUrl = json['profile_photo_url'] as String;
    } else if (json['profile_photo'] != null && json['profile_photo'] is Map) {
      final profilePhoto = json['profile_photo'] as Map<String, dynamic>;
      profilePhotoUrl = profilePhoto['file_url'] as String?;
    }

    return Student(
      id: json['id'] as int? ?? 0,
      name: fullName.isNotEmpty ? fullName : json['student_name'] as String? ?? 'Unknown Student',
      studentClass: json['applying_class'] as String? ?? json['class_name'] as String? ?? '',
      section: json['section'] as String? ?? '',
      bloodGroup: json['blood_group'] as String? ?? '',
      initials: _getInitials(
        firstName.isNotEmpty ? firstName : (json['student_name'] as String? ?? '').split(' ').first,
        lastName.isNotEmpty ? lastName : (json['student_name'] as String? ?? '').split(' ').last,
      ),
      parentsName: json['parent_name'] as String? ?? '',
      contact: json['parent_phone'] as String? ?? '',
      email:
          json['email'] as String? ?? json['user']?['email'] as String? ?? '',
      address: json['address'] as String? ?? '',
      admissionDate: json['admission_date'] as String? ?? '',
      studentId: json['student_id']?.toString() ?? '',
      attendance: 0.0,
      busRoute: json['bus_route'] ?? '',
      busNumber: json['bus_number'] ?? '',
      emergencyContact: json['emergency_contact'] as String? ?? '',
      medicalInfo: json['medical_information'] as String? ?? '',
      status: 'Active',
      academics: const StudentAcademics(
        overallScore: '0%',
        subjects: '',
        performance: '',
        lastExam: '',
      ),
      extracurricular: const StudentExtracurricular(
        activities: '',
        leadership: '',
        achievements: '',
        participation: '',
      ),
      fees: StudentFees(
        total: '₹${totalFeeAmount.toStringAsFixed(0)}',
        paid: '₹${paidFeeAmount.toStringAsFixed(0)}',
        due: '₹${dueFeeAmount.toStringAsFixed(0)}',
        status: feeStatus,
      ),
      profilePhotoUrl: profilePhotoUrl,
      awards: json['awards'] != null ? List<Map<String, dynamic>>.from(json['awards']) : [],
    );
  }

  static String _getInitials(String firstName, String lastName) {
    return (firstName.isNotEmpty ? firstName[0] : '') +
        (lastName.isNotEmpty ? lastName[0] : '');
  }
}

class StudentsManagementPage extends StatefulWidget {
  const StudentsManagementPage({super.key});

  @override
  State<StudentsManagementPage> createState() => _StudentsManagementPageState();
}

class _StudentsManagementPageState extends State<StudentsManagementPage> {
  late List<Student> _students;
  late List<Student> _visibleStudents;

  final TextEditingController _searchController = TextEditingController();
  String? _selectedClass;
  @override
  void initState() {
    super.initState();
    _students = [];
    _visibleStudents = [];
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    try {
      // Use the core ApiService that includes authentication
      final apiService = ApiService();
      await apiService.initialize();
      
      final response = await apiService.get(Endpoints.students);
      
      if (response.success && response.data != null) {
        List<dynamic> data = [];
        if (response.data is List) {
          data = response.data as List;
        } else if (response.data is Map && (response.data as Map)['results'] != null) {
          data = (response.data as Map)['results'] as List;
        }
        
        final students = data
            .map((item) => Student.fromJson(item as Map<String, dynamic>))
            .toList();
        if (!mounted) return;
        setState(() {
          _students = students;
          _visibleStudents = List<Student>.from(_students);
        });
      } else {
        throw Exception(response.error ?? 'Failed to fetch students');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching students: $e')));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int get _totalStudents => _students.length;
  int get _activeStudents =>
      _students.where((s) => s.status == 'Active').length;
  double get _avgAttendance =>
      _students.fold(0.0, (sum, s) => sum + s.attendance) / _students.length;
  int get _totalClasses => _students.map((s) => s.studentClass).toSet().length;
  double get _academicsScore {
    final scores = _students.map((s) {
      final scoreStr = s.academics.overallScore.replaceAll('%', '');
      return double.tryParse(scoreStr) ?? 85.6;
    });
    return scores.fold(0.0, (sum, score) => sum + score) / _students.length;
  }

  int get _extracurricularCount {
    return _students.fold(0, (sum, s) {
      final count = s.extracurricular.activities.split(',').length;
      return sum + count;
    });
  }

  // Check if user has edit permissions (Financial users are read-only)
  bool get _canEdit => ApiService().userRole != 'financial';

  String get _feesPaid {
    final total = _students.fold(0, (sum, s) {
      final paidStr = s.fees.paid.replaceAll('₹', '').replaceAll(',', '');
      return sum + (int.tryParse(paidStr) ?? 42000);
    });
    return '₹${total.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  void _filterStudents() {
    setState(() {
      final query = _searchController.text.toLowerCase();
      final selectedClass = _selectedClass;

      _visibleStudents = _students.where((student) {
        final matchesSearch =
            query.isEmpty ||
            student.name.toLowerCase().contains(query) ||
            student.studentClass.toLowerCase().contains(query) ||
            student.studentId.toLowerCase().contains(query);
        final matchesClass =
            selectedClass == null ||
            selectedClass.isEmpty ||
            student.studentClass.contains(selectedClass);
        return matchesSearch && matchesClass;
      }).toList();
    });
  }

  void _viewStudent(Student student) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            padding: const EdgeInsets.all(30),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${student.name} - Student Profile',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFFAAAAAA)),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 600;
                      if (isCompact) {
                        return Column(
                          children: [
                            _buildProfileImage(student),
                            const SizedBox(height: 20),
                            _buildProfileDetails(student),
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfileImage(student),
                          const SizedBox(width: 30),
                          Expanded(child: _buildProfileDetails(student)),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_canEdit) ...[
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF667EEA),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          onPressed: () {
                            _editStudent(student);
                          },
                          child: const Text('Edit Profile'),
                        ),
                        const SizedBox(width: 10),
                      ],
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C757D),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
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

  Widget _buildProfileImage(Student student) {
    return Column(
      children: [
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: student.profilePhotoUrl == null
                ? const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  )
                : null,
          ),
          child: student.profilePhotoUrl != null
              ? ClipOval(
                  child: Image.network(
                    student.profilePhotoUrl!,
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to initials if image fails to load
                      return Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            student.initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 48,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                )
              : Center(
                  child: Text(
                    student.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 48,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 20),
        Text(
          student.name,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          student.section.isNotEmpty 
            ? '${student.studentClass} • Section ${student.section}'
            : student.studentClass,
          style: const TextStyle(color: Color(0xFF666666)),
        ),
        const SizedBox(height: 5),
        Text(
          student.studentId.isNotEmpty 
            ? 'Student ID: ${student.studentId}'
            : 'Student ID: N/A',
          style: const TextStyle(
            color: Color(0xFF667EEA),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          student.status,
          style: const TextStyle(
            color: Color(0xFF667EEA),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStatBadge(
              icon: Icons.emoji_events,
              label: "Awards",
              count: student.awards.length.toString(),
              color: const Color(0xFFFFD700), // Gold
            ),
            const SizedBox(width: 12),
            _buildStatBadge(
              icon: Icons.stars,
              label: "Achievements",
              count: _getAchievementCount(student),
              color: const Color(0xFF667EEA),
            ),
          ],
        ),
      ],
    );
  }

  String _getAchievementCount(Student student) {
    // Achievements in Extracurricular is a string. 
    // We can count items if they are comma separated or just return a mock if empty.
    if (student.extracurricular.achievements.isEmpty || student.extracurricular.achievements == 'None') {
      return "0";
    }
    return student.extracurricular.achievements.split(',').length.toString();
  }

  Widget _buildStatBadge({
    required IconData icon,
    required String label,
    required String count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                count,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetails(Student student) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 0.85,
      children: [
        _DetailCard(
          title: 'Academic Information',
          items: [
            'Class: ${student.studentClass}',
            if (student.section.isNotEmpty) 'Section: ${student.section}',
            'Student ID: ${student.studentId.isNotEmpty ? student.studentId : "N/A"}',
            if (student.admissionDate.isNotEmpty) 'Admission Date: ${student.admissionDate}',
          ],
        ),
        _DetailCard(
          title: 'Contact Information',
          items: [
            'Email: ${student.email}',
            'Phone: ${student.contact}',
            'Address: ${student.address}',
          ],
        ),
        _DetailCard(
          title: 'Parent Information',
          items: [
            'Parents: ${student.parentsName}',
            'Emergency Contact: ${student.emergencyContact}',
          ],
        ),
        _DetailCard(
          title: 'Additional Details',
          items: [
            'Blood Group: ${student.bloodGroup}',
            'Bus Route: ${student.busRoute}',
            'Attendance: ${student.attendance}%',
          ],
        ),
        _DetailCard(title: 'Medical Information', items: [student.medicalInfo]),
        _DetailCard(
          title: 'Academics',
          items: [
            'Overall Score: ${student.academics.overallScore}',
            'Subjects: ${student.academics.subjects}',
            'Performance: ${student.academics.performance}',
            'Last Exam: ${student.academics.lastExam}',
          ],
        ),
        _DetailCard(
          title: 'Extracurricular Activities',
          items: [
            'Activities: ${student.extracurricular.activities}',
            'Leadership: ${student.extracurricular.leadership}',
            'Achievements: ${student.extracurricular.achievements}',
            'Participation: ${student.extracurricular.participation}',
          ],
        ),
        _DetailCard(
          title: 'Fees Information',
          items: [
            'Total Fees: ${student.fees.total}',
            'Paid Amount: ${student.fees.paid}',
            'Due Amount: ${student.fees.due}',
            'Payment Status: ${student.fees.status}',
          ],
        ),
        if (student.awards.isNotEmpty)
          _DetailCard(
            title: 'Awards & Achievements',
            items: student.awards.map((award) =>
              '${award['title']} (${award['level']})\n${award['category']} • ${award['date'] != null ? award['date'].toString().split(' ')[0] : ''}'
            ).toList(),
          ),
      ],
    );
  }

  void _editStudent(Student student) {
    Navigator.pushNamed(context, '/edit-student', arguments: student.id);
  }

  void _deleteStudent(Student student) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Delete ${student.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Close the confirmation dialog first
                Navigator.of(context).pop();

                // Use root navigator so the loading dialog is guaranteed to close
                final rootContext = app.SchoolManagementApp.navigatorKey.currentContext ?? context;

                showDialog(
                  context: rootContext,
                  barrierDismissible: false,
                  builder: (_) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                Future<void> closeLoading() async {
                  if (Navigator.of(rootContext, rootNavigator: true).canPop()) {
                    Navigator.of(rootContext, rootNavigator: true).pop();
                  }
                }

                try {
                  // Use the core ApiService for authenticated requests
                  final apiService = ApiService();
                  await apiService.initialize();
                  await apiService.delete('${Endpoints.students}${student.id}/');
                  await closeLoading();

                  if (!mounted) return;
                  setState(() {
                    _students.removeWhere((s) => s.id == student.id);
                    _visibleStudents.removeWhere((s) => s.id == student.id);
                  });

                  // Attempt to close any profile dialog underneath
                  if (Navigator.of(rootContext, rootNavigator: true).canPop()) {
                    Navigator.of(rootContext, rootNavigator: true).maybePop();
                  }

                  final messengerContext = app.SchoolManagementApp.navigatorKey.currentContext;
                  if (messengerContext != null) {
                    ScaffoldMessenger.of(messengerContext).showSnackBar(
                      const SnackBar(content: Text('Student deleted successfully!')),
                    );
                  }
                } catch (e) {
                  await closeLoading();
                  final messengerContext = app.SchoolManagementApp.navigatorKey.currentContext;
                  if (messengerContext != null) {
                    ScaffoldMessenger.of(messengerContext).showSnackBar(
                      SnackBar(content: Text('Error deleting student: $e')),
                    );
                  }
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _addStudent() async {
    // Navigate to admissions screen and refresh when returning
    await Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => const AdmissionsManagementPage())
    );
    // Refresh students list when returning from admissions
    if (mounted) {
      await _fetchStudents();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 900;

            if (isCompact) {
              return Column(
                children: [
                  Expanded(
                    child: Container(
                      color: const Color(0xFFF5F6FA),
                      child: _buildMainContent(isMobile: true),
                    ),
                  ),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 280,
                  child: ManagementSidebar(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    activeRoute: '/students',
                  ),
                ),
                Expanded(
                  child: Container(
                    color: const Color(0xFFF5F6FA),
                    child: _buildMainContent(isMobile: false),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }



  Widget _buildMainContent({required bool isMobile}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassContainer(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
            margin: const EdgeInsets.only(bottom: 30),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('👥', style: TextStyle(fontSize: 32)),
                          const SizedBox(width: 15),
                          Text(
                            'Students Management',
                            style: TextStyle(
                              fontSize: isMobile ? 22 : 28,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF333333),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Manage all students, their profiles, academic records, and attendance',
                        style: TextStyle(color: Color(0xFF666666), fontSize: 16),
                      ),
                    ],
                  ),
                ),
                if (!isMobile) ...[
                  _buildUserInfo(),
                  const SizedBox(width: 20),
                  _buildBackButton(),
                ],
              ],
            ),
          ),
          if (isMobile)
            GlassContainer(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 20),
              child: Row(
                children: [
                  Expanded(child: SchoolProfileHeader(apiService: ApiService(), isMobile: true)),
                  const Icon(Icons.arrow_back_ios_new, size: 16),
                ],
              ),
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = isMobile ? 1 : 4;
              final childAspectRatio = isMobile ? 3.4 : 1.35;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                childAspectRatio: childAspectRatio,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                children: [
                  _StatCard(
                    label: 'Total Students',
                    value: '$_totalStudents',
                    icon: '👥',
                    color: const Color(0xFF667EEA),
                  ),
                  _StatCard(
                    label: 'Active Students',
                    value: '$_activeStudents',
                    icon: '📈',
                    color: Colors.green,
                  ),
                  _StatCard(
                    label: 'Avg Attendance',
                    value: '${_avgAttendance.toStringAsFixed(1)}%',
                    icon: '📅',
                    color: Colors.orange,
                  ),
                  _StatCard(
                    label: 'Total Classes',
                    value: '$_totalClasses',
                    icon: '🏫',
                    color: Colors.blue,
                  ),
                  _StatCard(
                    label: 'Academics',
                    value: '${_academicsScore.toStringAsFixed(1)}%',
                    icon: '🎓',
                    color: Colors.purple,
                  ),
                  _StatCard(
                    label: 'Activities',
                    value: '$_extracurricularCount',
                    icon: '🏆',
                    color: Colors.amber,
                  ),
                  _StatCard(
                    label: 'Fees Collection',
                    value: _feesPaid,
                    icon: '💰',
                    color: Colors.teal,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 30),
          GlassContainer(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 30),
            child: Flex(
              direction: isMobile ? Axis.vertical : Axis.horizontal,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFE1E5E9),
                              width: 2,
                            ),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (_) => _filterStudents(),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText:
                                  'Search students by name, class, or ID...',
                              prefixIcon: Icon(Icons.search),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFE1E5E9),
                            width: 2,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButton<String>(
                          value: _selectedClass,
                          hint: const Text('All Classes'),
                          isExpanded: false,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(
                              value: null,
                              child: Text('All Classes'),
                            ),
                            DropdownMenuItem(
                              value: '9',
                              child: Text('Grade 9'),
                            ),
                            DropdownMenuItem(
                              value: '10',
                              child: Text('Grade 10'),
                            ),
                            DropdownMenuItem(
                              value: '11',
                              child: Text('Grade 11'),
                            ),
                            DropdownMenuItem(
                              value: '12',
                              child: Text('Grade 12'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedClass = value;
                            });
                            _filterStudents();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: isMobile ? 0 : 20, height: isMobile ? 15 : 0),
                if (_canEdit)
                  InkWell(
                    onTap: _addStudent,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: isMobile ? double.infinity : null,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 24,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF51CF66), Color(0xFF40C057)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF51CF66,
                            ).withValues(alpha: 0.25),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Add New Student',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = 350.0;
              final spacing = 20.0;
              final availableWidth = constraints.maxWidth;
              final crossAxisCount =
                  ((availableWidth + spacing) / (cardWidth + spacing))
                      .floor()
                      .clamp(1, 4);
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: _visibleStudents.map((student) {
                  return SizedBox(
                    width:
                        (availableWidth - (spacing * (crossAxisCount - 1))) /
                        crossAxisCount,
                    child: _buildStudentCard(student),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Student student) {
    return _StudentCardWithHover(
      student: student,
      onView: () => _viewStudent(student),
      onEdit: () => _editStudent(student),
      onDelete: () => _deleteStudent(student),
    );
  }

  Widget _buildUserInfo() {
    return SchoolProfileHeader(apiService: ApiService());
  }

  Widget _buildBackButton() {
    return InkWell(
      onTap: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DashboardPage()),
      ),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C757D), Color(0xFF495057)],
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
               color: Colors.black.withValues(alpha: 0.2),
               blurRadius: 4,
               offset: const Offset(0, 2),
             ),
           ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_back, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'Back to Dashboard',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentCardWithHover extends StatefulWidget {
  final Student student;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StudentCardWithHover({
    super.key,
    required this.student,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_StudentCardWithHover> createState() => _StudentCardWithHoverState();
}

class _StudentCardWithHoverState extends State<_StudentCardWithHover> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        transform: Matrix4.identity()..translate(0.0, _isHovered ? -8.0 : 0.0),
        child: GlassContainer(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: widget.student.profilePhotoUrl == null
                          ? const LinearGradient(
                              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                            )
                          : null,
                    ),
                    child: widget.student.profilePhotoUrl != null
                        ? ClipOval(
                            child: Image.network(
                              widget.student.profilePhotoUrl!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      widget.student.initials,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                        : Center(
                            child: Text(
                              widget.student.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.student.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.student.section.isNotEmpty
                            ? '${widget.student.studentClass} • Section ${widget.student.section} • Student ID: ${widget.student.studentId}'
                            : '${widget.student.studentClass} • Student ID: ${widget.student.studentId}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF666666),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = (constraints.maxWidth - 10) / 2;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      SizedBox(
                        width: itemWidth,
                        child: _DetailItem(
                          title: 'Attendance',
                          value: '${widget.student.attendance}%',
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _DetailItem(
                          title: 'Blood Group',
                          value: widget.student.bloodGroup,
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _DetailItem(
                          title: 'Parents',
                          value: widget.student.parentsName,
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _DetailItem(
                          title: 'Contact',
                          value: widget.student.contact,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _GradientButton(
                      label: 'View',
                      colors: const [Color(0xFF667EEA), Color(0xFF764BA2)],
                      onTap: widget.onView,
                    ),
                  ),
                  if (ApiService().userRole != 'financial') ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: _GradientButton(
                        label: 'Edit',
                        colors: const [Color(0xFFFFD93D), Color(0xFFFCC419)],
                        textColor: const Color(0xFF333333),
                        onTap: widget.onEdit,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _GradientButton(
                        label: 'Delete',
                        colors: const [Color(0xFFFF6B6B), Color(0xFFEE5A52)],
                        onTap: widget.onDelete,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final bool drawRightBorder;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.margin,
    this.borderRadius = 15,
    this.drawRightBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = drawRightBorder
        ? BorderRadius.zero
        : BorderRadius.circular(borderRadius);

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: radius,
              border: Border(
                right: drawRightBorder
                    ? BorderSide(color: Colors.white.withValues(alpha: 0.2))
                    : BorderSide.none,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 24,
                  offset: const Offset(2, 6),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}



class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: TextStyle(fontSize: 40, color: color)),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF666666),
                fontSize: 12,
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String title;
  final String value;

  const _DetailItem({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF666666),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final List<Color> colors;
  final Color textColor;
  final VoidCallback onTap;

  const _GradientButton({
    required this.label,
    required this.colors,
    this.textColor = Colors.white,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          gradient: LinearGradient(colors: colors),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final List<String> items;

  const _DetailCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                item,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
