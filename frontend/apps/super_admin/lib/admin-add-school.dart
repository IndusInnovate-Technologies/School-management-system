import 'package:flutter/material.dart';
import 'package:core/api/api_service.dart';
import 'package:core/api/endpoints.dart';
import 'admin-schools.dart' as schools;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize ApiService to load stored tokens and handle token refresh
  await ApiService().initialize();
  
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'School Management',
      home: const AddSchoolScreen(),
    ),
  );
}

class AddSchoolScreen extends StatefulWidget {
  const AddSchoolScreen({super.key});

  @override
  State<AddSchoolScreen> createState() => _AddSchoolScreenState();
}

class _AddSchoolScreenState extends State<AddSchoolScreen> {
  // --- 1. State & Controllers ---
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Text Controllers (Matching all HTML inputs)
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _principalController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _facilitiesController = TextEditingController();
  // New fields for school_id generation
  final TextEditingController _statecodeController = TextEditingController();
  final TextEditingController _districtcodeController = TextEditingController();
  final TextEditingController _registrationNumberController = TextEditingController();
  final TextEditingController _establishedYearController = TextEditingController();
  final TextEditingController _licenseExpiryController = TextEditingController();

  // Dropdown Values
  String? _selectedStatus;

  // --- Design Colors (Exact matches from CSS) ---
  final Color _gradStart = const Color(0xFF667eea);
  final Color _gradMid = const Color(0xFF764ba2);
  final Color _gradEnd = const Color(0xFFf093fb);
  final Color _bgColor = const Color(0xFFf8f9fa);
  final Color _inputBorder = const Color(0xFFe9ecef);

  // --- 2. Logic (API Call) ---
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Initialize ApiService to ensure tokens are loaded
    final apiService = ApiService();
    await apiService.initialize();

    // 1. Prepare Data (Matching backend model structure)
    // Combine city, state, zipCode into location field
    final List<String> locationParts = [];
    if (_cityController.text.isNotEmpty) locationParts.add(_cityController.text);
    if (_stateController.text.isNotEmpty) locationParts.add(_stateController.text);
    if (_zipController.text.isNotEmpty) locationParts.add(_zipController.text);
    final String location = locationParts.join(', ');

    // Build full address including description and facilities if provided
    final List<String> addressParts = [_addressController.text];
    if (_descController.text.isNotEmpty) {
      addressParts.add('\nDescription: ${_descController.text}');
    }
    if (_facilitiesController.text.isNotEmpty) {
      addressParts.add('\nFacilities: ${_facilitiesController.text}');
    }
    final String fullAddress = addressParts.join('\n');

    // Validate required fields for school_id generation
    final statecode = _statecodeController.text.trim();
    final districtcode = _districtcodeController.text.trim();
    final registrationNumber = _registrationNumberController.text.trim();
    
    if (statecode.isEmpty || districtcode.isEmpty || registrationNumber.isEmpty) {
      _showSnackBar('State Code, District Code, and Registration Number are required to generate school ID', isError: true);
      setState(() => _isLoading = false);
      return;
    }
    
    final Map<String, dynamic> schoolData = {
      'school_name': _nameController.text.trim(),
      'location': location.isNotEmpty ? location : _addressController.text.trim(),
      'statecode': statecode,
      'districtcode': districtcode,
      'registration_number': registrationNumber,
      'address': fullAddress.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'principal_name': _principalController.text.trim(),
      'status': _selectedStatus ?? 'active',
    };
    
    // Add optional fields if provided
    if (_establishedYearController.text.isNotEmpty) {
      final year = int.tryParse(_establishedYearController.text.trim());
      if (year != null) {
        schoolData['established_year'] = year;
      }
    }
    
    if (_licenseExpiryController.text.isNotEmpty) {
      schoolData['license_expiry'] = _licenseExpiryController.text.trim();
    }

    try {
      final response = await apiService.post(
        Endpoints.adminSchools,
        body: schoolData,
      );

      if (response.success) {
        if (mounted) {
          final message = response.data is Map<String, dynamic> &&
                   response.data['message'] != null
              ? response.data['message']
              : 'School added successfully!';
          _showSnackBar(message, isError: false);
          _clearForm();
          
          // Navigate back to schools list after successful submission
          // Wait a moment to show the success message
          await Future.delayed(const Duration(seconds: 1));
          
          if (mounted) {
            // Return true to indicate success, which will trigger refresh
            Navigator.of(context).pop(true);
          }
        }
      } else {
        String errorMessage = 'Failed to add school';
        if (response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          errorMessage = data['message'] as String? ??
              data['error'] as String? ??
              errorMessage;
          // Check for validation errors
          if (data['errors'] is Map) {
            final errors = data['errors'] as Map;
            final errorList = <String>[];
            errors.forEach((key, value) {
              if (value is List) {
                errorList.addAll(value.map((e) => e.toString()));
              } else {
                errorList.add(value.toString());
              }
            });
            if (errorList.isNotEmpty) {
              errorMessage = errorList.join(', ');
            }
          }
        } else if (response.error != null) {
          errorMessage = response.error!;
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString().replaceAll("Exception: ", "");
        // Handle network errors
        if (errorMsg.contains('Network error') || errorMsg.contains('Failed to fetch')) {
          errorMsg = 'Unable to connect to server. Please check your internet connection and ensure the backend server is running.';
        }
        _showSnackBar(errorMsg, isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _nameController.clear();
    _addressController.clear();
    _cityController.clear();
    _stateController.clear();
    _zipController.clear();
    _phoneController.clear();
    _emailController.clear();
    _principalController.clear();
    _capacityController.clear();
    _descController.clear();
    _facilitiesController.clear();
    _statecodeController.clear();
    _districtcodeController.clear();
    _registrationNumberController.clear();
    _establishedYearController.clear();
    _licenseExpiryController.clear();
    setState(() {
      _selectedStatus = 'active';
    });
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        backgroundColor: isError
            ? const Color(0xFFff6b6b)
            : const Color(0xFF51cf66), // CSS Colors
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  @override
  void dispose() {
    // Clean up controllers
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _principalController.dispose();
    _capacityController.dispose();
    _descController.dispose();
    _facilitiesController.dispose();
    _statecodeController.dispose();
    _districtcodeController.dispose();
    _registrationNumberController.dispose();
    _establishedYearController.dispose();
    _licenseExpiryController.dispose();
    super.dispose();
  }

  // --- 3. UI Construction ---
  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isDesktop = width > 768; // Media query breakpoint

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        // Gradient Header
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_gradStart, _gradMid, _gradEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          '🏫 School Management System',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton.icon(
            onPressed: () {
              // Navigate back to schools list
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                // If we can't pop, navigate to schools dashboard
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const schools.AdminDashboard(),
                  ),
                );
              }
            },
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
            label: const Text(
              "Back to Dashboard",
              style: TextStyle(color: Colors.white),
            ),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 800,
          ), // .container max-width
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page Title with Gradient Text
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [_gradStart, _gradMid],
                  ).createShader(bounds),
                  child: const Text(
                    'Add New School',
                    style: TextStyle(
                      fontSize: 32, // 2.5rem approx
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Enter school information to add to the system',
                  style: TextStyle(color: Color(0xFF666666), fontSize: 16),
                ),
                const SizedBox(height: 30),

                // Form Container Card
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                    child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Row 1 - School Name
                        Padding(
                          padding: const EdgeInsets.only(bottom: 25),
                          child: _buildInput(
                            label: 'School Name *',
                            controller: _nameController,
                            hint: 'Enter school name',
                          ),
                        ),
                        
                        // Row 2 - State Code, District Code, Registration Number (for school_id generation)
                        _buildResponsiveRow(isDesktop, [
                          _buildInput(
                            label: 'State Code *',
                            controller: _statecodeController,
                            hint: 'e.g., TG',
                          ),
                          _buildInput(
                            label: 'District Code *',
                            controller: _districtcodeController,
                            hint: 'e.g., HYD',
                          ),
                        ]),
                        
                        // Row 3 - Registration Number
                        Padding(
                          padding: const EdgeInsets.only(bottom: 25),
                          child: _buildInput(
                            label: 'Registration Number *',
                            controller: _registrationNumberController,
                            hint: 'Enter school registration number',
                          ),
                        ),

                        // Row 4 - Address and City
                        _buildResponsiveRow(isDesktop, [
                          _buildInput(
                            label: 'Address *',
                            controller: _addressController,
                            hint: 'Enter school address',
                          ),
                          _buildInput(
                            label: 'City *',
                            controller: _cityController,
                            hint: 'Enter city',
                          ),
                        ]),

                        // Row 5 - State and ZIP Code
                        _buildResponsiveRow(isDesktop, [
                          _buildInput(
                            label: 'State *',
                            controller: _stateController,
                            hint: 'Enter state',
                          ),
                          _buildInput(
                            label: 'ZIP Code *',
                            controller: _zipController,
                            hint: 'Enter ZIP code',
                          ),
                        ]),

                        // Row 6 - Phone and Email
                        _buildResponsiveRow(isDesktop, [
                          _buildInput(
                            label: 'Phone Number',
                            controller: _phoneController,
                            hint: 'Enter phone number',
                            type: TextInputType.phone,
                            isRequired: false,
                          ),
                          _buildInput(
                            label: 'Email *',
                            controller: _emailController,
                            hint: 'Enter email address',
                            type: TextInputType.emailAddress,
                          ),
                        ]),

                        // Row 7 - Principal Name and Status
                        _buildResponsiveRow(isDesktop, [
                          _buildInput(
                            label: 'Principal Name',
                            controller: _principalController,
                            hint: 'Enter principal name',
                            isRequired: false,
                          ),
                          _buildStatusDropdown(isDesktop),
                        ]),

                        // Row 8 - Established Year and License Expiry
                        _buildResponsiveRow(isDesktop, [
                          _buildInput(
                            label: 'Established Year',
                            controller: _establishedYearController,
                            hint: 'e.g., 2020',
                            type: TextInputType.number,
                            isRequired: false,
                          ),
                          _buildInput(
                            label: 'License Expiry (YYYY-MM-DD)',
                            controller: _licenseExpiryController,
                            hint: 'e.g., 2025-12-31',
                            isRequired: false,
                          ),
                        ]),

                        const SizedBox(height: 25),

                        // Description (Full width)
                        _buildInput(
                          label: 'School Description',
                          controller: _descController,
                          hint: 'Enter school description',
                          maxLines: 4,
                          isRequired: false,
                        ),

                        const SizedBox(height: 25),

                        // Facilities (Full width)
                        _buildInput(
                          label: 'Facilities',
                          controller: _facilitiesController,
                          hint: 'Enter available facilities',
                          maxLines: 3,
                          isRequired: false,
                        ),

                        const SizedBox(height: 40),

                        // Submit Button
                        Container(
                          width: double.infinity,
                          height: 55,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              colors: [_gradStart, _gradMid],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _gradStart.withValues(alpha: 0.3),
                                blurRadius: 25,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 3,
                                        ),
                                      ),
                                      SizedBox(width: 15),
                                      Text(
                                        "Processing...",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  )
                                : const Text(
                                    "Add School",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
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
    );
  }

  // --- 4. Helper Widgets (DRY Principles) ---

  // Handles the Grid behavior (Row on Desktop, Column on Mobile)
  Widget _buildResponsiveRow(bool isDesktop, List<Widget> children) {
    if (isDesktop) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 25),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: children[0]),
            const SizedBox(width: 20), // Gap
            Expanded(child: children[1]),
          ],
        ),
      );
    } else {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 25),
            child: children[0],
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 25),
            child: children[1],
          ),
        ],
      );
    }
  }

  // Standard Input Field
  Widget _buildInput({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType type = TextInputType.text,
    int maxLines = 1,
    bool isRequired = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: type,
          maxLines: maxLines,
          validator: isRequired
              ? (value) => (value == null || value.isEmpty) ? 'Required' : null
              : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.9),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 15,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _inputBorder, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _gradStart,
                width: 2,
              ), // Focus color
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFff6b6b), width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFff6b6b), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  // Status Dropdown Field
  Widget _buildStatusDropdown(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Status *",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedStatus ?? 'active',
          items: const [
            DropdownMenuItem(value: 'active', child: Text('Active')),
            DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
            DropdownMenuItem(value: 'suspended', child: Text('Suspended')),
          ],
          onChanged: (val) => setState(() => _selectedStatus = val),
          decoration: InputDecoration(
            hintText: "Select status",
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.9),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 15,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _inputBorder, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _gradStart, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFff6b6b), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
