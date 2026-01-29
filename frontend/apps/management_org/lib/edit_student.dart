import 'services/api_service.dart';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:core/api/api_service.dart' as core_api;
import 'widgets/school_profile_header.dart';

class EditStudentPage extends StatefulWidget {
  final int? studentId;

  const EditStudentPage({super.key, this.studentId});

  @override
  State<EditStudentPage> createState() => _EditStudentPageState();
}

class _EditStudentPageState extends State<EditStudentPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _admissionNumberController = TextEditingController();
  final _rollNumberController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _parentEmailController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _addressController = TextEditingController();
  final _medicalConditionsController = TextEditingController();
  final _notesController = TextEditingController();
  final _activitiesController = TextEditingController();
  final _leadershipController = TextEditingController();
  final _achievementsController = TextEditingController();
  final _participationController = TextEditingController();

  String? _studentClass;
  String? _section;
  String? _bloodGroup;
  DateTime? _dateOfBirth;
  String? _gender;
  String? _busRoute;
  Uint8List? _photoBytes;

  bool _isSubmitting = false;
  bool _showSuccess = false;
  bool _showError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    if (widget.studentId == null) return;

    try {
      final data = await ApiService.fetchStudentById(widget.studentId!);

      final user = data['user'] as Map<String, dynamic>? ?? {};
      final firstName = user['first_name'] as String? ?? '';
      final lastName = user['last_name'] as String? ?? '';
      final fullName = '$firstName $lastName'.trim();

      _nameController.text = fullName.isNotEmpty ? fullName : (data['name'] as String? ?? '');
      _studentClass = data['class_name'] as String?;
      _section = data['section'] as String?;
      _bloodGroup = data['blood_group'] as String?;

      final dob = data['date_of_birth'] as String?;
      if (dob != null && dob.isNotEmpty) {
        _dateOfBirth = DateTime.tryParse(dob);
      }

      _gender = data['gender'] as String?;
      _admissionNumberController.text = data['student_id'] as String? ?? '';
      _rollNumberController.text = data['student_id'] as String? ?? '';
      _parentNameController.text = data['parent_name'] as String? ?? '';
      _parentPhoneController.text = data['parent_phone'] as String? ?? '';
      _parentEmailController.text = user['email'] as String? ?? '';
      _emergencyContactController.text =
          data['emergency_contact'] as String? ?? '';
      _addressController.text = data['address'] as String? ?? '';
      _busRoute = data['bus_route'] as String?;
      _medicalConditionsController.text =
          data['medical_info'] as String? ?? '';
      _notesController.text = data['notes'] as String? ?? '';
      _activitiesController.text = data['activities'] as String? ?? '';
      _leadershipController.text = data['leadership'] as String? ?? '';
      _achievementsController.text = data['achievements'] as String? ?? '';
      _participationController.text = data['participation'] as String? ?? '';
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load student: $e')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _admissionNumberController.dispose();
    _rollNumberController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _parentEmailController.dispose();
    _emergencyContactController.dispose();
    _addressController.dispose();
    _medicalConditionsController.dispose();
    _notesController.dispose();
    _activitiesController.dispose();
    _leadershipController.dispose();
    _achievementsController.dispose();
    _participationController.dispose();
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

    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date of birth')),
      );
      return;
    }
    if (_gender == null || _gender!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select gender')),
      );
      return;
    }
    if (_studentClass == null || _studentClass!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select class')),
      );
      return;
    }
    if (_section == null || _section!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select section')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _showSuccess = false;
      _showError = false;
      _errorMessage = '';
    });

    try {
      final payload = {
        'student_id': _admissionNumberController.text.trim().isNotEmpty
            ? _admissionNumberController.text.trim()
            : _rollNumberController.text.trim(),
        'class_name': _studentClass,
        'section': _section,
        'date_of_birth': DateFormat('yyyy-MM-dd').format(_dateOfBirth!),
        'gender': _gender,
        'blood_group': _bloodGroup,
        'address': _addressController.text.trim(),
        'emergency_contact': _emergencyContactController.text.trim(),
        'medical_info': _medicalConditionsController.text.trim(),
        'parent_name': _parentNameController.text.trim(),
        'parent_phone': _parentPhoneController.text.trim(),
        'bus_route': _busRoute,
        'activities': _activitiesController.text.trim(),
        'leadership': _leadershipController.text.trim(),
        'achievements': _achievementsController.text.trim(),
        'participation': _participationController.text.trim(),
      };

      if (widget.studentId != null) {
        await ApiService.updateStudent(widget.studentId!, payload);
      }

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _showSuccess = true;
        _showError = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _showSuccess = false;
        _showError = true;
        _errorMessage = 'Error updating student: $e';
      });
    }
  }

  void _previewStudent() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Text('👥 Student Preview'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PreviewItem('Name', _nameController.text),
              _PreviewItem('Class',
                  '${_studentClass ?? 'Not provided'} • Section ${_section ?? 'Not provided'}'),
              _PreviewItem('Admission Number', _admissionNumberController.text),
              _PreviewItem('Roll Number', _rollNumberController.text),
              _PreviewItem('Date of Birth',
                  _dateOfBirth != null
                      ? DateFormat('yyyy-MM-dd').format(_dateOfBirth!)
                      : 'Not provided'),
              _PreviewItem('Gender', _gender ?? 'Not provided'),
              _PreviewItem('Blood Group', _bloodGroup ?? 'Not provided'),
              _PreviewItem('Parent Name', _parentNameController.text),
              _PreviewItem('Parent Phone', _parentPhoneController.text),
              _PreviewItem('Parent Email', _parentEmailController.text),
              _PreviewItem('Emergency Contact',
                  _emergencyContactController.text.isEmpty
                      ? 'Not provided'
                      : _emergencyContactController.text),
              _PreviewItem('Address', _addressController.text),
              _PreviewItem('Bus Route',
                  _busRoute == null || _busRoute!.isEmpty
                      ? 'Not assigned'
                      : _busRoute!),
              _PreviewItem('Medical Conditions',
                  _medicalConditionsController.text.isEmpty
                      ? 'None'
                      : _medicalConditionsController.text),
              _PreviewItem('Activities', _activitiesController.text.isEmpty ? 'Not provided' : _activitiesController.text),
              _PreviewItem('Leadership', _leadershipController.text.isEmpty ? 'Not provided' : _leadershipController.text),
              _PreviewItem('Achievements', _achievementsController.text.isEmpty ? 'Not provided' : _achievementsController.text),
              _PreviewItem('Participation', _participationController.text.isEmpty ? 'Not provided' : _participationController.text),
              _PreviewItem('Notes',
                  _notesController.text.isEmpty
                      ? 'No additional notes'
                      : _notesController.text),
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
                          onTap: () => Navigator.pushReplacementNamed(
                              context, '/teachers'),
                        ),
                        _NavItem(
                          icon: '👥',
                          title: 'Students',
                          isActive: true,
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
                          onTap: () => Navigator.pushReplacementNamed(
                              context, '/activities'),
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
                  child: Column(
                    children: [
                      // Header
                      Container(
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
                              'Edit Student',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            Row(
                              children: [
                                SchoolProfileHeader(apiService: core_api.ApiService()),
                                const SizedBox(width: 15),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    if (Navigator.canPop(context)) {
                                      Navigator.pop(context);
                                    } else {
                                      Navigator.pushReplacementNamed(context, '/students');
                                    }
                                  },
                                  icon: const Icon(Icons.arrow_back),
                                  label: const Text('Back to Students'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[700],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Form Container
                      Container(
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
                        constraints: const BoxConstraints(maxWidth: 900),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Form Header
                              const Center(
                                child: Column(
                                  children: [
                                    Text(
                                      '👥 Edit Student Information',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'Update student details and save changes',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 30),
                              // Success/Error Messages
                              if (_showSuccess)
                                Container(
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF51CF66),
                                        Color(0xFF40C057)
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  margin: const EdgeInsets.only(bottom: 20),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.white),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          '✅ Student information updated successfully!',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (_showError)
                                Container(
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFF6B6B), Color(0xFFEE5A52)],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  margin: const EdgeInsets.only(bottom: 20),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error, color: Colors.white),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          '❌ $_errorMessage',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (_isSubmitting)
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  margin: const EdgeInsets.only(bottom: 20),
                                  child: const Column(
                                    children: [
                                      SizedBox(
                                        width: 40,
                                        height: 40,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 4,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                              Color(0xFF667EEA)),
                                        ),
                                      ),
                                      SizedBox(height: 15),
                                      Text('Updating student information...'),
                                    ],
                                  ),
                                ),
                              // Photo Upload
                              Center(
                                child: GestureDetector(
                                  onTap: _pickPhoto,
                                  child: Container(
                                    width: 150,
                                    height: 150,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: gradient,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 4,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.1),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: _photoBytes != null
                                        ? ClipOval(
                                            child: Image.memory(
                                              _photoBytes!,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.camera_alt,
                                                color: Colors.white,
                                                size: 48,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                '📷',
                                                style: TextStyle(
                                                  fontSize: 24,
                                                  color: Colors.white.withValues(alpha: 0.9),
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 30),
                              // Form Fields
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: 'Full Name *',
                                  hintText: 'Enter student\'s full name',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  prefixIcon: const Icon(Icons.person),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter student name';
                                  }
                                  return null;
                                },
                              ),
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
                                      initialValue: _studentClass,
                                      items: const [
                                        DropdownMenuItem(
                                            value: 'Grade 9',
                                            child: Text('Grade 9')),
                                        DropdownMenuItem(
                                            value: 'Grade 10',
                                            child: Text('Grade 10')),
                                        DropdownMenuItem(
                                            value: 'Grade 11',
                                            child: Text('Grade 11')),
                                        DropdownMenuItem(
                                            value: 'Grade 12',
                                            child: Text('Grade 12')),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _studentClass = value;
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please select class';
                                        }
                                        return null;
                                      },
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
                                        prefixIcon: const Icon(Icons.class_),
                                      ),
                                      initialValue: _section,
                                      items: const [
                                        DropdownMenuItem(
                                            value: 'A', child: Text('Section A')),
                                        DropdownMenuItem(
                                            value: 'B', child: Text('Section B')),
                                        DropdownMenuItem(
                                            value: 'C', child: Text('Section C')),
                                        DropdownMenuItem(
                                            value: 'D', child: Text('Section D')),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _section = value;
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please select section';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      decoration: InputDecoration(
                                        labelText: 'Blood Group',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        prefixIcon: const Icon(Icons.bloodtype),
                                      ),
                                      initialValue: _bloodGroup,
                                      items: const [
                                        DropdownMenuItem(
                                            value: 'A+', child: Text('A+')),
                                        DropdownMenuItem(
                                            value: 'A-', child: Text('A-')),
                                        DropdownMenuItem(
                                            value: 'B+', child: Text('B+')),
                                        DropdownMenuItem(
                                            value: 'B-', child: Text('B-')),
                                        DropdownMenuItem(
                                            value: 'AB+', child: Text('AB+')),
                                        DropdownMenuItem(
                                            value: 'AB-', child: Text('AB-')),
                                        DropdownMenuItem(
                                            value: 'O+', child: Text('O+')),
                                        DropdownMenuItem(
                                            value: 'O-', child: Text('O-')),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _bloodGroup = value;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () async {
                                        final date = await showDatePicker(
                                          context: context,
                                          initialDate: _dateOfBirth ??
                                              DateTime.now().subtract(
                                                  const Duration(days: 365 * 10)),
                                          firstDate: DateTime(1990),
                                          lastDate: DateTime.now(),
                                        );
                                        if (date != null) {
                                          setState(() {
                                            _dateOfBirth = date;
                                          });
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey[300]!),
                                          borderRadius: BorderRadius.circular(10),
                                          color: Colors.white,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.calendar_today,
                                                color: Colors.grey[600]),
                                            const SizedBox(width: 10),
                                            Text(
                                              _dateOfBirth == null
                                                  ? 'Date of Birth *'
                                                  : DateFormat('yyyy-MM-dd')
                                                      .format(_dateOfBirth!),
                                              style: TextStyle(
                                                color: _dateOfBirth == null
                                                    ? Colors.grey[600]
                                                    : Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      decoration: InputDecoration(
                                        labelText: 'Gender *',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        prefixIcon: const Icon(Icons.people),
                                      ),
                                      initialValue: _gender,
                                      items: const [
                                        DropdownMenuItem(
                                            value: 'Male', child: Text('Male')),
                                        DropdownMenuItem(
                                            value: 'Female', child: Text('Female')),
                                        DropdownMenuItem(
                                            value: 'Other', child: Text('Other')),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _gender = value;
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please select gender';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              if (_dateOfBirth == null)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 12, top: 4, bottom: 8),
                                  child: Text(
                                    'Please select date of birth',
                                    style: TextStyle(
                                      color: Colors.red[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _admissionNumberController,
                                      decoration: InputDecoration(
                                        labelText: 'Admission Number *',
                                        hintText: 'Enter admission number',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        prefixIcon: const Icon(Icons.badge),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter admission number';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _rollNumberController,
                                      decoration: InputDecoration(
                                        labelText: 'Roll Number',
                                        hintText: 'Enter roll number',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        prefixIcon: const Icon(Icons.numbers),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Parent/Guardian Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 15),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _parentNameController,
                                      decoration: InputDecoration(
                                        labelText: 'Parent/Guardian Name *',
                                        hintText: 'Enter parent/guardian name',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        prefixIcon: const Icon(Icons.family_restroom),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter parent name';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _parentPhoneController,
                                      decoration: InputDecoration(
                                        labelText: 'Parent Phone *',
                                        hintText: 'Enter parent phone number',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        prefixIcon: const Icon(Icons.phone),
                                      ),
                                      keyboardType: TextInputType.phone,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter parent phone';
                                        }
                                        if (value.length < 10) {
                                          return 'Please enter a valid phone number';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _parentEmailController,
                                      decoration: InputDecoration(
                                        labelText: 'Parent Email',
                                        hintText: 'Enter parent email',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        prefixIcon: const Icon(Icons.email),
                                      ),
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) {
                                        if (value != null &&
                                            value.isNotEmpty &&
                                            !value.contains('@')) {
                                          return 'Please enter a valid email';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _emergencyContactController,
                                      decoration: InputDecoration(
                                        labelText: 'Emergency Contact',
                                        hintText: 'Enter emergency contact',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        prefixIcon: const Icon(Icons.emergency),
                                      ),
                                      keyboardType: TextInputType.phone,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _addressController,
                                decoration: InputDecoration(
                                  labelText: 'Address *',
                                  hintText: 'Enter complete address',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  prefixIcon: const Icon(Icons.location_on),
                                ),
                                maxLines: 3,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter address';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      decoration: InputDecoration(
                                        labelText: 'Bus Route',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        prefixIcon: const Icon(Icons.directions_bus),
                                      ),
                                      initialValue: _busRoute,
                                      items: const [
                                        DropdownMenuItem(
                                            value: null, child: Text('Not assigned')),
                                        DropdownMenuItem(
                                            value: 'Route 1', child: Text('Route 1')),
                                        DropdownMenuItem(
                                            value: 'Route 2', child: Text('Route 2')),
                                        DropdownMenuItem(
                                            value: 'Route 3', child: Text('Route 3')),
                                        DropdownMenuItem(
                                            value: 'Route 4', child: Text('Route 4')),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _busRoute = value;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _medicalConditionsController,
                                decoration: InputDecoration(
                                  labelText: 'Medical Conditions',
                                  hintText:
                                      'Enter any medical conditions or allergies',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  prefixIcon: const Icon(Icons.medical_services),
                                ),
                                maxLines: 3,
                              ),
                              const SizedBox(height: 20),
                               FormFieldSection(
                                title: '🌟 Extracurricular & Achievements',
                                children: [
                                  TextFormField(
                                    controller: _activitiesController,
                                    decoration: InputDecoration(
                                      labelText: 'Extracurricular Activities',
                                      hintText: 'Enter student\'s activities (sports, arts, etc.)',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      filled: true,
                                      fillColor: Colors.white,
                                      prefixIcon: const Icon(Icons.star),
                                    ),
                                    maxLines: 2,
                                  ),
                                  const SizedBox(height: 20),
                                  TextFormField(
                                    controller: _leadershipController,
                                    decoration: InputDecoration(
                                      labelText: 'Leadership Roles',
                                      hintText: 'Enter leadership positions (prefect, captain, etc.)',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      filled: true,
                                      fillColor: Colors.white,
                                      prefixIcon: const Icon(Icons.leaderboard),
                                    ),
                                    maxLines: 2,
                                  ),
                                  const SizedBox(height: 20),
                                  TextFormField(
                                    controller: _achievementsController,
                                    decoration: InputDecoration(
                                      labelText: 'Other Achievements',
                                      hintText: 'Enter special mentions or other achievements',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      filled: true,
                                      fillColor: Colors.white,
                                      prefixIcon: const Icon(Icons.emoji_events),
                                    ),
                                    maxLines: 2,
                                  ),
                                  const SizedBox(height: 20),
                                  TextFormField(
                                    controller: _participationController,
                                    decoration: InputDecoration(
                                      labelText: 'Participation Record',
                                      hintText: 'Enter notable events or competition participation',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      filled: true,
                                      fillColor: Colors.white,
                                      prefixIcon: const Icon(Icons.group),
                                    ),
                                    maxLines: 2,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _notesController,
                                decoration: InputDecoration(
                                  labelText: 'Additional Notes',
                                  hintText: 'Enter any additional notes or comments',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  prefixIcon: const Icon(Icons.note),
                                ),
                                maxLines: 3,
                              ),
                              const SizedBox(height: 30),
                              // Buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: _isSubmitting ? null : _submitForm,
                                    icon: const Icon(Icons.save),
                                    label: const Text('Update Student'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF667EEA),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 12),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  ElevatedButton.icon(
                                    onPressed: _previewStudent,
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
                                    onPressed: () => Navigator.pushReplacementNamed(context, '/students'),
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
                      ),
                      const SizedBox(height: 20),
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
}class FormFieldSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const FormFieldSection({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        ...children,
      ],
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

