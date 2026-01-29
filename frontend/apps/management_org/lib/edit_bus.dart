import 'package:flutter/material.dart';
import 'main.dart' as app;
import 'package:core/api/api_service.dart';
import 'package:core/api/endpoints.dart';
import 'widgets/school_profile_header.dart';

class EditBusPage extends StatefulWidget {
  final String? busId; // Changed to String to use bus_number

  const EditBusPage({super.key, this.busId});

  @override
  State<EditBusPage> createState() => _EditBusPageState();
}

class _EditBusPageState extends State<EditBusPage> {
  final _formKey = GlobalKey<FormState>();

  final _busNumberController = TextEditingController();
  final _capacityController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  final _driverNameController = TextEditingController();
  final _driverPhoneController = TextEditingController();
  final _driverLicenseController = TextEditingController();
  final _driverExperienceController = TextEditingController();
  final _routeNameController = TextEditingController();
  final _routeDistanceController = TextEditingController();
  final _startLocationController = TextEditingController();
  final _endLocationController = TextEditingController();
  final _notesController = TextEditingController();

  String? _busType;
  TimeOfDay? _morningStartTime;
  TimeOfDay? _morningEndTime;
  TimeOfDay? _afternoonStartTime;
  TimeOfDay? _afternoonEndTime;

  bool _isSubmitting = false;
  bool _showSuccess = false;
  bool _showError = false;
  String _errorMessage = '';
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadBusData();
  }

  Future<void> _loadBusData() async {
    if (widget.busId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _apiService.initialize();
      final response = await _apiService.get('${Endpoints.buses}${widget.busId}/');

      if (!response.success || response.data == null) {
        throw Exception(response.error ?? 'Failed to load bus data');
      }

      final busData = response.data as Map<String, dynamic>;

      if (mounted) {
        setState(() {
          _busNumberController.text = busData['bus_number'] ?? '';
          _busType = busData['bus_type'];
          _capacityController.text = (busData['capacity'] as num?)?.toString() ?? '';
          _registrationNumberController.text = busData['registration_number'] ?? '';
          _driverNameController.text = busData['driver_name'] ?? '';
          _driverPhoneController.text = busData['driver_phone'] ?? '';
          _driverLicenseController.text = busData['driver_license'] ?? '';
          _driverExperienceController.text = (busData['driver_experience'] as num?)?.toString() ?? '';
          _routeNameController.text = busData['route_name'] ?? '';
          _routeDistanceController.text = (busData['route_distance'] as num?)?.toString() ?? '';
          _startLocationController.text = busData['start_location'] ?? '';
          _endLocationController.text = busData['end_location'] ?? '';
          _notesController.text = busData['notes'] ?? '';

          // Parse times
          if (busData['morning_start_time'] != null) {
            final timeStr = busData['morning_start_time'].toString();
            final timeParts = timeStr.split(':');
            if (timeParts.length >= 2) {
              _morningStartTime = TimeOfDay(
                  hour: int.tryParse(timeParts[0]) ?? 7,
                  minute: int.tryParse(timeParts[1]) ?? 0);
            }
          }
          if (busData['morning_end_time'] != null) {
            final timeStr = busData['morning_end_time'].toString();
            final timeParts = timeStr.split(':');
            if (timeParts.length >= 2) {
              _morningEndTime = TimeOfDay(
                  hour: int.tryParse(timeParts[0]) ?? 8,
                  minute: int.tryParse(timeParts[1]) ?? 30);
            }
          }
          if (busData['afternoon_start_time'] != null) {
            final timeStr = busData['afternoon_start_time'].toString();
            final timeParts = timeStr.split(':');
            if (timeParts.length >= 2) {
              _afternoonStartTime = TimeOfDay(
                  hour: int.tryParse(timeParts[0]) ?? 15,
                  minute: int.tryParse(timeParts[1]) ?? 0);
            }
          }
          if (busData['afternoon_end_time'] != null) {
            final timeStr = busData['afternoon_end_time'].toString();
            final timeParts = timeStr.split(':');
            if (timeParts.length >= 2) {
              _afternoonEndTime = TimeOfDay(
                  hour: int.tryParse(timeParts[0]) ?? 16,
                  minute: int.tryParse(timeParts[1]) ?? 30);
            }
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _showError = true;
          _errorMessage = 'Error loading bus data: ${e.toString()}';
        });
      }
    }
  }

  @override
  void dispose() {
    _busNumberController.dispose();
    _capacityController.dispose();
    _registrationNumberController.dispose();
    _driverNameController.dispose();
    _driverPhoneController.dispose();
    _driverLicenseController.dispose();
    _driverExperienceController.dispose();
    _routeNameController.dispose();
    _routeDistanceController.dispose();
    _startLocationController.dispose();
    _endLocationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate times
    if (_morningStartTime == null || _morningEndTime == null) {
      setState(() {
        _showError = true;
        _errorMessage = 'Please select morning schedule times';
      });
      return;
    }

    if (_afternoonStartTime == null || _afternoonEndTime == null) {
      setState(() {
        _showError = true;
        _errorMessage = 'Please select afternoon schedule times';
      });
      return;
    }

    if (widget.busId == null) {
      setState(() {
        _showError = true;
        _errorMessage = 'Bus number is required';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _showSuccess = false;
      _showError = false;
      _errorMessage = '';
    });

    try {
      await _apiService.initialize();
      
      // Get school ID from current user's school
      final schoolResponse = await _apiService.get('/management-admin/schools/current/');
      String? schoolId;
      if (schoolResponse.success && schoolResponse.data != null) {
        final data = schoolResponse.data;
        if (data is Map) {
          final schoolData = data['data'] ?? data;
          if (schoolData is Map) {
            schoolId = schoolData['school_id']?.toString() ?? 
                       schoolData['id']?.toString();
          }
        }
      }

      if (schoolId == null) {
        throw Exception('No school found. Please contact administrator to assign a school to your account.');
      }

      // Prepare bus data
      final busData = {
        'school': schoolId,
        'bus_number': _busNumberController.text.trim(),
        'bus_type': _busType ?? 'Standard Bus',
        'capacity': int.parse(_capacityController.text.trim()),
        'registration_number': _registrationNumberController.text.trim(),
        'driver_name': _driverNameController.text.trim(),
        'driver_phone': _driverPhoneController.text.trim(),
        'driver_license': _driverLicenseController.text.trim(),
        'driver_experience': _driverExperienceController.text.trim().isEmpty
            ? null
            : int.tryParse(_driverExperienceController.text.trim()),
        'route_name': _routeNameController.text.trim(),
        'route_distance': _routeDistanceController.text.trim().isEmpty
            ? null
            : double.tryParse(_routeDistanceController.text.trim()),
        'start_location': _startLocationController.text.trim(),
        'end_location': _endLocationController.text.trim(),
        'morning_start_time': '${_morningStartTime!.hour.toString().padLeft(2, '0')}:${_morningStartTime!.minute.toString().padLeft(2, '0')}',
        'morning_end_time': '${_morningEndTime!.hour.toString().padLeft(2, '0')}:${_morningEndTime!.minute.toString().padLeft(2, '0')}',
        'afternoon_start_time': '${_afternoonStartTime!.hour.toString().padLeft(2, '0')}:${_afternoonStartTime!.minute.toString().padLeft(2, '0')}',
        'afternoon_end_time': '${_afternoonEndTime!.hour.toString().padLeft(2, '0')}:${_afternoonEndTime!.minute.toString().padLeft(2, '0')}',
        'notes': _notesController.text.trim(),
        'is_active': true,
      };

      // Update bus using bus_number as the identifier
      final busResponse = await _apiService.put('${Endpoints.buses}${widget.busId}/', body: busData);

      if (!busResponse.success) {
        throw Exception(busResponse.error ?? 'Failed to update bus');
      }

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _showSuccess = true;
        _showError = false;
      });

      await Future<void>.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      
      // Navigate back to buses page
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _showSuccess = false;
        _showError = true;
        _errorMessage = 'Error updating bus: ${e.toString()}';
      });
    }
  }

  void _previewBus() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Text('🚌 Bus Preview'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PreviewItem('Bus Number', _busNumberController.text),
              _PreviewItem('Bus Type', _busType ?? 'Not provided'),
              _PreviewItem('Capacity',
                  _capacityController.text.isEmpty
                      ? 'Not provided'
                      : '${_capacityController.text} passengers'),
              _PreviewItem('Registration',
                  _registrationNumberController.text),
              _PreviewItem('Driver Name', _driverNameController.text),
              _PreviewItem('Driver Phone', _driverPhoneController.text),
              _PreviewItem('License Number', _driverLicenseController.text),
              _PreviewItem('Experience',
                  _driverExperienceController.text.isEmpty
                      ? '0 years'
                      : '${_driverExperienceController.text} years'),
              _PreviewItem('Route Name', _routeNameController.text),
              _PreviewItem('Distance',
                  _routeDistanceController.text.isEmpty
                      ? 'Not provided'
                      : '${_routeDistanceController.text} km'),
              _PreviewItem(
                  'Morning Schedule',
                  _morningStartTime != null && _morningEndTime != null
                      ? '${_morningStartTime!.format(context)} - ${_morningEndTime!.format(context)}'
                      : 'Not provided'),
              _PreviewItem(
                  'Afternoon Schedule',
                  _afternoonStartTime != null && _afternoonEndTime != null
                      ? '${_afternoonStartTime!.format(context)} - ${_afternoonEndTime!.format(context)}'
                      : 'Not provided'),
              _PreviewItem('Start Location',
                  _startLocationController.text.isEmpty
                      ? 'Not provided'
                      : _startLocationController.text),
              _PreviewItem('End Location',
                  _endLocationController.text.isEmpty
                      ? 'Not provided'
                      : _endLocationController.text),
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
          _buildSidebar(),
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
                              'Edit Bus',
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
                                      Navigator.pushReplacementNamed(context, '/buses');
                                    }
                                  },
                                  icon: const Icon(Icons.arrow_back),
                                  label: const Text('Back to Buses'),
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
                        constraints: const BoxConstraints(maxWidth: 800),
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
                                      '🚌 Edit Bus Information',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'Update bus details, driver information, and route',
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
                                          '✅ Bus information updated successfully!',
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
                                      Text('Updating bus information...'),
                                    ],
                                  ),
                                ),
                              // Form Fields
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _busNumberController,
                                      decoration: InputDecoration(
                                        labelText: 'Bus Number *',
                                        hintText: 'Enter bus number',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        prefixIcon: const Icon(Icons.directions_bus),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter bus number';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      decoration: InputDecoration(
                                        labelText: 'Bus Type *',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        prefixIcon: const Icon(Icons.category),
                                      ),
                                      initialValue: _busType,
                                      items: const [
                                        DropdownMenuItem(
                                            value: 'Mini Bus',
                                            child: Text('Mini Bus')),
                                        DropdownMenuItem(
                                            value: 'Standard Bus',
                                            child: Text('Standard Bus')),
                                        DropdownMenuItem(
                                            value: 'Large Bus',
                                            child: Text('Large Bus')),
                                        DropdownMenuItem(
                                            value: 'AC Bus', child: Text('AC Bus')),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _busType = value;
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please select bus type';
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
                                      controller: _capacityController,
                                      decoration: InputDecoration(
                                        labelText: 'Passenger Capacity *',
                                        hintText: 'Enter passenger capacity',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        prefixIcon: const Icon(Icons.people),
                                      ),
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter capacity';
                                        }
                                        if (int.tryParse(value) == null) {
                                          return 'Please enter a valid number';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _registrationNumberController,
                                      decoration: InputDecoration(
                                        labelText: 'Registration Number *',
                                        hintText: 'Enter registration number',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        prefixIcon: const Icon(Icons.badge),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter registration number';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Driver Information',
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
                                      controller: _driverNameController,
                                      decoration: InputDecoration(
                                        labelText: 'Driver Name *',
                                        hintText: 'Enter driver\'s full name',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        prefixIcon: const Icon(Icons.person),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter driver name';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _driverPhoneController,
                                      decoration: InputDecoration(
                                        labelText: 'Driver Phone *',
                                        hintText: 'Enter driver\'s phone number',
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
                                          return 'Please enter driver phone';
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
                                      controller: _driverLicenseController,
                                      decoration: InputDecoration(
                                        labelText: 'Driver License Number *',
                                        hintText: 'Enter license number',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        prefixIcon: const Icon(Icons.credit_card),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter license number';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _driverExperienceController,
                                      decoration: InputDecoration(
                                        labelText: 'Years of Experience',
                                        hintText: 'Enter years of experience',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        prefixIcon: const Icon(Icons.work_history),
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Route Information',
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
                                      controller: _routeNameController,
                                      decoration: InputDecoration(
                                        labelText: 'Route Name *',
                                        hintText: 'Enter route name',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        prefixIcon: const Icon(Icons.route),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter route name';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _routeDistanceController,
                                      decoration: InputDecoration(
                                        labelText: 'Route Distance (km)',
                                        hintText: 'Enter route distance',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        prefixIcon: const Icon(Icons.straighten),
                                      ),
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Schedule',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 15),
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () async {
                                        final time = await showTimePicker(
                                          context: context,
                                          initialTime: _morningStartTime ?? TimeOfDay.now(),
                                        );
                                        if (time != null) {
                                          setState(() {
                                            _morningStartTime = time;
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
                                            Icon(Icons.access_time,
                                                color: Colors.grey[600]),
                                            const SizedBox(width: 10),
                                            Text(
                                              _morningStartTime == null
                                                  ? 'Morning Start Time *'
                                                  : _morningStartTime!.format(context),
                                              style: TextStyle(
                                                color: _morningStartTime == null
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
                                    child: InkWell(
                                      onTap: () async {
                                        final time = await showTimePicker(
                                          context: context,
                                          initialTime: _morningEndTime ??
                                              const TimeOfDay(hour: 8, minute: 30),
                                        );
                                        if (time != null) {
                                          setState(() {
                                            _morningEndTime = time;
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
                                            Icon(Icons.access_time,
                                                color: Colors.grey[600]),
                                            const SizedBox(width: 10),
                                            Text(
                                              _morningEndTime == null
                                                  ? 'Morning End Time *'
                                                  : _morningEndTime!.format(context),
                                              style: TextStyle(
                                                color: _morningEndTime == null
                                                    ? Colors.grey[600]
                                                    : Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_morningStartTime == null || _morningEndTime == null)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 12, top: 4, bottom: 8),
                                  child: Text(
                                    'Please select morning schedule times',
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
                                    child: InkWell(
                                      onTap: () async {
                                        final time = await showTimePicker(
                                          context: context,
                                          initialTime: _afternoonStartTime ?? TimeOfDay.now(),
                                        );
                                        if (time != null) {
                                          setState(() {
                                            _afternoonStartTime = time;
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
                                            Icon(Icons.access_time,
                                                color: Colors.grey[600]),
                                            const SizedBox(width: 10),
                                            Text(
                                              _afternoonStartTime == null
                                                  ? 'Afternoon Start Time *'
                                                  : _afternoonStartTime!.format(context),
                                              style: TextStyle(
                                                color: _afternoonStartTime == null
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
                                    child: InkWell(
                                      onTap: () async {
                                        final time = await showTimePicker(
                                          context: context,
                                          initialTime: _afternoonEndTime ??
                                              const TimeOfDay(hour: 16, minute: 30),
                                        );
                                        if (time != null) {
                                          setState(() {
                                            _afternoonEndTime = time;
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
                                            Icon(Icons.access_time,
                                                color: Colors.grey[600]),
                                            const SizedBox(width: 10),
                                            Text(
                                              _afternoonEndTime == null
                                                  ? 'Afternoon End Time *'
                                                  : _afternoonEndTime!.format(context),
                                              style: TextStyle(
                                                color: _afternoonEndTime == null
                                                    ? Colors.grey[600]
                                                    : Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_afternoonStartTime == null ||
                                  _afternoonEndTime == null)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 12, top: 4, bottom: 8),
                                  child: Text(
                                    'Please select afternoon schedule times',
                                    style: TextStyle(
                                      color: Colors.red[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _startLocationController,
                                decoration: InputDecoration(
                                  labelText: 'Start Location',
                                  hintText: 'Enter starting location',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  prefixIcon: const Icon(Icons.location_on),
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _endLocationController,
                                decoration: InputDecoration(
                                  labelText: 'End Location',
                                  hintText: 'Enter ending location',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  prefixIcon: const Icon(Icons.location_on),
                                ),
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
                                    label: const Text('Update Bus'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF667EEA),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 12),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  ElevatedButton.icon(
                                    onPressed: _previewBus,
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
                                        Navigator.pushReplacementNamed(context, '/buses');
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
                    isActive: true,
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

