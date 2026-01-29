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
  List<Map<String, dynamic>> _deviationLog = [];

  Map<String, dynamic>? get firstMorningStop =>
      _morningStops.isNotEmpty ? _morningStops.first : null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

      // Get current student's bus assignments - filter by student ID string
      final response = await _apiService.get('${Endpoints.busStopStudents}?search=$targetStudentId');
      
      if (response.success && response.data != null) {
        // Handle paginated response
        List assignments;
        if (response.data is Map) {
          final dataMap = response.data as Map<String, dynamic>;
          assignments = dataMap['results'] as List? ?? [];
        } else if (response.data is List) {
          assignments = response.data as List;
        } else {
          throw Exception('Unexpected response format');
        }
        
        // Filter assignments strictly to match this student name/ID
        // search parameter is good, but let's double check the results
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
            _errorMessage = 'No bus assigned to you yet. Please contact the school office.';
          });
          return;
        }

        // Get the first assignment - it now includes bus_details and stop_details
        final firstAssignment = filteredAssignments.first as Map<String, dynamic>;
        final busDetails = firstAssignment['bus_details'] as Map<String, dynamic>?;
        
        if (busDetails == null) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Bus details not available. Please contact the school office.';
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
          _isLoading = false;
        });
        
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

  // Helper method to filter stops by type
  List<Map<String, String>> _filterStops(String type) {
    final stops = type == 'morning' ? _morningStops : _afternoonStops;
    return stops.map((stop) => {
      'name': stop['stop_name']?.toString() ?? 'Unknown',
      'time': _formatTime(stop['stop_time']?.toString()),
      'type': type,
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

  // ✅ Top Stats Grid
  Widget _statsGrid(BuildContext context) {
    List<Map<String, dynamic>> stats = [
      {
        "icon": "🚌",
        "value": "BUS-001",
        "label": "Bus Number",
        "color": Theme.of(context).colorScheme.primary,
      },
      {
        "icon": "🛣️",
        "value": "Route A",
        "label": "Route",
        "color": Theme.of(context).colorScheme.secondary,
      },
      {
        "icon": "👨‍💼",
        "value": _busData!['driver_name'] ?? 'N/A',
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
        const SizedBox(height: 25),

        _title("⚠️ Deviation Log"),
        _buildDeviationLog(context),
        const SizedBox(height: 25),

        _title("⚡ Quick Actions"),
        _actionButtons(context),
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

  // 🔄 MODIFIED: Bus Info Box (Now includes Live Tracking)
  Widget _busInfoCard(BuildContext context) {
    Map<String, String> info = {
      "Route": "Route A",
      "Driver":
          "John Smith", // Driver info remains in the static list for clarity
      "Pickup Time": "7:30 AM",
      "Drop Time": "3:30 PM",
      "Contact": "+1-555-0123",
      "Capacity": "45 Students",
    };

    return _box(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Bus Status (Simplified to reflect general status)
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text("🚌", style: TextStyle(fontSize: 20)),
                  SizedBox(width: 8),
                  Text(
                    "BUS-001",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xff333333),
                    ),
                  ),
                ],
              ),
              // Simplified Live Status Badge
              Row(
                children: [
                  Icon(Icons.directions_bus, size: 16, color: Colors.green),
                  SizedBox(width: 4),
                  Text(
                    "In Transit",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 20),

          // Row 2: Live Status & ETA
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "📍 Next Stop: Central Park Stop",
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
              ),
              const SizedBox(height: 5),
              Text(
                "⏳ ETA to Destination: 15 minutes",
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
                    "Estimated Arrival: 7:45 AM",
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

          // Row 3: Static Details Grid
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
                _routeListContent(_filterStops('pickup'), true),
                _routeListContent(_filterStops('drop'), false),
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

  // 🆕 NEW FEATURE: Deviation Log List Builder
  Widget _buildDeviationLog(BuildContext context) {
    return _box(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _deviationLog.map((log) {
          final isDeviation = log['delay'] != '0 min';
          final icon = isDeviation ? Icons.warning : Icons.check_circle;
          final color = isDeviation ? Colors.red : Colors.green;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${log['time']} - ${isDeviation ? 'Deviation' : 'On Schedule'}",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        log['reason']!,
                        style: const TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 13,
                        ),
                      ),
                      if (isDeviation)
                        Text(
                          "Delay: ${log['delay']}",
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ✅ Button List (Includes Emergency Alert)
  Widget _actionButtons(BuildContext context) {
    List<Map<String, dynamic>> actions = [
      {
        "text": "📍 Track Bus Live",
        "icon": Icons.location_on,
        "color": Theme.of(context).colorScheme.primary,
        "onTap": () => _msg(context, "Tracking bus..."),
      },
      {
        "text": "📞 Contact Driver",
        "icon": Icons.phone,
        "color": Theme.of(context).colorScheme.secondary,
        "onTap": () => _msg(context, "Calling driver..."),
      },
      {
        "text": "⚠️ Report Issue",
        "icon": Icons.warning,
        "color": Colors.orange,
        "onTap": () => _msg(context, "Reporting issue..."),
      },
      // Red button now links to Full Schedule View
      {
        "text": "📅 View Full Schedule",
        "icon": Icons.schedule,
        "color": Colors.red,
        "onTap": () => _msg(context, "Opening Full Schedule..."),
      },
    ];

    return Column(
      children: actions.map((a) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: a["color"] as Color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 3,
            ),
            onPressed: a["onTap"] as VoidCallback,
            icon: Icon(a["icon"] as IconData, size: 20),
            label: Text(
              a["text"] as String,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        );
      }).toList(),
    );
  }

  // 🆕 NEW FEATURE: Stop Details Modal
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _statsGrid(context),
            const SizedBox(height: 20),
            _content(context),
          ],
        ),
      ),
    );
  }
}
