import 'dart:ui';

import 'package:flutter/material.dart';
import 'main.dart' as app;
import 'dashboard.dart';
import 'widgets/student_list_dialog.dart';
import 'widgets/school_profile_header.dart';
import 'package:core/api/api_service.dart';
import 'package:core/api/endpoints.dart';
import 'unified_bus_form.dart';
import 'models/bus_details_model.dart';
import 'widgets/bus_details_view.dart';
import 'widgets/management_sidebar.dart';
import 'utils.dart';

class BusStop {
  final String name;
  final String time;
  final int students;

  const BusStop({
    required this.name,
    required this.time,
    required this.students,
  });
}

class Bus {
  final String id; // Changed to String to store UUID
  final String busNumber;
  final String driverName;
  final String driverPhone;
  final String route;
  final int stops;
  final int students;
  final int capacity;
  final String licensePlate;
  final String model;
  final String status;
  final List<BusStop> routeStops;
  final List<BusStop> returnStops;

  const Bus({
    required this.id,
    required this.busNumber,
    required this.driverName,
    required this.driverPhone,
    required this.route,
    required this.stops,
    required this.students,
    required this.capacity,
    required this.licensePlate,
    required this.model,
    required this.status,
    required this.routeStops,
    required this.returnStops,
  });
}

class BusesManagementPage extends StatefulWidget {
  const BusesManagementPage({super.key});

  @override
  State<BusesManagementPage> createState() => _BusesManagementPageState();
}

class _BusesManagementPageState extends State<BusesManagementPage> {
  List<Bus> _buses = [];
  final TextEditingController _searchController = TextEditingController();
  late List<Bus> _visibleBuses;
  bool _isLoading = true;
  String? _errorMessage;
  final ApiService _apiService = ApiService();

  // Check if user has edit permissions (Financial users are read-only)
  bool get _canEdit => _apiService.userRole != 'financial';

  @override
  void initState() {
    super.initState();
    _visibleBuses = [];
    _loadBuses();
  }

  Future<void> _loadBuses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _apiService.initialize();
      final response = await _apiService.get(Endpoints.buses);

      if (!response.success) {
        throw Exception(response.error ?? 'Failed to load buses');
      }

      List<dynamic> busesData = [];
      if (response.data is List) {
        busesData = response.data as List;
      } else if (response.data is Map && (response.data as Map)['results'] != null) {
        busesData = (response.data as Map)['results'] as List;
      }

      List<Bus> loadedBuses = [];
      for (var busData in busesData) {
        final busMap = busData as Map<String, dynamic>;
        final busId = busMap['bus_number']?.toString() ?? busMap['bus_id']?.toString() ?? busMap['id']?.toString();
        
        if (busId == null || busId.isEmpty) continue;

        // Fetch complete bus details with stops and students
        final detailResponse = await _apiService.get('${Endpoints.buses}$busId/');
        
        if (!detailResponse.success || detailResponse.data is! Map) {
          // Fallback to basic data if detail fetch fails
          final bus = Bus(
            id: busId,
            busNumber: busMap['bus_number'] ?? '',
            driverName: busMap['driver_name'] ?? '',
            driverPhone: busMap['driver_phone'] ?? '',
            route: busMap['route_name'] ?? '',
            stops: 0,
            students: 0,
            capacity: (busMap['capacity'] as num?)?.toInt() ?? 0,
            licensePlate: busMap['registration_number'] ?? '',
            model: busMap['bus_type'] ?? '',
            status: (busMap['is_active'] as bool? ?? false) ? 'Active' : 'Inactive',
            routeStops: [],
            returnStops: [],
          );
          loadedBuses.add(bus);
          continue;
        }

        // Parse complete bus details
        final busDetails = BusDetails.fromJson(detailResponse.data as Map<String, dynamic>);
        
        // Convert to Bus model for compatibility with existing UI
        final bus = Bus(
          id: busId,
          busNumber: busDetails.busNumber,
          driverName: busDetails.driverName,
          driverPhone: busDetails.driverPhone,
          route: busDetails.routeName,
          stops: busDetails.totalStops,
          students: busDetails.totalStudents,
          capacity: busDetails.capacity,
          licensePlate: busDetails.registrationNumber,
          model: busDetails.busType,
          status: busDetails.isActive ? 'Active' : 'Inactive',
          routeStops: busDetails.morningStops.map((stop) => BusStop(
            name: stop.stopName,
            time: stop.stopTime ?? '00:00',
            students: stop.students.length,
          )).toList(),
          returnStops: busDetails.afternoonStops.map((stop) => BusStop(
            name: stop.stopName,
            time: stop.stopTime ?? '00:00',
            students: stop.students.length,
          )).toList(),
        );
        
        loadedBuses.add(bus);
      }

      if (mounted) {
        setState(() {
          _buses = loadedBuses;
          _visibleBuses = List<Bus>.from(loadedBuses);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading buses: ${e.toString()}';
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int get _totalBuses => _buses.length;
  int get _activeBuses => _buses.where((b) => b.status == 'Active').length;
  int get _totalStudents => _buses.fold(0, (sum, bus) => sum + bus.students);
  int get _totalRoutes => _buses.map((b) => b.route).toSet().length;

  void _filterBuses(String query) {
    setState(() {
      if (query.isEmpty) {
        _visibleBuses = List<Bus>.from(_buses);
      } else {
        final lower = query.toLowerCase();
        _visibleBuses = _buses.where((bus) {
          return bus.busNumber.toLowerCase().contains(lower) ||
              bus.driverName.toLowerCase().contains(lower) ||
              bus.route.toLowerCase().contains(lower);
        }).toList();
      }
    });
  }

  void _viewBus(Bus bus) async {
    try {
      await _apiService.initialize();
      final response = await _apiService.get('${Endpoints.buses}${bus.id}/');
      
      if (!response.success || response.data is! Map) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load bus details')),
          );
        }
        return;
      }

      final busDetails = BusDetails.fromJson(response.data as Map<String, dynamic>);

      if (mounted) {
        showDialog<void>(
          context: context,
          barrierDismissible: true,
          builder: (context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 800),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(15),
                          topRight: Radius.circular(15),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${bus.busNumber} - Complete Details',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Row(
                            children: [
                              if (_canEdit) ...[
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.white),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    _editBus(bus);
                                  },
                                  tooltip: 'Edit Bus',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.people, color: Colors.white),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    _manageStudents(bus);
                                  },
                                  tooltip: 'Manage Students',
                                ),
                              ],
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: BusDetailsView(busDetails: busDetails),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading bus details: $e')),
        );
      }
    }
  }

  Widget _buildProfileImage(Bus bus) {
    return Column(
      children: [
        Container(
          width: 150,
          height: 150,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            ),
          ),
          child: const Center(
            child: Text(
              '🚌',
              style: TextStyle(fontSize: 48),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          bus.busNumber,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          bus.route,
          style: const TextStyle(color: Color(0xFF666666)),
        ),
        const SizedBox(height: 5),
        Text(
          bus.status,
          style: const TextStyle(
            color: Color(0xFF667EEA),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileDetails(Bus bus) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 20,
      mainAxisSpacing: 20,
      childAspectRatio: 1.2,
      children: [
        _DetailCard(
          title: 'Bus Information',
          items: [
            'Model: ${bus.model}',
            'License Plate: ${bus.licensePlate}',
            'Capacity: ${bus.capacity} students',
            'Current Load: ${bus.students} students',
          ],
        ),
        _DetailCard(
          title: 'Driver Information',
          items: [
            'Name: ${bus.driverName}',
            'Phone: ${bus.driverPhone}',
            'Route: ${bus.route}',
            'Stops: ${bus.stops}',
          ],
        ),
      ],
    );
  }

  Widget _buildRouteMap(String title, List<BusStop> stops, {String? busId, String? routeType}) {
    final ApiService apiService = ApiService();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🛣️', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (stops.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No stops added yet',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...stops.asMap().entries.map(
              (entry) {
                final index = entry.key;
                final stop = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () {
                      // Double tap to view students - for real API integration
                      if (busId != null) {
                        _viewStopStudents(context, stop.name, busId, routeType ?? 'morning', apiService);
                      }
                    },
                    onDoubleTap: () {
                      if (busId != null) {
                        _viewStopStudents(context, stop.name, busId, routeType ?? 'morning', apiService);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: busId != null ? const Color(0xFF667EEA) : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              stop.time,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              stop.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ),
                          Text(
                            '${stop.students} students',
                            style: const TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 12,
                            ),
                          ),
                          if (busId != null) ...[
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: () {
                                _viewStopStudents(context, stop.name, busId, routeType ?? 'morning', apiService);
                              },
                              icon: const Icon(Icons.visibility, size: 16),
                              label: const Text('View'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF667EEA),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                minimumSize: Size.zero,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _viewStopStudents(BuildContext context, String stopName, String busId, String routeType, ApiService apiService) async {
    try {
      // First, get bus stops for this bus and route type
      await apiService.initialize();
      final stopsResponse = await apiService.get('${Endpoints.buses}$busId/');
      
      if (!stopsResponse.success) {
        throw Exception('Failed to load bus stops');
      }

      final busData = stopsResponse.data as Map<String, dynamic>;
      final stops = routeType == 'morning' 
          ? (busData['morning_stops'] as List?) ?? []
          : (busData['afternoon_stops'] as List?) ?? [];

      // Find the stop by name
      final stop = stops.firstWhere(
        (s) => (s as Map)['stop_name'] == stopName,
        orElse: () => null,
      );

      if (stop == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stop not found')),
        );
        return;
      }

      final stopId = (stop as Map)['stop_id']?.toString();
      if (stopId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stop ID not found')),
        );
        return;
      }

      // Load students for this stop
      final studentsResponse = await apiService.get('${Endpoints.busStops}$stopId/students/');
      final students = studentsResponse.success 
          ? ((studentsResponse.data as List?) ?? [])
          : <dynamic>[];

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => StudentListDialog(
            stopId: stopId,
            stopName: stopName,
            routeType: routeType,
            busId: busId,
            initialStudents: students,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading students: $e')),
        );
      }
    }
  }

  Future<void> _editBus(Bus bus) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => UnifiedBusFormDialog(
        bus: bus,
        onSave: () {
          _loadBuses();
        },
      ),
    );
    
    // Show success popup and refresh list after dialog closes
    if (result == true && mounted) {
      _loadBuses();
      // Show success popup dialog
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 10),
              Text('Success'),
            ],
          ),
          content: const Text('Updated Successfully'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _manageStudents(Bus bus) async {
    showDialog(
      context: context,
      builder: (context) => _StudentManagementDialog(
        bus: bus,
        apiService: _apiService,
        onRefresh: () => _loadBuses(),
      ),
    );
  }

  void _deleteBus(Bus bus) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Delete ${bus.busNumber}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await _apiService.initialize();
                  final response = await _apiService.delete('${Endpoints.buses}${bus.id}/');
                  
                  if (response.success) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Bus deleted successfully!')),
                      );
                      _loadBuses(); // Refresh the list
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error deleting bus: ${response.error ?? "Unknown error"}')),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting bus: ${e.toString()}')),
                    );
                  }
                }
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addBus() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => UnifiedBusFormDialog(
        bus: null,
        onSave: () {
          _loadBuses();
        },
      ),
    );
    
    // Show success popup and refresh list after dialog closes
    if (result == true && mounted) {
      _loadBuses();
      // Show success popup dialog
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 10),
              Text('Success'),
            ],
          ),
          content: const Text('New bus added Successfully'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
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
                    activeRoute: '/buses',
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
                          const Text('🚌', style: TextStyle(fontSize: 32)),
                          const SizedBox(width: 15),
                          Text(
                            'Buses Management',
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
                        'Manage bus routes, drivers, students, and transportation schedules',
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
                   Expanded(child: SchoolProfileHeader(apiService: _apiService, isMobile: true)),
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
                    label: 'Total Buses',
                    value: '$_totalBuses',
                    icon: '🚌',
                    color: const Color(0xFF667EEA),
                  ),
                  _StatCard(
                    label: 'Active Buses',
                    value: '$_activeBuses',
                    icon: '✅',
                    color: Colors.green,
                  ),
                  _StatCard(
                    label: 'Students Transported',
                    value: '$_totalStudents',
                    icon: '👥',
                    color: Colors.orange,
                  ),
                  _StatCard(
                    label: 'Bus Routes',
                    value: '$_totalRoutes',
                    icon: '🛣️',
                    color: Colors.blue,
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
                      onChanged: _filterBuses,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Search buses by number, driver, or route...',
                        prefixIcon: Icon(Icons.search),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: isMobile ? 0 : 20,
                  height: isMobile ? 15 : 0,
                ),
                if (_canEdit)
                  InkWell(
                    onTap: _addBus,
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
                            color: const Color(0xFF51CF66).withValues(alpha: 0.25),
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
                            'Add New Bus',
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
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_errorMessage != null)
            GlassContainer(
              padding: const EdgeInsets.all(30),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loadBuses,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (_visibleBuses.isEmpty)
            GlassContainer(
              padding: const EdgeInsets.all(30),
              child: Column(
                children: [
                  const Icon(Icons.directions_bus_outlined, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No buses found',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _addBus,
                    child: const Text('Add First Bus'),
                  ),
                ],
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final spacing = 20.0;
                final cardWidth = (constraints.maxWidth - spacing) / 2;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: _visibleBuses.map((bus) {
                    return SizedBox(
                      width: cardWidth,
                      child: _buildBusCard(bus),
                    );
                  }).toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBusCard(Bus bus) {
    return _BusCardWithHover(
      bus: bus,
      onView: () => _viewBus(bus),
      onEdit: () => _editBus(bus),
      onDelete: () => _deleteBus(bus),
    );
  }

  Widget _buildUserInfo() {
    return SchoolProfileHeader(apiService: _apiService);
  }

  Widget _buildBackButton() {
    return InkWell(
      onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => DashboardPage())),
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
            Icon(Icons.arrow_back, color: Colors.white, size: 16),
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
}

class _BusCardWithHover extends StatefulWidget {
  final Bus bus;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BusCardWithHover({
    required this.bus,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_BusCardWithHover> createState() => _BusCardWithHoverState();
}

class _BusCardWithHoverState extends State<_BusCardWithHover> {
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
        transform: Matrix4.identity()
          ..translate(0.0, _isHovered ? -8.0 : 0.0),
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
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        '🚌',
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.bus.busNumber,
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
                          '${widget.bus.route} • Driver: ${widget.bus.driverName}',
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
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = (constraints.maxWidth - 10) / 2;
                  final itemHeight = 70.0;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      SizedBox(
                        width: itemWidth,
                        height: itemHeight,
                        child: _DetailItem(
                          title: 'Students',
                          value: '${widget.bus.students}/${widget.bus.capacity}',
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        height: itemHeight,
                        child: _DetailItem(
                          title: 'Stops',
                          value: '${widget.bus.stops}',
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        height: itemHeight,
                        child: _DetailItem(
                          title: 'Driver',
                          value: widget.bus.driverName,
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        height: itemHeight,
                        child: _DetailItem(
                          title: 'Status',
                          value: widget.bus.status,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Text('🛣️', style: TextStyle(fontSize: 14)),
                        SizedBox(width: 8),
                        Text(
                          'Route Stops',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...widget.bus.routeStops.take(3).map(
                          (stop) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              stop.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        if (widget.bus.routeStops.length > 3)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '+${widget.bus.routeStops.length - 3} more',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _GradientButton(
                      label: 'View Details',
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
      width: double.infinity,
      height: double.infinity,
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
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
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

  const _DetailCard({
    required this.title,
    required this.items,
  });

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
                maxLines: 2,
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


// Student Management Dialog
class _StudentManagementDialog extends StatefulWidget {
  final Bus bus;
  final ApiService apiService;
  final VoidCallback onRefresh;

  const _StudentManagementDialog({required this.bus, required this.apiService, required this.onRefresh});

  @override
  State<_StudentManagementDialog> createState() => _StudentManagementDialogState();
}

class _StudentManagementDialogState extends State<_StudentManagementDialog> {
  List<Map<String, dynamic>> _morningStops = [];
  List<Map<String, dynamic>> _afternoonStops = [];
  bool _isLoading = true;
  String? _selectedRouteType = 'morning';
  String? _selectedStopId;

  @override
  void initState() {
    super.initState();
    _loadStops();
  }

  Future<void> _loadStops() async {
    setState(() { _isLoading = true; });
    try {
      await widget.apiService.initialize();
      final response = await widget.apiService.get('${Endpoints.buses}${widget.bus.id}/');
      if (response.success && response.data is Map) {
        final busData = response.data as Map<String, dynamic>;
        setState(() {
          _morningStops = (busData['morning_stops'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          _afternoonStops = (busData['afternoon_stops'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          _isLoading = false;
        });
      } else {
        setState(() { _isLoading = false; });
      }
    } catch (e) {
      setState(() { _isLoading = false; });
      // Error is handled by the UI state - no need for SnackBar in dialog context
    }
  }

  @override
  Widget build(BuildContext context) {
    final stops = _selectedRouteType == 'morning' ? _morningStops : _afternoonStops;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Manage Students - ${widget.bus.busNumber}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'morning', label: Text('Morning Route'), icon: Icon(Icons.wb_sunny)),
                      ButtonSegment(value: 'afternoon', label: Text('Afternoon Route'), icon: Icon(Icons.nightlight)),
                    ],
                    selected: {_selectedRouteType!},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _selectedRouteType = newSelection.first;
                        _selectedStopId = null;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (stops.isNotEmpty)
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Select Stop', border: OutlineInputBorder()),
                initialValue: _selectedStopId,
                items: stops.map((stop) {
                  final stopId = stop['stop_id']?.toString() ?? '';
                  final stopName = stop['stop_name'] ?? 'Unknown';
                  return DropdownMenuItem(value: stopId, child: Text(stopName));
                }).toList(),
                onChanged: (value) { setState(() { _selectedStopId = value; }); },
              ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _selectedStopId == null
                      ? const Center(child: Text('Please select a stop to manage students'))
                      : _StudentListForStop(
                          stopId: _selectedStopId!,
                          stopName: stops.firstWhere((s) => (s['stop_id']?.toString() ?? '') == _selectedStopId, orElse: () => {'stop_name': 'Unknown'})['stop_name'] ?? 'Unknown',
                          routeType: _selectedRouteType!,
                          busId: widget.bus.id,
                          apiService: widget.apiService,
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentListForStop extends StatefulWidget {
  final String stopId; final String stopName; final String routeType; final String busId; final ApiService apiService;
  const _StudentListForStop({required this.stopId, required this.stopName, required this.routeType, required this.busId, required this.apiService});
  @override
  State<_StudentListForStop> createState() => _StudentListForStopState();
}

class _StudentListForStopState extends State<_StudentListForStop> {
  List<Map<String, dynamic>> _students = []; 
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() { 
    super.initState(); 
    _loadStudents(); 
  }
  
  @override
  void didUpdateWidget(_StudentListForStop oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload students if stopId changed
    if (oldWidget.stopId != widget.stopId) {
      _loadStudents();
    }
  }
  
  Future<void> _loadStudents() async {
    if (widget.stopId.isEmpty) {
      setState(() { 
        _isLoading = false; 
        _errorMessage = 'Invalid stop ID';
      });
      return;
    }
    
    setState(() { 
      _isLoading = true; 
      _errorMessage = null;
    });
    
    try {
      await widget.apiService.initialize();
      final url = '${Endpoints.busStops}${widget.stopId}/students/';
      final response = await widget.apiService.get(url);
      
      if (response.success) {
        if (response.data is List) {
          setState(() { 
            _students = (response.data as List).cast<Map<String, dynamic>>(); 
            _isLoading = false; 
          });
        } else {
          setState(() { 
            _isLoading = false; 
            _errorMessage = 'Unexpected response format';
            _students = [];
          });
        }
      } else {
        setState(() { 
          _isLoading = false; 
          _errorMessage = response.error ?? 'Failed to load students';
          _students = [];
        });
      }
    } catch (e) { 
      setState(() { 
        _isLoading = false; 
        _errorMessage = 'Error: $e';
        _students = [];
      });
    }
  }
  Future<void> _addStudent() async {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => StudentListDialog(
          stopId: widget.stopId, stopName: widget.stopName, routeType: widget.routeType, busId: widget.busId, initialStudents: _students,
        ),
      ).then((_) => _loadStudents());
    }
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Students at ${widget.stopName}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              onPressed: _addStudent,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Student'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF51CF66), foregroundColor: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadStudents,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _students.isEmpty
                      ? const Center(child: Text('No students assigned to this stop'))
                      : ListView.builder(
                          shrinkWrap: false,
                          itemCount: _students.length,
                          itemBuilder: (context, index) {
                            final student = _students[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(child: Text((student['student_name'] ?? '?')[0].toUpperCase())),
                                title: Text(student['student_name'] ?? 'Unknown'),
                                subtitle: Text('ID: ${student['student_id_string'] ?? 'N/A'} • Class: ${student['student_class'] ?? 'N/A'}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    try {
                                      await widget.apiService.initialize();
                                      final response = await widget.apiService.delete('${Endpoints.busStopStudents}${student['id']}/');
                                      if (response.success) {
                                        _loadStudents();
                                        // Student list will refresh automatically - no need for SnackBar in dialog
                                      } else {
                                        // Show error in the UI if needed
                                        if (mounted) {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Error'),
                                              content: Text(response.error ?? 'Failed to remove student'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: const Text('OK'),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Error'),
                                            content: Text('Error removing student: $e'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('OK'),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }
}

