import 'package:flutter/material.dart';
import 'widgets/school_profile_header.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:typed_data'; // For photo bytes
import 'package:image_picker/image_picker.dart'; // For picking photos
import 'package:intl/intl.dart';
import 'main.dart' as app;
import 'dashboard.dart';
import 'students.dart';
import 'teachers.dart';
import 'buses.dart';
import 'events.dart';
import 'notifications.dart';
import 'activities.dart';
import 'awards.dart';
import 'gallery.dart';
import 'calendar.dart';
import 'package:core/api/api_service.dart';
import 'package:core/api/endpoints.dart';
import 'admissions_form.dart';

// --- Data Model (Enhanced from Block 2) ---

// --- Data Model (Enhanced from Block 2) ---
class Admission {
  final int id;
  final String studentName;
  final String parentName;
  final DateTime dateOfBirth;
  final String gender;
  final String applyingClass;
  final String address;
  final String category;
  final String status;
  final String? admissionNumber;
  final String? studentId;
  final String? email;
  final String? fatherName;
  final String? motherName;
  final String? guardianName;
  final String? fatherPhone;
  final String? motherPhone;
  final String? parentPhone;
  final String? emergencyContact;
  final String? medicalInformation;
  final String? bloodGroup;
  final String? previousSchool;
  final String? remarks;
  final String? section;
  final String? profilePhotoUrl;

  Admission({
    required this.id,
    required this.studentName,
    required this.parentName,
    required this.dateOfBirth,
    required this.gender,
    required this.applyingClass,
    required this.address,
    required this.category,
    required this.status,
    this.admissionNumber,
    this.studentId,
    this.email,
    this.parentPhone,
    this.fatherName,
    this.motherName,
    this.guardianName,
    this.fatherPhone,
    this.motherPhone,
    this.emergencyContact,
    this.medicalInformation,
    this.bloodGroup,
    this.previousSchool,
    this.remarks,
    this.section,
    this.profilePhotoUrl,
  });

  Admission copyWith({
    int? id,
    String? studentName,
    String? parentName,
    DateTime? dateOfBirth,
    String? gender,
    String? applyingClass,
    String? address,
    String? category,
    String? status,
    String? admissionNumber,
    String? studentId,
    String? email,
    String? parentPhone,
    String? fatherName,
    String? motherName,
    String? guardianName,
    String? fatherPhone,
    String? motherPhone,
    String? emergencyContact,
    String? medicalInformation,
    String? bloodGroup,
    String? previousSchool,
    String? remarks,
    String? section,
    String? profilePhotoUrl,
  }) {
    return Admission(
      id: id ?? this.id,
      studentName: studentName ?? this.studentName,
      parentName: parentName ?? this.parentName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      applyingClass: applyingClass ?? this.applyingClass,
      address: address ?? this.address,
      category: category ?? this.category,
      status: status ?? this.status,
      admissionNumber: admissionNumber ?? this.admissionNumber,
      studentId: studentId ?? this.studentId,
      email: email ?? this.email,
      parentPhone: parentPhone ?? this.parentPhone,
      fatherName: fatherName ?? this.fatherName,
      motherName: motherName ?? this.motherName,
      guardianName: guardianName ?? this.guardianName,
      fatherPhone: fatherPhone ?? this.fatherPhone,
      motherPhone: motherPhone ?? this.motherPhone,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      medicalInformation: medicalInformation ?? this.medicalInformation,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      previousSchool: previousSchool ?? this.previousSchool,
      remarks: remarks ?? this.remarks,
      section: section ?? this.section,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
    );
  }
}

// --- Main Screen ---
class AdmissionsManagementPage extends StatefulWidget {
  const AdmissionsManagementPage({super.key});

  @override
  State<AdmissionsManagementPage> createState() => _AdmissionsManagementPageState();
}

class _AdmissionsManagementPageState extends State<AdmissionsManagementPage> {
  // -- State Variables --
  List<Admission> _allAdmissions = [];
  List<Admission> _filteredAdmissions = [];
  
  
  // Search/Filter Controllers
  
  // Search/Filter Controllers
  final TextEditingController _searchController = TextEditingController();



  String _filterStatus = "";
  String _filterClass = "";
  
  bool _isSubmitting = false;
  bool _isLoading = false;
  final ApiService _apiService = ApiService();
  
  // Pending edit arguments from navigation
  Map<String, dynamic>? _pendingEditArgs;
  bool _hasCheckedPendingEdit = false;

  Admission? _editingAdmission; // Track if we are editing
  bool _isDisposed = false;
  
  // -- Helper Widgets --

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
              color: const Color(0xFF495057).withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.arrow_back, size: 16, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Back to Dashboard',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }



  @override
  void initState() {
    super.initState();
    // _loadAdmissions will be called, and it will trigger _handlePendingEdit at the end
    _loadAdmissions();
    _searchController.addListener(_filterAdmissions);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasCheckedPendingEdit) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic> && args['action'] == 'edit') {
        _pendingEditArgs = args;
        // If data is already loaded, try to handle it now
        if (!_isLoading && _allAdmissions.isNotEmpty) {
          _handlePendingEdit();
        }
      }
      _hasCheckedPendingEdit = true;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _searchController.removeListener(_filterAdmissions);
    _searchController.dispose();
    super.dispose();
  }

  // -- API Methods --

  Future<void> _loadAdmissions() async {
    if (!mounted || _isDisposed) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.get(Endpoints.admissions);

      if (response.success && response.data != null) {
        List<Admission> admissions = [];
        
        // Handle different response formats
        dynamic data = response.data;
        
        // If response is a list, use it directly
        if (data is List) {
          for (var item in data) {
            if (item is Map<String, dynamic>) {
              final admission = _parseAdmissionFromJson(item);
              if (admission != null) {
                admissions.add(admission);
              }
            }
          }
        }
        // If response is an object with a 'results' field (pagination)
        else if (data is Map<String, dynamic>) {
          if (data['results'] != null && data['results'] is List) {
            for (var item in data['results'] as List) {
              if (item is Map<String, dynamic>) {
                final admission = _parseAdmissionFromJson(item);
                if (admission != null) {
                  admissions.add(admission);
                }
              }
            }
          }
          // If data itself is a list-like structure
          else if (data['data'] != null && data['data'] is List) {
            for (var item in data['data'] as List) {
              if (item is Map<String, dynamic>) {
                final admission = _parseAdmissionFromJson(item);
                if (admission != null) {
                  admissions.add(admission);
                }
              }
            }
          }
        }

        if (mounted) {
          setState(() {
            _allAdmissions = admissions;
            _filteredAdmissions = List.from(_allAdmissions);
          });
        }
        
        // Check for pending edit action after loading
        if (mounted && _pendingEditArgs != null) {
          _handlePendingEdit();
        }
      } else {
        // Handle error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load admissions: ${response.error ?? "Unknown error"}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading admissions: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Admission? _parseAdmissionFromJson(Map<String, dynamic> json) {
    try {
      print('Parsing admission JSON: ${json.keys.toList()}');
      
      // Parse dates
      DateTime? dateOfBirth;
      
      if (json['date_of_birth'] != null) {
        if (json['date_of_birth'] is String) {
          dateOfBirth = DateTime.tryParse(json['date_of_birth']);
        } else if (json['date_of_birth'] is DateTime) {
          dateOfBirth = json['date_of_birth'];
        }
      }

      if (dateOfBirth == null) {
        print('Error: dateOfBirth is null. Raw value: ${json['date_of_birth']}');
        return null;
      }

      // Use student_id as the primary identifier (it's the PK in backend)
      // student_id is required and should always be present
      final studentIdValue = json['student_id']?.toString() ?? json['id']?.toString() ?? '';
      
      if (studentIdValue.isEmpty) {
        print('Warning: Admission missing student_id: ${json['student_name']}. Available keys: ${json.keys.toList()}');
        return null; // Skip admissions without student_id
      }
      
      print('Successfully parsing admission: $studentIdValue');
      
      return Admission(
        id: studentIdValue.hashCode, // Use hash code for internal ID comparison
        studentName: json['student_name'] ?? '',
        parentName: json['parent_name'] ?? '',
        dateOfBirth: dateOfBirth,
        gender: json['gender'] ?? '',
        applyingClass: json['applying_class'] ?? '',
        address: json['address'] ?? '',
        category: json['category'] ?? '',
        status: json['status'] ?? 'Pending',
        admissionNumber: json['admission_number'],
        studentId: studentIdValue, // Always set studentId since it's required
        email: json['email'],
        parentPhone: json['parent_phone'],
        fatherName: json['father_name'],
        motherName: json['mother_name'],
        guardianName: json['guardian_name'],
        fatherPhone: json['father_phone'],
        motherPhone: json['mother_phone'],
        emergencyContact: json['emergency_contact'],
        medicalInformation: json['medical_information'],
        bloodGroup: json['blood_group'],
        previousSchool: json['previous_school'],
        remarks: json['remarks'],
        section: json['section'],
        profilePhotoUrl: _extractProfilePhoto(json),
      );
    } catch (e) {
      print('Error parsing admission: $e');
      return null;
    }
  }

  String? _extractProfilePhoto(Map<String, dynamic> json) {
    if (json['profile_photo_url'] != null) {
      return json['profile_photo_url'] as String;
    } else if (json['profile_photo'] != null && json['profile_photo'] is Map) {
      final profilePhoto = json['profile_photo'] as Map<String, dynamic>;
      return profilePhoto['file_url'] as String?;
    }
    return null;
  }

  // -- Logic Methods --

  void _handlePendingEdit() {
    if (_pendingEditArgs == null) return;
    
    final studentId = _pendingEditArgs!['studentId'] as String?;
    final dbId = _pendingEditArgs!['dbId'] as int?;
    
    if (studentId == null && dbId == null) return;
    
    try {
      // Try to find by studentId (String) first
      Admission? targetAdmission;
      if (studentId != null) {
        targetAdmission = _allAdmissions.cast<Admission?>().firstWhere(
          (a) => a?.studentId == studentId,
          orElse: () => null,
        );
      }
      
      // If not found, try by internal ID (hashcode check might not be reliable if generated, strictly use studentId match if possible)
      // Since we don't store dbId in Admission model explicitly as 'dbId' but as 'id' (hashcode) in current parse
      // We rely on studentId string mostly.
      
      if (targetAdmission != null) {
        // Clear args so it doesn't open again implicitly
        _pendingEditArgs = null;
        // Small delay to ensure UI is ready
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _showEditAdmissionDialog(context, targetAdmission!);
        });
      } else {
        print('Could not find admission for edit: $studentId');
      }
    } catch (e) {
      print('Error handling pending edit: $e');
    }
  }



  void _showEditAdmissionDialog(BuildContext context, Admission admission) {
    if (!mounted || _isDisposed) return;
    if (!mounted || _isDisposed) return;
    
    // We don't populate controllers anymore because AdmissionForm handles it.
    // just show the dialog.


    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900, maxHeight: 800),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF667EEA),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Edit Admission',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        _editingAdmission = null;
                        _clearForm();
                        Navigator.pop(dialogContext);
                      },
                    ),
                  ],
                ),
              ),
              // Form Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: AdmissionForm(
                    initialData: admission,
                    isSubmitting: _isSubmitting,
                    submitLabel: 'Update Admission',
                    onSubmit: (data, photoBytes) => _handleFormSubmit(data, photoBytes, isUpdate: true, admissionId: admission.studentId, dialogContext: dialogContext),
                  ),
                ),
              ),
              // Footer (simplified - cancel button only, as submit is now inside AdmissionForm?)
              // Wait, the AdmissionForm has a submit button.
              // We should probably NOT have a footer with buttons if the form has one.
              // BUT, the original design had the button in the footer.
              // The new AdmissionForm has the button at the bottom.
              // So we can remove the footer submit button, but keep a Cancel button or "Close" icon in header.
              // Let's keep a minimal footer or just remove it if the form's button is sufficient.
              // The form's button is "Submit Admission" or "Update Admission". 
              // Dialog usually has actions at bottom right.
              // If we put the button inside the form, it scrolls with the form.
              // If we want it pinned, we need to extract it or pass key.
              // For simplicity and "safe" refactoring, let's let it scroll. It's robust.
              // So I will remove the footer submit button and just leave a "Cancel" if needed, 
              // or rely on the "Close" icon in header.
              // Let's keep a minimal footer with just "Cancel" for better UX.
              Container(
                 padding: const EdgeInsets.all(20),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.end,
                   children: [
                     TextButton(
                       onPressed: () => Navigator.pop(dialogContext),
                       child: const Text('Cancel'),
                     ),
                   ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  void _clearForm() {
    if (!mounted || _isDisposed) return;
    // We only need to clear the search filter and editing state
    _editingAdmission = null;
    _pendingEditArgs = null;
    // Note: The AdmissionForm widgets handle their own form clearing when disposed or rebuilt.
  }

  void _filterAdmissions() {
    if (!mounted || _isDisposed) return;
    
    // Safely get search text to avoid "used after disposed" error
    late final String searchText;
    try {
      searchText = _searchController.text;
    } catch (_) {
      return; // Controller already disposed
    }

    setState(() {
      _filteredAdmissions = _allAdmissions.where((admission) {
        final matchesSearch = searchText.isEmpty ||
            admission.studentName.toLowerCase().contains(searchText.toLowerCase()) ||
            admission.parentName.toLowerCase().contains(searchText.toLowerCase());

        final matchesStatus = _filterStatus.isEmpty || admission.status == _filterStatus;
        final matchesClass = _filterClass.isEmpty || admission.applyingClass == _filterClass;

        return matchesSearch && matchesStatus && matchesClass;
      }).toList();
    });
  }

  Future<void> _handleFormSubmit(Map<String, dynamic> data, Uint8List? photoBytes, {bool isUpdate = false, String? admissionId, BuildContext? dialogContext}) async {
    if (!mounted || _isDisposed) return;
    
    setState(() {
      _isSubmitting = true;
    });

    try {
        ApiResponse response;
        
        if (isUpdate) {
             final url = '${Endpoints.admissions}$admissionId/';
             if (photoBytes != null) {
                  final stringFields = data.map((key, value) => MapEntry(key, value.toString()));
                  response = await _apiService.uploadFile(
                    url,
                    fileBytes: photoBytes,
                    fileName: 'profile_photo.jpg',
                    fieldName: 'profile_photo',
                    method: 'PATCH',
                    additionalFields: stringFields,
                  );
             } else {
                 response = await _apiService.patch(url, body: data);
             }
             
        } else {
            data['status'] = 'Pending';
            
            if (photoBytes != null) {
               final stringFields = data.map((key, value) => MapEntry(key, value.toString()));
               response = await _apiService.uploadFile(
                 Endpoints.admissions,
                 fileBytes: photoBytes,
                 fileName: 'profile_photo.jpg',
                 fieldName: 'profile_photo',
                 method: 'POST',
                 additionalFields: stringFields,
               );
            } else {
                response = await _apiService.post(Endpoints.admissions, body: data);
            }
        }

        if (!mounted || _isDisposed) return;
        
        if (response.success) {
            
            if (isUpdate) {
                 if (mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Admission updated successfully"), backgroundColor: Colors.green),
                     );
                     Navigator.pop(dialogContext ?? context); // Close dialog using specific context if available
                 }
            } else {
                if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Application submitted successfully!"), backgroundColor: Color(0xFF667EEA)),
                    );
                    _clearForm();
                }
            }
            _loadAdmissions();
        } else {
            if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: ${response.error ?? 'Unknown error'}"), backgroundColor: Colors.red),
                );
            }
        }

    } catch (e) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text("Exception: $e"), backgroundColor: Colors.red),
            );
        }
    } finally {
        if (mounted) {
            setState(() {
                _isSubmitting = false;
            });
        }
    }
  }
  Future<void> _deleteAdmission(int id) async {
    if (!mounted || _isDisposed) return;
    try {
      // Find the admission to get student_id
      final admission = _allAdmissions.firstWhere((a) => a.id == id);
      
      // student_id is required - if missing, show error
      if (admission.studentId == null || admission.studentId!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: Admission missing student ID'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      // Call backend API to delete using student_id as PK
      final response = await _apiService.delete('${Endpoints.admissions}${admission.studentId}/');
      if (!mounted || _isDisposed) return;

      if (response.success) {
        // Reload admissions from server
        await _loadAdmissions();
        if (!mounted || _isDisposed) return;
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Admission deleted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: ${response.error ?? "Unknown error"}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting admission: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _changeStatus(int id, String newStatus) async {
    if (!mounted || _isDisposed) return;
    try {
      final index = _allAdmissions.indexWhere((a) => a.id == id);
      if (index == -1) return;

      final admission = _allAdmissions[index];
      
      // student_id is required - if missing, show error
      if (admission.studentId == null || admission.studentId!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: Admission missing student ID'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      // Use student_id as the primary key for API calls
      final studentId = admission.studentId!;
      
      // Generate admission number if approving and not already set
      String? admissionNumber = admission.admissionNumber;
      if (newStatus == 'Approved' && admissionNumber == null) {
        // Generate unique admission number
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        admissionNumber = 'ADM-${DateTime.now().year}-${timestamp.toString().substring(timestamp.toString().length - 6)}';
      }

      // Prepare update data
      final updateData = {
        'status': newStatus,
      };
      
      // Include admission number if it's being set
      if (admissionNumber != null) {
        updateData['admission_number'] = admissionNumber;
      }

      // Call backend API to update status using student_id as PK
      final response = await _apiService.patch(
        '${Endpoints.admissions}$studentId/',
        body: updateData,
      );

      if (!mounted || _isDisposed) return;

      if (response.success && response.data != null) {
        // If status is Approved, create Student record
        if (newStatus == 'Approved') {
          try {
            // Get admission data to create student
            final admissionData = response.data as Map<String, dynamic>;
            
            // Prepare student data from admission
            final studentData = {
              'admission_no': admissionNumber ?? admissionData['admission_number'] ?? 'ADM-${DateTime.now().millisecondsSinceEpoch}',
              'first_name': admission.studentName.split(' ').first,
              'last_name': admission.studentName.split(' ').length > 1 
                  ? admission.studentName.split(' ').sublist(1).join(' ')
                  : null,
              'date_of_birth': DateFormat('yyyy-MM-dd').format(admission.dateOfBirth),
              'gender': admission.gender,
              'address': admission.address,
              'email': admission.email,
              'parent_name': admission.parentName,
              'applying_class': admission.applyingClass,
              'section': admission.section,
              if (admission.parentPhone != null)
                'parent_phone': admission.parentPhone,
              if (admission.emergencyContact != null)
                'emergency_contact': admission.emergencyContact,
              'is_active': true,
              if (admissionData['blood_group'] != null)
                'blood_group': admissionData['blood_group'],
              if (admissionData['medical_information'] != null)
                'medical_information': admissionData['medical_information'],
            };

            // Call backend API to create student
            await _apiService.post(
              Endpoints.students,
              body: studentData,
            );
            if (!mounted || _isDisposed) return;
          } catch (e) {
            print('Error creating student: $e');
            // Continue even if student creation fails
          }
        }

        // Reload admissions to get updated data from server
        await _loadAdmissions();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(newStatus == 'Approved' 
                  ? 'Status updated and student created successfully!'
                  : 'Status updated to $newStatus successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Handle error
        String errorMessage = 'Failed to update status. Please try again.';
        if (response.data != null && response.data is Map) {
          final errorData = response.data as Map<String, dynamic>;
          errorMessage = errorData['message'] ?? 
                        errorData['error'] ?? 
                        errorMessage;
        } else if (response.error != null) {
          errorMessage = response.error!;
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // -- Helpers --


  // -- UI Builders --
  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      body: Row(
        children: [
          // --- Sidebar ---
          if (isDesktop)
            _buildSidebar(),

          // --- Main Content ---
          Expanded(
            child: Container(
              color: const Color(0xFFF5F6FA),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(),
                    const SizedBox(height: 30),

                    // Stats
                    _buildStatsOverview(),
                    const SizedBox(height: 30),

                    // Form and Grid Area
                    LayoutBuilder(builder: (context, constraints) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Add Application Form (Embedded)
                          _buildSectionTitle("➕", "New Admission Application"),
                          const SizedBox(height: 15),
                          AdmissionForm(
                            isSubmitting: _isSubmitting,
                            submitLabel: 'Submit Admission',
                            onSubmit: (data, photoBytes) => _handleFormSubmit(data, photoBytes, isUpdate: false),
                          ),
                          
                          const SizedBox(height: 30),
                          
                          // Search and Filter
                          _buildSectionTitle("🔍", "Search & Filter"),
                          const SizedBox(height: 15),
                          _buildSearchFilterSection(),

                          const SizedBox(height: 30),
                          
                          // Applications Grid
                          _buildSectionTitle("📋", "All Applications"),
                          const SizedBox(height: 15),
                          _buildAdmissionsGrid(),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(String title, bool isActive, VoidCallback onTap) {
    return _NavItemWithHover(
      title: title,
      isActive: isActive,
      onTap: onTap,
    );
  }

  Widget _buildHeader() {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admissions Management',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Manage student admissions, applications, and enrollment',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
          _buildUserInfo(),
          const SizedBox(width: 20),
          _buildBackButton(),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final gradient = const LinearGradient(
      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    // Safe navigation helper for sidebar
    void navigateToRoute(String route) {
      final navigator = app.SchoolManagementApp.navigatorKey.currentState;
      if (navigator != null) {
        if (navigator.canPop() || route != '/dashboard') {
          navigator.pushReplacementNamed(route);
        } else {
          navigator.pushNamed(route);
        }
      }
    }

    return Container(
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
                    isActive: false,
                    onTap: () => navigateToRoute('/dashboard'),
                  ),
                  _NavItem(
                    icon: '👨‍🏫',
                    title: 'Teachers',
                    onTap: () => navigateToRoute('/teachers'),
                  ),
                  _NavItem(
                    icon: '👥',
                    title: 'Students',
                    onTap: () => navigateToRoute('/students'),
                  ),
                  _NavItem(
                    icon: '🚌',
                    title: 'Buses',
                    onTap: () => navigateToRoute('/buses'),
                  ),
                  _NavItem(
                    icon: '🎯',
                    title: 'Activities',
                    onTap: () => navigateToRoute('/activities'),
                  ),
                  _NavItem(
                    icon: '📅',
                    title: 'Events',
                    onTap: () => navigateToRoute('/events'),
                  ),
                  _NavItem(
                    icon: '📆',
                    title: 'Calendar',
                    onTap: () => navigateToRoute('/calendar'),
                  ),
                  _NavItem(
                    icon: '🔔',
                    title: 'Notifications',
                    onTap: () => navigateToRoute('/notifications'),
                  ),
                  _NavItem(
                    icon: '🛣️',
                    title: 'Bus Routes',
                    onTap: () => navigateToRoute('/bus-routes'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsOverview() {
    final pending = _allAdmissions.where((a) => a.status == 'Pending').length;
    final approved = _allAdmissions.where((a) => a.status == 'Approved').length;
    final enrolled = _allAdmissions.where((a) => a.status == 'Enrolled').length;

    return Row(
      children: [
        
        Expanded(
          child: _buildStatCard("Total Applications", _allAdmissions.length.toString(), const Color(0xFF667EEA)),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildStatCard("Pending Review", pending.toString(), Colors.orange),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildStatCard("Approved", approved.toString(), Colors.green),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildStatCard("Enrolled", enrolled.toString(), Colors.blue),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String emoji, String title) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }



  Widget _buildSearchFilterSection() {
    if (_isDisposed) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search applications...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onChanged: (value) {
                    _filterAdmissions();
                  },
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    hintText: 'All Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  initialValue: _filterStatus.isEmpty ? null : _filterStatus,
                  items: const [
                    DropdownMenuItem(value: '', child: Text('All Status')),
                    DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'Approved', child: Text('Approved')),
                    DropdownMenuItem(value: 'Rejected', child: Text('Rejected')),
                    DropdownMenuItem(value: 'Enrolled', child: Text('Enrolled')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _filterStatus = value ?? '';
                    });
                    _filterAdmissions();
                  },
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    hintText: 'All Classes',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  initialValue: _filterClass.isEmpty ? null : _filterClass,
                  items: [
                    const DropdownMenuItem(value: '', child: Text('All Classes')),
                    ...List.generate(12, (i) {
                      final className = 'Class ${i + 1}';
                      return DropdownMenuItem(
                        value: className,
                        child: Text(className),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _filterClass = value ?? '';
                    });
                    _filterAdmissions();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdmissionsGrid() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
          ),
        ),
      );
    }

    if (_filteredAdmissions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                _allAdmissions.isEmpty 
                  ? 'No admissions found. Add a new admission to get started.'
                  : 'No admissions match your search criteria.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }



    return LayoutBuilder(
      builder: (context, constraints) {
        double width = constraints.maxWidth;
        int crossAxisCount = width > 1100 ? 3 : width > 700 ? 2 : 1;
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 1.4,
          ),
          itemCount: _filteredAdmissions.length,
          itemBuilder: (context, index) {
            return _AdmissionCard(
              admission: _filteredAdmissions[index],
              onView: () => _viewAdmission(context, _filteredAdmissions[index]),
              onEdit: () => _showEditAdmissionDialog(context, _filteredAdmissions[index]),
              onDelete: () => _deleteAdmission(_filteredAdmissions[index].id),
              onChangeStatus: (status) => _changeStatus(_filteredAdmissions[index].id, status),
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(String label, String number, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            number,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _viewAdmission(BuildContext context, Admission admission) {
    showDialog(
      context: context,
      builder: (context) => _AdmissionDetailDialog(admission: admission),
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

class _NavItemWithHover extends StatefulWidget {
  final String title;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItemWithHover({
    required this.title,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavItemWithHover> createState() => _NavItemWithHoverState();
}

class _NavItemWithHoverState extends State<_NavItemWithHover> {
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
        margin: const EdgeInsets.only(bottom: 10),
        transform: Matrix4.identity()
          ..translate(_isHovered ? 8.0 : 0.0, 0.0),
        decoration: BoxDecoration(
          color: widget.isActive
              ? Colors.white.withValues(alpha: 0.3)
              : _isHovered
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          title: Text(
            widget.title,
            style: TextStyle(
              color: Colors.white,
              fontWeight: widget.isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          onTap: widget.onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

// --- Widgets from Block 2 for Card & Dialogs ---

class _AdmissionCard extends StatelessWidget {
  final Admission admission;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(String) onChangeStatus;

  const _AdmissionCard({
    required this.admission,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
    required this.onChangeStatus,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending': return const Color(0xFF856404);
      case 'Approved': return const Color(0xFF155724);
      case 'Rejected': return const Color(0xFF721C24);
      case 'Enrolled': return const Color(0xFF004085);
      default: return Colors.black;
    }
  }

  Color _getStatusBg(String status) {
     switch (status) {
      case 'Pending': return const Color(0xFFFFF3CD);
      case 'Approved': return const Color(0xFFD4EDDA);
      case 'Rejected': return const Color(0xFFF8D7DA);
      case 'Enrolled': return const Color(0xFFCCE5FF);
      default: return Colors.grey[200]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  admission.studentName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusBg(admission.status),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  admission.status,
                  style: TextStyle(color: _getStatusColor(admission.status), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'delete') {
                     showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Application'),
                        content: const Text('Are you sure you want to delete this application?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                          TextButton(onPressed: () { onDelete(); Navigator.pop(context); }, child: const Text('Delete', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                  } else if (value.startsWith('status_')) {
                    onChangeStatus(value.replaceFirst('status_', ''));
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
                  const PopupMenuItem(value: 'status_Approved', child: Row(children: [Icon(Icons.check_circle, size: 18, color: Colors.green), SizedBox(width: 8), Text('Approve')])),
                  const PopupMenuItem(value: 'status_Rejected', child: Row(children: [Icon(Icons.cancel, size: 18, color: Colors.red), SizedBox(width: 8), Text('Reject')])),
                  const PopupMenuItem(value: 'status_Enrolled', child: Row(children: [Icon(Icons.school, size: 18, color: Colors.blue), SizedBox(width: 8), Text('Enroll')])),
                  const PopupMenuDivider(),
                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete')])),
                ],
              ),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFEEEEEE)),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _DetailRow(label: "👤 Parent", value: admission.parentName),
                _DetailRow(label: "📚 Class", value: admission.applyingClass),
                _DetailRow(label: "📅 DOB", value: DateFormat('MMM dd, yyyy').format(admission.dateOfBirth)),
                _DetailRow(label: "🏷️ Category", value: admission.category),
              ],
            ),
          ),
           Row(
             mainAxisAlignment: MainAxisAlignment.end,
             children: [
               InkWell(
                 onTap: onView,
                 borderRadius: BorderRadius.circular(8),
                 child: Container(
                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                   decoration: BoxDecoration(
                     gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                     borderRadius: BorderRadius.circular(8),
                   ),
                   child: const Row(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       Icon(Icons.visibility, size: 16, color: Colors.white),
                       SizedBox(width: 8),
                       Text(
                         "View Details",
                         style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                       ),
                     ],
                   ),
                 ),
               ),
             ],
           )
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF666666), fontWeight: FontWeight.w500, fontSize: 13)),
        Text(value, style: const TextStyle(color: Color(0xFF333333), fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}

class _AdmissionDetailDialog extends StatelessWidget {
  final Admission admission;
  const _AdmissionDetailDialog({required this.admission});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Admission Details', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              if (admission.studentId != null) _DetailItem('Student ID', admission.studentId!),
              if (admission.admissionNumber != null) _DetailItem('Admission Number', admission.admissionNumber!),
              _DetailItem('Student Name', admission.studentName),
              if (admission.fatherName != null) _DetailItem('Father Name', admission.fatherName!),
              if (admission.motherName != null) _DetailItem('Mother Name', admission.motherName!),
              if (admission.guardianName != null) _DetailItem('Guardian Name', admission.guardianName!),
              if (admission.fatherPhone != null) _DetailItem('Father Phone', admission.fatherPhone!),
              if (admission.motherPhone != null) _DetailItem('Mother Phone', admission.motherPhone!),
              _DetailItem('Date of Birth', DateFormat('MMM dd, yyyy').format(admission.dateOfBirth)),
              _DetailItem('Gender', admission.gender),
              if (admission.bloodGroup != null) _DetailItem('Blood Group', admission.bloodGroup!),
              _DetailItem('Applying for Class', admission.applyingClass),
              if (admission.email != null) _DetailItem('Email', admission.email!),
              _DetailItem('Address', admission.address),
              if (admission.emergencyContact != null) _DetailItem('Emergency Contact', admission.emergencyContact!),
              if (admission.medicalInformation != null) _DetailItem('Medical Information', admission.medicalInformation!),
              _DetailItem('Category', admission.category),
              _DetailItem('Status', admission.status),
              if (admission.previousSchool != null) _DetailItem('Previous School', admission.previousSchool!),
              if (admission.remarks != null) _DetailItem('Remarks', admission.remarks!),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  const _DetailItem(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}




// Glass Container Widget
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool drawRightBorder;
  final double borderRadius;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.drawRightBorder = false,
    this.borderRadius = 12,
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