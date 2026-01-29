import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:core/api/api_service.dart';
import 'package:core/api/endpoints.dart';
import 'dashboard.dart';

// Blood group options
const List<String> bloodGroupOptions = [
  'A+',
  'A-',
  'B+',
  'B-',
  'AB+',
  'AB-',
  'O+',
  'O-',
];

class AddTeacherPage extends StatefulWidget {
  const AddTeacherPage({super.key});

  @override
  State<AddTeacherPage> createState() => _AddTeacherPageState();
}

class _AddTeacherPageState extends State<AddTeacherPage> {
  final _formKey = GlobalKey<FormState>();

  final _employeeNoController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _departmentController = TextEditingController();
  final _mobileNoController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _subjectSpecializationController = TextEditingController();
  final _emergencyContactController = TextEditingController();


  String? _gender;
  String? _bloodGroup;
  DateTime? _dob;

  final _emergencyContactRelationController = TextEditingController();
  final _salaryController = TextEditingController();
  final _experienceController = TextEditingController();


  DateTime? _joiningDate;
  Uint8List? _photoBytes;
  
  bool _isClassTeacher = false;
  String? _classTeacherClass;
  String? _classTeacherGrade;
  bool _isLoadingDepartments = true;
  List<Map<String, dynamic>> _departments = [];
  final List<String> _defaultDepartmentNames = [
    'Science', 'Mathematics', 'English', 'History', 'Geography', 'Computer Science'
  ];

  bool _isSubmitting = false;
  bool _showSuccess = false;
  bool _showError = false;
  String _errorMessage = '';

  TeacherPreviewData get _previewData => TeacherPreviewData(
        employeeNo: _employeeNoController.text,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        qualification: _qualificationController.text,
        department: _departmentController.text,
        mobileNo: _mobileNoController.text,
        email: _emailController.text,
        address: _addressController.text,

        subjectSpecialization: _subjectSpecializationController.text,
      );

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    setState(() => _isLoadingDepartments = true);
    try {
      final apiService = ApiService();
      await apiService.initialize();
      final response = await apiService.get(Endpoints.departments);
      
      if (response.success && response.data != null) {
        List<dynamic> data = [];
        if (response.data is List) {
          data = response.data as List;
        } else if (response.data is Map && (response.data as Map)['results'] != null) {
          data = (response.data as Map)['results'] as List;
        }
        
        if (mounted) {
          setState(() {
            _departments = data.map((d) => d as Map<String, dynamic>).toList();
            // If no departments from API, add default ones as fallback
            if (_departments.isEmpty) {
              _departments = _defaultDepartmentNames.map((name) => <String, dynamic>{
                'id': name,
                'name': name,
              }).toList();
            }
            _isLoadingDepartments = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            // If API fails, use default departments as fallback
            _departments = _defaultDepartmentNames.map((name) => <String, dynamic>{
              'id': name,
              'name': name,
            }).toList();
            _isLoadingDepartments = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDepartments = false);
      }
    }
  }

  @override
  void dispose() {
    _departmentController.dispose();
    _employeeNoController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _qualificationController.dispose();
    _mobileNoController.dispose();
    _emailController.dispose();
    _addressController.dispose();
      _nationalityController.dispose();
    _subjectSpecializationController.dispose();
    _emergencyContactController.dispose();
    _emergencyContactRelationController.dispose();
    _salaryController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _photoBytes = bytes;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _showSuccess = false;
      _showError = false;
    });

    try {
      // Prepare teacher data for API
      // Helper function to convert empty strings to null
      String? nullIfEmpty(String? value) {
        if (value == null || value.trim().isEmpty) return null;
        return value.trim();
      }
      
      final teacherData = <String, dynamic>{
        'employee_no': _employeeNoController.text.trim().isNotEmpty 
            ? _employeeNoController.text.trim() 
            : 'EMP-${DateTime.now().millisecondsSinceEpoch}',
        'first_name': _firstNameController.text.trim().isNotEmpty 
            ? _firstNameController.text.trim() 
            : '',
        'last_name': nullIfEmpty(_lastNameController.text),
        'qualification': nullIfEmpty(_qualificationController.text),
        'joining_date': _joiningDate != null 
            ? DateFormat('yyyy-MM-dd').format(_joiningDate!) 
            : null,
        'dob': _dob != null 
            ? DateFormat('yyyy-MM-dd').format(_dob!) 
            : null,
        'gender': _gender,
        'is_active': true,
        'is_class_teacher': _isClassTeacher,
        'salary': nullIfEmpty(_salaryController.text),
        'experience': nullIfEmpty(_experienceController.text),
      };
      
      // Add department - try to find matching ID by name from loaded departments
      final departmentName = _departmentController.text.trim();
      if (departmentName.isNotEmpty) {
        // Try to find a matching department ID
        final matchingDept = _departments.firstWhere(
          (d) => d['name']?.toString().toLowerCase() == departmentName.toLowerCase(),
          orElse: () => <String, dynamic>{},
        );
        
        if (matchingDept.isNotEmpty && matchingDept['id'] != null) {
          final matchingId = int.tryParse(matchingDept['id'].toString());
          if (matchingId != null) {
            teacherData['department'] = matchingId;
          } else {
             // If ID is not an int (e.g. from defaults), send the name
            teacherData['department'] = departmentName;
          }
        } else {
          // No matching department found, send the name string
          // Note: Backend must handle string name if no ID is provided, 
          // or create a new department.
          teacherData['department'] = departmentName;
        }
      }
      
      // Add optional fields only if they have values
      final mobileNo = nullIfEmpty(_mobileNoController.text);
      if (mobileNo != null) teacherData['mobile_no'] = mobileNo;
      
      final email = nullIfEmpty(_emailController.text);
      if (email != null) teacherData['email'] = email;
      
      final address = nullIfEmpty(_addressController.text);
      if (address != null) teacherData['address'] = address;
      
      if (_bloodGroup != null && _bloodGroup!.isNotEmpty) {
        teacherData['blood_group'] = _bloodGroup;
      }
      
      final nationality = nullIfEmpty(_nationalityController.text);
      if (nationality != null) teacherData['nationality'] = nationality;
      
      final subjectSpecialization = nullIfEmpty(_subjectSpecializationController.text);
      if (subjectSpecialization != null) teacherData['subject_specialization'] = subjectSpecialization;
      
      final emergencyContact = nullIfEmpty(_emergencyContactController.text);
      if (emergencyContact != null) teacherData['emergency_contact'] = emergencyContact;

      final emergencyContactRelation = nullIfEmpty(_emergencyContactRelationController.text);
      if (emergencyContactRelation != null) teacherData['emergency_contact_relation'] = emergencyContactRelation;

      if (_isClassTeacher) {
        if (_classTeacherClass != null && _classTeacherClass!.isNotEmpty) {
          teacherData['class_teacher_class'] = _classTeacherClass;
        }
        if (_classTeacherGrade != null && _classTeacherGrade!.isNotEmpty) {
          teacherData['class_teacher_grade'] = _classTeacherGrade;
        }
      }

      // Note: Profile photo will be sent as multipart/form-data with the request
      // The backend handles file upload directly

      // Call API to create teacher using multipart/form-data for file upload
      final apiService = ApiService();
      await apiService.initialize();
      
      // If photo is available, use multipart upload, otherwise use JSON
      // Convert Map<String, dynamic> to Map<String, String> for uploadFile
      Map<String, String>? additionalFieldsString;
      if (_photoBytes != null && _photoBytes!.isNotEmpty) {
        additionalFieldsString = <String, String>{};
        teacherData.forEach((key, value) {
          if (value != null) {
            additionalFieldsString![key] = value.toString();
          }
        });
      }
      
      final response = _photoBytes != null && _photoBytes!.isNotEmpty
          ? await apiService.uploadFile(
              Endpoints.teachers,
              fileBytes: _photoBytes!,
              fileName: 'teacher_photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
              fieldName: 'profile_photo',
              additionalFields: additionalFieldsString,
            )
          : await apiService.post(Endpoints.teachers, body: teacherData);
      
      if (!response.success) {
        // Get detailed error message from response
        String errorMessage = 'Failed to create teacher';
        if (response.data is Map) {
          final errorData = response.data as Map<String, dynamic>;
          if (errorData.containsKey('detail')) {
            errorMessage = errorData['detail'].toString();
          } else if (errorData.isNotEmpty) {
            // Format validation errors
            final errors = errorData.entries.map((e) => '${e.key}: ${e.value}').join(', ');
            errorMessage = 'Validation errors: $errors';
          }
        } else if (response.error != null) {
          errorMessage = response.error!;
        }
        throw Exception(errorMessage);
      }
      
      final responseData = response.data as Map<String, dynamic>? ?? {};
      
      if (!mounted) return;
      
      setState(() {
        _isSubmitting = false;
        _showSuccess = true;
        _showError = false;
        _errorMessage = '';
      });
      
      await Future<void>.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/teachers');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _showSuccess = false;
        _showError = true;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _previewTeacher() async {
    final data = _previewData;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '👨‍🏫 Teacher Preview',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (data.employeeNo != null && data.employeeNo!.isNotEmpty)
                      _PreviewRow(label: 'Employee No', value: data.employeeNo),
                    _PreviewRow(
                      label: 'Name',
                      value: '${data.firstName ?? ''} ${data.lastName ?? ''}'.trim(),
                    ),
                    _PreviewRow(label: 'Department', value: data.department),
                    _PreviewRow(label: 'Mobile No', value: data.mobileNo),
                    _PreviewRow(label: 'Email', value: data.email),
                    _PreviewRow(label: 'Address', value: data.address),
                    _PreviewRow(label: 'Qualification', value: data.qualification),
                    _PreviewRow(label: 'Subject Specialization', value: data.subjectSpecialization),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF667EEA),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close Preview'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isCompact = size.width < 768;
    final gradient = const LinearGradient(
      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 280,
            decoration: BoxDecoration(
              gradient: gradient,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'packages/management_org/assets/Vidyarambh.png',
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.school,
                              size: 56,
                              color: Color(0xFF667EEA),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        _NavItem(
                          icon: '📊',
                          title: 'Overview',
                          onTap: () => Navigator.pushReplacementNamed(
                              context, '/dashboard'),
                        ),
                        _NavItem(
                          icon: '👨‍🏫',
                          title: 'Teachers',
                          isActive: true,
                        ),
                        _NavItem(
                          icon: '👥',
                          title: 'Students',
                          onTap: () => Navigator.pushReplacementNamed(
                              context, '/students'),
                        ),
                        _NavItem(
                          icon: '🚌',
                          title: 'Buses',
                          onTap: () =>
                              Navigator.pushReplacementNamed(context, '/buses'),
                        ),
                        _NavItem(
                          icon: '🎯',
                          title: 'Activities',
                          onTap: () =>
                              Navigator.pushReplacementNamed(context, '/activities'),
                        ),
                        _NavItem(
                          icon: '📅',
                          title: 'Events',
                          onTap: () =>
                              Navigator.pushReplacementNamed(context, '/events'),
                        ),
                        _NavItem(
                          icon: '📆',
                          title: 'Calendar',
                          onTap: () =>
                              Navigator.pushReplacementNamed(context, '/calendar'),
                        ),
                        _NavItem(
                          icon: '🔔',
                          title: 'Notifications',
                          onTap: () =>
                              Navigator.pushReplacementNamed(context, '/notifications'),
                        ),
                        _NavItem(
                          icon: '🛣️',
                          title: 'Bus Routes',
                          onTap: () =>
                              Navigator.pushReplacementNamed(context, '/bus-routes'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Main Content
          Expanded(
            child: Container(
              color: const Color(0xFFF5F6FA),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeader(),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => DashboardPage())),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.white.withValues(alpha: 0.2),
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.arrow_back, size: 16),
                                  SizedBox(width: 6),
                                  Text('Back to Dashboard'),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(isCompact ? 20 : 40),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                            if (_showSuccess)
                              const _MessageBanner.success(
                                message:
                                    '✅ Teacher added successfully! Redirecting to dashboard...',
                              ),
                            if (_showError)
                              _MessageBanner.error(
                                message:
                                    _errorMessage.isNotEmpty ? _errorMessage : '❌ Error adding teacher. Please try again.',
                              ),
                            if (_isSubmitting)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 20),
                                child: _LoadingIndicator(),
                              ),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isTwoColumns = constraints.maxWidth > 600;
                                return Wrap(
                                  spacing: 30,
                                  runSpacing: 30,
                                  children: [
                                    // Employee No (required)
                                    SizedBox(
                                      width:
                                          isTwoColumns ? (constraints.maxWidth - 30) / 2 : constraints.maxWidth,
                                      child: _LabeledField(
                                        label: 'Employee Number',
                                        child: TextFormField(
                                          controller: _employeeNoController,
                                          decoration: _inputDecoration(
                                            hint: 'Enter employee number (auto-generated if empty)',
                                          ),
                                        ),
                                      ),
                                    ),
                                    // First Name *
                                    SizedBox(
                                      width:
                                          isTwoColumns ? (constraints.maxWidth - 30) / 2 : constraints.maxWidth,
                                      child: _LabeledField(
                                        label: 'First Name *',
                                        child: TextFormField(
                                          controller: _firstNameController,
                                          decoration: _inputDecoration(
                                            hint: "Enter teacher's first name",
                                          ),
                                          validator: _requiredValidator,
                                        ),
                                      ),
                                    ),
                                    // Last Name
                                    SizedBox(
                                      width:
                                          isTwoColumns ? (constraints.maxWidth - 30) / 2 : constraints.maxWidth,
                                      child: _LabeledField(
                                        label: 'Last Name',
                                        child: TextFormField(
                                          controller: _lastNameController,
                                          decoration: _inputDecoration(
                                            hint: "Enter teacher's last name",
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Date of Birth
                                    SizedBox(
                                      width:
                                          isTwoColumns ? (constraints.maxWidth - 30) / 2 : constraints.maxWidth,
                                      child: _LabeledField(
                                        label: 'Date of Birth',
                                        child: InkWell(
                                          onTap: () async {
                                            final date = await showDatePicker(
                                              context: context,
                                              initialDate: DateTime.now().subtract(const Duration(days: 365 * 30)),
                                              firstDate: DateTime(1950),
                                              lastDate: DateTime.now(),
                                            );
                                            if (date != null) {
                                              setState(() => _dob = date);
                                            }
                                          },
                                          child: InputDecorator(
                                            decoration: _inputDecoration(
                                              hint: 'Select date of birth',
                                            ),
                                            child: Text(
                                              _dob != null
                                                  ? DateFormat('yyyy-MM-dd').format(_dob!)
                                                  : 'Select date of birth',
                                              style: TextStyle(
                                                color: _dob != null ? Colors.black : Colors.grey,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Gender
                                    SizedBox(
                                      width:
                                          isTwoColumns ? (constraints.maxWidth - 30) / 2 : constraints.maxWidth,
                                      child: _LabeledField(
                                        label: 'Gender',
                                        child: DropdownButtonFormField<String>(
                                          initialValue: _gender,
                                          items: const [
                                            DropdownMenuItem(value: 'Male', child: Text('Male')),
                                            DropdownMenuItem(value: 'Female', child: Text('Female')),
                                            DropdownMenuItem(value: 'Other', child: Text('Other')),
                                          ],
                                          decoration: _inputDecoration(
                                            hint: 'Select gender',
                                          ),
                                          onChanged: (value) => setState(() => _gender = value),
                                        ),
                                      ),
                                    ),
                                    // Qualification
                                    SizedBox(
                                      width:
                                          isTwoColumns ? (constraints.maxWidth - 30) / 2 : constraints.maxWidth,
                                      child: _LabeledField(
                                        label: 'Qualification',
                                        child: TextFormField(
                                          controller: _qualificationController,
                                          decoration: _inputDecoration(
                                            hint: 'Enter qualification',
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Experience
                                    SizedBox(
                                      width: isTwoColumns ? (constraints.maxWidth - 30) / 2 : constraints.maxWidth,
                                      child: _LabeledField(
                                        label: 'Experience (Years)',
                                        child: TextFormField(
                                          controller: _experienceController,
                                          decoration: _inputDecoration(hint: 'e.g. 5'),
                                        ),
                                      ),
                                    ),
                                    // Salary
                                    SizedBox(
                                      width: isTwoColumns ? (constraints.maxWidth - 30) / 2 : constraints.maxWidth,
                                      child: _LabeledField(
                                        label: 'Salary',
                                        child: TextFormField(
                                          controller: _salaryController,
                                          decoration: _inputDecoration(hint: 'Enter salary'),
                                        ),
                                      ),
                                    ),
                                    // Joining Date
                                    SizedBox(
                                      width:
                                          isTwoColumns ? (constraints.maxWidth - 30) / 2 : constraints.maxWidth,
                                      child: _LabeledField(
                                        label: 'Joining Date',
                                        child: InkWell(
                                          onTap: () async {
                                            final date = await showDatePicker(
                                              context: context,
                                              initialDate: DateTime.now(),
                                              firstDate: DateTime(2000),
                                              lastDate: DateTime(2030),
                                            );
                                            if (date != null) {
                                              setState(() => _joiningDate = date);
                                            }
                                          },
                                          child: InputDecorator(
                                            decoration: _inputDecoration(
                                              hint: 'Select joining date',
                                            ),
                                            child: Text(
                                              _joiningDate != null
                                                  ? DateFormat('yyyy-MM-dd').format(_joiningDate!)
                                                  : 'Select joining date',
                                              style: TextStyle(
                                                color: _joiningDate != null ? Colors.black : Colors.grey,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Department *
                                    SizedBox(
                                      width:
                                          isTwoColumns ? (constraints.maxWidth - 30) / 2 : constraints.maxWidth,
                                      child: _LabeledField(
                                        label: 'Department *',
                                        child: TextFormField(
                                          controller: _departmentController,
                                          decoration: _inputDecoration(
                                            hint: 'Enter department',
                                          ),
                                          validator: (value) {
                                            if (value == null || value.trim().isEmpty) {
                                              return 'Please enter a department';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ),
                                    // Class Teacher Assignment
                                    SizedBox(
                                      width: constraints.maxWidth,
                                      child: _LabeledField(
                                        label: 'Class Teacher Assignment',
                                        child: Column(
                                          children: [
                                            CheckboxListTile(
                                              title: const Text('Assign as Class Teacher'),
                                              value: _isClassTeacher,
                                              onChanged: (value) => setState(() => _isClassTeacher = value ?? false),
                                              contentPadding: EdgeInsets.zero,
                                              controlAffinity: ListTileControlAffinity.leading,
                                            ),
                                            if (_isClassTeacher)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 10),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: DropdownButtonFormField<String>(
                                                        value: _classTeacherClass,
                                                        decoration: _inputDecoration(hint: 'Select Class'),
                                                        items: [
                                                          'Nursery',
                                                          'LKG',
                                                          'UKG',
                                                          'Class 1',
                                                          'Class 2',
                                                          'Class 3',
                                                          'Class 4',
                                                          'Class 5',
                                                          'Class 6',
                                                          'Class 7',
                                                          'Class 8',
                                                          'Class 9',
                                                          'Class 10',
                                                        ]
                                                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                                            .toList(),
                                                        onChanged: (v) => setState(() => _classTeacherClass = v),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 20),
                                                    Expanded(
                                                      child: DropdownButtonFormField<String>(
                                                        value: _classTeacherGrade,
                                                        decoration: _inputDecoration(hint: 'Select Section'),
                                                        items: ['A', 'B', 'C', 'D']
                                                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                                            .toList(),
                                                        onChanged: (v) => setState(() => _classTeacherGrade = v),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Mobile No
                                    SizedBox(
                                      width:
                                          isTwoColumns ? (constraints.maxWidth - 30) / 2 : constraints.maxWidth,
                                      child: _LabeledField(
                                        label: 'Mobile Number',
                                        child: TextFormField(
                                          controller: _mobileNoController,
                                          keyboardType: TextInputType.phone,
                                          decoration: _inputDecoration(
                                            hint: 'Enter mobile number',
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Email
                                    SizedBox(
                                      width:
                                          isTwoColumns ? (constraints.maxWidth - 30) / 2 : constraints.maxWidth,
                                      child: _LabeledField(
                                        label: 'Email Address',
                                        child: TextFormField(
                                          controller: _emailController,
                                          keyboardType: TextInputType.emailAddress,
                                          decoration: _inputDecoration(
                                            hint: 'Enter email address',
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Address
                                    SizedBox(
                                      width: constraints.maxWidth,
                                      child: _LabeledField(
                                        label: 'Address',
                                        child: TextFormField(
                                          controller: _addressController,
                                          maxLines: 3,
                                          decoration: _inputDecoration(
                                            hint: 'Enter complete address',
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Blood Group
                                    SizedBox(
                                      width:
                                          isTwoColumns ? (constraints.maxWidth - 30) / 2 : constraints.maxWidth,
                                      child: _LabeledField(
                                        label: 'Blood Group',
                                        child: DropdownButtonFormField<String>(
                                          initialValue: _bloodGroup,
                                          items: [
                                            const DropdownMenuItem<String>(
                                              value: null,
                                              child: Text('Select Blood Group'),
                                            ),
                                            ...bloodGroupOptions.map(
                                              (bg) => DropdownMenuItem<String>(
                                                value: bg,
                                                child: Text(bg),
                                              ),
                                            ),
                                          ],
                                          decoration: _inputDecoration(
                                            hint: 'Select blood group',
                                          ),
                                          onChanged: (value) => setState(() => _bloodGroup = value),
                                        ),
                                      ),
                                    ),
                                    // Nationality
                                    SizedBox(
                                      width:
                                          isTwoColumns ? (constraints.maxWidth - 30) / 2 : constraints.maxWidth,
                                      child: _LabeledField(
                                        label: 'Nationality',
                                        child: TextFormField(
                                          controller: _nationalityController,
                                          decoration: _inputDecoration(
                                            hint: 'Enter nationality',
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Subject Specialization
                                    SizedBox(
                                      width: constraints.maxWidth,
                                      child: _LabeledField(
                                        label: 'Subject Specialization',
                                        child: TextFormField(
                                          controller: _subjectSpecializationController,
                                          maxLines: 3,
                                          decoration: _inputDecoration(
                                            hint: 'Enter subject specialization details',
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Emergency Contact
                                    SizedBox(
                                      width:
                                          isTwoColumns ? (constraints.maxWidth - 30) / 2 : constraints.maxWidth,
                                      child: _LabeledField(
                                        label: 'Emergency Contact',
                                        child: TextFormField(
                                          controller: _emergencyContactController,
                                          keyboardType: TextInputType.phone,
                                          decoration: _inputDecoration(
                                            hint: 'Enter emergency contact number',
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Emergency Contact Relation
                                    SizedBox(
                                      width:
                                          isTwoColumns ? (constraints.maxWidth - 30) / 2 : constraints.maxWidth,
                                      child: _LabeledField(
                                        label: 'Emergency Contact Relation',
                                        child: TextFormField(
                                          controller: _emergencyContactRelationController,
                                          decoration: _inputDecoration(
                                            hint: 'e.g. Spouse, Parent',
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Profile Photo
                                    SizedBox(
                                      width: constraints.maxWidth,
                                      child: _LabeledField(
                                        label: 'Profile Photo',
                                        child: _PhotoUploader(
                                          onTap: _pickPhoto,
                                          photoBytes: _photoBytes,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 30),
                            Wrap(
                              spacing: 15,
                              runSpacing: 15,
                              alignment: WrapAlignment.center,
                              children: [
                                _GradientButton(
                                  label: '💾 Save Teacher',
                                  colors: const [
                                    Color(0xFF667EEA),
                                    Color(0xFF764BA2),
                                  ],
                                  onTap: _isSubmitting ? null : _submitForm,
                                ),
                                _GradientButton(
                                  label: '👁️ Preview',
                                  colors: const [
                                    Color(0xFF6C757D),
                                    Color(0xFF495057),
                                  ],
                                  onTap: _previewTeacher,
                                ),
                                _GradientButton(
                                  label: '❌ Cancel',
                                  colors: const [
                                    Color(0xFFFF6B6B),
                                    Color(0xFFEE5A52),
                                  ],
                                  onTap: () => Navigator.pushReplacementNamed(context, '/teachers'),
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
            ),
          ),
        ),
      ),
    ),
    ],
     ),
    );
}
}
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text(
            '👨‍🏫 Add New Teacher',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Fill in the details below to add a new teacher to the system',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE1E5E9), width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE1E5E9), width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }


class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabeledField({
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _PhotoUploader extends StatelessWidget {
  final VoidCallback onTap;
  final Uint8List? photoBytes;

  const _PhotoUploader({
    required this.onTap,
    required this.photoBytes,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFF667EEA),
            width: 2,
            style: BorderStyle.solid,
          ),
          color: const Color(0x1A667EEA),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.photo_camera, size: 48, color: Color(0xFF667EEA)),
            const SizedBox(height: 10),
            const Text(
              'Click to upload photo or drag and drop',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF666666)),
            ),
            if (photoBytes != null) ...[
              const SizedBox(height: 16),
              CircleAvatar(
                radius: 50,
                backgroundImage: MemoryImage(photoBytes!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final List<Color> colors;
  final VoidCallback? onTap;

  const _GradientButton({
    required this.label,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: onTap == null ? 0.6 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(colors: colors),
            boxShadow: [
              BoxShadow(
                color: colors.last.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  final String message;
  final List<Color> colors;

  const _MessageBanner._({
    required this.message,
    required this.colors,
  });

  const _MessageBanner.success({required String message})
      : this._(
          message: message,
          colors: const [Color(0xFF51CF66), Color(0xFF40C057)],
        );

  const _MessageBanner.error({required String message})
      : this._(
          message: message,
          colors: const [Color(0xFFFF6B6B), Color(0xFFEE5A52)],
        );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(colors: colors),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation(Color(0xFF667EEA)),
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Saving teacher information...',
          style: TextStyle(color: Color(0xFF666666)),
        ),
      ],
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final String label;
  final String? value;

  const _PreviewRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          text: '$label: ',
          style: const TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.w600,
          ),
          children: [
            TextSpan(
              text: (value?.isEmpty ?? true) ? 'Not provided' : value,
              style: const TextStyle(
                color: Color(0xFF555555),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TeacherPreviewData {
  final String? employeeNo;
  final String? firstName;
  final String? lastName;
  final String? department;
  final String? mobileNo;
  final String? email;
  final String? address;
  final String? qualification;
  final String? subjectSpecialization;

  const TeacherPreviewData({
    required this.employeeNo,
    required this.firstName,
    required this.lastName,
    required this.department,
    required this.mobileNo,
    required this.email,
    required this.address,
    required this.qualification,
    required this.subjectSpecialization,
  });
}

class _NavItem extends StatelessWidget {
  final String icon;
  final String title;
  final VoidCallback? onTap;
  final bool isActive;

  const _NavItem({
    required this.icon,
    required this.title,
    this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.white.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Text(
          icon,
          style: const TextStyle(fontSize: 18),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onTap: onTap,
      ),
    );
  }
}
