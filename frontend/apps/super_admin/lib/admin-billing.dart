import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'main.dart' as main_dashboard;
import 'admin-schools.dart' as schools;
import 'admin-revenue.dart' as revenue;
import 'admin-add-school.dart' as add_school;
import 'admin-school-management.dart' as school_management;

void main() {
  // Ensure we can use NumberFormat, especially for locales.
  Intl.defaultLocale = 'en_IN';
  runApp(const BillingApp());
}

// --- Data Model ---
class School {
  final int id;
  final String name;
  final String location;
  final int students;
  final int monthlyBill;
  final int ratePerStudent;
  final String avatarLetter;

  School({
    required this.id,
    required this.name,
    required this.location,
    required this.students,
    required this.monthlyBill,
    required this.ratePerStudent,
  }) : avatarLetter = name.substring(0, 1);
}

// --- Global Data and Constants ---
final List<School> schoolsData = [
  School(
    id: 1,
    name: "Central High School",
    location: "New York, NY",
    students: 1250,
    monthlyBill: 125000,
    ratePerStudent: 100,
  ),
  School(
    id: 2,
    name: "North Elementary",
    location: "Chicago, IL",
    students: 800,
    monthlyBill: 80000,
    ratePerStudent: 100,
  ),
  School(
    id: 3,
    name: "South Middle School",
    location: "Los Angeles, CA",
    students: 950,
    monthlyBill: 95000,
    ratePerStudent: 100,
  ),
  School(
    id: 4,
    name: "East Academy",
    location: "Miami, FL",
    students: 600,
    monthlyBill: 60000,
    ratePerStudent: 100,
  ),
  School(
    id: 5,
    name: "West Institute",
    location: "Seattle, WA",
    students: 700,
    monthlyBill: 70000,
    ratePerStudent: 100,
  ),
  School(
    id: 6,
    name: "Riverside High",
    location: "Austin, TX",
    students: 1100,
    monthlyBill: 110000,
    ratePerStudent: 100,
  ),
];

final int totalStudents = schoolsData.fold(
  0,
  (sum, school) => sum + school.students,
);
final int totalBilling = schoolsData.fold(
  0,
  (sum, school) => sum + school.monthlyBill,
);
final int activeSchools = schoolsData.length;

// --- App Setup ---
class BillingApp extends StatelessWidget {
  const BillingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Billing Management - Admin Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        fontFamily: 'Segoe UI',
        scaffoldBackgroundColor: const Color(0xfff8f9fa),
      ),
      home: const BillingDashboard(),
    );
  }
}

// --- Dashboard State Management ---
class BillingDashboard extends StatefulWidget {
  const BillingDashboard({super.key});

  @override
  State<BillingDashboard> createState() => _BillingDashboardState();
}

class _BillingDashboardState extends State<BillingDashboard> {
  int _currentTabIndex = 0; // 0: Billing, 1: Schools, 2: Rates
  double _ratePerStudent = 100.0;
  String? _selectedSchoolId;
  String? _selectedBillingPeriod;
  DateTime _selectedBillingDate = DateTime.now();
  final _rateController = TextEditingController(text: '100');

  // Utility to format numbers to Indian Rupees (₹)
  String formatCurrency(int amount) {
    // Ensure the correct locale is set for Indian Rupee symbol and grouping
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  String formatNumber(int number) {
    final formatter = NumberFormat('#,##0');
    return formatter.format(number);
  }

  // Helper function to show a custom alert dialog (simulating JS alert)
  void _showAlert(String title, String content) {
    // Replace dialog with a SnackBar to avoid Navigator usage
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title\n$content'),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _rateController.text = _ratePerStudent.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  // --- Widgets for Reusability ---


  Widget _buildOverviewCard(
    String icon,
    String number,
    String label,
    String change,
  ) {
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
      padding: const EdgeInsets.all(25),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  colors: [Color(0xffdc3545), Color(0xffc82333)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(
                  icon,
                  style: const TextStyle(fontSize: 24, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              number,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xffdc3545),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: const TextStyle(fontSize: 14, color: Color(0xff666666)),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(40, 167, 69, 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                change,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff28a745),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String title) {
    final bool isActive = _currentTabIndex == index;
    final Color primaryColor = const Color(0xffdc3545);
    final Color textColor = isActive ? Colors.white : Colors.black;
    final Decoration decoration = BoxDecoration(
      color: isActive ? null : Colors.white,
      gradient: isActive
          ? const LinearGradient(
              colors: [Color(0xffdc3545), Color(0xffc82333)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : null,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: isActive ? primaryColor : const Color(0xffe9ecef),
        width: 2,
      ),
    );

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          decoration: decoration,
          child: Center(
            child: Text(
              title,
              style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
            ),
          ),
        ),
      ),
    );
  }

  // --- Tab Content Widgets ---

  void _updateRate() {
    double? newRate = double.tryParse(_rateController.text);
    if (newRate != null && newRate > 0) {
      setState(() {
        _ratePerStudent = newRate;
      });
      _showAlert(
        'Rate Updated',
        'Billing rate updated to ${formatCurrency(_ratePerStudent.toInt())} per student. This will be applied to all schools.',
      );
    } else {
      _showAlert('Invalid Rate', 'Please enter a valid rate.');
    }
  }

  Widget _buildBillingSystemTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Billing System Configuration',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        const Text(
          'Configure billing rates and manage the billing system for all schools.',
        ),
        const SizedBox(height: 25),
        // Rate Config
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xfff8f9fa),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Current Billing Rate',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 15),
              Wrap(
                spacing: 15,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Rate per Student:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(
                    width: 150,
                    child: TextFormField(
                      controller: _rateController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                          borderSide: BorderSide(color: Color(0xffe9ecef)),
                        ),
                        suffixText: '₹',
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _updateRate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffdc3545),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Update Rate'),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Text(
                'Note: This rate will be applied to all schools. Each student will be charged ${formatCurrency(_ratePerStudent.toInt())} per month.',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        // Generate Bill Form
        Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Generate New Bill',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              _buildFormGroup(
                label: 'Select School',
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedSchoolId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      borderSide: BorderSide(color: Color(0xffe9ecef)),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  hint: const Text('Choose a school...'),
                  items: schoolsData
                      .map(
                        (school) => DropdownMenuItem(
                          value: school.id.toString(),
                          child: Text(school.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedSchoolId = value),
                ),
              ),
              _buildFormGroup(
                label: 'Billing Period',
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedBillingPeriod,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      borderSide: BorderSide(color: Color(0xffe9ecef)),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  hint: const Text('Select period...'),
                  items: const [
                    DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                    DropdownMenuItem(
                      value: 'quarterly',
                      child: Text('Quarterly'),
                    ),
                    DropdownMenuItem(
                      value: 'half-yearly',
                      child: Text('Half-Yearly'),
                    ),
                    DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedBillingPeriod = value),
                ),
              ),
              _buildFormGroup(
                label: 'Billing Date',
                child: InkWell(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xffe9ecef),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_selectedBillingDate.year}-${_selectedBillingDate.month.toString().padLeft(2, '0')}-${_selectedBillingDate.day.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleGenerateBillForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffdc3545),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Generate Bill',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBillingDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedBillingDate) {
      setState(() {
        _selectedBillingDate = picked;
      });
    }
  }

  void _handleGenerateBillForm() {
    if (_selectedSchoolId != null && _selectedBillingPeriod != null) {
      final school = schoolsData.firstWhere(
        (s) => s.id.toString() == _selectedSchoolId,
      );
      final billAmount = school.students * _ratePerStudent;
      _showAlert(
        'Bill Generated Successfully!',
        'School: ${school.name}\nPeriod: $_selectedBillingPeriod\nDate: ${_selectedBillingDate.year}-${_selectedBillingDate.month.toString().padLeft(2, '0')}-${_selectedBillingDate.day.toString().padLeft(2, '0')}\nStudent Count: ${school.students.toString()}\nRate per Student: ${formatCurrency(_ratePerStudent.toInt())}\nTotal Bill: ${formatCurrency(billAmount.toInt())}',
      );
    } else {
      _showAlert('Missing Fields', 'Please fill in all required fields.');
    }
  }

  Widget _buildFormGroup({required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xff333333),
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildSchoolBillingTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'School Billing Details',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        const Text('View and manage billing for individual schools.'),
        const SizedBox(height: 25),
        // Schools Grid
        LayoutBuilder(
          builder: (context, constraints) {
            // FIX 1: Increased mainAxisExtent to 532 (from 520) to fix 12px overflow.
            final double cardHeight = 540;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 450, // Max width of each card
                crossAxisSpacing: 40,
                mainAxisSpacing: 40,
                // Apply fixed height
                mainAxisExtent: cardHeight,
              ),
              itemCount: schoolsData.length,
              itemBuilder: (context, index) {
                return _buildSchoolCard(schoolsData[index]);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildSchoolCard(School school) {
    // Current rate from state is used for calculations
    final currentBill = (school.students * _ratePerStudent).toInt();

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
      padding: const EdgeInsets.all(25),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: [Color(0xffdc3545), Color(0xffc82333)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    school.avatarLetter,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    school.name,
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
            ],
          ),
          const SizedBox(height: 20),
          // School Stats - Implemented as a 2x2 grid (4 items total)
          GridView.count(
            crossAxisCount: 2,
            // FIX 2: Adjusted childAspectRatio to 2.9 (from 3.0) to provide more vertical space and fix 0.667px overflow.
            childAspectRatio: 2.9,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStatItem(formatNumber(school.students), 'Students'),
              _buildStatItem(formatCurrency(currentBill), 'Monthly Bill'),
              _buildStatItem(
                formatCurrency(_ratePerStudent.toInt()),
                'Per Student',
              ),
              _buildStatItem('12', 'Billing Cycle'),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xfff8f9fa),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildBillingRow(
                  'Student Count:',
                  formatNumber(school.students),
                ),
                _buildBillingRow(
                  'Rate per Student:',
                  formatCurrency(_ratePerStudent.toInt()),
                ),
                _buildBillingRow(
                  'Total Bill:',
                  formatCurrency(currentBill),
                  isTotal: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _viewBillingDetails(school),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff007bff), // btn-view blue
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'View Details',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _generateSchoolBill(school),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffdc3545), // btn-bill red
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Generate Bill',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String number, String label) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xfff8f9fa),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Reduced vertical padding from 5 to 4
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, // Added to prevent overflow
        children: [
          Text(
            number,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xffdc3545),
            ),
          ),
          const SizedBox(height: 4), // Reduced from 5 to 4
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xff666666),
            ),
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
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? Colors.black : const Color(0xff666666),
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: const Color(0xffdc3545),
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  void _viewBillingDetails(School school) {
    final currentBill = (school.students * _ratePerStudent).toInt();
    final annualBill = currentBill * 12;
    _showAlert(
      'Billing Details: ${school.name}',
      'Student Count: ${formatNumber(school.students)}\nRate per Student: ${formatCurrency(_ratePerStudent.toInt())}\nMonthly Bill: ${formatCurrency(currentBill)}\nAnnual Bill: ${formatCurrency(annualBill)}',
    );
  }

  void _generateSchoolBill(School school) {
    final billAmount = (school.students * _ratePerStudent).toInt();
    _showAlert(
      'Bill Generated for ${school.name}',
      'Student Count: ${formatNumber(school.students)}\nRate per Student: ${formatCurrency(_ratePerStudent.toInt())}\nTotal Bill: ${formatCurrency(billAmount)}\nDue Date: 30 days from today',
    );
  }

  Widget _buildRateConfigurationTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rate Configuration',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        const Text(
          'Configure billing rates and manage pricing for different services.',
        ),
        const SizedBox(height: 25),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xfff8f9fa),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Billing Rates',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 15),
              Text('Student Management: ₹100 per student per month'),
              Text('Premium Support: ₹500 per school per month (Optional)'),
              Text('Advanced Analytics: ₹200 per school per month (Optional)'),
              Text('Custom Integration: ₹1000 one-time fee (On Request)'),
            ],
          ),
        ),
      ],
    );
  }

  // --- Main Layout ---
  @override
  Widget build(BuildContext context) {
    // Determine if we should show the sidebar inline (desktop) or as a bottom nav (mobile)
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    Widget mainContent = Padding(
      padding: const EdgeInsets.all(28),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
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
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Billing Management',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
                  ),
                  if (isDesktop)
                    Row(
                      children: [
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22.5),
                            gradient: const LinearGradient(
                              colors: [Color(0xffdc3545), Color(0xffc82333)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
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
                        ElevatedButton(
                          onPressed: () {
                            // Navigate back to dashboard
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => const main_dashboard.AdminDashboardScreen(),
                              ),
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xff6c757d,
                            ), // back-btn grey
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Text('←'),
                              SizedBox(width: 8),
                              Text('Back to Dashboard'),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Billing Overview
            GridView.count(
              crossAxisCount: isDesktop ? 4 : 2,
              childAspectRatio: 0.85, // Changed from 1.0 to 0.85 to provide more vertical space
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              children: [
                _buildOverviewCard(
                  '📋',
                  formatCurrency(totalBilling),
                  'Total Billing',
                  '+15.3%',
                ),
                _buildOverviewCard(
                  '💰',
                  formatCurrency(_ratePerStudent.toInt()),
                  'Rate per Student',
                  'Fixed',
                ),
                _buildOverviewCard(
                  '👥',
                  formatNumber(totalStudents),
                  'Total Students',
                  '+8.2%',
                ),
                _buildOverviewCard(
                  '🏫',
                  activeSchools.toString(),
                  'Active Schools',
                  '+1',
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Content Tabs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTabButton(0, 'Billing System'),
                const SizedBox(width: 8),
                _buildTabButton(1, 'School Billing'),
                const SizedBox(width: 8),
                _buildTabButton(2, 'Rate Configuration'),
              ],
            ),
            const SizedBox(height: 28),

            // Tab Content
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
              padding: const EdgeInsets.all(28),
              child: IndexedStack(
                index: _currentTabIndex,
                children: [
                  _buildBillingSystemTab(),
                  _buildSchoolBillingTab(),
                  _buildRateConfigurationTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      drawer: !isDesktop ? const Drawer(child: UnifiedSidebar(initialActiveSection: 'billing')) : null,
      body: isDesktop
          ? Row(
              children: [
                // Sidebar (Fixed Width)
                const UnifiedSidebar(initialActiveSection: 'billing'),
                // Main Content (Flexible)
                Expanded(child: mainContent),
              ],
            )
          : Column(
              children: [
                // Main Content for Mobile
                Expanded(child: mainContent),
                // Footer navigation for mobile (simulating sticky bottom bar)
                SizedBox(
                  height: 60,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      TextButton(
                        onPressed: () => setState(() => _currentTabIndex = 0),
                        child: Text(
                          'Billing',
                          style: TextStyle(
                            color: _currentTabIndex == 0
                                ? Colors.red
                                : Colors.grey,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _currentTabIndex = 1),
                        child: Text(
                          'Schools',
                          style: TextStyle(
                            color: _currentTabIndex == 1
                                ? Colors.red
                                : Colors.grey,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _currentTabIndex = 2),
                        child: Text(
                          'Rates',
                          style: TextStyle(
                            color: _currentTabIndex == 2
                                ? Colors.red
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
        targetScreen = const revenue.RevenueDashboard();
        break;
      case 'licenses':
      case 'school_management':
        targetScreen = const school_management.SchoolDashboard();
        break;
      case 'billing':
        targetScreen = const BillingDashboard();
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
