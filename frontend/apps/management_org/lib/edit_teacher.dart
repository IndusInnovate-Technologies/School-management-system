import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:core/api/api_service.dart';
import 'package:core/api/endpoints.dart';
import 'widgets/school_profile_header.dart';
import 'widgets/management_sidebar.dart';

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

class EditTeacherPage extends StatefulWidget {
  final String? employeeNo;

  const EditTeacherPage({super.key, this.employeeNo});

  @override
  State<EditTeacherPage> createState() => _EditTeacherPageState();
}

class _EditTeacherPageState extends State<EditTeacherPage> {
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
  bool _isClassTeacher = false;
  String? _classTeacherClass;
  String? _classTeacherSection;
  
  DateTime? _dob;
  DateTime? _joiningDate;
  Uint8List? _photoBytes;

  bool _isSubmitting = false;
  bool _showSuccess = false;
  bool _showError = false;
  String _errorMessage = '';



  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  Future<void> _loadTeacherData() async {
    if (widget.employeeNo == null || widget.employeeNo!.isEmpty) return;
    try {
      // Use core ApiService for authenticated requests
      final apiService = ApiService();
      await apiService.initialize();
      final response = await apiService.get('${Endpoints.teachers}${widget.employeeNo}/');
      
      if (!response.success || response.data == null) {
        throw Exception(response.error ?? 'Failed to load teacher');
      }
      
      final data = response.data as Map<String, dynamic>;
      
      _employeeNoController.text = data['employee_no'] as String? ?? '';
      _firstNameController.text = data['first_name'] as String? ?? '';
      _lastNameController.text = data['last_name'] as String? ?? '';
      _qualificationController.text = data['qualification'] as String? ?? '';
      // Set department - prioritize department_name if available, else try department object/string
      if (data['department_name'] != null && data['department_name'].toString().isNotEmpty) {
        _departmentController.text = data['department_name'].toString();
      } else if (data['department'] != null) {
        if (data['department'] is Map) {
          _departmentController.text = data['department']['name']?.toString() ?? '';
        } else {
          _departmentController.text = data['department'].toString();
        }
      }
      _gender = data['gender'] as String?;
      _mobileNoController.text = data['mobile_no'] as String? ?? '';
      _emailController.text = data['email'] as String? ?? '';
      _addressController.text = data['address'] as String? ?? '';
      _bloodGroup = data['blood_group'] as String?;
      _nationalityController.text = data['nationality'] as String? ?? '';
      _subjectSpecializationController.text = data['subject_specialization'] as String? ?? '';
      _emergencyContactController.text = data['emergency_contact'] as String? ?? '';
      _isClassTeacher = data['is_class_teacher'] as bool? ?? false;
      _classTeacherClass = data['class_teacher_class'] as String?;
      _classTeacherSection = data['class_teacher_section'] as String?;
      
      if (data['dob'] != null) {
        _dob = DateTime.tryParse(data['dob']);
      }
      if (data['joining_date'] != null) {
        _joiningDate = DateTime.tryParse(data['joining_date']);
      }
      
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load teacher: $e')),
      );
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
      _errorMessage = '';
    });

    try {
      // Note: Profile photo will be sent as multipart/form-data with the request
      // The backend handles file upload directly

      final payload = <String, dynamic>{
        'employee_no': _employeeNoController.text.trim(),
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'qualification': _qualificationController.text.trim(),
        'department_name': _departmentController.text.trim(),
        'joining_date': _joiningDate != null 
            ? DateFormat('yyyy-MM-dd').format(_joiningDate!) 
            : null,
        'dob': _dob != null 
            ? DateFormat('yyyy-MM-dd').format(_dob!) 
            : null,
        'gender': _gender,
        'department': _departmentController.text.trim(),
        'mobile_no': _mobileNoController.text.trim(),
        'email': _emailController.text.trim(),
        'address': _addressController.text.trim(),
        if (_bloodGroup != null && _bloodGroup!.isNotEmpty) 'blood_group': _bloodGroup,
        'nationality': _nationalityController.text.trim(),
        'is_class_teacher': _isClassTeacher,
        if (_isClassTeacher && _classTeacherClass != null && _classTeacherClass!.isNotEmpty) 
          'class_teacher_class': _classTeacherClass,
        if (_isClassTeacher && _classTeacherSection != null && _classTeacherSection!.isNotEmpty) 
          'class_teacher_section': _classTeacherSection,
        'subject_specialization': _subjectSpecializationController.text.trim(),
        'emergency_contact': _emergencyContactController.text.trim(),
      };

      if (widget.employeeNo != null && widget.employeeNo!.isNotEmpty) {
        // Use core ApiService for authenticated requests
        final apiService = ApiService();
        await apiService.initialize();
        
        // If photo is available, use multipart upload, otherwise use JSON
        // Convert Map<String, dynamic> to Map<String, String> for uploadFile
        Map<String, String>? additionalFieldsString;
        if (_photoBytes != null && _photoBytes!.isNotEmpty) {
          additionalFieldsString = <String, String>{};
          payload.forEach((key, value) {
            if (value != null) {
              additionalFieldsString![key] = value.toString();
            }
          });
        }
        
        final response = _photoBytes != null && _photoBytes!.isNotEmpty
            ? await apiService.uploadFile(
                '${Endpoints.teachers}${widget.employeeNo}/',
                fileBytes: _photoBytes!,
                fileName: 'teacher_photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
                fieldName: 'profile_photo',
                additionalFields: additionalFieldsString,
              )
            : await apiService.put('${Endpoints.teachers}${widget.employeeNo}/', body: payload);
        
        if (!response.success) {
          throw Exception(response.error ?? 'Failed to update teacher');
        }
      }

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _showSuccess = true;
        _showError = false;
      });
      Navigator.pushReplacementNamed(context, '/teachers');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _showSuccess = false;
        _showError = true;
        _errorMessage = 'Error updating teacher: $e';
      });
    }
  }

  void _previewTeacher() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('👨‍🏫 Teacher Preview'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PreviewItem('Employee No', _employeeNoController.text),
              _PreviewItem('Name', '${_firstNameController.text} ${_lastNameController.text}'.trim()),
              _PreviewItem('Department', _departmentController.text),
              _PreviewItem('Gender', _gender ?? 'Not provided'),
              _PreviewItem('Mobile No', _mobileNoController.text),
              _PreviewItem('Email', _emailController.text),
              _PreviewItem('Address', _addressController.text),
              _PreviewItem('Blood Group', _bloodGroup ?? 'Not provided'),
              _PreviewItem('Nationality', _nationalityController.text),
              _PreviewItem('Qualification', _qualificationController.text),
              _PreviewItem('Subject Specialization', _subjectSpecializationController.text),
              _PreviewItem('Emergency Contact', _emergencyContactController.text),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
              foregroundColor: Colors.white,
            ),
            child: const Text('Close Preview'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gradient = const LinearGradient(
      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      body: Row(
        children: [
          ManagementSidebar(gradient: gradient, activeRoute: '/teachers'),
          Expanded(
            child: Container(
              color: const Color(0xFFF5F6FA),
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _Header(gradient: gradient),
                      _FormCard(
                        formKey: _formKey,
                        gradient: gradient,
                        employeeNoController: _employeeNoController,
                        firstNameController: _firstNameController,
                        lastNameController: _lastNameController,
                        qualificationController: _qualificationController,
                        departmentController: _departmentController,

                        gender: _gender,
                        onGenderChanged: (value) {
                          setState(() {
                            _gender = value;
                          });
                        },
                        dob: _dob,
                        onDobChanged: (value) {
                          setState(() {
                            _dob = value;
                          });
                        },
                        joiningDate: _joiningDate,
                        onJoiningDateChanged: (value) {
                          setState(() {
                            _joiningDate = value;
                          });
                        },
                        mobileNoController: _mobileNoController,
                        emailController: _emailController,
                        addressController: _addressController,
                        bloodGroup: _bloodGroup,
                        onBloodGroupChanged: (value) => setState(() => _bloodGroup = value),
                        nationalityController: _nationalityController,
                        isClassTeacher: _isClassTeacher,
                        onIsClassTeacherChanged: (value) {
                          setState(() {
                            _isClassTeacher = value;
                            if (!value) {
                              _classTeacherClass = null;
                              _classTeacherSection = null;
                            }
                          });
                        },
                        classTeacherClass: _classTeacherClass,
                        onClassTeacherClassChanged: (value) {
                          setState(() {
                            _classTeacherClass = value;
                          });
                        },
                        classTeacherSection: _classTeacherSection,
                        onClassTeacherSectionChanged: (value) {
                          setState(() {
                            _classTeacherSection = value;
                          });
                        },
                        subjectSpecializationController: _subjectSpecializationController,
                        emergencyContactController: _emergencyContactController,
                        photoBytes: _photoBytes,
                        onPickPhoto: _pickPhoto,
                        isSubmitting: _isSubmitting,
                        showSuccess: _showSuccess,
                        showError: _showError,
                        errorMessage: _errorMessage,
                        onSubmit: _submitForm,
                        onPreview: _previewTeacher,
                      ),
                    ],
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



class _Header extends StatelessWidget {
  final LinearGradient gradient;

  const _Header({required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Edit Teacher',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Row(
            children: [
              SchoolProfileHeader(apiService: ApiService()),
              const SizedBox(width: 15),
              ElevatedButton.icon(
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacementNamed(context, '/teachers');
                  }
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Teachers'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[700],
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final LinearGradient gradient;
  final TextEditingController employeeNoController;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController qualificationController;
  final TextEditingController departmentController;
  final String? gender;
  final ValueChanged<String?> onGenderChanged;
  final DateTime? dob;
  final ValueChanged<DateTime?> onDobChanged;
  final DateTime? joiningDate;
  final ValueChanged<DateTime?> onJoiningDateChanged;
  final TextEditingController mobileNoController;
  final TextEditingController emailController;
  final TextEditingController addressController;
  final String? bloodGroup;
  final ValueChanged<String?> onBloodGroupChanged;
  final TextEditingController nationalityController;
  final bool isClassTeacher;
  final ValueChanged<bool> onIsClassTeacherChanged;
  final String? classTeacherClass;
  final ValueChanged<String?> onClassTeacherClassChanged;
  final String? classTeacherSection;
  final ValueChanged<String?> onClassTeacherSectionChanged;
  final TextEditingController subjectSpecializationController;
  final TextEditingController emergencyContactController;
  final Uint8List? photoBytes;
  final Future<void> Function() onPickPhoto;
  final bool isSubmitting;
  final bool showSuccess;
  final bool showError;
  final String errorMessage;
  final Future<void> Function() onSubmit;
  final VoidCallback onPreview;

  _FormCard({
    required this.formKey,
    required this.gradient,
    required this.employeeNoController,
    required this.firstNameController,
    required this.lastNameController,
    required this.qualificationController,
    required this.departmentController,
    required this.gender,
    required this.onGenderChanged,
    required this.dob,
    required this.onDobChanged,
    required this.joiningDate,
    required this.onJoiningDateChanged,
    required this.mobileNoController,
    required this.emailController,
    required this.addressController,
    required this.bloodGroup,
    required this.onBloodGroupChanged,
    required this.nationalityController,
    required this.isClassTeacher,
    required this.onIsClassTeacherChanged,
    required this.classTeacherClass,
    required this.onClassTeacherClassChanged,
    required this.classTeacherSection,
    required this.onClassTeacherSectionChanged,
    required this.subjectSpecializationController,
    required this.emergencyContactController,
    required this.photoBytes,
    required this.onPickPhoto,
    required this.isSubmitting,
    required this.showSuccess,
    required this.showError,
    required this.errorMessage,
    required this.onSubmit,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      constraints: const BoxConstraints(maxWidth: 800),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Column(
                children: [
                  Text(
                    '👨‍🏫 Edit Teacher Information',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Update teacher details and save changes',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            if (showSuccess)
              _MessageBanner(
                gradientColors: const [Color(0xFF51CF66), Color(0xFF40C057)],
                icon: Icons.check_circle,
                text: '✅ Teacher information updated successfully!',
              ),
            if (showError)
              _MessageBanner(
                gradientColors: const [Color(0xFFFF6B6B), Color(0xFFEE5A52)],
                icon: Icons.error,
                text: '❌ $errorMessage',
              ),
            if (isSubmitting)
              const _LoadingBanner(text: 'Updating teacher information...'),
            _PhotoUpload(
              gradient: gradient,
              photoBytes: photoBytes,
              onPickPhoto: onPickPhoto,
            ),
            const SizedBox(height: 20),
            // Employee Number
            TextFormField(
              controller: employeeNoController,
              decoration: InputDecoration(
                labelText: 'Employee Number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.work),
              ),
            ),
            const SizedBox(height: 20),
            // First Name and Last Name
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: firstNameController,
                    decoration: InputDecoration(
                      labelText: 'First Name *',
                      hintText: 'Enter first name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter first name';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: TextFormField(
                    controller: lastNameController,
                    decoration: InputDecoration(
                      labelText: 'Last Name',
                      hintText: 'Enter last name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Date of Birth and Gender
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: dob ?? DateTime.now().subtract(const Duration(days: 365 * 30)),
                        firstDate: DateTime(1950),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        onDobChanged(date);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Date of Birth',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        dob != null
                            ? DateFormat('yyyy-MM-dd').format(dob!)
                            : 'Select date of birth',
                        style: TextStyle(
                          color: dob != null ? Colors.black : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Gender',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.people),
                    ),
                    initialValue: gender,
                    items: const [
                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                      DropdownMenuItem(value: 'Female', child: Text('Female')),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                    ],
                    onChanged: onGenderChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Qualification and Joining Date
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: qualificationController,
                    decoration: InputDecoration(
                      labelText: 'Qualification',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.school),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: joiningDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        onJoiningDateChanged(date);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Joining Date',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.event),
                      ),
                      child: Text(
                        joiningDate != null
                            ? DateFormat('yyyy-MM-dd').format(joiningDate!)
                            : 'Select joining date',
                        style: TextStyle(
                          color: joiningDate != null ? Colors.black : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Department
            // Department
            TextFormField(
              controller: departmentController,
              decoration: InputDecoration(
                labelText: 'Department *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.business),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a department';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            // Mobile No and Email
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: mobileNoController,
                    decoration: InputDecoration(
                      labelText: 'Mobile Number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Address
            TextFormField(
              controller: addressController,
              decoration: InputDecoration(
                labelText: 'Address',
                hintText: 'Enter complete address',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.location_on),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            // Blood Group and Nationality
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: bloodGroup,
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
                    decoration: InputDecoration(
                      labelText: 'Blood Group',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.bloodtype),
                    ),
                    onChanged: onBloodGroupChanged,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: TextFormField(
                    controller: nationalityController,
                    decoration: InputDecoration(
                      labelText: 'Nationality',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.public),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Class Teacher Assignment Section
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Is Class Teacher'),
                    value: isClassTeacher,
                    onChanged: (value) {
                      onIsClassTeacherChanged(value ?? false);
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            if (isClassTeacher) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Class *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.school),
                      ),
                      initialValue: classTeacherClass,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Select Class')),
                        ...List.generate(10, (index) => 'Class ${index + 1}')
                            .map((c) => DropdownMenuItem(value: c, child: Text(c))),
                      ],
                      onChanged: onClassTeacherClassChanged,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Section *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.star),
                      ),
                      initialValue: classTeacherSection,
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Select Section')),
                        DropdownMenuItem(value: 'A', child: Text('Section A')),
                        DropdownMenuItem(value: 'B', child: Text('Section B')),
                        DropdownMenuItem(value: 'C', child: Text('Section C')),
                        DropdownMenuItem(value: 'D', child: Text('Section D')),
                      ],
                      onChanged: onClassTeacherSectionChanged,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            // Subject Specialization
            TextFormField(
              controller: subjectSpecializationController,
              decoration: InputDecoration(
                labelText: 'Subject Specialization',
                hintText: 'Enter subject specialization details',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.star),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            // Emergency Contact
            TextFormField(
              controller: emergencyContactController,
              decoration: InputDecoration(
                labelText: 'Emergency Contact',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.emergency),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: isSubmitting ? null : onSubmit,
                  icon: const Icon(Icons.save),
                  label: const Text('Update Teacher'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667EEA),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
                const SizedBox(width: 15),
                ElevatedButton.icon(
                  onPressed: onPreview,
                  icon: const Icon(Icons.preview),
                  label: const Text('Preview'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD93D),
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
                const SizedBox(width: 15),
                ElevatedButton.icon(
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      Navigator.pushReplacementNamed(context, '/teachers');
                    }
                  },
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B6B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
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

class _MessageBanner extends StatelessWidget {
  final List<Color> gradientColors;
  final IconData icon;
  final String text;

  const _MessageBanner({
    required this.gradientColors,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingBanner extends StatelessWidget {
  final String text;

  const _LoadingBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
            ),
          ),
          const SizedBox(height: 15),
          Text(text),
        ],
      ),
    );
  }
}

class _PhotoUpload extends StatelessWidget {
  final LinearGradient gradient;
  final Uint8List? photoBytes;
  final Future<void> Function() onPickPhoto;

  const _PhotoUpload({
    required this.gradient,
    required this.photoBytes,
    required this.onPickPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onPickPhoto,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (photoBytes != null)
              ClipOval(
                child: Image.memory(
                  photoBytes!,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: gradient,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.photo_camera, color: Colors.white, size: 40),
                ),
              ),
            const SizedBox(height: 15),
            const Text(
              'Tap to upload new photo or drag and drop',
              style: TextStyle(
                color: Color(0xFF667EEA),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewItem extends StatelessWidget {
  final String label;
  final String value;

  const _PreviewItem(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

