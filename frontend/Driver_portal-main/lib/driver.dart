import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';
import 'student_details_view.dart';

// --- DATA MODELS (API-backed) ---

enum AttendanceStatus { present, absent, unknown }

class Student {
  final int id;
  final String name;
  final String avatarUrl;
  AttendanceStatus status;
  final String? studentId;
  final String? busStopStudentId; // uuid for save-attendance API
  final String? motherName;
  final String? fatherName;
  final String? contact;
  final String? classSection;
  final String? pickupTime;
  final String? dropoffTime;

  Student({
    required this.id,
    required this.name,
    required this.avatarUrl,
    this.status = AttendanceStatus.unknown,
    this.studentId,
    this.busStopStudentId,
    this.motherName,
    this.fatherName,
    this.contact,
    this.classSection,
    this.pickupTime,
    this.dropoffTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
      'status': status.toString().split('.').last,
      'studentId': studentId,
      'busStopStudentId': busStopStudentId,
      'motherName': motherName,
      'fatherName': fatherName,
      'contact': contact,
      'classSection': classSection,
      'pickupTime': pickupTime,
      'dropoffTime': dropoffTime,
    };
  }

  static Student fromJson(Map<String, dynamic> json) {
    AttendanceStatus status = AttendanceStatus.unknown;
    final statusStr = (json['status'] ?? '').toString();
    if (statusStr == 'present') status = AttendanceStatus.present;
    if (statusStr == 'absent') status = AttendanceStatus.absent;
    final id = json['id'];
    return Student(
      id: id is int ? id : (id is String ? id.hashCode : 0),
      name: (json['name'] ?? json['student_name'] ?? '') as String,
      avatarUrl: (json['avatarUrl'] ?? '') as String,
      status: status,
      studentId: json['studentId'] as String? ?? json['student_id_string'] as String?,
      busStopStudentId: json['busStopStudentId'] as String? ?? json['id']?.toString(),
      motherName: json['motherName'] as String?,
      fatherName: json['fatherName'] as String?,
      contact: json['contact'] as String?,
      classSection: (json['classSection'] ?? json['student_class'] ?? '') as String?,
      pickupTime: json['pickupTime'] as String?,
      dropoffTime: json['dropoffTime'] as String?,
    );
  }

  /// From API driver/stops/ student object (id = bus_stop_student uuid for save-attendance; attendance_status from DB)
  static Student fromApiStudent(Map<String, dynamic> json, int index) {
    final cls = json['student_class'] as String? ?? '';
    final sec = json['student_section'] as String? ?? '';
    final classSection = sec.isEmpty ? cls : '$cls - $sec';
    final parentName = (json['parent_name'] ?? '') as String;
    final parentPhone = (json['parent_phone'] ?? '') as String;
    final emergencyContact = (json['emergency_contact'] ?? '') as String;
    final contact = parentPhone.isNotEmpty ? parentPhone : emergencyContact;
    final pickup = json['pickup_time']?.toString();
    final dropoff = json['dropoff_time']?.toString();
    final studentIdStr = (json['student_id_string'] ?? '') as String;
    AttendanceStatus status = AttendanceStatus.unknown;
    final attStr = (json['attendance_status'] ?? '').toString().toLowerCase();
    if (attStr == 'present') status = AttendanceStatus.present;
    if (attStr == 'absent') status = AttendanceStatus.absent;
    final busStopStudentId = json['id']?.toString();
    return Student(
      id: index,
      name: (json['student_name'] ?? '') as String,
      avatarUrl: '',
      status: status,
      studentId: studentIdStr.isNotEmpty ? studentIdStr : null,
      busStopStudentId: busStopStudentId != null && busStopStudentId.isNotEmpty ? busStopStudentId : null,
      motherName: parentName.isNotEmpty ? parentName : null,
      fatherName: null,
      contact: contact.isNotEmpty ? contact : null,
      classSection: classSection.isEmpty ? null : classSection,
      pickupTime: pickup != null && pickup.isNotEmpty ? pickup : null,
      dropoffTime: dropoff != null && dropoff.isNotEmpty ? dropoff : null,
    );
  }
}

class BusStop {
  final int id;
  final String? stopId;
  String name;
  String address;
  final List<Student> students;
  String notes;

  int get studentsCount => students.length;

  BusStop({
    required this.id,
    this.stopId,
    required this.name,
    this.address = '',
    required this.students,
    this.notes = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stopId': stopId,
      'name': name,
      'address': address,
      'notes': notes,
      'students': students.map((s) => s.toJson()).toList(),
    };
  }

  static BusStop fromJson(Map<String, dynamic> json) {
    final studentsJson = (json['students'] as List?) ?? [];
    final students = studentsJson
        .asMap()
        .entries
        .map((e) => Student.fromJson(Map<String, dynamic>.from(e.value)))
        .toList();
    final id = json['id'];
    return BusStop(
      id: id is int ? id : 0,
      stopId: json['stop_id'] as String? ?? json['stopId'] as String?,
      name: (json['name'] ?? json['stop_name'] ?? '') as String,
      address: (json['address'] ?? json['stop_address'] ?? '') as String,
      students: students,
      notes: (json['notes'] ?? '') as String,
    );
  }

  /// From API driver/stops/ stop object (address from DB stop_address)
  static BusStop fromApiStop(Map<String, dynamic> json, int index) {
    final studentsJson = (json['students'] as List?) ?? [];
    final students = studentsJson
        .asMap()
        .entries
        .map((e) => Student.fromApiStudent(Map<String, dynamic>.from(e.value), e.key))
        .toList();
    return BusStop(
      id: index,
      stopId: json['stop_id'] as String?,
      name: (json['stop_name'] ?? '') as String,
      address: (json['stop_address'] ?? '') as String,
      students: students,
      notes: (json['notes'] ?? '') as String,
    );
  }

  BusStop copyWith({String? name, String? address, String? notes, List<Student>? students}) {
    return BusStop(
      id: id,
      stopId: stopId,
      name: name ?? this.name,
      address: address ?? this.address,
      students: students ?? this.students,
      notes: notes ?? this.notes,
    );
  }
}

// Route info from API (assigned bus)
class RouteInfo {
  final String busNumber;
  final String routeName;
  final String startLocation;
  final String endLocation;
  final String driverFirstName;

  RouteInfo({
    this.busNumber = '',
    this.routeName = '',
    this.startLocation = '',
    this.endLocation = '',
    this.driverFirstName = '',
  });
}

// --- 1. DRIVER PORTAL SCREEN (API-backed) ---

class DriverPortalScreen extends StatefulWidget {
  const DriverPortalScreen({super.key});

  @override
  State<DriverPortalScreen> createState() => _DriverPortalScreenState();
}

class _DriverPortalScreenState extends State<DriverPortalScreen> {
  static const String _baseUrlKey = 'API_BASE_URL';
  static const String _defaultBaseUrl = 'http://10.0.2.2:8000';

  List<BusStop> stops = [];
  RouteInfo routeInfo = RouteInfo();
  bool _loading = true;
  String? _error;

  String get _baseUrl =>
      const String.fromEnvironment(_baseUrlKey, defaultValue: _defaultBaseUrl);

  @override
  void initState() {
    super.initState();
    _loadFromApi();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _loadFromApi() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Not logged in';
        stops = [];
      });
      return;
    }
    try {
      final routeRes = await http.get(
        Uri.parse('$_baseUrl/api/driver/route/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (routeRes.statusCode == 403) {
        setState(() {
          _loading = false;
          _error = 'No bus assigned. Contact admin.';
          stops = [];
        });
        return;
      }
      if (routeRes.statusCode != 200) {
        setState(() {
          _loading = false;
          _error = 'Failed to load route';
          stops = [];
        });
        return;
      }
      final routeData = jsonDecode(routeRes.body) as Map<String, dynamic>;
      // Driver name from buses table driver_name column (API returns driver_name / driver_first_name)
      final driverName = (routeData['driver_name'] ?? routeData['driver_first_name'] ?? '') as String;
      final info = RouteInfo(
        busNumber: (routeData['bus_number'] ?? '') as String,
        routeName: (routeData['route_name'] ?? '') as String,
        startLocation: (routeData['start_location'] ?? '') as String,
        endLocation: (routeData['end_location'] ?? '') as String,
        driverFirstName: driverName.trim().isEmpty ? '' : driverName.trim(),
      );

      final stopsRes = await http.get(
        Uri.parse('$_baseUrl/api/driver/stops/?route_type=morning'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (stopsRes.statusCode != 200) {
        setState(() {
          _loading = false;
          routeInfo = info;
          stops = [];
          _error = 'Failed to load stops';
        });
        return;
      }
      final stopsData = jsonDecode(stopsRes.body) as Map<String, dynamic>;
      final stopsList = (stopsData['stops'] as List?) ?? [];
      final list = stopsList
          .asMap()
          .entries
          .map((e) => BusStop.fromApiStop(
              Map<String, dynamic>.from(e.value), e.key))
          .toList();
      setState(() {
        _loading = false;
        routeInfo = info;
        stops = list;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Error: ${e.toString()}';
        stops = [];
      });
    }
  }

  Future<void> _saveStops(List<BusStop> updatedStops) async {
    final token = await _getToken();
    if (token == null) return;
    for (final stop in updatedStops) {
      if (stop.stopId == null) continue;
      try {
        await http.patch(
          Uri.parse('$_baseUrl/api/driver/stops/${stop.stopId}/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'notes': stop.notes}),
        );
      } catch (_) {}
    }
    setState(() {
      stops = updatedStops;
    });
  }

  Future<void> _saveAttendance(String stopId, List<Map<String, String>> attendance) async {
    final token = await _getToken();
    if (token == null) return;
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/driver/stops/$stopId/attendance/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'date': dateStr, 'attendance': attendance}),
      );
      if (mounted && res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance saved.'), duration: Duration(seconds: 2)),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save attendance.'), backgroundColor: Colors.red),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save attendance.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showStartRideConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start Ride'),
        content: const Text('Are you sure you want to start the ride?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _rideStart();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Start Ride'),
          ),
        ],
      ),
    );
  }

  Future<void> _rideStart() async {
    final token = await _getToken();
    if (token == null) return;
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/driver/ride/start/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (mounted && res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride started!'), duration: Duration(seconds: 1)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start ride'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showEndRideConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Ride'),
        content: const Text('Are you sure you want to end the ride?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _rideEnd();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('End Ride'),
          ),
        ],
      ),
    );
  }

  Future<void> _rideEnd() async {
    final token = await _getToken();
    if (token == null) return;
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/driver/ride/end/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (mounted && res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride ended!'), duration: Duration(seconds: 1)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to end ride'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showLogoutConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('token');
              await prefs.remove('user');
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const DriverLoginScreen()),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(title: const Text('Driver Portal'), backgroundColor: Colors.indigo),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(title: const Text('Driver Portal'), backgroundColor: Colors.indigo),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _loadFromApi, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }
    final routeTitle = routeInfo.routeName.isNotEmpty
        ? routeInfo.routeName
        : (routeInfo.busNumber.isNotEmpty ? 'Bus ${routeInfo.busNumber}' : 'Assigned Route');
    final routeSubtitle = routeInfo.startLocation.isNotEmpty || routeInfo.endLocation.isNotEmpty
        ? '${routeInfo.startLocation} - ${routeInfo.endLocation}'
        : 'Tap for details';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Driver Portal'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Sign out',
            onPressed: _showLogoutConfirm,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // START RIDE and END RIDE buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _showStartRideConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('START RIDE', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _showEndRideConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('END RIDE', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
              child: Text(routeTitle, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AssignedRouteDetailsScreen(stops: stops, routeInfo: routeInfo),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 8)],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.alt_route, color: Colors.blue, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(routeSubtitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Student Tracking heading
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18),
              child: Text('Student Tracking', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
            ),

            // Student Tracking Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentTrackingDetailsScreen(
                      stops: stops,
                      onStopsUpdated: (updatedStops) async {
                        setState(() {
                          stops = updatedStops;
                        });
                        await _saveStops(updatedStops);
                      },
                      onSaveAttendance: _saveAttendance,
                    ),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 8)],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.directions_bus, color: Colors.blue, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text('${stops.length} Stops', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Location Tracking heading
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18),
              child: Text('Location Tracking', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
            ),

            // Location card with map thumbnail and ETA button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LocationTrackingDetailsScreen()),
                ),
                child: Container(
                  height: 260,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 8)],
                  ),
                  child: Stack(
                    children: [
                      // placeholder map area
                      Positioned.fill(
                        child: Container(
                          margin: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(child: Icon(Icons.map, size: 48, color: Colors.blueGrey)),
                        ),
                      ),
                      // ETA button overlay
                      Positioned(
                        right: 22,
                        bottom: 18,
                        child: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ETA: 15 minutes')));
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          child: const Text('ETA', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  
}







// Bus Location Model
class BusLocation {
  final String busId;
  final double latitude;
  final double longitude;
  final int speed;
  final DateTime lastUpdated;
  final String status;

  BusLocation({
    required this.busId,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.lastUpdated,
    required this.status,
  });
}

// --- ASSIGNED ROUTE DETAILS SCREEN ---

class AssignedRouteDetailsScreen extends StatelessWidget {
  final List<BusStop> stops;
  final RouteInfo routeInfo;

  const AssignedRouteDetailsScreen({super.key, required this.stops, required this.routeInfo});

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.indigo, size: 24),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(routeInfo.routeName.isNotEmpty ? '${routeInfo.routeName} - Details' : 'Route Details'),
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Route Summary',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
              const Divider(height: 24),
              _buildDetailRow(Icons.route, 'Route Name', routeInfo.routeName.isNotEmpty ? routeInfo.routeName : '${routeInfo.startLocation} - ${routeInfo.endLocation}'),
              _buildDetailRow(Icons.directions_bus, 'Bus Number', routeInfo.busNumber.isNotEmpty ? routeInfo.busNumber : '-'),
              _buildDetailRow(Icons.person, 'Driver', routeInfo.driverFirstName.isNotEmpty ? routeInfo.driverFirstName : '-'),
              _buildDetailRow(Icons.person_outline, 'Total Students', '${stops.fold<int>(0, (p, s) => p + s.studentsCount)}'),
              _buildDetailRow(Icons.stop, 'Total Stops', '${stops.length}'),
            ],
          ),
        ),
      ),
    );
  }
}

// --- STUDENT TRACKING DETAILS SCREEN ---

class StudentTrackingDetailsScreen extends StatefulWidget {
  final List<BusStop> stops;
  final Function(List<BusStop>) onStopsUpdated;
  final Future<void> Function(String stopId, List<Map<String, String>> attendance)? onSaveAttendance;

  const StudentTrackingDetailsScreen({
    super.key,
    required this.stops,
    required this.onStopsUpdated,
    this.onSaveAttendance,
  });

  @override
  State<StudentTrackingDetailsScreen> createState() => _StudentTrackingDetailsScreenState();
}

class _StudentTrackingDetailsScreenState extends State<StudentTrackingDetailsScreen> {
  late List<BusStop> stops;

  @override
  void initState() {
    super.initState();
    stops = List.from(widget.stops);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('Student Tracking (${stops.length} Stops)'),
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: stops.length,
              itemBuilder: (context, index) {
                return _StopListItem(
                  busStop: stops[index],
                  onBusStopChanged: () {
                    widget.onStopsUpdated(stops);
                  },
                  onSaveAttendance: widget.onSaveAttendance,
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// --- LOCATION TRACKING DETAILS SCREEN ---

class LocationTrackingDetailsScreen extends StatelessWidget {
  const LocationTrackingDetailsScreen({super.key});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Location Tracking'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.schedule),
            tooltip: 'ETA: 15 minutes',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ETA: 15 minutes'), duration: Duration(seconds: 2)),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.all(12),
              child: Stack(
                children: [
                  Container(
                    height: 400,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.map, size: 100, color: Colors.indigo.shade200),
                          const SizedBox(height: 12),
                          const Text('Map View', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 4),
                          const Text('(Google Maps Integration)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 4)],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.fullscreen, color: Colors.indigo),
                        tooltip: 'Full Screen',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const FullScreenMapViewScreen()),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}



class _StopListItem extends StatelessWidget {
  final BusStop busStop;
  final VoidCallback? onBusStopChanged;
  final Future<void> Function(String stopId, List<Map<String, String>> attendance)? onSaveAttendance;

  const _StopListItem({
    required this.busStop,
    this.onBusStopChanged,
    this.onSaveAttendance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.indigo.shade400, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          busStop.name.isNotEmpty
                              ? 'Stop ${busStop.id + 1} (${busStop.name})'
                              : 'Stop ${busStop.id + 1}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      busStop.address.isNotEmpty ? busStop.address : busStop.name,
                      style: const TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Students: ${busStop.studentsCount}',
                      style: const TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 70,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StudentAttendanceScreen(
                          busStop: busStop,
                          onBusStopChanged: onBusStopChanged,
                          onSaveAttendance: onSaveAttendance,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('View', style: TextStyle(color: Colors.white, fontSize: 11)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- 4. STUDENT ATTENDANCE SCREEN ---

class StudentAttendanceScreen extends StatefulWidget {
  final BusStop busStop;
  final VoidCallback? onBusStopChanged;
  final Future<void> Function(String stopId, List<Map<String, String>> attendance)? onSaveAttendance;

  const StudentAttendanceScreen({
    super.key,
    required this.busStop,
    this.onBusStopChanged,
    this.onSaveAttendance,
  });

  @override
  State<StudentAttendanceScreen> createState() => _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  Color _getButtonColor(AttendanceStatus currentStatus, AttendanceStatus buttonType) {
    if (currentStatus == buttonType) {
      return buttonType == AttendanceStatus.present ? Colors.green : Colors.red;
    }
    return Colors.grey.shade300;
  }

  void _toggleAttendance(Student student, AttendanceStatus newStatus) {
    setState(() {
      student.status = newStatus;
    });
  }

  Future<void> _saveAttendance() async {
    if (widget.busStop.stopId == null || widget.onSaveAttendance == null) return;
    final attendance = <Map<String, String>>[];
    for (final student in widget.busStop.students) {
      if (student.busStopStudentId == null || student.busStopStudentId!.isEmpty) continue;
      // Only save students explicitly marked Present or Absent; skip Not marked (day-by-day)
      if (student.status == AttendanceStatus.unknown) continue;
      attendance.add({
        'bus_stop_student_id': student.busStopStudentId!,
        'status': student.status == AttendanceStatus.present ? 'present' : 'absent',
      });
    }
    await widget.onSaveAttendance!(widget.busStop.stopId!, attendance);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('Stop ${widget.busStop.id + 1}${widget.busStop.name.isNotEmpty ? ' (${widget.busStop.name})' : ''} - Attendance'),
        backgroundColor: Colors.indigo,
      ),
      body: Column(
        children: [
          Expanded(
            child: widget.busStop.students.isEmpty
                ? const Center(child: Text('No students at this stop'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: widget.busStop.students.length,
                    itemBuilder: (context, index) {
                      final student = widget.busStop.students[index];
                      return _StudentAttendanceCard(
                        student: student,
                        busStop: widget.busStop,
                        onPresent: () => _toggleAttendance(student, AttendanceStatus.present),
                        onAbsent: () => _toggleAttendance(student, AttendanceStatus.absent),
                        getButtonColor: _getButtonColor,
                      );
                    },
                  ),
          ),
          if (widget.busStop.students.isNotEmpty && widget.onSaveAttendance != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveAttendance,
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text('Save Attendance', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// _StudentAttendanceCard: student details on tap
class _StudentAttendanceCard extends StatelessWidget {
  final Student student;
  final BusStop? busStop;
  final VoidCallback onPresent;
  final VoidCallback onAbsent;
  final Color Function(AttendanceStatus, AttendanceStatus) getButtonColor;

  const _StudentAttendanceCard({
    required this.student,
    this.busStop,
    required this.onPresent,
    required this.onAbsent,
    required this.getButtonColor,
  });

  void _showStudentDetails(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Close button aligned to top-right
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                // Student details content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: StudentDetailsView(student: student, busStop: busStop),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _showStudentDetails(context),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  student.name.isNotEmpty ? student.name[0] : '?',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => _showStudentDetails(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      student.status == AttendanceStatus.present
                          ? 'Present'
                          : student.status == AttendanceStatus.absent
                              ? 'Absent'
                              : 'Not marked',
                      style: TextStyle(
                        fontSize: 12,
                        color: student.status == AttendanceStatus.present
                            ? Colors.green
                            : student.status == AttendanceStatus.absent
                                ? Colors.red
                                : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onPresent,
              style: ElevatedButton.styleFrom(
                backgroundColor: getButtonColor(student.status, AttendanceStatus.present),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('Present', style: TextStyle(color: Colors.white, fontSize: 11)),
            ),
            const SizedBox(width: 6),
            ElevatedButton(
              onPressed: onAbsent,
              style: ElevatedButton.styleFrom(
                backgroundColor: getButtonColor(student.status, AttendanceStatus.absent),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('Absent', style: TextStyle(color: Colors.white, fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }
}

// --- FULL SCREEN MAP VIEW ---

class FullScreenMapViewScreen extends StatelessWidget {
  const FullScreenMapViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map View'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.schedule),
            tooltip: 'ETA: 15 minutes',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ETA: 15 minutes')),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 120, color: Colors.indigo.shade200),
            const SizedBox(height: 20),
            const Text('Full Screen Map View', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text('(Google Maps Integration)', style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}