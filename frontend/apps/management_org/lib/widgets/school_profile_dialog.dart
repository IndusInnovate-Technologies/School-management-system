import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:core/api/api_service.dart';
import 'package:core/api/endpoints.dart';
import 'package:core/api/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:main_login/main.dart' as main_login;

/// Dialog to display school profile details
class SchoolProfileDialog extends StatefulWidget {
  final String schoolId;
  final ApiService apiService;

  const SchoolProfileDialog({
    super.key,
    required this.schoolId,
    required this.apiService,
  });

  @override
  State<SchoolProfileDialog> createState() => _SchoolProfileDialogState();
}

class _SchoolProfileDialogState extends State<SchoolProfileDialog> {
  Map<String, dynamic>? _schoolData;
  bool _isLoading = true;
  String? _errorMessage;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadSchoolDetails();
  }

  Future<void> _loadSchoolDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.apiService.initialize();
      // Try to get school details from super admin endpoint first
      final response = await widget.apiService.get('${Endpoints.adminSchools}${widget.schoolId}/');
      
      if (response.success && response.data != null) {
        final data = response.data;
        if (data is Map) {
          setState(() {
            _schoolData = data as Map<String, dynamic>;
            _isLoading = false;
          });
          return;
        }
      }
      
      
      final currentResponse = await widget.apiService.get('/management-admin/schools/current/');
      if (currentResponse.success && currentResponse.data != null) {
        final data = currentResponse.data;
        if (data is Map) {
          final schoolData = data['data'] ?? data;
          if (schoolData is Map) {
            setState(() {
              _schoolData = schoolData as Map<String, dynamic>;
              _isLoading = false;
            });
            return;
          }
        }
      }
      
      setState(() {
        _errorMessage = 'Failed to load school details';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndUploadLogo() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() {
        _isUploading = true;
      });

      final bytes = await image.readAsBytes();
      final fileName = image.name;

      final response = await widget.apiService.uploadFile(
        '/management-admin/schools/upload-logo/',
        fileBytes: bytes,
        fileName: fileName,
        fieldName: 'logo',
      );

      if (response.success && response.data != null) {
        final data = response.data;
        final schoolData = data['data'] ?? data;
        
        setState(() {
           if (schoolData is Map) {
             // Update the local data with the new logo info
             _schoolData = schoolData as Map<String, dynamic>;
           }
           _isUploading = false;
        });

        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              content: const Text('Logo uploaded successfully'),
              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
            ),
          );
        }
      } else {
        throw Exception(response.error ?? 'Upload failed');
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Upload Error'),
            content: Text('Error uploading logo: $e'),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
          ),
        );
      }
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'School Profile',
                  style: TextStyle(
                    fontSize: 24,
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
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, 
                                  color: Colors.red, size: 48),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadSchoolDetails,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          child: _buildSchoolDetails(),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  String? _getSchoolName(Map<String, dynamic> school) {
    // Try school_name first (new field name), then name (backward compatibility)
    String? schoolName = school['school_name']?.toString();
    if (schoolName != null && schoolName.trim().isNotEmpty && schoolName.trim().toUpperCase() != 'NA') {
      return schoolName.trim();
    }
    
    schoolName = school['name']?.toString();
    if (schoolName != null && schoolName.trim().isNotEmpty && schoolName.trim().toUpperCase() != 'NA') {
      return schoolName.trim();
    }
    
    return null;
  }

  Widget _buildSchoolDetails() {
    if (_schoolData == null) return const SizedBox();
    
    final school = _schoolData!;
    final logoUrl = school['logo_url']?.toString();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // School Logo/Initial
        Center(
          child: Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: logoUrl == null ? const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ) : null,
                ),
                child: ClipOval(
                  child: logoUrl != null 
                    ? Image.network(
                        logoUrl,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => Center(
                          child: Text(
                            (_getSchoolName(school) ?? 'S')[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 40,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          (_getSchoolName(school) ?? 'S')[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 40,
                          ),
                        ),
                      ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: InkWell(
                  onTap: _pickAndUploadLogo,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _isUploading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.camera_alt,
                            color: Colors.grey,
                            size: 20,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // School Name
        _buildInfoRow('School Name', _getSchoolName(school) ?? 'N/A'),
        const SizedBox(height: 16),
        
        // School ID
        _buildInfoRow('School ID', school['school_id']?.toString() ?? 'N/A'),
        const SizedBox(height: 16),
        
        // Principal Name
        if (school['principal_name'] != null)
          _buildInfoRow('Principal Name', school['principal_name']?.toString() ?? 'N/A'),
        if (school['principal_name'] != null) const SizedBox(height: 16),
        
        // Phone Number
        if (school['phone'] != null)
          _buildInfoRow('Phone Number', school['phone']?.toString() ?? 'N/A'),
        if (school['phone'] != null) const SizedBox(height: 16),
        
        // Email
        if (school['email'] != null)
          _buildInfoRow('Email', school['email']?.toString() ?? 'N/A'),
        if (school['email'] != null) const SizedBox(height: 16),
        
        // Address
        if (school['address'] != null)
          _buildInfoRow('Address', school['address']?.toString() ?? 'N/A'),
        if (school['address'] != null) const SizedBox(height: 16),
        
        // Location
        if (school['location'] != null)
          _buildInfoRow('Location', school['location']?.toString() ?? 'N/A'),
        if (school['location'] != null) const SizedBox(height: 16),
        
        // Established Year
        if (school['established_year'] != null)
          _buildInfoRow('Established Year', school['established_year']?.toString() ?? 'N/A'),
        if (school['established_year'] != null) const SizedBox(height: 16),
        
        // Status
        if (school['status'] != null)
          _buildInfoRow('Status', 
              (school['status']?.toString() ?? 'N/A').toUpperCase()),
        if (school['status'] != null) const SizedBox(height: 16),
        
        // Registration Number
        if (school['registration_number'] != null)
          _buildInfoRow('Registration Number', 
              school['registration_number']?.toString() ?? 'N/A'),
        if (school['registration_number'] != null) const SizedBox(height: 24),
        
        // Change Password Button
        Center(
          child: ElevatedButton.icon(
            onPressed: _showChangePasswordDialog,
            icon: const Icon(Icons.lock, size: 20),
            label: const Text('Change Password'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ],
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
              onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
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
                          // USE THE METHOD'S context (the State's context), not the vanished dialog's context
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
                            builder: (ctx) => AlertDialog(
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
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
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

