import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'main.dart' as main_dashboard;
import 'admin-schools.dart' as schools;
import 'admin-billing.dart' as billing;
import 'admin-add-school.dart' as add_school;
import 'admin-school-management.dart' as school_management;

void main() {
  runApp(const RevenueApp());
}

// --- 1. DATA MODEL ---
class School {
  final int id;
  final String name;
  final String location;
  final int students;
  final int revenue;
  final int ratePerStudent;
  final String avatarLetter;
  // HTML-derived data (assumed static for demo)
  final String studentChange;
  final bool isStudentChangePositive;
  final String revenueChange;
  final bool isRevenueChangePositive;

  School({
    required this.id,
    required this.name,
    required this.location,
    required this.students,
    required this.revenue,
    required this.ratePerStudent,
    // Add new fields
    this.studentChange = '+8.2%', // Dummy data
    this.isStudentChangePositive = true, // Dummy data
    this.revenueChange = '+12.5%', // Dummy data
    this.isRevenueChangePositive = true, // Dummy data
  }) : avatarLetter = name.substring(0, 1);
}

// --- 2. GLOBAL DATA ---
final List<School> schoolsData = [
  School(
    id: 1,
    name: "Central High School",
    location: "New York, NY",
    students: 1250,
    revenue: 125000,
    ratePerStudent: 100,
  ),
  School(
    id: 2,
    name: "North Elementary",
    location: "Chicago, IL",
    students: 800,
    revenue: 80000,
    ratePerStudent: 100,
  ),
  School(
    id: 3,
    name: "South Middle School",
    location: "Los Angeles, CA",
    students: 950,
    revenue: 95000,
    ratePerStudent: 100,
  ),
  School(
    id: 4,
    name: "East Academy",
    location: "Miami, FL",
    students: 600,
    revenue: 60000,
    ratePerStudent: 100,
  ),
  School(
    id: 5,
    name: "West Institute",
    location: "Seattle, WA",
    students: 700,
    revenue: 70000,
    ratePerStudent: 100,
  ),
  School(
    id: 6,
    name: "Riverside High",
    location: "Austin, TX",
    students: 1100,
    revenue: 110000,
    ratePerStudent: 100,
  ),
];

// Calculate overall metrics
final int totalRevenue = schoolsData.fold(
  0,
  (sum, school) => sum + school.revenue,
);
final int totalStudents = schoolsData.fold(
  0,
  (sum, school) => sum + school.students,
);
final int activeSchools = schoolsData.length;
// Values pulled from HTML overview cards
const int totalRevenueChange = 125000;
const String totalRevenueChangePercent = '+12.5%';
const int activeSchoolsChange = 1;
const String activeSchoolsChangePercent = '+1';
const String totalStudentsChangePercent = '+8.2%';
const int expectedRevenue = 540000;
const String expectedRevenueChangePercent = '+15.3%';

// --- Sample Chart Data (Static for demonstration) ---
final Map<String, List<Map<String, dynamic>>> chartData = {
  'Monthly': [
    {'label': 'Jan', 'revenue': 480000},
    {'label': 'Feb', 'revenue': 510000},
    {'label': 'Mar', 'revenue': 540000},
    {'label': 'Apr', 'revenue': 560000},
    {'label': 'May', 'revenue': 550000},
    {'label': 'Jun', 'revenue': 580000},
  ],
  'Quarterly': [
    {'label': 'Q1', 'revenue': 1400000},
    {'label': 'Q2', 'revenue': 1650000},
    {'label': 'Q3', 'revenue': 1780000},
    {'label': 'Q4', 'revenue': 1850000},
  ],
  'HalfYearly': [
    {'label': 'H1', 'revenue': 2850000},
    {'label': 'H2', 'revenue': 3500000},
  ],
  'Annually': [
    {'label': '2023', 'revenue': 5800000},
    {'label': '2024', 'revenue': 6350000},
  ],
};

// --- APP SETUP ---
class RevenueApp extends StatelessWidget {
  const RevenueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Revenue Management - Admin Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xff28a745),
        fontFamily: 'Segoe UI',
        scaffoldBackgroundColor: const Color(0xfff8f9fa),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff28a745)),
        useMaterial3: true,
      ),
      home: const RevenueDashboard(),
    );
  }
}

// --- CUSTOM BAR CHART WIDGET ---
class RevenueBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String title;

  const RevenueBarChart({super.key, required this.data, required this.title});

  @override
  Widget build(BuildContext context) {
    final values = data.map<int>((e) => e['revenue'] as int).toList();
    final labels = data.map<String>((e) => e['label'] as String).toList();
    final maxValue = values.reduce(max).toDouble();
    final minValue = 0.0; // Bar charts typically start from 0

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xffe9ecef), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xff333333),
            ),
          ),
          const SizedBox(height: 20),
          // Chart Area
          SizedBox(
            height: 350,
            width: double.infinity,
            child: CustomPaint(
              painter: _BarChartPainter(values, maxValue, minValue, labels),
            ),
          ),
          // X-Axis Labels
          Padding(
            padding: const EdgeInsets.only(top: 10.0, left: 20, right: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: labels
                  .map(
                    (label) => Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xff666666),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// --- CUSTOM BAR CHART PAINTER ---
class _BarChartPainter extends CustomPainter {
  final List<int> values;
  final double maxValue;
  final double minValue;
  final List<String> labels;

  _BarChartPainter(this.values, this.maxValue, this.minValue, this.labels);

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;
    const double padding = 40.0;
    const double bottomPadding = 30.0;
    const double topPadding = 20.0;
    final double chartHeight = height - padding - bottomPadding - topPadding;
    final double chartWidth = width - 2 * padding;
    final double range = maxValue - minValue;
    final double scaleY = range > 0 ? chartHeight / range : 0;

    // Calculate bar width and spacing - ensure bars fit within container
    final int barCount = values.length;
    final double availableWidth = chartWidth;

    // Set maximum bar width to prevent bars from being too wide
    const double maxBarWidth = 120.0;
    const double minBarSpacing = 20.0;

    // Calculate optimal bar width and spacing
    double barWidth;
    double barSpacing;

    if (barCount == 1) {
      barWidth = (availableWidth * 0.4).clamp(40.0, maxBarWidth);
      barSpacing = (availableWidth - barWidth) / 2;
    } else {
      // Calculate spacing first, then bar width
      final double totalSpacing = minBarSpacing * (barCount - 1);
      final double maxTotalBarWidth = availableWidth - totalSpacing;
      final double calculatedBarWidth = maxTotalBarWidth / barCount;

      // Use the smaller of calculated width or max width
      barWidth = calculatedBarWidth.clamp(40.0, maxBarWidth);

      // Recalculate spacing to center bars
      final double totalBarWidth = barWidth * barCount;
      barSpacing = (availableWidth - totalBarWidth) / (barCount + 1);
    }

    // Draw grid lines and Y-axis labels
    final Paint gridPaint = Paint()
      ..color = const Color(0xffe9ecef)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final Paint axisPaint = Paint()
      ..color = const Color(0xff666666)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw Y-axis
    canvas.drawLine(
      Offset(padding, topPadding),
      Offset(padding, height - bottomPadding),
      axisPaint,
    );

    // Draw X-axis
    canvas.drawLine(
      Offset(padding, height - bottomPadding),
      Offset(width - padding, height - bottomPadding),
      axisPaint,
    );

    // Draw horizontal grid lines
    const int gridLines = 5;
    for (int i = 0; i <= gridLines; i++) {
      final double y = topPadding + (chartHeight / gridLines) * i;
      canvas.drawLine(
        Offset(padding, y),
        Offset(width - padding, y),
        gridPaint,
      );
    }

    // Draw bars
    final Paint barPaint = Paint()
      ..color = const Color(0xff28a745)
      ..style = PaintingStyle.fill;

    final Paint barBorderPaint = Paint()
      ..color = const Color(0xff20c997)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    if (values.isNotEmpty) {
      for (int i = 0; i < values.length; i++) {
        final double barHeight = (values[i] - minValue) * scaleY;
        // Center bars properly with calculated spacing
        final double x = padding + barSpacing + i * (barWidth + barSpacing);
        final double y = height - bottomPadding - barHeight;

        // Ensure bar doesn't overflow
        final double clampedX = x.clamp(padding, width - padding - barWidth);

        // Draw bar with gradient effect (darker at bottom)
        final Rect barRect = Rect.fromLTWH(clampedX, y, barWidth, barHeight);

        // Draw bar shadow
        final Paint shadowPaint = Paint()
          ..color = const Color(0xff28a745).withValues(alpha: 0.2)
          ..style = PaintingStyle.fill;
        canvas.drawRect(
          Rect.fromLTWH(clampedX + 2, y + 2, barWidth, barHeight),
          shadowPaint,
        );

        // Draw main bar
        canvas.drawRect(barRect, barPaint);
        canvas.drawRect(barRect, barBorderPaint);

        // Draw value label on top of bar
        final textPainter = TextPainter(
          text: TextSpan(
            text: _formatValue(values[i]),
            style: const TextStyle(
              color: Color(0xff333333),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        if (barHeight > 20) {
          textPainter.paint(
            canvas,
            Offset(
              clampedX + (barWidth - textPainter.width) / 2,
              y - textPainter.height - 4,
            ),
          );
        }
      }
    }
  }

  String _formatValue(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toString();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// --- DASHBOARD STATE MANAGEMENT ---
class RevenueDashboard extends StatefulWidget {
  const RevenueDashboard({super.key});

  @override
  State<RevenueDashboard> createState() => _RevenueDashboardState();
}

class _RevenueDashboardState extends State<RevenueDashboard> {
  // Set default tab to 2 (Revenue)
  int _currentChartPeriodIndex = 0; // For chart period selection

  final List<String> _periodKeys = [
    'Monthly',
    'Quarterly',
    'HalfYearly',
    'Annually',
  ];

  String formatCurrency(int amount) {
    String value = amount.toString();
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String result = value.replaceAllMapped(reg, (Match m) => '${m[1]},');
    return '₹$result';
  }

  String formatNumber(int number) {
    String value = number.toString();
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return value.replaceAllMapped(reg, (Match m) => '${m[1]},');
  }

  void _showAlert(String title, String content) {
    // Use SnackBar instead of dialog to avoid Navigator calls
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title\n$content'),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // =========================================================
  // CORE WIDGET METHODS
  // =========================================================

  void _viewSchoolDetails(School school) {
    _showAlert(
      'School Details: ${school.name}',
      'Location: ${school.location}\nStudents: ${formatNumber(school.students)}\nRevenue: ${formatCurrency(school.revenue)}\nRate per Student: ${formatCurrency(school.ratePerStudent)}',
    );
  }

  void _generateBill(School school) {
    final billAmount = school.students * school.ratePerStudent;
    _showAlert(
      'Bill Generated for ${school.name}',
      'Student Count: ${formatNumber(school.students)}\nRate per Student: ${formatCurrency(school.ratePerStudent)}\nTotal Bill: ${formatCurrency(billAmount)}\nDue Date: 30 days from today',
    );
  }

  Widget _buildOverviewCard(
    String icon,
    String number,
    String label,
    String change,
    bool isPositive,
  ) {
    final Color changeColor = isPositive
        ? const Color(0xff28a745)
        : const Color(0xffdc3545);
    final Color bgColor = isPositive
        ? const Color.fromRGBO(40, 167, 69, 0.1)
        : const Color.fromRGBO(220, 53, 69, 0.1);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xffe9ecef), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: const LinearGradient(
                colors: [Color(0xff28a745), Color(0xff20c997)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                icon,
                style: const TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              number,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: changeColor,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xff666666)),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              change,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: changeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // New dedicated widget for stat items inside the school card to control height
  Widget _buildSchoolStatItem(String number, String label, Color color) {
    return Container(
      // **REDUCED HEIGHT FROM 90 TO 60**
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xfff8f9fa),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              number,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Color(0xff666666)),
          ),
        ],
      ),
    );
  }

  Widget _buildSchoolRevenueCard(School school) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xffe9ecef), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Avatar, Name, Location
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(
                    colors: [Color(0xff28a745), Color(0xff20c997)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    school.avatarLetter,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      school.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      school.location,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xff666666),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 2: Stats Grid (3 columns)
          GridView.count(
            crossAxisCount: 3,
            // childAspectRatio adjusted for the smaller stat item height
            childAspectRatio: 0.8,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildSchoolStatItem(
                formatNumber(school.students),
                'Students',
                const Color(0xff28a745),
              ),
              _buildSchoolStatItem(
                formatCurrency(school.revenue),
                'Revenue',
                const Color(0xff28a745),
              ),
              _buildSchoolStatItem(
                formatCurrency(school.ratePerStudent),
                'Per Student',
                const Color(0xff28a745),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 3: Billing Info section
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xfff8f9fa),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBillingRow(
                  'Student Count:',
                  formatNumber(school.students),
                ),
                _buildBillingRow(
                  'Rate per Student:',
                  formatCurrency(school.ratePerStudent),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: Color(0xffe9ecef)),
                ),
                // WRAPPED TOTAL BILL ROW IN A FITTEDBOX TO PREVENT OVERFLOW
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _buildBillingRow(
                    'Total Bill:',
                    formatCurrency(school.revenue),
                    isTotal: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Row 4: Action Buttons
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'View Details',
                  const Color(0xff007bff),
                  () => _viewSchoolDetails(school),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionButton(
                  'Generate Bill',
                  const Color(0xff28a745),
                  () => _generateBill(school),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBillingRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min, // Essential for FittedBox
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? Colors.black : const Color(0xff666666),
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              color: const Color(0xff28a745),
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 3,
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  // --- Placeholder Tab Content ---
  Widget _buildPlaceholderTab(String title) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(
          '$title Content (Not Implemented)',
          style: const TextStyle(fontSize: 20, color: Color(0xff666666)),
        ),
      ),
    );
  }

  // --- Header Content ---
  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 30),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xffe9ecef), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Revenue Management',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Color(0xff333333),
            ),
          ),
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22.5),
                  gradient: const LinearGradient(
                    colors: [Color(0xff28a745), Color(0xff20c997)],
                  ),
                ),
                child: const Center(
                  child: Text(
                    'A',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              const Text('Admin User'),
              const SizedBox(width: 15),
              // Back to Dashboard Button
              _buildActionButton(
                '← Back to Dashboard',
                const Color(0xff6c757d),
                () {
                  // Navigate back to dashboard
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const main_dashboard.AdminDashboardScreen(),
                    ),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Revenue Overview and School Grid Content ---
  Widget _buildRevenueOverviewTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Revenue Overview Cards
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth >= 1200 ? 4 : (constraints.maxWidth >= 600 ? 2 : 1);
            
            return GridView.count(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 1.0,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
            _buildOverviewCard(
              '💰',
              formatCurrency(totalRevenue),
              'Total Revenue',
              totalRevenueChangePercent,
              true,
            ),
            _buildOverviewCard(
              '🏫',
              formatNumber(activeSchools),
              'Active Schools',
              activeSchoolsChangePercent,
              true,
            ),
            _buildOverviewCard(
              '👥',
              formatNumber(totalStudents),
              'Total Students',
              totalStudentsChangePercent,
              true,
            ),
            _buildOverviewCard(
              '📋',
              formatCurrency(expectedRevenue),
              'Expected Revenue',
              expectedRevenueChangePercent,
              true,
            ),
              ],
            );
          },
        ),
        const SizedBox(height: 30),

        // 2. Chart Period Tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(_periodKeys.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ChoiceChip(
                  label: Text(_periodKeys[index]),
                  selected: _currentChartPeriodIndex == index,
                  onSelected: (bool selected) {
                    setState(() {
                      _currentChartPeriodIndex = selected
                          ? index
                          : _currentChartPeriodIndex;
                    });
                  },
                  selectedColor: const Color(0xff28a745).withValues(alpha: 0.9),
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: _currentChartPeriodIndex == index
                        ? Colors.white
                        : const Color(0xff333333),
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide(
                    color: _currentChartPeriodIndex == index
                        ? const Color(0xff28a745)
                        : const Color(0xffe9ecef),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 30),

        // 3. Revenue Bar Chart
        RevenueBarChart(
          title: '${_periodKeys[_currentChartPeriodIndex]} Revenue Report',
          data: chartData[_periodKeys[_currentChartPeriodIndex]]!,
        ),
        const SizedBox(height: 30),

        // 4. School Revenue Cards Grid
        LayoutBuilder(
          builder: (context, constraints) {
            // Determine cross axis count based on screen width
            final int crossAxisCount = constraints.maxWidth > 800 ? 2 : 1;

            // **CARD HEIGHT ADJUSTED TO FIT COMPACT CONTENT**
            const double cardHeight = 470.0;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 25,
                mainAxisSpacing: 25,
                // Using a fixed height is the safest way to prevent overflow here.
                mainAxisExtent: cardHeight,
              ),
              itemCount: schoolsData.length,
              itemBuilder: (context, index) {
                return _buildSchoolRevenueCard(schoolsData[index]);
              },
            );
          },
        ),
      ],
    );
  }


  // --- Final Build Method ---
  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    // Always show revenue overview tab
    Widget currentTabContent = _buildRevenueOverviewTab();

    Widget mainContent = Padding(
      padding: EdgeInsets.all(isDesktop ? 30 : 15),
      child: SingleChildScrollView(
        // Mobile Bottom Overflow Fix: Increased padding to avoid bottom overflow
        padding: EdgeInsets.only(bottom: isDesktop ? 0 : 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isDesktop) _buildHeader(),
            // Tab Content Wrapper
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.1),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
                border: Border.all(color: const Color(0xffe9ecef), width: 1),
              ),
              padding: const EdgeInsets.all(30),
              child: currentTabContent,
            ),
          ],
        ),
      ),
    );

    // Build conditional bottom navigation bar for mobile
    final Widget? bottomNav = isDesktop
        ? null
        : BottomNavigationBar(
            currentIndex: 2, // Revenue is always selected
            onTap: (idx) {
              switch (idx) {
                case 0: // Dashboard
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const main_dashboard.AdminDashboardScreen(),
                    ),
                    (route) => false,
                  );
                  break;
                case 1: // Schools
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const schools.AdminDashboard(),
                    ),
                  );
                  break;
                case 2: // Revenue - already here
                  break;
              }
            },
            selectedItemColor: const Color(0xff28a745),
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.school),
                label: 'Schools',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.monetization_on),
                label: 'Revenue',
              ),
            ],
          );

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              title: const Text('Revenue Management'),
              backgroundColor: const Color(0xff28a745),
              foregroundColor: Colors.white,
            ),
      resizeToAvoidBottomInset: false,
      body: isDesktop
          ? Row(
              children: [
                const UnifiedSidebar(initialActiveSection: 'revenue'),
                Expanded(child: mainContent),
              ],
            )
          : mainContent,
      drawer: isDesktop ? null : const Drawer(child: UnifiedSidebar(initialActiveSection: 'revenue')),
      bottomNavigationBar: bottomNav,
    );
  }
}

// Unified Sidebar (same as main.dart)
class UnifiedSidebar extends StatefulWidget {
  final String initialActiveSection;
  
  const UnifiedSidebar({
    super.key,
    this.initialActiveSection = 'overview',
  });

  @override
  State<UnifiedSidebar> createState() => _UnifiedSidebarState();
}

class _UnifiedSidebarState extends State<UnifiedSidebar> {
  late String activeSection;
  
  @override
  void initState() {
    super.initState();
    activeSection = widget.initialActiveSection;
  }

  void navigateTo(String section) {
    setState(() {
      activeSection = section;
    });
    
    // Close drawer on mobile
    if (Scaffold.of(context).hasDrawer) {
      Navigator.of(context).pop();
    }
    
    // Navigate to the corresponding screen
    Widget? targetScreen;
    switch (section) {
      case 'overview':
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const main_dashboard.AdminDashboardScreen()),
          (route) => false,
        );
        return;
      case 'schools':
        targetScreen = const schools.AdminDashboard();
        break;
      case 'revenue':
        targetScreen = const RevenueDashboard();
        break;
      case 'licenses':
      case 'school_management':
        targetScreen = const school_management.SchoolDashboard();
        break;
      case 'billing':
        targetScreen = const billing.BillingDashboard();
        break;
      case 'reports':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reports page coming soon')),
        );
        return;
      case 'settings':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings page coming soon')),
        );
        return;
    }
    
    // Navigate to the target screen
    if (targetScreen != null) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => targetScreen!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFe9ecef))),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            offset: Offset(2, 0),
            blurRadius: 10,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo - Fixed at top
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF007bff), Color(0xFF0056b3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                Text(
                  '🏫 SMS',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'School Management System',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          // Nav Menu - Scrollable
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UnifiedSidebarNavItem(
                    icon: '📊',
                    title: 'Overview',
                    isActive: activeSection == 'overview',
                    onTap: () => navigateTo('overview'),
                  ),
                  UnifiedSidebarNavItem(
                    icon: '🏫',
                    title: 'Schools',
                    isActive: activeSection == 'schools',
                    onTap: () => navigateTo('schools'),
                  ),
                  UnifiedSidebarNavItem(
                    icon: '➕',
                    title: 'Add School',
                    isActive: activeSection == 'add_school',
                    onTap: () async {
                      setState(() {
                        activeSection = 'add_school';
                      });
                      if (Scaffold.of(context).hasDrawer) {
                        Navigator.of(context).pop();
                      }
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const add_school.AddSchoolScreen(),
                        ),
                      );
                      if (result == true) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const schools.AdminDashboard(refreshOnMount: true),
                          ),
                        );
                      }
                    },
                  ),
                  UnifiedSidebarNavItem(
                    icon: '📋',
                    title: 'Licenses',
                    isActive: activeSection == 'licenses',
                    onTap: () => navigateTo('licenses'),
                  ),
                  UnifiedSidebarNavItem(
                    icon: '💰',
                    title: 'Revenue',
                    isActive: activeSection == 'revenue',
                    onTap: () => navigateTo('revenue'),
                  ),
                  UnifiedSidebarNavItem(
                    icon: '💳',
                    title: 'Billing',
                    isActive: activeSection == 'billing',
                    onTap: () => navigateTo('billing'),
                  ),
                  UnifiedSidebarNavItem(
                    icon: '📈',
                    title: 'Reports',
                    isActive: activeSection == 'reports',
                    onTap: () => navigateTo('reports'),
                  ),
                  UnifiedSidebarNavItem(
                    icon: '⚙️',
                    title: 'Settings',
                    isActive: activeSection == 'settings',
                    onTap: () => navigateTo('settings'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UnifiedSidebarNavItem extends StatefulWidget {
  final String icon;
  final String title;
  final bool isActive;
  final VoidCallback onTap;

  const UnifiedSidebarNavItem({
    super.key,
    required this.icon,
    required this.title,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<UnifiedSidebarNavItem> createState() => _UnifiedSidebarNavItemState();
}

class _UnifiedSidebarNavItemState extends State<UnifiedSidebarNavItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF007bff);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            decoration: BoxDecoration(
              color: widget.isActive
                  ? primaryColor
                  : (_isHovering
                        ? const Color(0xFFe9ecef)
                        : const Color(0xFFf8f9fa)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.isActive
                    ? primaryColor
                    : (_isHovering
                          ? const Color(0xFFced4da)
                          : const Color(0xFFe9ecef)),
                width: 1,
              ),
              gradient: widget.isActive
                  ? const LinearGradient(
                      colors: [primaryColor, Color(0xFF0056b3)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Text(
                  widget.icon,
                  style: TextStyle(
                    fontSize: 18,
                    color: widget.isActive ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.title,
                  style: TextStyle(
                    color: widget.isActive
                        ? Colors.white
                        : const Color(0xFF333333),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
