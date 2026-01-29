import 'package:flutter/material.dart';
import 'dart:math' as math; // Used for random data generation

// -------------------------------------------------------------------------
// 1. UTILITY FUNCTIONS & DATA MODELS
// -------------------------------------------------------------------------

/// Utility function to create a MaterialColor from a single color value.
MaterialColor createMaterialColor(Color color) {
  List<double> strengths = <double>[.05, .1, .2, .3, .4, .5, .6, .7, .8, .9];
  Map<int, Color> swatch = {};
  final int r = color.red, g = color.green, b = color.blue;

  swatch[50] = Color.fromRGBO(r, g, b, 0.05);

  for (int i = 0; i < 9; i++) {
    int key = (i + 1) * 100;
    if (i + 1 < strengths.length) {
      swatch[key] = Color.fromRGBO(r, g, b, strengths[i + 1]);
    } else {
      swatch[key] = Color.fromRGBO(r, g, b, 1.0);
    }
  }

  return MaterialColor(color.value, swatch);
}

class DashboardData {
  // Use const constructor since all fields are final and initialized immediately
  const DashboardData();

  final String userName = 'Parent User';
  final String totalHomework = '3';
  final String upcomingTests = '2';
  final String totalResults = '3';
  final String academicsScore = '85.6%';
  final String extracurricularCount = '5';
  final String feesStatus = 'Paid';
  final Map<String, dynamic> busDetails = const {
    'busNumber': 'BUS-001',
    'route': 'Route A',
    'driver': 'Mr. Smith',
    'pickupTime': '7:30 AM',
    'dropTime': '3:30 PM',
  };
  final List<Map<String, String>> homework = const [
    {
      'title': 'Algebra Chapter 5',
      'status': 'pending',
      'subject': 'Mathematics',
      'dueDate': '2025-11-10',
    },
    {
      'title': 'Photosynthesis Essay',
      'status': 'completed',
      'subject': 'Science',
      'dueDate': '2025-11-08',
    },
  ];
  final List<Map<String, String>> tests = const [
    {
      'subject': 'History Mid-Term',
      'date': '2025-11-15',
      'duration': '90 minutes',
    },
    {'subject': 'Math Quiz', 'date': '2025-11-18', 'duration': '30 minutes'},
  ];
  final List<Map<String, dynamic>> results = const [
    {
      'subject': 'Mathematics',
      'examType': 'Mid-Term',
      'score': 85,
      'grade': 'A',
      'date': '2024-12-01',
      'status': 'completed',
    },
    {
      'subject': 'Science',
      'examType': 'Unit Test',
      'score': 92,
      'grade': 'A+',
      'date': '2024-11-28',
      'status': 'completed',
    },
    {
      'subject': 'English',
      'examType': 'Final Exam',
      'score': 78,
      'grade': 'B+',
      'date': '2024-11-25',
      'status': 'completed',
    },
  ];
}

// -------------------------------------------------------------------------
// 2. MAIN APP SETUP & CONSTANTS
// -------------------------------------------------------------------------

void main() {
  runApp(const SchoolManagementSystemApp());
}

class SchoolManagementSystemApp extends StatelessWidget {
  const SchoolManagementSystemApp({super.key});

  // Sharpened primary color for better contrast
  static const Color primaryPurple = Color(
    0xFF5A67C4,
  ); // Darker than 0xFF667eea
  static const Color lightBackground = Color(0xFFF8F9FA);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Academic Performance Dashboard',
      theme: ThemeData(
        // Using createMaterialColor requires calling the function
        primarySwatch: createMaterialColor(primaryPurple),
        primaryColor: primaryPurple,
        fontFamily: 'Segoe UI',
        useMaterial3: true,
        scaffoldBackgroundColor: lightBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryPurple,
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold, // Bolder title
          ),
        ),
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// -------------------------------------------------------------------------
// 3. HOME SCREEN (STATEFUL WIDGET)
// -------------------------------------------------------------------------

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DashboardData mockData = const DashboardData();
  final math.Random _random = math.Random();

  // Initialize state variables for Calendar
  int currentMonth = DateTime.now().month - 1; // 0-indexed for month names
  int currentYear = DateTime.now().year;

  String _overallScore = '84%';
  String _attendanceRate = '97%';
  String _classRank = '7th';
  String _selectedPeriod = 'Monthly'; // For performance period selection

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
      );
    }
  }

  void _refreshPerformanceStats() {
    setState(() {
      final overallScoreValue =
          (_random.nextDouble() * 30 + 70).toStringAsFixed(1);
      final attendanceRateValue = (_random.nextInt(20) + 80);
      final classRankValue = _random.nextInt(30) + 1;

      _overallScore = '$overallScoreValue%';
      _attendanceRate = '$attendanceRateValue%';
      _classRank = '$classRankValue${_getOrdinalSuffix(classRankValue)}';
    });
    _showSnackBar('Performance data refreshed!');
  }

  String _getOrdinalSuffix(int n) {
    if (n >= 11 && n <= 13) return 'th';
    switch (n % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  // --- Calendar Control Methods ---
  void previousMonth() {
    setState(() {
      currentMonth--;
      if (currentMonth < 0) {
        currentMonth = 11;
        currentYear--;
      }
    });
  }

  void nextMonth() {
    setState(() {
      currentMonth++;
      if (currentMonth > 11) {
        currentMonth = 0;
        currentYear++;
      }
    });
  }

  // --- WIDGET BUILDERS ---

  Widget _buildPerformanceStats() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use responsive sizing based on available width
        final isNarrow = constraints.maxWidth < 600;

        if (isNarrow) {
          // For narrow screens, use scrollable horizontal list
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SizedBox(
                  width: 160,
                  child: _PerformanceStatItem(
                    label: 'Overall Score',
                    value: _overallScore,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 160,
                  child: _PerformanceStatItem(
                    label: 'Attendance',
                    value: _attendanceRate,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 160,
                  child: _PerformanceStatItem(
                    label: 'Class Rank',
                    value: _classRank,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
          );
        } else {
          // For wider screens, use flexible row
          return Row(
            children: [
              Expanded(
                child: _PerformanceStatItem(
                  label: 'Overall Score',
                  value: _overallScore,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PerformanceStatItem(
                  label: 'Attendance',
                  value: _attendanceRate,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PerformanceStatItem(
                  label: 'Class Rank',
                  value: _classRank,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildPerformanceOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        // FIX 1: Corrected 'boxBoxShadow' to 'boxShadow'
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '📊 Student Performance Overview',
                  // Increased font size and contrast for the title
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    // FIX 2: Corrected 'shade90m0' to 'shade900'
                    color: Colors.grey.shade900,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _refreshPerformanceStats,
                icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
                label: const Text(
                  'Refresh',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF28A745),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 25),

          // Grades Chart
          _buildGradesChart(),
          const SizedBox(height: 20),

          // Attendance Chart
          _buildAttendanceChart(),
          const SizedBox(height: 30),

          // Performance Stats Grid
          _buildPerformanceStats(),
        ],
      ),
    );
  }

  Widget _buildGradesChart() {
    // Data for different periods
    Map<String, Map<String, dynamic>> periodData = {
      'Monthly': {
        'labels': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
        'percentages': [93, 94, 86, 90, 89, 86],
      },
      'Quarterly': {
        'labels': ['Q1', 'Q2', 'Q3', 'Q4'],
        'percentages': [91, 89, 92, 88],
      },
      'Half-Yearly': {
        'labels': ['H1 2024', 'H2 2024'],
        'percentages': [90, 90],
      },
      'Annually': {
        'labels': ['2022', '2023', '2024'],
        'percentages': [88, 91, 90],
      },
    };

    final currentData = periodData[_selectedPeriod]!;
    final labels = currentData['labels'] as List<String>;
    final percentages = currentData['percentages'] as List<int>;
    final maxPercentage = 100;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.show_chart,
                      color: Color(0xFF5A67C4),
                      size: 22, // Increased icon size
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '$_selectedPeriod Grades Performance',
                        style: const TextStyle(
                          fontSize: 17, // Increased font size
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF333333),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Period Selector Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Monthly', 'Quarterly', 'Half-Yearly', 'Annually'].map(
                (period) {
                  final isSelected = _selectedPeriod == period;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedPeriod = period;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF5A67C4) // Sharpened color
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          period,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Bar Chart
          // FIX: Increased height from 200 to 220 to prevent overflow in the chart column
          SizedBox(
            height: 220,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(labels.length, (index) {
                final percentage = percentages[index];
                // Base bar height scaled down from the new total height (220 - padding/labels)
                final barHeight = (percentage / maxPercentage) * 160;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Percentage label
                        Text(
                          '$percentage%',
                          style: const TextStyle(
                            fontSize: 14, // Increased size
                            fontWeight: FontWeight.w700, // Increased boldness
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Bar
                        Container(
                          width: double.infinity,
                          height: barHeight,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF5A67C4), Color(0xFF764BA2)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Label
                        Text(
                          labels[index],
                          style: const TextStyle(
                            fontSize: 13, // Increased size
                            color: Color(0xFF666666),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ), // Extra space to prevent overflow
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.bar_chart, color: Color(0xFF5A67C4), size: 14),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Column Chart: Monthly grade percentages showing academic performance',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceChart() {
    // Data for different periods
    Map<String, Map<String, dynamic>> periodData = {
      'Monthly': {
        'labels': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
        'percentages': [85, 89, 93, 90, 93, 90],
      },
      'Quarterly': {
        'labels': ['Q1', 'Q2', 'Q3', 'Q4'],
        'percentages': [89, 91, 92, 90],
      },
      'Half-Yearly': {
        'labels': ['H1 2024', 'H2 2024'],
        'percentages': [90, 91],
      },
      'Annually': {
        'labels': ['2022', '2023', '2024'],
        'percentages': [87, 90, 91],
      },
    };

    final currentData = periodData[_selectedPeriod]!;
    final months = currentData['labels'] as List<String>;
    final percentages = currentData['percentages'] as List<int>;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.insert_chart,
                      color: Color(0xFF4CAF50), // Sharper green
                      size: 22, // Increased icon size
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '$_selectedPeriod Attendance Performance',
                        style: const TextStyle(
                          fontSize: 17, // Increased font size
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF333333),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Period Selector Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Monthly', 'Quarterly', 'Half-Yearly', 'Annually'].map(
                (period) {
                  final isSelected = _selectedPeriod == period;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedPeriod = period;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF4CAF50) // Sharper green
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          period,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Line Chart
          // FIX: Increased height from 180 to 200 for safe rendering of labels
          SizedBox(
            height: 200,
            child: CustomPaint(
              painter: _LineChartPainter(
                months: months,
                percentages: percentages,
              ),
              child: Container(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.show_chart, color: Color(0xFF4CAF50), size: 14),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Line Chart: Monthly attendance percentages showing attendance trends',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCalendar() {
    // Get month name
    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    // Safety check for index
    final monthName = (currentMonth >= 0 && currentMonth < 12)
        ? monthNames[currentMonth]
        : 'Invalid Month';

    // Calculate days in current month
    final daysInMonth = DateTime(currentYear, currentMonth + 2, 0).day;
    final firstDayOfMonth = DateTime(currentYear, currentMonth + 1, 1);
    final firstWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday

    // Mock attendance data (Present days) - will vary by month
    final presentDays = [
      3,
      4,
      5,
      7,
      10,
      11,
      12,
      13,
      14,
      17,
      18,
      19,
      20,
      21,
      24,
      25,
      26,
      27,
      28,
    ];
    final absentDays = [6, 15]; // Red color

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_month,
                      color: Color(0xFF5A67C4),
                      size: 24, // Increased icon size
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Student Calendar',
                        style: TextStyle(
                          fontSize: 20, // Increased font size for title
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade900,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.chevron_left,
                      color: Color(0xFF5A67C4),
                    ),
                    onPressed: previousMonth,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5A67C4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$monthName $currentYear',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14, // Increased font size
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF5A67C4),
                    ),
                    onPressed: nextMonth,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Calendar Grid
          Column(
            children: [
              // Weekday headers
              Row(
                children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map(
                  (day) {
                    return Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700, // Bolder
                            color: Color(0xFF5A67C4), // Primary color
                            fontSize: 15, // Increased size
                          ),
                        ),
                      ),
                    );
                  },
                ).toList(),
              ),
              const SizedBox(height: 10),

              // Calendar days
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemCount: firstWeekday + daysInMonth, // Total cells needed
                itemBuilder: (context, index) {
                  final dayNumber = index - firstWeekday + 1;

                  if (dayNumber < 1 || dayNumber > daysInMonth) {
                    // Empty cell for days outside current month
                    return Container();
                  }

                  final now = DateTime.now();
                  final isPresent = presentDays.contains(dayNumber);
                  final isAbsent = absentDays.contains(dayNumber);
                  final isToday = dayNumber == now.day &&
                      currentMonth == now.month - 1 &&
                      currentYear == now.year;

                  Color bgColor = Colors.grey.shade100; // Default background
                  Color textColor = Colors.black87;
                  String? statusText;

                  if (isPresent) {
                    bgColor = const Color(0xFF4CAF50).withValues(alpha: 0.9);
                    textColor = Colors.white;
                    statusText = 'P';
                  } else if (isAbsent) {
                    bgColor = const Color(0xFFEF5350).withValues(alpha: 0.9);
                    textColor = Colors.white;
                    statusText = 'A';
                  }

                  return InkWell(
                    onTap: () => _showDateDetails(
                      context,
                      dayNumber,
                      isPresent,
                      isAbsent,
                    ),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(6),
                        border: isToday
                            ? Border.all(
                                color: const Color(0xFF5A67C4),
                                width: 3, // Thicker border for Today
                              )
                            : null,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsets.all(
                            4.0,
                          ), // Increased padding
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$dayNumber',
                                style: TextStyle(
                                  fontSize: 16, // Increased font size
                                  fontWeight: FontWeight.w800, // Extra bold
                                  color: textColor,
                                ),
                              ),
                              if (statusText != null) ...[
                                const SizedBox(height: 1),
                                Text(
                                  statusText,
                                  style: TextStyle(
                                    fontSize: 10, // Increased font size
                                    color: textColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 15),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(const Color(0xFF4CAF50), 'Present'),
              const SizedBox(width: 20),
              _buildLegendItem(const Color(0xFFEF5350), 'Absent'),
              const SizedBox(width: 20),
              _buildLegendItem(
                Colors.grey.shade100, // Use the actual default cell color
                'No Record',
                hasBorder: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, {bool hasBorder = false}) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: hasBorder ? Border.all(color: Colors.grey.shade400) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ],
    );
  }

  // Method to show date details dialog
  void _showDateDetails(
    BuildContext context,
    int day,
    bool isPresent,
    bool isAbsent,
  ) {
    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final dateString = '${monthNames[currentMonth]} $day, $currentYear';

    // Mock data for the selected date
    final List<Map<String, dynamic>> dayEvents = day == 17
        ? []
        : [
            // Make one date empty
            {
              'type': 'event',
              'icon': Icons.event,
              'title': 'Science Fair',
              'time': '10:00 AM',
              'color': Colors.blue,
            },
            {
              'type': 'event',
              'icon': Icons.celebration,
              'title': 'Sports Day',
              'time': '2:00 PM',
              'color': Colors.orange,
            },
          ];

    final List<Map<String, dynamic>> dayExams = day == 17
        ? [
            {
              'subject': 'Physics',
              'time': '11:00 AM',
              'duration': '1 hour',
              'type': 'Quiz',
            },
          ]
        : [
            {
              'subject': 'Mathematics',
              'time': '9:00 AM',
              'duration': '2 hours',
              'type': 'Mid-Term',
            },
          ];

    final List<Map<String, dynamic>> dayHomework = day == 17
        ? [
            {
              'subject': 'English',
              'title': 'Essay on Climate Change',
              'status': 'pending',
            },
          ]
        : [
            {
              'subject': 'History',
              'title': 'Chapter 5 Questions',
              'status': 'completed',
            },
          ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateString,
                            style: const TextStyle(
                              fontSize: 22, // Increased size
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5A67C4), // Sharper color
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                isPresent
                                    ? Icons.check_circle
                                    : (isAbsent
                                        ? Icons.cancel
                                        : Icons.help_outline),
                                color: isPresent
                                    ? Colors.green
                                    : (isAbsent ? Colors.red : Colors.grey),
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isPresent
                                    ? 'Present'
                                    : (isAbsent ? 'Absent' : 'No Record'),
                                style: TextStyle(
                                  fontSize: 15, // Increased size
                                  color: isPresent
                                      ? Colors.green
                                      : (isAbsent ? Colors.red : Colors.grey),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Scrollable content
                Flexible(
                  // Use Flexible to allow the column to take space and the SingleChildScrollView to work
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Events Section
                        if (dayEvents.isNotEmpty) ...[
                          _buildDetailSection(
                            '📅 Events',
                            dayEvents
                                .map(
                                  (event) => ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(
                                      event['icon'] as IconData,
                                      color: event['color'] as Color,
                                      size: 20, // Increased size
                                    ),
                                    title: Text(
                                      event['title'] as String,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700, // Bolder
                                        fontSize: 15, // Increased size
                                      ),
                                    ),
                                    subtitle: Text(
                                      event['time'] as String,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Exams Section
                        if (dayExams.isNotEmpty) ...[
                          _buildDetailSection(
                            '📝 Exams',
                            dayExams
                                .map(
                                  (exam) => Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                exam['subject'] as String,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize:
                                                      16, // Increased size
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${exam['type']} • ${exam['time']} • ${exam['duration']}',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey.shade700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Homework Section
                        if (dayHomework.isNotEmpty) ...[
                          _buildDetailSection(
                            '📚 Homework',
                            dayHomework
                                .map(
                                  (hw) => Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                hw['subject'] as String,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Text(
                                                hw['title'] as String,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey.shade700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          hw['status'] == 'completed'
                                              ? Icons.check_circle
                                              : Icons.pending,
                                          color: hw['status'] == 'completed'
                                              ? Colors.green
                                              : Colors.orange,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18, // Increased size
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  // Helper method to build the list of Stat Cards for the left/center section
  Widget _buildStatCardsList() {
    // List of all stats
    final allStats = [
      // Row 1: Profile, Bus, Projects
      _StatCard(
        icon: Icons.person,
        number: 'Profile',
        label: 'Student Profile',
        color: const Color(0xFF5A67C4),
        onTap: () => _showSnackBar("Redirecting to Profile"),
      ),
      _StatCard(
        icon: Icons.directions_bus,
        number: 'Bus',
        label: 'Bus Details',
        color: const Color(0xFF17a2b8),
        onTap: () => _showSnackBar("Redirecting to Bus Details"),
      ),
      _StatCard(
        icon: Icons.science,
        number: 'Projects',
        label: 'Student Projects',
        color: const Color(0xFF6f42c1),
        onTap: () => _showSnackBar("Redirecting to Projects"),
      ),
      // Row 2: Tasks, Tests, Results
      _StatCard(
        icon: Icons.check_circle_outline,
        number: 'Tasks',
        label: 'Daily Tasks',
        color: const Color(0xFF20c997),
        onTap: () => _showSnackBar("Redirecting to Daily Tasks"),
      ),
      _StatCard(
        icon: Icons.assessment,
        number: mockData.upcomingTests,
        label: 'Tests',
        color: const Color(0xFFf093fb),
        onTap: () => _showSnackBar("Redirecting to Tests"),
      ),
      _StatCard(
        icon: Icons.bar_chart,
        number: mockData.totalResults,
        label: 'Results',
        color: const Color(0xFF28a745),
        onTap: () => _showSnackBar("Redirecting to Results"),
      ),
      // Row 3: Homework, Academics, Activities
      _StatCard(
        icon: Icons.assignment,
        number: mockData.totalHomework,
        label: 'Homework',
        color: const Color(0xFF764ba2),
        onTap: () => _showSnackBar("Redirecting to Homework"),
      ),
      _StatCard(
        icon: Icons.school,
        number: mockData.academicsScore,
        label: 'Academics',
        color: const Color(0xFF5A67C4),
        onTap: () => _showSnackBar("Redirecting to Academics"),
      ),
      _StatCard(
        icon: Icons.sports_soccer,
        number: mockData.extracurricularCount,
        label: 'Activities',
        color: const Color(0xFFFFC107),
        onTap: () => _showSnackBar("Redirecting to Activities"),
      ),
      // Row 4: Gallery, Fees, Teacher
      _StatCard(
        icon: Icons.house,
        number: 'Gallery',
        label: 'School Gallery',
        color: const Color(0xFFfd7e14),
        onTap: () => _showSnackBar("Redirecting to Gallery"),
      ),
      _StatCard(
        icon: Icons.payment,
        number: mockData.feesStatus,
        label: 'Fees',
        color: const Color(0xFF20c997),
        onTap: () => _showSnackBar("Redirecting to Fees"),
      ),
      _StatCard(
        icon: Icons.message,
        number: 'Contact',
        label: 'Teacher',
        color: const Color(0xFFe83e8c),
        onTap: () => _showSnackBar("Contacting Teacher"),
      ),
      // Row 5: Calendar
      _StatCard(
        icon: Icons.calendar_month,
        number: 'Calendar',
        label: 'Academic Calendar',
        color: const Color(0xFF6c757d),
        onTap: () => _showSnackBar("Redirecting to Academic Calendar"),
      ),
    ];

    // Arranges cards in 3 columns, flowing one-by-one horizontally.
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: allStats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // Three cards per row
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.0, // Adjust aspect ratio for a wider card look
      ),
      itemBuilder: (context, index) {
        return allStats[index];
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏫 School Management System'),
        actions: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.white24,
                child: Text('👨‍👩‍👧‍👦'),
              ),
              const SizedBox(width: 8),
              Text(
                mockData.userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ), // Bolder username
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () => _showSnackBar('Logged out!'),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dashboard Title Section (Gradient Text simulated with ShaderMask)
            ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  colors: <Color>[
                    SchoolManagementSystemApp.primaryPurple,
                    Color(0xFF764ba2),
                  ],
                  tileMode: TileMode.mirror,
                ).createShader(bounds);
              },
              child: const Text(
                'Parent Dashboard',
                style: TextStyle(
                  fontSize: 34, // Increased size
                  fontWeight: FontWeight.w800, // Extra bold
                  color: Colors.white, // Color is overridden by the shader
                ),
              ),
            ),
            const Text(
              'Student progress and information',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 30),

            // FIRST ROW LAYOUT: Stats (LEFT) | Calendar (CENTER) | Performance (RIGHT)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LEFT: STAT CARDS
                Expanded(
                  flex: 3,
                  child: _buildStatCardsList(), // Stats GridView
                ),
                const SizedBox(width: 20),

                // CENTER: CALENDAR
                Expanded(
                  flex: 2,
                  child: _buildAttendanceCalendar(),
                ),
                const SizedBox(width: 20),

                // RIGHT: PERFORMANCE OVERVIEW
                Expanded(
                  flex: 3,
                  child: _buildPerformanceOverview(),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // SECOND ROW: Homework + Tests
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _SectionCard(
                    title: '📚 Recent Homework',
                    child: _HomeworkList(homework: mockData.homework),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _SectionCard(
                    title: '📋 Upcoming Tests',
                    child: _TestsList(tests: mockData.tests),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // THIRD ROW: Results + Bus Details
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _SectionCard(
                    title: '📊 Recent Results',
                    child: _ResultsList(results: mockData.results),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _SectionCard(
                    title: '🚌 Bus Details',
                    child: _BusDetailsCard(details: mockData.busDetails),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 100), // Space for floating button
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showChatDialog(context),
        backgroundColor: Colors.lightBlueAccent.shade700,
        icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
        label: const Text('Chat', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  // WhatsApp-like chat dialog
  void _showChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _WhatsAppChatDialog();
      },
    );
  }
}

// -------------------------------------------------------------------------
// 4. REUSABLE COMPONENTS
// -------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20, // Increased size
                fontWeight: FontWeight.bold,
                color: Color(0xFF5A67C4), // Sharper color
              ),
            ),
            const Divider(),
            child,
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String number;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.icon,
    required this.number,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext classContext) {
    return InkWell(
      onTap: onTap,
      child: Container(
        // Increased padding slightly for vertical space within the grid cell
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border(left: BorderSide(color: color, width: 5)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        // Aligned content to center vertically within the cell
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Icon (Left)
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                // Number/Status (Right)
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      number,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        height: 1.1,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Label (Below the icon/number row)
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _PerformanceStatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _PerformanceStatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 20,
      ), // Increased padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 32, // Significantly increased size
                fontWeight: FontWeight.w900, // Extra bold
                color: color,
                height: 1.0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14, // Increased size
              color: Colors.grey,
              height: 1.0,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _BusDetailsCard extends StatelessWidget {
  final Map<String, dynamic> details;

  const _BusDetailsCard({required this.details});

  Widget _buildDetailRow(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800, // Bolder
              color: Color(0xFF5A67C4),
              fontSize: 18, // Increased size
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ), // Increased size
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.directions_bus,
                color: Color(0xFF5A67C4),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Bus ${details['busNumber']}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDetailRow('Route', details['route'] as String),
              _buildDetailRow('Driver', details['driver'] as String),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDetailRow('Pickup Time', details['pickupTime'] as String),
              _buildDetailRow('Drop Time', details['dropTime'] as String),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeworkList extends StatelessWidget {
  final List<Map<String, String>> homework;

  const _HomeworkList({required this.homework});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: homework.length,
      itemBuilder: (context, index) {
        final item = homework[index];
        final isPending = item['status'] == 'pending';
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(10),
            border: Border(
              left: BorderSide(
                color: isPending ? Colors.orange : Colors.green,
                width: 4,
              ),
            ),
          ),
          child: ListTile(
            title: Text(
              item['title']!,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ), // Bolder
            ),
            subtitle: Text(
              '${item['subject']!} - Due: ${item['dueDate']!}',
              style: const TextStyle(fontSize: 13), // Adjusted size
            ),
            trailing: Chip(
              label: Text(
                item['status']!,
                style: TextStyle(
                  color: isPending ? Colors.black87 : Colors.white,
                  fontWeight: FontWeight.w600, // Bolder chip text
                ),
              ),
              backgroundColor: isPending
                  ? const Color(0xFFFFC107).withValues(alpha: 0.5)
                  : const Color(0xFF40c057),
            ),
          ),
        );
      },
    );
  }
}

class _TestsList extends StatelessWidget {
  final List<Map<String, String>> tests;

  const _TestsList({required this.tests});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tests.length,
      itemBuilder: (context, index) {
        final item = tests[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(10),
            border: const Border(
              left: BorderSide(color: Color(0xFFf093fb), width: 4),
            ),
          ),
          child: ListTile(
            title: Text(
              '${item['subject']!} Test',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ), // Bolder
            ),
            subtitle: Text(
              'Date: ${item['date']!} • Duration: ${item['duration']!}',
              style: const TextStyle(fontSize: 13), // Adjusted size
            ),
            trailing: Chip(
              label: const Text(
                'Upcoming',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: const Color(0xFFf093fb).withValues(alpha: 0.5),
            ),
          ),
        );
      },
    );
  }
}

class _ResultsList extends StatelessWidget {
  final List<Map<String, dynamic>> results;

  const _ResultsList({required this.results});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(10),
            border: const Border(
              left: BorderSide(color: Color(0xFF28a745), width: 4),
            ),
          ),
          child: ListTile(
            title: Text(
              '${item['subject']} - ${item['examType']}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ), // Bolder
            ),
            subtitle: Text(
              'Score: ${item['score']}% • Grade: ${item['grade']} • Date: ${item['date']}',
              style: const TextStyle(fontSize: 13), // Adjusted size
            ),
            trailing: const Chip(
              label: Text(
                'Completed',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: Color(0xFF40c057),
            ),
          ),
        );
      },
    );
  }
}

// Line Chart Painter for Attendance Performance
class _LineChartPainter extends CustomPainter {
  final List<String> months;
  final List<int> percentages;

  _LineChartPainter({required this.months, required this.percentages});

  @override
  void paint(Canvas canvas, Size size) {
    // FIX: Safely exit if data is empty or too small to calculate spacing
    if (months.isEmpty) return;

    final paint = Paint()
      ..color =
          const Color(0xFF4CAF50) // Sharper green line
      ..strokeWidth =
          3.5 // Thicker line
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color =
          const Color(0xFF4CAF50) // Sharper green point
      ..style = PaintingStyle.fill;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Calculate positions
    // Chart height is based on the container size defined in _buildAttendanceChart (200)
    final chartHeight = size.height - 60;
    final chartWidth = size.width - 40;

    // FIX: Corrected calculation for xSpacing to handle single or zero elements gracefully.
    final xSpacing = months.length > 1 ? chartWidth / (months.length - 1) : 0.0;

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;

    // Draw horizontal grid lines and Y-axis labels
    for (int i = 0; i <= 4; i++) {
      final y = 20 + (chartHeight / 4) * i;
      canvas.drawLine(Offset(20, y), Offset(size.width - 20, y), gridPaint);

      final percentage = 100 - (i * 25);
      textPainter.text = TextSpan(
        text: '$percentage%',
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 11,
        ), // Sharper Y-axis label
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - 5));
    }

    // If there is only one point, draw a point but no line, and no need for spacing calculation.
    if (months.isEmpty) return;

    // Draw line
    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < percentages.length; i++) {
      final x = 20 + (months.length > 1 ? (i * xSpacing) : (chartWidth / 2));
      // Normalize values from 100-0 to fit chart area
      final normalizedValue = (100 - percentages[i]) / 100;
      final y = 20 + (normalizedValue * chartHeight);

      points.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    if (months.length > 1) {
      canvas.drawPath(path, paint);
    }

    // Draw points and labels
    for (int i = 0; i < points.length; i++) {
      final point = points[i];

      // Draw point
      canvas.drawCircle(point, 6, pointPaint); // Larger point
      canvas.drawCircle(point, 3, Paint()..color = Colors.white);

      // Draw percentage label
      textPainter.text = TextSpan(
        text: '${percentages[i]}%',
        style: const TextStyle(
          color: Color(0xFF4CAF50), // Sharper color for label
          fontSize: 12, // Slightly larger font
          fontWeight: FontWeight.w700,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(point.dx - textPainter.width / 2, point.dy - 20),
      );

      // Draw month label
      textPainter.text = TextSpan(
        text: months[i],
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 13,
        ), // Sharper month label
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(point.dx - textPainter.width / 2, size.height - 25),
      );
    }
  }

  // Set shouldRepaint to true if the data is dynamic (it is, based on _selectedPeriod)
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// -------------------------------------------------------------------------
// WhatsApp-Like Chat Dialog
// -------------------------------------------------------------------------

class _WhatsAppChatDialog extends StatefulWidget {
  @override
  State<_WhatsAppChatDialog> createState() => _WhatsAppChatDialogState();
}

class _WhatsAppChatDialogState extends State<_WhatsAppChatDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _teachers = [
    {
      'name': 'Mr. John Smith',
      'subject': 'Mathematics',
      'online': true,
      'unread': 2,
      'lastMessage': 'Great progress this week!',
      'time': '10:30 AM',
      'avatar': '👨‍🏫',
    },
    {
      'name': 'Ms. Sarah Johnson',
      'subject': 'English',
      'online': false,
      'unread': 0,
      'lastMessage': 'Assignment submitted',
      'time': 'Yesterday',
      'avatar': '👩‍🏫',
    },
    {
      'name': 'Dr. Michael Brown',
      'subject': 'Science',
      'online': true,
      'unread': 1,
      'lastMessage': 'Lab report feedback ready',
      'time': '2:15 PM',
      'avatar': '👨‍🔬',
    },
    {
      'name': 'Mrs. Emily Davis',
      'subject': 'History',
      'online': false,
      'unread': 0,
      'lastMessage': 'See you in class',
      'time': '2 days ago',
      'avatar': '👩‍🏫',
    },
    {
      'name': 'Mr. Robert Wilson',
      'subject': 'Sports',
      'online': true,
      'unread': 0,
      'lastMessage': 'Sports day next week',
      'time': '11:45 AM',
      'avatar': '⚽',
    },
  ];

  final List<Map<String, dynamic>> _groups = [
    {
      'name': 'Class 10-A Parents',
      'members': 35,
      'unread': 5,
      'lastMessage': 'Parent meeting on Friday',
      'time': '1:20 PM',
      'avatar': '👨‍👩‍👧‍👦',
    },
    {
      'name': 'Mathematics Study Group',
      'members': 12,
      'unread': 0,
      'lastMessage': 'Practice problems shared',
      'time': 'Yesterday',
      'avatar': '📐',
    },
    {
      'name': 'School Events Committee',
      'members': 8,
      'unread': 3,
      'lastMessage': 'Annual day preparations',
      'time': '3:30 PM',
      'avatar': '🎭',
    },
    {
      'name': 'Sports Team Parents',
      'members': 20,
      'unread': 0,
      'lastMessage': 'Tournament schedule',
      'time': '3 days ago',
      'avatar': '🏆',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredTeachers {
    if (_searchQuery.isEmpty) return _teachers;
    return _teachers
        .where(
          (teacher) =>
              teacher['name'].toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              teacher['subject'].toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
        )
        .toList();
  }

  List<Map<String, dynamic>> get _filteredGroups {
    if (_searchQuery.isEmpty) return _groups;
    return _groups
        .where(
          (group) =>
              group['name'].toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    SchoolManagementSystemApp.primaryPurple,
                    Color(0xFF764BA2),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          // Chat icon (kept the new trending icon)
                          Icon(
                            Icons.send_time_extension,
                            color: Colors.white,
                            size: 28,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'School Chat',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // REMOVED: Icons.more_vert (three dots) button here
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Search teachers, groups...',
                        hintStyle: TextStyle(color: Colors.white70),
                        prefixIcon: Icon(Icons.search, color: Colors.white),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Tabs
            Container(
              color: Colors.grey.shade100,
              child: TabBar(
                controller: _tabController,
                labelColor: SchoolManagementSystemApp.primaryPurple,
                unselectedLabelColor: Colors.grey,
                indicatorColor: SchoolManagementSystemApp.primaryPurple,
                indicatorWeight: 3,
                tabs: const [
                  Tab(icon: Icon(Icons.chat), text: 'Chats'),
                  Tab(icon: Icon(Icons.group), text: 'Groups'),
                ],
              ),
            ),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildChatsTab(), _buildGroupsTab()],
              ),
            ),
            // New chat button
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: () => _showNewChatDialog(context),
                backgroundColor: SchoolManagementSystemApp.primaryPurple,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Start New Chat',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatsTab() {
    return Container(
      color: Colors.grey.shade50,
      child: _filteredTeachers.isEmpty
          ? const Center(
              child: Text(
                'No teachers found',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: _filteredTeachers.length,
              itemBuilder: (context, index) {
                final teacher = _filteredTeachers[index];
                return _buildChatTile(
                  avatar: teacher['avatar'],
                  name: teacher['name'],
                  subtitle: teacher['lastMessage'],
                  time: teacher['time'],
                  unread: teacher['unread'],
                  online: teacher['online'],
                  onTap: () => _openChatWithTeacher(context, teacher),
                );
              },
            ),
    );
  }

  Widget _buildGroupsTab() {
    return Container(
      color: Colors.grey.shade50,
      child: _filteredGroups.isEmpty
          ? const Center(
              child: Text(
                'No groups found',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: _filteredGroups.length,
              itemBuilder: (context, index) {
                final group = _filteredGroups[index];
                return _buildChatTile(
                  avatar: group['avatar'],
                  name: group['name'],
                  subtitle: group['lastMessage'],
                  time: group['time'],
                  unread: group['unread'],
                  isGroup: true,
                  members: group['members'],
                  onTap: () => _openGroup(context, group),
                );
              },
            ),
    );
  }

  Widget _buildChatTile({
    required String avatar,
    required String name,
    required String subtitle,
    required String time,
    int unread = 0,
    bool online = false,
    bool isGroup = false,
    int members = 0,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: SchoolManagementSystemApp.primaryPurple.withValues(
                      alpha: 0.1,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(avatar, style: const TextStyle(fontSize: 24)),
                  ),
                ),
                if (online && !isGroup)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            // Darkened Name Text
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                            color: Colors
                                .black, // Changed to pure black for max visibility
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        time,
                        style: TextStyle(
                          color: unread > 0
                              ? SchoolManagementSystemApp.primaryPurple
                              : Colors.black54, // Darker time stamp
                          fontSize: 13,
                          fontWeight: unread > 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          isGroup ? '$members members · $subtitle' : subtitle,
                          style: const TextStyle(
                            // Darkened Subtitle Text
                            color: Colors
                                .black, // Changed to pure black for max visibility
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unread > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: const BoxDecoration(
                            color: SchoolManagementSystemApp.primaryPurple,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unread.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openChatWithTeacher(
    BuildContext context,
    Map<String, dynamic> teacher,
  ) {
    // FIX: Postpone navigation using Future.delayed or scheduleMicrotask
    // This allows the current InkWell/GestureDetector tap sequence to finish safely.
    Navigator.of(context).pop(); // Pop the chat selection dialog immediately
    Future.delayed(const Duration(milliseconds: 100), () {
      showDialog(
        context: context,
        builder: (context) => _TeacherChatScreen(teacher: teacher),
      );
    });
  }

  void _openGroup(BuildContext context, Map<String, dynamic> group) {
    // FIX: Postpone navigation
    Navigator.of(context).pop(); // Pop the chat selection dialog immediately
    Future.delayed(const Duration(milliseconds: 100), () {
      showDialog(
        context: context,
        builder: (context) => _GroupChatScreen(group: group),
      );
    });
  }

  void _showNewChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start New Chat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select a teacher:'),
            const SizedBox(height: 8),
            ..._teachers.map(
              (teacher) => ListTile(
                leading: Text(
                  teacher['avatar'],
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(
                  teacher['name'],
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(teacher['subject']),
                onTap: () {
                  Navigator.of(context).pop();
                  // FIX: Apply delay here as well if this navigates to a new chat
                  Future.delayed(const Duration(milliseconds: 100), () {
                    _openChatWithTeacher(context, teacher);
                  });
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------------------
// Teacher Chat Screen
// -------------------------------------------------------------------------

class _TeacherChatScreen extends StatefulWidget {
  final Map<String, dynamic> teacher;
  const _TeacherChatScreen({required this.teacher});

  @override
  State<_TeacherChatScreen> createState() => _TeacherChatScreenState();
}

class _TeacherChatScreenState extends State<_TeacherChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'text': 'Hello! How can I help you today?',
      'isTeacher': true,
      'time': '10:25 AM',
    },
    {
      'text': 'I wanted to discuss my child\'s recent test scores.',
      'isTeacher': false,
      'time': '10:26 AM',
    },
    {
      'text':
          'Of course! Your child scored 85% on the last test. That\'s excellent progress!',
      'isTeacher': true,
      'time': '10:28 AM',
    },
    {
      'text': 'Thank you! Any areas we should focus on?',
      'isTeacher': false,
      'time': '10:29 AM',
    },
    {
      'text': 'Just review chapter 5 exercises for better understanding.',
      'isTeacher': true,
      'time': '10:30 AM',
    },
  ];

  // State variable to track if text field is empty
  bool _isTextFieldEmpty = true;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_updateTextFieldState);
  }

  @override
  void dispose() {
    _messageController.removeListener(_updateTextFieldState);
    _messageController.dispose();
    super.dispose();
  }

  void _updateTextFieldState() {
    final isEmpty = _messageController.text.isEmpty;
    if (_isTextFieldEmpty != isEmpty) {
      setState(() {
        _isTextFieldEmpty = isEmpty;
      });
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      setState(() {
        _messages.add({
          'text': _messageController.text,
          'isTeacher': false,
          'time': 'Just now',
        });
        _messageController.clear();
      });
    }
  }

  void _sendVoiceMessage() {
    _showSnackBar("Recording voice message...");
    // Implement actual recording logic here (start/stop)
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    SchoolManagementSystemApp.primaryPurple,
                    Color(0xFF764BA2),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Text(
                    widget.teacher['avatar'],
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.teacher['name'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          widget.teacher['online'] ? 'Online' : 'Offline',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Removed video and audio call buttons as requested.
                ],
              ),
            ),
            // Messages
            Expanded(
              child: Container(
                color: Colors.grey.shade50,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return _buildMessage(
                      message['text'],
                      message['isTeacher'],
                      message['time'],
                    );
                  },
                ),
              ),
            ),
            // Input
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.attach_file,
                      color: SchoolManagementSystemApp.primaryPurple,
                    ),
                    onPressed: () => _showSnackBar("Attach file dialog"),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) {
                        // Only handle submission if the send button is active (text mode)
                        if (!_isTextFieldEmpty) {
                          _sendMessage();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Voice/Send Button logic
                  _isTextFieldEmpty
                      ? // Show voice button if text field is empty
                      GestureDetector(
                          onLongPress: _sendVoiceMessage,
                          onLongPressUp: () => _showSnackBar(
                            "Voice recording stopped. Message sent!",
                          ),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: SchoolManagementSystemApp.primaryPurple,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.mic, color: Colors.white),
                          ),
                        )
                      : // Show send button if text field has text
                      FloatingActionButton(
                          mini: true,
                          onPressed: _sendMessage,
                          backgroundColor:
                              SchoolManagementSystemApp.primaryPurple,
                          child: const Icon(Icons.send, color: Colors.white),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(String text, bool isTeacher, String time) {
    return Align(
      alignment: isTeacher ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 350),
        decoration: BoxDecoration(
          color: isTeacher
              ? Colors.white
              : SchoolManagementSystemApp.primaryPurple,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                // UPDATED: Changed text color to pure black/white for maximum contrast
                color: isTeacher ? Colors.black : Colors.white,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                // UPDATED: Increased contrast on timestamps
                color: isTeacher ? Colors.black54 : Colors.white,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

// -------------------------------------------------------------------------
// Group Chat Screen
// -------------------------------------------------------------------------

class _GroupChatScreen extends StatefulWidget {
  final Map<String, dynamic> group;
  const _GroupChatScreen({required this.group});

  @override
  State<_GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<_GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'text': 'Parent meeting scheduled for Friday at 3 PM',
      'sender': 'Admin',
      'time': '1:15 PM',
    },
    {
      'text': 'Thanks for the update!',
      'sender': 'Sarah\'s Mom',
      'time': '1:16 PM',
    },
    {
      'text': 'Will there be a virtual option?',
      'sender': 'John\'s Dad',
      'time': '1:18 PM',
    },
    {
      'text': 'Yes, we\'ll share the meeting link tomorrow.',
      'sender': 'Admin',
      'time': '1:20 PM',
    },
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      setState(() {
        _messages.add({
          'text': _messageController.text,
          'sender': 'You',
          'time': 'Just now',
        });
        _messageController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    SchoolManagementSystemApp.primaryPurple,
                    Color(0xFF764BA2),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Text(
                    widget.group['avatar'],
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.group['name'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          '${widget.group['members']} members',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline, color: Colors.white),
                    onPressed: () => _showSnackBar("Group Info"),
                  ),
                ],
              ),
            ),
            // Messages
            Expanded(
              child: Container(
                color: Colors.grey.shade50,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final isMe = message['sender'] == 'You';
                    return _buildGroupMessage(
                      message['text'],
                      message['sender'],
                      message['time'],
                      isMe,
                    );
                  },
                ),
              ),
            ),
            // Input
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.attach_file,
                      color: SchoolManagementSystemApp.primaryPurple,
                    ),
                    onPressed: () => _showSnackBar("Attach file dialog"),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    mini: true,
                    onPressed: _sendMessage,
                    backgroundColor: SchoolManagementSystemApp.primaryPurple,
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupMessage(
    String text,
    String sender,
    String time,
    bool isMe,
  ) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 350),
        decoration: BoxDecoration(
          color: isMe ? SchoolManagementSystemApp.primaryPurple : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                sender,
                style: const TextStyle(
                  // UPDATED: Changed color to green (like WhatsApp) for contrast
                  color: Color(0xFF075E54),
                  fontWeight: FontWeight.w800, // Extra bold for emphasis
                  fontSize: 13,
                ),
              ),
            if (!isMe) const SizedBox(height: 4),
            Text(
              text,
              style: TextStyle(
                // UPDATED: Changed text color to pure black/white for maximum contrast
                color: isMe ? Colors.white : Colors.black,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                // UPDATED: Increased contrast on timestamps
                color: isMe ? Colors.white : Colors.black54,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

