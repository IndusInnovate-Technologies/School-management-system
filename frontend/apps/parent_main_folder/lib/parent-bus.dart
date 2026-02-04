import 'package:flutter/material.dart';
import 'package:core/api/api_service.dart';
import 'package:core/api/endpoints.dart';

void main() {
  runApp(const BusDetailsApp());
}

// Define the overall application structure and theme
class BusDetailsApp extends StatelessWidget {
  const BusDetailsApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Define primary colors used across the app (matching your HTML gradient)
    const Color primaryBlue = Color(0xFF667eea);
    const Color primaryPurple = Color(0xFF764ba2);

    return MaterialApp(
      title: 'Bus Tracker - School Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBlue,
          primary: primaryBlue,
          secondary: primaryPurple,
          surface: const Color(0xFFF8F9FA), // Light surface background
          onPrimary: Colors.white,
        ),
        useMaterial3: true,
        fontFamily: 'Segoe UI',
      ),
      home: const BusDetailsPage(),
    );
  }
}

// Converted to StatefulWidget to manage alert state
class BusDetailsPage extends StatefulWidget {
  final String? studentId;
  const BusDetailsPage({super.key, this.studentId});

  @override
  State<BusDetailsPage> createState() => _BusDetailsPageState();
}

class _BusDetailsPageState extends State<BusDetailsPage>
    with SingleTickerProviderStateMixin {
  // Mock state for proximity alert setting (in minutes)
  // (Previously unused) proximity threshold can be added here when needed
  late TabController _tabController;

  bool _isLoading = true;
  String? _errorMessage;
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _busData;
  List<Map<String, dynamic>> _morningStops = [];
  List<Map<String, dynamic>> _afternoonStops = [];
  // Weekly bus attendance: list of { date, status }
  DateTime _attendanceWeekStart = DateTime.now();
  List<Map<String, dynamic>> _busAttendanceWeek = [];
  String? _currentStudentId; // resolved when loading bus details (used for attendance)

  Map<String, dynamic>? get firstMorningStop =>
      _morningStops.isNotEmpty ? _morningStops.first : null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBusDetails());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBusDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      await _apiService.initialize();
      
      String? targetStudentId = widget.studentId;
      
      // If studentId not provided, fetch current student profile
      if (targetStudentId == null) {
        final profileResponse = await _apiService.get('/student-parent/student-profile/');
        if (profileResponse.success && profileResponse.data != null) {
          final profileData = profileResponse.data as Map<String, dynamic>;
          targetStudentId = profileData['student_id']?.toString() ?? profileData['id']?.toString();
        }
      }

      if (targetStudentId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Could not identify student. Please login again.';
        });
        return;
      }
      
      debugPrint('Loading bus details for student: $targetStudentId');

      // Use student-parent bus-details endpoint (returns data for this student when assigned to a bus)
      final response = await _apiService.get(
        Endpoints.studentParentBusDetails,
        queryParameters: targetStudentId.isNotEmpty ? {'student_id': targetStudentId} : null,
      );

      if (response.success && response.data != null) {
        // Handle response: { results: [...] }
        List assignments;
        if (response.data is Map) {
          final dataMap = response.data as Map<String, dynamic>;
          assignments = dataMap['results'] as List? ?? [];
        } else if (response.data is List) {
          assignments = response.data as List;
        } else {
          throw Exception('Unexpected response format');
        }

        // Results are already filtered by student on the backend; optionally match by id
        final filteredAssignments = assignments.where((a) {
          final assignment = a as Map<String, dynamic>;
          final sid = assignment['student_id_string']?.toString() ??
              assignment['student_id']?.toString();
          String? nestedSid;
          if (assignment['student'] is Map) {
            nestedSid = assignment['student']['student_id']?.toString() ??
                assignment['student']['id']?.toString();
          } else if (assignment['student'] is String) {
            nestedSid = assignment['student'];
          }
          return sid == targetStudentId || nestedSid == targetStudentId;
        }).toList();

        if (filteredAssignments.isEmpty) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Bus is not added [Not assigned].';
          });
          return;
        }

        // Get the first assignment - it now includes bus_details and stop_details
        final firstAssignment = filteredAssignments.first as Map<String, dynamic>;
        final busDetails = firstAssignment['bus_details'] as Map<String, dynamic>?;
        
        if (busDetails == null) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Bus is not added [Not assigned].';
          });
          return;
        }

        // Group assignments by route type to separate morning and afternoon stops
        final morningStops = <Map<String, dynamic>>[];
        final afternoonStops = <Map<String, dynamic>>[];
        
        for (var assignment in filteredAssignments) {
          final assignmentMap = assignment as Map<String, dynamic>;
          final stopDetails = assignmentMap['stop_details'] as Map<String, dynamic>?;
          
          if (stopDetails != null) {
            final routeType = stopDetails['route_type']?.toString() ?? '';
            
            if (routeType == 'morning') {
              morningStops.add(stopDetails);
            } else if (routeType == 'afternoon') {
              afternoonStops.add(stopDetails);
            }
          }
        }
        
        // Sort stops by stop_order
        morningStops.sort((a, b) => (a['stop_order'] ?? 0).compareTo(b['stop_order'] ?? 0));
        afternoonStops.sort((a, b) => (a['stop_order'] ?? 0).compareTo(b['stop_order'] ?? 0));
        
        setState(() {
          _busData = busDetails;
          _morningStops = morningStops;
          _afternoonStops = afternoonStops;
          _currentStudentId = targetStudentId;
          _isLoading = false;
        });
        _loadBusAttendanceWeek();
        
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load bus details. Please try again later.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading bus details: ${e.toString()}';
      });
    }
  }

  /// Monday of the week for [date].
  static DateTime _mondayOfWeek(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  Future<void> _loadBusAttendanceWeek() async {
    final studentId = _currentStudentId ?? widget.studentId;
    if (studentId == null || studentId.isEmpty) return;
    final monday = _mondayOfWeek(_attendanceWeekStart);
    final weekStartStr = '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
    try {
      final response = await _apiService.get(
        Endpoints.studentParentBusAttendance,
        queryParameters: {
          'student_id': studentId,
          'week_start': weekStartStr,
        },
      );
      if (response.success && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        final list = data['attendance'] as List<dynamic>?;
        setState(() {
          _busAttendanceWeek = list != null
              ? list.map((e) => Map<String, dynamic>.from(e as Map)).toList()
              : [];
        });
      }
    } catch (_) {}
  }

  void _previousWeek() {
    setState(() {
      _attendanceWeekStart = _attendanceWeekStart.subtract(const Duration(days: 7));
    });
    _loadBusAttendanceWeek();
  }

  void _nextWeek() {
    setState(() {
      _attendanceWeekStart = _attendanceWeekStart.add(const Duration(days: 7));
    });
    _loadBusAttendanceWeek();
  }

  // Helper method to format time to 12-hour format
  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty || timeStr == 'N/A') return 'N/A';
    try {
      // Split by ':' - handle HH:mm:ss or HH:mm
      final parts = timeStr.split(':');
      if (parts.length < 2) return timeStr;
      
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      
      final period = hour >= 12 ? 'PM' : 'AM';
      int hour12 = hour % 12;
      if (hour12 == 0) hour12 = 12;
      
      final minuteStr = minute.toString().padLeft(2, '0');
      return '$hour12:$minuteStr $period';
    } catch (e) {
      return timeStr;
    }
  }

  // Helper method to filter stops by type (pickup = morning stops, drop = afternoon stops)
  List<Map<String, String>> _filterStops(String type) {
    final isPickup = type == 'pickup' || type == 'morning';
    final stops = isPickup ? _morningStops : _afternoonStops;
    return stops.map((stop) => {
      'name': stop['stop_name']?.toString() ?? 'Unknown',
      'time': _formatTime(stop['stop_time']?.toString()),
      'type': isPickup ? 'pickup' : 'drop',
      'address': stop['address']?.toString() ?? 'No address',
    }).toList();
  }

  // ✅ Header (Refactored to AppBar)
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text(
        "Bus Details",
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: false,
      // Apply the exact gradient from the HTML header
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2), Color(0xFFF093FB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _loadBusDetails,
        ),
      ],
    );
  }

  // Top Stats Grid (4 cards: Bus Number, Route, Driver, Pickup Time)
  Widget _statsGrid(BuildContext context) {
    List<Map<String, dynamic>> stats = [
      {
        "icon": "🚌",
        "value": _busData?['bus_number'] ?? 'N/A',
        "label": "Bus Number",
        "color": Theme.of(context).colorScheme.primary,
      },
      {
        "icon": "🛣️",
        "value": _busData?['route'] ?? 'N/A',
        "label": "Route",
        "color": Theme.of(context).colorScheme.secondary,
      },
      {
        "icon": "👨‍💼",
        "value": _busData?['driver_name'] ?? 'N/A',
        "label": "Driver",
        "color": Colors.orange,
      },
      {
        "icon": "⏰",
        "value": _formatTime(firstMorningStop?['stop_time']?.toString()),
        "label": "Pickup Time",
        "color": Colors.green,
      },
    ];

    return SizedBox(
      height: 120, // Fixed height
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        itemCount: stats.length,
        itemBuilder: (c, i) {
          return Container(
            width: 150, // Fixed width for each card
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: (stats[i]["color"] as Color).withValues(alpha: 0.2),
                  blurRadius: 8,
                ),
              ],
              border: Border(
                top: BorderSide(color: stats[i]["color"] as Color, width: 4),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stats[i]["icon"] as String,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 4),
                Text(
                  stats[i]["value"] as String,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  stats[i]["label"] as String,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ✅ Main Content Section
  Widget _content(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title("🚌 Bus Information & Live Status"),
        _busInfoCard(context),
        const SizedBox(height: 25),

        _title("🛣️ Route Stops"),
        _buildRouteTabs(context),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _title(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xff333333),
        ),
      ),
    );
  }

  Widget _buildBusAttendanceSection(BuildContext context) {
    final monday = _mondayOfWeek(_attendanceWeekStart);
    final sunday = monday.add(const Duration(days: 6));
    final monthNames = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final weekLabel = '${monday.day} ${monthNames[monday.month - 1]} – ${sunday.day} ${monthNames[sunday.month - 1]} ${sunday.year}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_bus, color: Color(0xFF667eea), size: 22),
              const SizedBox(width: 8),
              const Text(
                'Bus attendance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff333333),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Color(0xFF667eea)),
                onPressed: _previousWeek,
                padding: EdgeInsets.zero,
              ),
              Text(
                weekLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xff333333),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Color(0xFF667eea)),
                onPressed: _nextWeek,
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF667eea),
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(7, (i) {
              final dayData = i < _busAttendanceWeek.length
                  ? _busAttendanceWeek[i] as Map<String, dynamic>?
                  : null;
              final dateStr = dayData?['date']?.toString();
              final status = dayData?['status']?.toString();
              DateTime? date;
              if (dateStr != null) {
                try {
                  date = DateTime.parse(dateStr);
                } catch (_) {}
              }
              final isPresent = status == 'present';
              final isAbsent = status == 'absent';
              final now = DateTime.now();
              final isToday = date != null &&
                  date.year == now.year &&
                  date.month == now.month &&
                  date.day == now.day;

              Color bgColor = Colors.grey.shade100;
              Color textColor = Colors.black87;
              // When no attendance: show hyphen (—) in the cell; when present/absent show P/A
              String label = '—';
              if (isPresent) {
                bgColor = const Color(0xFF4CAF50).withValues(alpha: 0.9);
                textColor = Colors.white;
                label = 'P';
              } else if (isAbsent) {
                bgColor = const Color(0xFFEF5350).withValues(alpha: 0.9);
                textColor = Colors.white;
                label = 'A';
              }

              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i < 6 ? 4 : 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        date != null ? date.day.toString() : '—',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(6),
                          border: isToday
                              ? Border.all(color: const Color(0xFF667eea), width: 2)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // Bus Info Box – uses fetched _busData and first stop times
  Widget _busInfoCard(BuildContext context) {
    final busNumber = _busData?['bus_number']?.toString() ?? 'N/A';
    final route = _busData?['route']?.toString() ?? 'N/A';
    final driverName = _busData?['driver_name']?.toString() ?? 'N/A';
    final driverContact = _busData?['driver_contact']?.toString() ?? 'N/A';
    final capacity = _busData?['capacity']?.toString() ?? 'N/A';
    final status = _busData?['status']?.toString() ?? 'Active';
    final pickupTime = _formatTime(firstMorningStop?['stop_time']?.toString());
    final dropTime = _firstDropTime();

    Map<String, String> info = {
      "Route": route,
      "Driver": driverName,
      "Pickup Time": pickupTime != 'N/A' ? pickupTime : '—',
      "Drop Time": dropTime,
      "Contact": driverContact != 'N/A' ? driverContact : '—',
      "Capacity": capacity != 'N/A' ? '$capacity Students' : '—',
    };

    return _box(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Bus number and status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text("🚌", style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    busNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xff333333),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    Icons.directions_bus,
                    size: 16,
                    color: status == 'Active' ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    status == 'Active' ? "In Transit" : status,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: status == 'Active' ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 20),

          // Row 2: First morning stop and pickup time from API
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (firstMorningStop != null)
                Text(
                  "📍 Next Stop: ${firstMorningStop!['stop_name'] ?? '—'}",
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    pickupTime != 'N/A'
                        ? "Estimated Pickup: $pickupTime"
                        : "Pickup time as per route",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20),

          // Row 3: Details from API
          Column(
            children: info.entries.map((e) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      e.key,
                      style: const TextStyle(color: Color(0xFF666666)),
                    ),
                    Text(
                      e.value,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _firstDropTime() {
    if (_afternoonStops.isNotEmpty) {
      final t = _afternoonStops.first['stop_time']?.toString();
      return _formatTime(t);
    }
    return '—';
  }

  // Tabbed Route View Container
  Widget _buildRouteTabs(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tab Bar for Pickup/Drop-off
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TabBar(
              controller: _tabController,
              labelColor: primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorColor: primaryColor,
              tabs: const [
                Tab(icon: Icon(Icons.pin_drop), text: "Pickup Stops"),
                Tab(icon: Icon(Icons.school), text: "Drop-off Stops"),
              ],
            ),
          ),

          // Tab View for the lists
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tabController,
              children: [
                _routeListContent(_filterStops('morning'), true),
                _routeListContent(_filterStops('afternoon'), false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Route List Content (Used inside TabBarView)
  Widget _routeListContent(List<Map<String, String>> stops, bool isPickup) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: stops.length,
      itemBuilder: (context, index) {
        final stop = stops[index];
        Color color = isPickup
            ? const Color(0xFF51cf66)
            : Theme.of(context).colorScheme.secondary;

        return GestureDetector(
          onTap: () => _showStopDetailsModal(context, stop),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border(left: BorderSide(color: color, width: 4)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12.withValues(alpha: 0.05),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      (isPickup ? "⬆️ " : "⬇️ ") + stop["name"]!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        stop["time"]!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Address: ${stop["address"]!}",
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Stop Details Modal
  void _showStopDetailsModal(BuildContext context, Map<String, String> stop) {
    final bool isPickup = stop['type'] == 'pickup';
    final Color accentColor = isPickup
        ? Colors.green
        : Theme.of(context).colorScheme.secondary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${isPickup ? 'Pick-up' : 'Drop-off'} Stop Details",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
              const Divider(height: 25),

              _modalDetailRow("Stop Name:", stop['name']!),
              _modalDetailRow("Scheduled Time:", stop['time']!),
              _modalDetailRow("Stop Type:", stop['type']!.toUpperCase()),
              _modalDetailRow("Address:", stop['address']!),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _msg(context, "Navigating to ${stop['name']}...");
                  },
                  icon: const Icon(Icons.navigation, color: Colors.white),
                  label: const Text(
                    "Get Directions",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper for Modal Info Rows
  Widget _modalDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF666666))),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Reusable Box decorator (Mimics the main-section box style)
  Widget _box(Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  void _msg(BuildContext c, String m) {
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(context),
      body: _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.directions_bus_outlined, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _statsGrid(context),
                  const SizedBox(height: 20),
                  _buildBusAttendanceSection(context),
                  const SizedBox(height: 25),
                  _content(context),
                ],
              ),
            ),
    );
  }
}
