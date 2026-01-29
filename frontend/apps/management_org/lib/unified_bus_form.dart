import 'package:flutter/material.dart';
import 'package:core/api/api_service.dart';
import 'package:core/api/endpoints.dart';
import 'buses.dart';
import 'utils.dart';

// Data model for stops in the unified form
class StopData {
  String name = '';
  String address = '';
  String? time;
  int order = 1;
  String? stopId; // For existing stops
  List<Map<String, dynamic>> students = [];

  StopData({
    this.name = '',
    this.address = '',
    this.time,
    this.order = 1,
    this.stopId,
    List<Map<String, dynamic>>? students,
  }) : students = students ?? [];

  Map<String, dynamic> toJson() {
    return {
      'stop_name': name,
      'stop_address': address,
      'stop_time': time,
      'stop_order': order,
    };
  }
}

// Unified Bus Form Dialog
class UnifiedBusFormDialog extends StatefulWidget {
  final Bus? bus;
  final VoidCallback onSave;

  const UnifiedBusFormDialog({
    super.key,
    this.bus,
    required this.onSave,
  });

  @override
  State<UnifiedBusFormDialog> createState() => _UnifiedBusFormDialogState();
}

class _UnifiedBusFormDialogState extends State<UnifiedBusFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  
  // === BUS DETAILS CONTROLLERS ===
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
  bool _isActive = true;
  
  // === STOPS DATA ===
  List<StopData> _morningStops = [];
  List<StopData> _afternoonStops = [];
  
  // === STATE ===
  bool _isSubmitting = false;
  bool _isSuccess = false;
  bool _isLoading = false;
  int _currentStep = 0;
  final bool _autoSyncAfternoonStops = true; // Auto-sync afternoon stops from morning
  
  @override
  void initState() {
    super.initState();
    if (widget.bus != null) {
      _loadBusData();
    } else {
      _morningStops.add(StopData(order: 1));
      _syncAfternoonStopsFromMorning();
    }
  }
  
  // Auto-generate afternoon stops from morning stops (reverse order)
  // Morning 1st stop = Afternoon last stop
  // IMPORTANT: Syncs name, address, and students from morning stops
  // Students from morning stops are copied to afternoon stops when they match by name
  void _syncAfternoonStopsFromMorning() {
    if (!_autoSyncAfternoonStops) return;
    
    setState(() {
      // Create a map of existing afternoon stops by name to preserve times, students, and stopId
      final existingAfternoonMap = <String, StopData>{};
      for (var stop in _afternoonStops) {
        if (stop.name.isNotEmpty) {
          existingAfternoonMap[stop.name] = stop;
        }
      }
      
      // Generate afternoon stops in reverse order
      final reversedMorningStops = _morningStops.reversed.toList();
      _afternoonStops = reversedMorningStops.asMap().entries.map((entry) {
        final index = entry.key;
        final morningStop = entry.value;
        
        // Find existing afternoon stop with same name to preserve time, students, and stopId
        final existingAfternoonStop = existingAfternoonMap[morningStop.name];
        
        // If afternoon stop exists, preserve its time and stopId, but sync students from morning
        if (existingAfternoonStop != null) {
          // Merge students: start with morning students, then add any unique afternoon students
          final mergedStudents = <String, Map<String, dynamic>>{};
          
          // Add all morning students
          for (var student in morningStop.students) {
            final studentId = student['student_id_string']?.toString() ?? 
                             student['id']?.toString() ?? '';
            if (studentId.isNotEmpty) {
              mergedStudents[studentId] = Map<String, dynamic>.from(student);
            }
          }
          
          // Add any afternoon students that aren't already in morning (preserve unique afternoon students)
          for (var student in existingAfternoonStop.students) {
            final studentId = student['student_id_string']?.toString() ?? 
                             student['id']?.toString() ?? '';
            if (studentId.isNotEmpty && !mergedStudents.containsKey(studentId)) {
              mergedStudents[studentId] = Map<String, dynamic>.from(student);
            }
          }
          
          return StopData(
            name: morningStop.name, // Update name from morning
            address: morningStop.address, // Update address from morning
            time: existingAfternoonStop.time, // Preserve existing afternoon time
            order: index + 1,
            stopId: existingAfternoonStop.stopId, // Preserve stopId
            students: mergedStudents.values.toList(), // Sync students from morning, preserve unique afternoon students
          );
        } else {
          // New afternoon stop - copy students from morning stop
          return StopData(
            name: morningStop.name,
            address: morningStop.address,
            time: null, // No time set yet - user must set it
            order: index + 1,
            stopId: null,
            students: List<Map<String, dynamic>>.from(morningStop.students), // Copy students from morning stop
          );
        }
      }).toList();
    });
  }
  
  // Get all students across all stops to check for duplicates
  Map<String, Map<String, dynamic>> _getAllAssignedStudents() {
    final allStudents = <String, Map<String, dynamic>>{};
    for (var stop in [..._morningStops, ..._afternoonStops]) {
      for (var student in stop.students) {
        final studentId = student['student_id_string']?.toString() ?? 
                         student['id']?.toString() ?? '';
        if (studentId.isNotEmpty) {
          allStudents[studentId] = {
            'student': student,
            'stop_name': stop.name,
            'stop_index': _morningStops.contains(stop) 
                ? _morningStops.indexOf(stop) + 1
                : _afternoonStops.indexOf(stop) + 1,
            'route_type': _morningStops.contains(stop) ? 'morning' : 'afternoon',
          };
        }
      }
    }
    return allStudents;
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
  
  Future<void> _loadBusData() async {
    if (widget.bus == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      await _apiService.initialize();
      final response = await _apiService.get('${Endpoints.buses}${widget.bus!.id}/');
      
      if (response.success && response.data is Map) {
        final busData = response.data as Map<String, dynamic>;
        
        // Load bus details
        _busNumberController.text = busData['bus_number'] ?? '';
        _capacityController.text = (busData['capacity'] ?? '').toString();
        _registrationNumberController.text = busData['registration_number'] ?? '';
        _driverNameController.text = busData['driver_name'] ?? '';
        _driverPhoneController.text = busData['driver_phone'] ?? '';
        _driverLicenseController.text = busData['driver_license'] ?? '';
        _driverExperienceController.text = (busData['driver_experience'] ?? '').toString();
        _routeNameController.text = busData['route_name'] ?? '';
        _routeDistanceController.text = (busData['route_distance'] ?? '').toString();
        _startLocationController.text = busData['start_location'] ?? '';
        _endLocationController.text = busData['end_location'] ?? '';
        _notesController.text = busData['notes'] ?? '';
        _busType = busData['bus_type'];
        _isActive = busData['is_active'] ?? true;
        
        // Parse times
        if (busData['morning_start_time'] != null) {
          final time = _parseTime(busData['morning_start_time']);
          if (time != null) _morningStartTime = time;
        }
        if (busData['morning_end_time'] != null) {
          final time = _parseTime(busData['morning_end_time']);
          if (time != null) _morningEndTime = time;
        }
        if (busData['afternoon_start_time'] != null) {
          final time = _parseTime(busData['afternoon_start_time']);
          if (time != null) _afternoonStartTime = time;
        }
        if (busData['afternoon_end_time'] != null) {
          final time = _parseTime(busData['afternoon_end_time']);
          if (time != null) _afternoonEndTime = time;
        }
        
        // Load stops
        final morningStopsData = busData['morning_stops'] as List? ?? [];
        final afternoonStopsData = busData['afternoon_stops'] as List? ?? [];
        
        _morningStops = morningStopsData.map((stop) {
          final stopMap = stop as Map<String, dynamic>;
          // Load students for this stop
          final students = (stopMap['students'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          return StopData(
            name: stopMap['stop_name'] ?? '',
            address: stopMap['stop_address'] ?? '',
            time: stopMap['stop_time']?.toString(),
            order: stopMap['stop_order'] ?? 1,
            stopId: stopMap['stop_id']?.toString(),
            students: students,
          );
        }).toList();
        
        // Load afternoon stops but preserve their times
        _afternoonStops = afternoonStopsData.map((stop) {
          final stopMap = stop as Map<String, dynamic>;
          final students = (stopMap['students'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          return StopData(
            name: stopMap['stop_name'] ?? '',
            address: stopMap['stop_address'] ?? '',
            time: stopMap['stop_time']?.toString(),
            order: stopMap['stop_order'] ?? 1,
            stopId: stopMap['stop_id']?.toString(),
            students: students,
          );
        }).toList();
        
        if (_morningStops.isEmpty) {
          _morningStops.add(StopData(order: 1));
        }
        
        // Sync afternoon stops from morning if they don't exist
        if (_afternoonStops.isEmpty && _morningStops.isNotEmpty) {
          _syncAfternoonStopsFromMorning();
        } else {
          // Sync students from morning stops to afternoon stops (students assigned to morning should appear in afternoon)
          _syncAfternoonStopsFromMorning();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading bus data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  TimeOfDay? _parseTime(dynamic timeValue) {
    if (timeValue == null) return null;
    final timeStr = timeValue.toString();
    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      return TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 0,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    }
    return null;
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 850),
        padding: const EdgeInsets.all(24),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.bus == null ? 'Add New Bus' : 'Edit Bus',
                        style: const TextStyle(
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
                  
                  // Stepper
                  Expanded(
                    child: Stepper(
                      currentStep: _currentStep,
                      onStepContinue: _currentStep < 2
                          ? () {
                              if (_validateCurrentStep()) {
                                setState(() => _currentStep++);
                              }
                            }
                          : null,
                      onStepCancel: _currentStep > 0
                          ? () {
                              setState(() => _currentStep--);
                            }
                          : null,
                      steps: [
                        Step(
                          title: const Text('Bus Details'),
                          content: _buildBusDetailsSection(),
                          isActive: _currentStep >= 0,
                          state: _currentStep > 0
                              ? StepState.complete
                              : StepState.indexed,
                        ),
                        Step(
                          title: const Text('Morning Route Stops'),
                          content: _buildStopsSection('morning'),
                          isActive: _currentStep >= 1,
                          state: _currentStep > 1
                              ? StepState.complete
                              : StepState.indexed,
                        ),
                        Step(
                          title: const Text('Afternoon Route Stops'),
                          content: _buildStopsSection('afternoon'),
                          isActive: _currentStep >= 2,
                          state: _currentStep >= 2
                              ? StepState.complete
                              : StepState.indexed,
                        ),
                      ],
                    ),
                  ),
                  
                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF667EEA),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(widget.bus == null
                                ? 'Create Bus'
                                : 'Update Bus'),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
  
  Widget _buildBusDetailsSection() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bus Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _busNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Bus Number *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Bus Type *',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _busType,
                    items: ['Mini Bus', 'Standard Bus', 'Large Bus', 'AC Bus']
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _busType = v),
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _capacityController,
                    decoration: const InputDecoration(
                      labelText: 'Capacity *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _registrationNumberController,
              decoration: const InputDecoration(
                labelText: 'Registration Number *',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            const Text(
              'Driver Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _driverNameController,
                    decoration: const InputDecoration(
                      labelText: 'Driver Name *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _driverPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'Driver Phone',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _driverLicenseController,
                    decoration: const InputDecoration(
                      labelText: 'Driver License *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _driverExperienceController,
                    decoration: const InputDecoration(
                      labelText: 'Experience (Years)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Route Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _routeNameController,
              decoration: const InputDecoration(
                labelText: 'Route Name *',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _routeDistanceController,
                    decoration: const InputDecoration(
                      labelText: 'Route Distance (km)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _startLocationController,
                    decoration: const InputDecoration(
                      labelText: 'Start Location',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _endLocationController,
                    decoration: const InputDecoration(
                      labelText: 'End Location',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Schedule Times',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Morning Start Time *'),
                    subtitle: Text(_morningStartTime?.format(context) ?? 'Select time'),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _morningStartTime ?? TimeOfDay.now(),
                      );
                      if (time != null) {
                        setState(() => _morningStartTime = time);
                      }
                    },
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text('Morning End Time *'),
                    subtitle: Text(_morningEndTime?.format(context) ?? 'Select time'),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _morningEndTime ?? TimeOfDay.now(),
                      );
                      if (time != null) {
                        setState(() => _morningEndTime = time);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Afternoon Start Time *'),
                    subtitle: Text(_afternoonStartTime?.format(context) ?? 'Select time'),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _afternoonStartTime ?? TimeOfDay.now(),
                      );
                      if (time != null) {
                        setState(() => _afternoonStartTime = time);
                      }
                    },
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text('Afternoon End Time *'),
                    subtitle: Text(_afternoonEndTime?.format(context) ?? 'Select time'),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _afternoonEndTime ?? TimeOfDay.now(),
                      );
                      if (time != null) {
                        setState(() => _afternoonEndTime = time);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStopsSection(String routeType) {
    final stops = routeType == 'morning' ? _morningStops : _afternoonStops;
    final isAfternoon = routeType == 'afternoon';
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${routeType == 'morning' ? 'Morning' : 'Afternoon'} Route Stops',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isAfternoon)
                    const Text(
                      'Auto-generated from morning stops (read-only except time)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
              if (!isAfternoon)
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      final newOrder = stops.isEmpty
                          ? 1
                          : (stops.map((s) => s.order).reduce((a, b) => a > b ? a : b) + 1);
                      _morningStops.add(StopData(order: newOrder));
                      _syncAfternoonStopsFromMorning();
                    });
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Stop'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF51CF66),
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (stops.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('No stops added. Click "Add Stop" to add one.'),
              ),
            )
          else
            ...stops.asMap().entries.map((entry) {
              final index = entry.key;
              final stop = entry.value;
              return _StopCard(
                stop: stop,
                index: index,
                routeType: routeType,
                onUpdate: (updatedStop) {
                  setState(() {
                    if (routeType == 'morning') {
                      _morningStops[index] = updatedStop;
                      // Sync name and address to afternoon stops, but preserve afternoon times
                      _syncAfternoonStopsFromMorning();
                    } else {
                      // Afternoon stops: allow all updates (name, address, time are all editable)
                      // But name and address will be synced from morning, so only time and students matter here
                      _afternoonStops[index] = updatedStop;
                    }
                  });
                },
                onDelete: () {
                  if (routeType == 'morning') {
                    setState(() {
                      _morningStops.removeAt(index);
                      // Reorder remaining stops
                      for (var i = 0; i < _morningStops.length; i++) {
                        _morningStops[i].order = i + 1;
                      }
                      _syncAfternoonStopsFromMorning();
                    });
                  }
                  // Afternoon stops cannot be deleted (they're auto-generated)
                },
                onAddStudents: () => _showAddStudentsDialog(stop, routeType, index),
              );
            }),
        ],
      ),
    );
  }
  
  Widget _StopCard({
    required StopData stop,
    required int index,
    required String routeType,
    required Function(StopData) onUpdate,
    required VoidCallback onDelete,
    required VoidCallback onAddStudents,
  }) {
    final isAfternoon = routeType == 'afternoon';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text('Stop ${index + 1}: ${stop.name.isEmpty ? "New Stop" : stop.name}'),
        subtitle: Text('${stop.students.length} students'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextFormField(
                  initialValue: stop.name,
                  decoration: InputDecoration(
                    labelText: 'Stop Name *',
                    border: const OutlineInputBorder(),
                    filled: isAfternoon,
                    fillColor: isAfternoon ? Colors.grey[200] : null,
                  ),
                  readOnly: isAfternoon,
                  onChanged: isAfternoon ? null : (v) {
                    stop.name = v;
                    onUpdate(stop);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: stop.address,
                  decoration: InputDecoration(
                    labelText: 'Stop Address',
                    border: const OutlineInputBorder(),
                    filled: isAfternoon,
                    fillColor: isAfternoon ? Colors.grey[200] : null,
                  ),
                  readOnly: isAfternoon,
                  onChanged: isAfternoon ? null : (v) {
                    stop.address = v;
                    onUpdate(stop);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: const Text('Stop Time *'),
                        subtitle: Text(
                          stop.time ?? 'Not set - Click to select time',
                          style: TextStyle(
                            color: stop.time == null ? Colors.orange : Colors.black,
                            fontStyle: stop.time == null ? FontStyle.italic : FontStyle.normal,
                          ),
                        ),
                        trailing: const Icon(Icons.access_time, color: Colors.blue),
                        onTap: () async {
                          // Both morning and afternoon stops: time is editable
                          TimeOfDay? initialTime;
                          if (stop.time != null && stop.time!.isNotEmpty) {
                            final parts = stop.time!.split(':');
                            if (parts.length >= 2) {
                              initialTime = TimeOfDay(
                                hour: int.tryParse(parts[0]) ?? 0,
                                minute: int.tryParse(parts[1]) ?? 0,
                              );
                            }
                          }
                          final time = await showTimePicker(
                            context: context,
                            initialTime: initialTime ?? TimeOfDay.now(),
                          );
                          if (time != null) {
                            stop.time =
                                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                            onUpdate(stop);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        initialValue: stop.order.toString(),
                        decoration: InputDecoration(
                          labelText: 'Stop Order *',
                          border: const OutlineInputBorder(),
                          filled: isAfternoon,
                          fillColor: isAfternoon ? Colors.grey[200] : null,
                        ),
                        keyboardType: TextInputType.number,
                        readOnly: isAfternoon,
                        onChanged: isAfternoon ? null : (v) {
                          stop.order = int.tryParse(v) ?? 1;
                          onUpdate(stop);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Students at this stop:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton.icon(
                      onPressed: onAddStudents,
                      icon: const Icon(Icons.person_add, size: 18),
                      label: const Text('Add Students'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF51CF66),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (stop.students.isEmpty)
                  const Text(
                    'No students assigned',
                    style: TextStyle(color: Colors.grey),
                  )
                else
                  ...stop.students.map((student) {
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          (student['student_name'] ?? '?')[0].toUpperCase(),
                        ),
                      ),
                      title: Text(student['student_name'] ?? 'Unknown'),
                      subtitle: Text('ID: ${student['student_id_string'] ?? student['id'] ?? 'N/A'}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            final studentId = student['student_id_string']?.toString() ?? 
                                             student['id']?.toString() ?? '';
                            stop.students.remove(student);
                            
                            // If morning stop, also remove from corresponding afternoon stop
                            if (routeType == 'morning') {
                              final correspondingAfternoonStop = _afternoonStops.firstWhere(
                                (afternoonStop) => afternoonStop.name == stop.name,
                                orElse: () => StopData(),
                              );
                              if (correspondingAfternoonStop.name.isNotEmpty && studentId.isNotEmpty) {
                                correspondingAfternoonStop.students.removeWhere(
                                  (s) => (s['student_id_string']?.toString() ?? s['id']?.toString()) == studentId
                                );
                              }
                              // Sync to ensure consistency
                              _syncAfternoonStopsFromMorning();
                            }
                            
                            onUpdate(stop);
                          });
                        },
                      ),
                    );
                  }),
                const SizedBox(height: 8),
                if (!isAfternoon)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text('Delete Stop', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _showAddStudentsDialog(
      StopData stop, String routeType, int stopIndex) async {
    final studentIdController = TextEditingController();
    bool isLoadingStudents = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Add Students to ${stop.name.isEmpty ? "Stop ${stopIndex + 1}" : stop.name}'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: studentIdController,
                  decoration: const InputDecoration(
                    labelText: 'Enter Student ID',
                    hintText: 'Search by Student ID',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onSubmitted: (value) async {
                    if (value.isEmpty) return;
                    setDialogState(() => isLoadingStudents = true);
                    
                    // Flag to track if student should be blocked from adding
                    bool shouldBlockAdding = false;
                    String? blockingBusNumber;
                    
                    try {
                      await _apiService.initialize();
                      final response = await _apiService.get(Endpoints.students);
                      if (response.success) {
                        List<dynamic> allStudents = [];
                        if (response.data is List) {
                          allStudents = response.data as List;
                        } else if (response.data is Map &&
                            (response.data as Map)['results'] != null) {
                          allStudents = (response.data as Map)['results'] as List;
                        }
                        final student = allStudents.firstWhere(
                          (s) =>
                              s['student_id']?.toString() == value ||
                              s['id']?.toString() == value,
                          orElse: () => null,
                        );
                        if (student != null) {
                          final studentIdString = student['student_id']?.toString() ??
                              student['id']?.toString();
                          
                          // First, check if student is already assigned to another bus in the database
                          String? existingBusNumber;
                          try {
                            await _apiService.initialize();
                            
                            // Get current bus number (for existing bus use widget.bus!.id, for new use form value)
                            final currentBusNumber = widget.bus != null 
                                ? widget.bus!.id 
                                : _busNumberController.text.trim();
                            
                            debugPrint('Checking if student $studentIdString is assigned to another bus...');
                            debugPrint('Current bus number: $currentBusNumber');
                            
                            // Try search first, then fallback to getting all and filtering
                            var busStopStudentsResponse = await _apiService.get(
                              '${Endpoints.busStopStudents}?search=$studentIdString'
                            );
                            
                            // If search doesn't return results, try getting all and filtering client-side
                            if (!busStopStudentsResponse.success || 
                                busStopStudentsResponse.data == null ||
                                (busStopStudentsResponse.data is List && (busStopStudentsResponse.data as List).isEmpty) ||
                                (busStopStudentsResponse.data is Map && 
                                 (busStopStudentsResponse.data as Map)['results'] != null &&
                                 ((busStopStudentsResponse.data as Map)['results'] as List).isEmpty)) {
                              debugPrint('Search returned no results, trying to get all bus-stop-students...');
                              busStopStudentsResponse = await _apiService.get(Endpoints.busStopStudents);
                            }
                            
                            debugPrint('Bus stop students response: ${busStopStudentsResponse.success}');
                            
                            if (busStopStudentsResponse.success && busStopStudentsResponse.data != null) {
                              List<dynamic> assignments = [];
                              if (busStopStudentsResponse.data is List) {
                                assignments = busStopStudentsResponse.data as List;
                              } else if (busStopStudentsResponse.data is Map) {
                                final dataMap = busStopStudentsResponse.data as Map;
                                if (dataMap['results'] != null) {
                                  assignments = dataMap['results'] as List;
                                } else if (dataMap['data'] != null) {
                                  if (dataMap['data'] is List) {
                                    assignments = dataMap['data'] as List;
                                  } else {
                                    assignments = [dataMap['data']];
                                  }
                                }
                              }
                              
                              debugPrint('Found ${assignments.length} total bus-stop-student assignments');
                              
                              // Check if student is assigned to a different bus
                              for (var assignment in assignments) {
                                if (assignment is Map) {
                                  // Verify this is the correct student by checking multiple fields
                                  final assignmentStudentId = assignment['student_id_string']?.toString() ?? 
                                                             assignment['student_id']?.toString();
                                  
                                  // Also check nested student object if present
                                  String? nestedStudentId;
                                  if (assignment['student'] is Map) {
                                    final studentObj = assignment['student'] as Map;
                                    nestedStudentId = studentObj['student_id']?.toString() ?? 
                                                    studentObj['id']?.toString();
                                  } else if (assignment['student'] is String) {
                                    nestedStudentId = assignment['student'] as String;
                                  }
                                  
                                  final finalStudentId = assignmentStudentId ?? nestedStudentId;
                                  
                                  debugPrint('Checking assignment - student_id: $finalStudentId (looking for: $studentIdString)');
                                  
                                  // Check if this matches our student (try multiple formats)
                                  bool isMatch = finalStudentId == studentIdString || 
                                                finalStudentId == value;
                                  
                                  // Also try partial matching if exact match fails
                                  if (!isMatch && finalStudentId != null && studentIdString != null) {
                                    isMatch = finalStudentId.contains(studentIdString) || 
                                             studentIdString.contains(finalStudentId);
                                  }
                                  
                                  if (!isMatch) {
                                    continue; // Skip if not the same student
                                  }
                                  
                                  debugPrint('✓ Found matching student assignment!');
                                  
                                  // Try to get bus number from the new bus_number field first (from updated serializer)
                                  String? assignedBusNumber = assignment['bus_number']?.toString();
                                  debugPrint('Bus number from direct field: $assignedBusNumber');
                                  
                                  // If not available, try the nested structure
                                  if (assignedBusNumber == null || assignedBusNumber.isEmpty) {
                                    // Try bus_stop_detail first (new structure)
                                    final busStopDetail = assignment['bus_stop_detail'];
                                    if (busStopDetail is Map) {
                                      final busInfo = busStopDetail['bus'];
                                      if (busInfo is Map) {
                                        assignedBusNumber = busInfo['bus_number']?.toString() ?? 
                                                           busInfo['id']?.toString();
                                        debugPrint('Bus number from bus_stop_detail: $assignedBusNumber');
                                      }
                                    }
                                    
                                    // Fallback to old structure
                                    if (assignedBusNumber == null || assignedBusNumber.isEmpty) {
                                      // Get the bus_stop info
                                      final busStopInfo = assignment['bus_stop'];
                                      debugPrint('Bus stop info: $busStopInfo');
                                      
                                      if (busStopInfo is Map) {
                                    // Try to get bus info from nested structure
                                    final busInfo = busStopInfo['bus'];
                                    debugPrint('Bus info type: ${busInfo.runtimeType}, value: $busInfo');
                                    
                                    if (busInfo is Map) {
                                      assignedBusNumber = busInfo['bus_number']?.toString() ?? 
                                                         busInfo['bus_id']?.toString() ??
                                                         busInfo['id']?.toString();
                                      debugPrint('Extracted bus_number from Map: $assignedBusNumber');
                                    } else if (busInfo is String) {
                                      // busInfo is a bus ID string - we need to fetch the bus to get bus_number
                                      debugPrint('Bus info is string (ID): $busInfo, fetching bus details...');
                                      try {
                                        final busResponse = await _apiService.get('${Endpoints.buses}$busInfo/');
                                        if (busResponse.success && busResponse.data is Map) {
                                          final busData = busResponse.data as Map;
                                          assignedBusNumber = busData['bus_number']?.toString() ??
                                                             busData['id']?.toString() ??
                                                             busInfo; // Fallback to ID if bus_number not found
                                          debugPrint('Fetched bus_number from API: $assignedBusNumber');
                                        } else {
                                          // If we can't fetch bus details, use the ID as fallback
                                          assignedBusNumber = busInfo;
                                          debugPrint('Could not fetch bus details, using ID: $assignedBusNumber');
                                        }
                                      } catch (e) {
                                        debugPrint('Error fetching bus details: $e');
                                        // If fetch fails, treat as potential conflict if it's a new bus
                                        if (currentBusNumber.isEmpty) {
                                          assignedBusNumber = 'another bus';
                                        } else {
                                          assignedBusNumber = busInfo;
                                        }
                                      }
                                    }
                                    
                                    // Also try to get bus_number directly from bus_stop if available
                                    if (assignedBusNumber == null || assignedBusNumber.isEmpty) {
                                      assignedBusNumber = busStopInfo['bus_number']?.toString() ??
                                                         busStopInfo['bus_id']?.toString();
                                      debugPrint('Tried bus_stop direct fields, got: $assignedBusNumber');
                                    }
                                    
                                    debugPrint('Final assigned bus number: "$assignedBusNumber"');
                                    debugPrint('Current bus number: "$currentBusNumber"');
                                    
                                    // If we found an assignment, check if it's a conflict
                                    if (assignedBusNumber != null && assignedBusNumber.isNotEmpty) {
                                      // If bus numbers don't match, it's a conflict
                                      if (assignedBusNumber.trim().toLowerCase() != currentBusNumber.trim().toLowerCase()) {
                                        existingBusNumber = assignedBusNumber;
                                        debugPrint('✓✓✓ CONFLICT DETECTED - Student is assigned to different bus: $existingBusNumber');
                                        break;
                                      } 
                                      // If they match, it's the same bus - no conflict
                                      else {
                                        debugPrint('Student is assigned to same bus, no conflict');
                                      }
                                    } 
                                    // If we found an assignment but couldn't determine bus number,
                                    // ALWAYS treat as conflict (student is assigned somewhere, we just don't know which bus)
                                    else {
                                      // Student is assigned somewhere but we can't determine which bus
                                      // This is always a conflict - student shouldn't be in multiple places
                                      existingBusNumber = 'another bus';
                                      debugPrint('✓✓✓ CONFLICT DETECTED - Student is assigned but bus number unknown');
                                      break;
                                    }
                                      } else {
                                        debugPrint('Bus stop info is not a Map, type: ${busStopInfo.runtimeType}');
                                        // If bus_stop is not a Map, we can't determine the bus - treat as conflict
                                        existingBusNumber = 'another bus';
                                        debugPrint('✓✓✓ CONFLICT DETECTED - Bus stop info is not a Map');
                                        break;
                                      }
                                    }
                                  }
                                  
                                  // Final check: If we still don't have a bus number but found an assignment, treat as conflict
                                  if (assignedBusNumber.isEmpty) {
                                    // Student is assigned somewhere - this is always a conflict
                                    existingBusNumber = 'another bus';
                                    debugPrint('✓✓✓ CONFLICT DETECTED - Student assigned but bus number could not be determined');
                                    break;
                                  }
                                  
                                  // Final comparison check - we know assignedBusNumber is not null/empty here
                                  debugPrint('Final assigned bus number: "$assignedBusNumber"');
                                  debugPrint('Current bus number: "$currentBusNumber"');
                                  
                                  // If bus numbers don't match, it's a conflict
                                  final assignedBus = assignedBusNumber.trim().toLowerCase();
                                  final currentBus = currentBusNumber.trim().toLowerCase();
                                  if (assignedBus != currentBus) {
                                    existingBusNumber = assignedBusNumber;
                                    debugPrint('✓✓✓ CONFLICT DETECTED - Student is assigned to different bus: $existingBusNumber');
                                    break;
                                  } 
                                  // If they match, it's the same bus - no conflict
                                  else {
                                    debugPrint('Student is assigned to same bus, no conflict');
                                  }
                                }
                              }
                            }
                            
                            // If student is assigned to another bus, set flag to block adding
                            if (existingBusNumber != null && existingBusNumber.isNotEmpty) {
                              shouldBlockAdding = true;
                              blockingBusNumber = existingBusNumber;
                              debugPrint('✓✓✓ Student is assigned to different bus: $existingBusNumber');
                            } else {
                              debugPrint('Student is not assigned to another bus, continuing...');
                            }
                          } catch (e) {
                            debugPrint('Error checking student bus assignment: $e');
                            debugPrint('Stack trace: ${StackTrace.current}');
                            // Continue with local check if API check fails
                          }
                          
                          // If student is blocked, show popup and prevent adding
                          if (shouldBlockAdding && blockingBusNumber != null) {
                            debugPrint('✓✓✓ Showing popup for bus: $blockingBusNumber');
                            setDialogState(() {
                              isLoadingStudents = false;
                            });
                            
                            // Clear the input field
                            studentIdController.clear();
                            
                            // Use a small delay to ensure state updates
                            await Future.delayed(const Duration(milliseconds: 100));
                            
                            if (mounted) {
                              // Show popup on top of the add student dialog
                              await showDialog(
                                context: context,
                                barrierDismissible: true,
                                builder: (dialogContext) => AlertDialog(
                                  title: const Row(
                                    children: [
                                      Icon(Icons.warning, color: Colors.orange, size: 28),
                                      SizedBox(width: 10),
                                      Text('Student Already Assigned'),
                                    ],
                                  ),
                                  content: Text(
                                    'The student with ID $studentIdString is already assigned to Bus Number: $blockingBusNumber\n\n'
                                    'Please remove the student from that bus first before assigning to this bus.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dialogContext),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            }
                            // IMPORTANT: Return here to prevent adding the student
                            return;
                          }
                          
                          // Reset loading state if check passed
                          setDialogState(() {
                            isLoadingStudents = false;
                          });
                          
                          // Check if student is already assigned to any stop in current form
                          final allAssignedStudents = _getAllAssignedStudents();
                          if (allAssignedStudents.containsKey(studentIdString)) {
                            final assignedInfo = allAssignedStudents[studentIdString]!;
                            final assignedStopName = assignedInfo['stop_name'] as String;
                            final assignedStopIndex = assignedInfo['stop_index'] as int;
                            final assignedRouteType = assignedInfo['route_type'] as String;
                            
                            // Check if it's the same stop
                            if (stop.name == assignedStopName && 
                                routeType == assignedRouteType) {
                              setDialogState(() {
                                isLoadingStudents = false;
                              });
                              // Use dialog instead of snackbar since we're in a dialog context
                              showDialog(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: const Text('Student Already Added'),
                                  content: const Text('This student is already added to this stop.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dialogContext),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              // Show popup that student is already assigned to another stop in this bus
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Student Already Assigned'),
                                  content: Text(
                                    'This student is already assigned to:\n'
                                    'Stop $assignedStopIndex (${assignedRouteType == 'morning' ? 'Morning' : 'Afternoon'} Route): $assignedStopName\n\n'
                                    'Please remove the student from that stop first before assigning to a different stop.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          } else {
                            // Student not assigned, add them
                            final studentMap = {
                              'id': student['student_id'] ?? student['id'],
                              'student_id_string': studentIdString,
                              'student_name': student['student_name'] ?? 'Unknown',
                              'student_class': student['applying_class'] ?? '',
                            };
                            
                            setDialogState(() {
                              isLoadingStudents = false;
                            });
                            
                            setState(() {
                              stop.students.add(studentMap);
                              // If morning stop, sync to corresponding afternoon stop
                              if (routeType == 'morning') {
                                // Find corresponding afternoon stop by name and add the student
                                final correspondingAfternoonStop = _afternoonStops.firstWhere(
                                  (afternoonStop) => afternoonStop.name == stop.name,
                                  orElse: () => StopData(),
                                );
                                if (correspondingAfternoonStop.name.isNotEmpty) {
                                  // Check if student is not already in afternoon stop
                                  final studentId = studentMap['student_id_string']?.toString() ?? 
                                                   studentMap['id']?.toString() ?? '';
                                  final alreadyExists = correspondingAfternoonStop.students.any(
                                    (s) => (s['student_id_string']?.toString() ?? s['id']?.toString()) == studentId
                                  );
                                  if (!alreadyExists) {
                                    correspondingAfternoonStop.students.add(Map<String, dynamic>.from(studentMap));
                                  }
                                }
                                // Also sync all stops to ensure consistency
                                _syncAfternoonStopsFromMorning();
                              } else if (routeType == 'afternoon') {
                                // If afternoon stop, also sync
                                _syncAfternoonStopsFromMorning();
                              }
                            });
                            studentIdController.clear();
                            // Student added successfully - no need to show message, field is cleared
                          }
                        } else {
                          setDialogState(() {
                            isLoadingStudents = false;
                          });
                          setDialogState(() {
                            isLoadingStudents = false;
                          });
                          // Use dialog instead of snackbar
                          showDialog(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Student Not Found'),
                              content: Text('Student with ID $value not found. Please check the student ID and try again.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      // Check if mounted and if ScaffoldMessenger is available
                      if (mounted) {
                        try {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        } catch (scaffoldError) {
                          // If ScaffoldMessenger is not available (e.g., in dialog), show dialog instead
                          debugPrint('Error showing snackbar: $scaffoldError');
                          debugPrint('Original error: $e');
                          if (mounted) {
                            showDialog(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('Error'),
                                content: Text('Error: $e'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dialogContext),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          }
                        }
                      }
                    } finally {
                      setDialogState(() => isLoadingStudents = false);
                    }
                  },
                ),
                if (isLoadingStudents)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
  
  bool _validateCurrentStep() {
    if (_currentStep == 0) {
      if (!_formKey.currentState!.validate()) return false;
      if (_morningStartTime == null ||
          _morningEndTime == null ||
          _afternoonStartTime == null ||
          _afternoonEndTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select all schedule times'),
          ),
        );
        return false;
      }
    }
    return true;
  }
  
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_morningStartTime == null ||
        _morningEndTime == null ||
        _afternoonStartTime == null ||
        _afternoonEndTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select all schedule times'),
        ),
      );
      return;
    }
    
    // Validate all students before submission - check if any are assigned to other buses
    final currentBusNumber = widget.bus != null 
        ? widget.bus!.id 
        : _busNumberController.text.trim();
    
    if (currentBusNumber.isNotEmpty) {
      setState(() => _isSubmitting = true);
      
      try {
        await _apiService.initialize();
        
        // Get all students from all stops
        final allStudents = _getAllAssignedStudents();
        final List<Map<String, String>> validationErrors = [];
        
        // Check each student
        for (var entry in allStudents.entries) {
          final studentId = entry.key;
          final studentInfo = entry.value;
          
          try {
            // Check if student is assigned to another bus
            var busStopStudentsResponse = await _apiService.get(
              '${Endpoints.busStopStudents}?search=$studentId'
            );
            
            if (!busStopStudentsResponse.success || 
                busStopStudentsResponse.data == null ||
                (busStopStudentsResponse.data is List && (busStopStudentsResponse.data as List).isEmpty) ||
                (busStopStudentsResponse.data is Map && 
                 (busStopStudentsResponse.data as Map)['results'] != null &&
                 ((busStopStudentsResponse.data as Map)['results'] as List).isEmpty)) {
              busStopStudentsResponse = await _apiService.get(Endpoints.busStopStudents);
            }
            
            if (busStopStudentsResponse.success && busStopStudentsResponse.data != null) {
              List<dynamic> assignments = [];
              if (busStopStudentsResponse.data is List) {
                assignments = busStopStudentsResponse.data as List;
              } else if (busStopStudentsResponse.data is Map) {
                final dataMap = busStopStudentsResponse.data as Map;
                if (dataMap['results'] != null) {
                  assignments = dataMap['results'] as List;
                } else if (dataMap['data'] != null) {
                  if (dataMap['data'] is List) {
                    assignments = dataMap['data'] as List;
                  } else {
                    assignments = [dataMap['data']];
                  }
                }
              }
              
              // Check if student is assigned to a different bus
              for (var assignment in assignments) {
                if (assignment is Map) {
                  final assignmentStudentId = assignment['student_id_string']?.toString() ?? 
                                             assignment['student_id']?.toString();
                  
                  String? nestedStudentId;
                  if (assignment['student'] is Map) {
                    final studentObj = assignment['student'] as Map;
                    nestedStudentId = studentObj['student_id']?.toString() ?? 
                                    studentObj['id']?.toString();
                  } else if (assignment['student'] is String) {
                    nestedStudentId = assignment['student'] as String;
                  }
                  
                  final finalStudentId = assignmentStudentId ?? nestedStudentId;
                  
                  if (finalStudentId == studentId || 
                      finalStudentId?.contains(studentId) == true ||
                      studentId.contains(finalStudentId ?? '')) {
                    final busStopInfo = assignment['bus_stop'];
                    if (busStopInfo is Map) {
                      final busInfo = busStopInfo['bus'];
                      String? assignedBus;
                      if (busInfo is Map) {
                        assignedBus = busInfo['bus_number']?.toString() ?? 
                                     busInfo['id']?.toString();
                      } else if (busInfo is String) {
                        assignedBus = busInfo;
                      }
                      
                      if (assignedBus != null && 
                          assignedBus.isNotEmpty && 
                          assignedBus.trim() != currentBusNumber.trim()) {
                        final stopName = studentInfo['stop_name'] as String? ?? 'Unknown Stop';
                        validationErrors.add({
                          'student_id': studentId,
                          'student_name': studentInfo['student_name'] as String? ?? studentId,
                          'stop_name': stopName,
                          'assigned_bus': assignedBus,
                        });
                        break;
                      }
                    }
                  }
                }
              }
            }
          } catch (e) {
            debugPrint('Error validating student $studentId: $e');
          }
        }
        
        // If there are validation errors, show them and prevent submission
        if (validationErrors.isNotEmpty) {
          setState(() => _isSubmitting = false);
          
          await showDialog(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.error, color: Colors.red, size: 28),
                  SizedBox(width: 10),
                  Text('Cannot Create Bus'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'The following students are already assigned to other buses:\n',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ...validationErrors.map((error) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        '• ${error['student_name']} (ID: ${error['student_id']}) at stop "${error['stop_name']}" is already in Bus ${error['assigned_bus']}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    )),
                    const SizedBox(height: 10),
                    const Text(
                      'Please remove these students from the stops before creating the bus.',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          return; // Prevent form submission
        }
      } catch (e) {
        debugPrint('Error during validation: $e');
        // Continue with submission if validation check fails
      }
    }
    
    setState(() => _isSubmitting = true);
    
    // Track if bus was saved successfully
    bool busSavedSuccessfully = false;
    
    try {
      await _apiService.initialize();
      
      // Get school ID
      final schoolResponse =
          await _apiService.get('/management-admin/schools/current/');
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
        throw Exception(
            'No school found. Please contact administrator to assign a school to your account.');
      }
      
      // Validate capacity field
      final capacityText = _capacityController.text.trim();
      final capacity = int.tryParse(capacityText);
      if (capacity == null || capacity <= 0) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid capacity value. Please enter a valid positive number.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // 1. Create/Update Bus
      final busData = {
        'school': schoolId,
        'bus_number': _busNumberController.text.trim(),
        'bus_type': _busType ?? 'Standard Bus',
        'capacity': capacity,
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
        'morning_start_time':
            '${_morningStartTime!.hour.toString().padLeft(2, '0')}:${_morningStartTime!.minute.toString().padLeft(2, '0')}',
        'morning_end_time':
            '${_morningEndTime!.hour.toString().padLeft(2, '0')}:${_morningEndTime!.minute.toString().padLeft(2, '0')}',
        'afternoon_start_time':
            '${_afternoonStartTime!.hour.toString().padLeft(2, '0')}:${_afternoonStartTime!.minute.toString().padLeft(2, '0')}',
        'afternoon_end_time':
            '${_afternoonEndTime!.hour.toString().padLeft(2, '0')}:${_afternoonEndTime!.minute.toString().padLeft(2, '0')}',
        'notes': _notesController.text.trim(),
        'is_active': _isActive,
      };
      
      final busResponse = widget.bus == null
          ? await _apiService.post(Endpoints.buses, body: busData)
          : await _apiService.put(
              '${Endpoints.buses}${widget.bus!.id}/', body: busData);
      
      if (!busResponse.success) {
        // Get detailed error message
        String errorMessage = 'Failed to save bus';
        if (busResponse.data is Map) {
          final errorData = busResponse.data as Map<String, dynamic>;
          if (errorData.containsKey('detail')) {
            errorMessage = errorData['detail'].toString();
          } else if (errorData.isNotEmpty) {
            // Format validation errors
            final errors = errorData.entries.map((e) => '${e.key}: ${e.value}').join(', ');
            errorMessage = 'Validation errors: $errors';
          }
        } else if (busResponse.error != null) {
          errorMessage = busResponse.error!;
        }
        throw Exception(errorMessage);
      }
      
      // Extract bus_number from response
      String busNumber;
      if (widget.bus != null) {
        busNumber = widget.bus!.id;
      } else {
        // For new bus, get bus_number from response
        final responseData = busResponse.data;
        if (responseData is Map) {
          busNumber = responseData['bus_number']?.toString() ?? 
                     _busNumberController.text.trim();
        } else {
          busNumber = _busNumberController.text.trim();
        }
        
        // Validate that we got a bus_number
        if (busNumber.isEmpty) {
          throw Exception('Bus created but no bus number returned from server');
        }
      }
      
      // Bus is successfully saved at this point - mark it
      busSavedSuccessfully = true;
      
      // 2-5. Create stops and assign students (non-critical - errors won't prevent dialog from closing)
      try {
      // 2. Delete existing stops for this bus (if editing)
      if (widget.bus != null) {
        final existingStopsResponse = await _apiService.get(
            '${Endpoints.busStops}?bus=$busNumber');
        if (existingStopsResponse.success &&
            existingStopsResponse.data is List) {
          final existingStops = existingStopsResponse.data as List;
          for (var stop in existingStops) {
            final stopId = stop['stop_id']?.toString();
            if (stopId != null) {
              await _apiService.delete('${Endpoints.busStops}$stopId/');
            }
          }
        }
      }
      
      // 3. Create Morning Stops
      for (var stop in _morningStops) {
          if (stop.name.isEmpty) continue;
          try {
        final stopData = {
          'bus': busNumber,
          'stop_name': stop.name,
          'stop_address': stop.address,
          'stop_time': stop.time,
          'route_type': 'morning',
          'stop_order': stop.order,
        };
        final stopResponse =
            await _apiService.post(Endpoints.busStops, body: stopData);
            if (stopResponse.success) {
        final responseData = stopResponse.data;
        if (responseData is Map) {
                final stopId = responseData['stop_id']?.toString() ?? 
                   responseData['id']?.toString();
                if (stopId != null && stopId.isNotEmpty) {
                  stop.stopId = stopId;
                }
              }
            }
          } catch (e) {
            debugPrint('Error creating morning stop "${stop.name}": $e');
          }
      }
      
      // 4. Create Afternoon Stops
      for (var stop in _afternoonStops) {
          if (stop.name.isEmpty) continue;
          try {
        final stopData = {
          'bus': busNumber,
          'stop_name': stop.name,
          'stop_address': stop.address,
          'stop_time': stop.time,
          'route_type': 'afternoon',
          'stop_order': stop.order,
        };
        final stopResponse =
            await _apiService.post(Endpoints.busStops, body: stopData);
            if (stopResponse.success) {
        final responseData = stopResponse.data;
        if (responseData is Map) {
                final stopId = responseData['stop_id']?.toString() ?? 
                   responseData['id']?.toString();
                if (stopId != null && stopId.isNotEmpty) {
                  stop.stopId = stopId;
                }
              }
            }
          } catch (e) {
            debugPrint('Error creating afternoon stop "${stop.name}": $e');
          }
      }
      
      // 5. Assign Students to Stops
        final assignedStudentIds = <String>{};
      for (var stop in [..._morningStops, ..._afternoonStops]) {
        if (stop.stopId != null && stop.students.isNotEmpty) {
          for (var student in stop.students) {
            final studentId = student['student_id_string']?.toString() ?? 
                             student['id']?.toString() ?? '';
            
              if (studentId.isEmpty || assignedStudentIds.contains(studentId)) {
              continue;
            }
            
            try {
              final response = await _apiService.post(Endpoints.busStopStudents, body: {
                'stop': stop.stopId,
                'student_id': studentId,
              });
              
              if (response.success) {
                assignedStudentIds.add(studentId);
              } else {
                // During form submission, just log the error - don't show popup
                // The popup should only show when user is actively adding a student to a stop
                final errorMessage = response.error ?? 'Failed to assign student';
                debugPrint('Error assigning student $studentId during form submission: $errorMessage');
                // Note: Students that fail to assign will simply not be added to the stop
                // User can add them later after resolving the conflict
              }
            } catch (e) {
              debugPrint('Error assigning student: $e');
            }
            }
          }
        }
      } catch (e) {
        // Log errors but don't prevent dialog from closing - bus is already saved
        debugPrint('Error creating stops or assigning students: $e');
      }
      
      // Reset submitting state
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
      
      // Call onSave callback to refresh the bus list (before closing dialog)
      try {
        widget.onSave();
      } catch (e) {
        debugPrint('Error in onSave callback: $e');
      }
      
      // Close dialog and return true to indicate success
      // This MUST happen - bus is saved, so dialog should close regardless of stops/students
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      // Reset submitting state on error
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
      
      // If bus was saved successfully, close dialog anyway (stops/students errors are non-critical)
      if (busSavedSuccessfully) {
        // Call onSave callback to refresh
        try {
          widget.onSave();
        } catch (e2) {
          debugPrint('Error in onSave callback: $e2');
        }
        
        // Close dialog even though there were errors in stops/students
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        // Bus save failed - don't close dialog, show error
        if (mounted) {
        try {
          if (Navigator.of(context).canPop()) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${e.toString()}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        } catch (contextError) {
          debugPrint('Error showing snackbar: $contextError');
          debugPrint('Original error: $e');
          }
        }
      }
    }
  }
}

