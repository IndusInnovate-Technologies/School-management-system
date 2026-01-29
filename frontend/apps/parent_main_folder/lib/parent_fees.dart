import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Fees Portal',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const StudentFeesPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class StudentFeesPage extends StatefulWidget {
  const StudentFeesPage({super.key});

  @override
  State<StudentFeesPage> createState() => _StudentFeesPageState();
}

class _StudentFeesPageState extends State<StudentFeesPage> {
  // --- Data ---
  final List<Map<String, dynamic>> feeStructure = [
    {
      "type": "feeStructure",
      "name": "Tuition Fee",
      "amount": 30000,
      "status": "paid",
      "dueDate": "2024-06-30",
      "description": "Annual tuition fee for academic year",
    },
    {
      "type": "feeStructure",
      "name": "Transport Fee",
      "amount": 8000,
      "status": "paid",
      "dueDate": "2024-06-30",
      "description": "Bus transportation service fee",
    },
    {
      "type": "feeStructure",
      "name": "Library Fee",
      "amount": 2000,
      "status": "paid",
      "dueDate": "2024-06-30",
      "description": "Library membership and book access",
    },
    {
      "type": "feeStructure",
      "name": "Sports Fee",
      "amount": 5000,
      "status": "due",
      "dueDate": "2024-12-31",
      "description": "Sports facilities and equipment fee",
    },
  ];

  final List<Map<String, dynamic>> paymentHistory = [
    {
      "type": "paymentHistory",
      "title": "Q1 Payment",
      "amount": 15000,
      "date": "2024-06-15",
      "method": "Online Transfer",
      "status": "completed",
      "transactionId": "TXN123456",
    },
    {
      "type": "paymentHistory",
      "title": "Q2 Payment",
      "amount": 15000,
      "date": "2024-09-15",
      "method": "Credit Card",
      "status": "completed",
      "transactionId": "TXN123457",
    },
    {
      "type": "paymentHistory",
      "title": "Q3 Payment",
      "amount": 12000,
      "date": "2024-11-15",
      "method": "Bank Transfer",
      "status": "completed",
      "transactionId": "TXN123458",
    },
  ];

  final List<Map<String, dynamic>> paymentSchedule = [
    {
      "type": "paymentSchedule",
      "quarter": "Q1 (Apr-Jun)",
      "amount": 15000,
      "dueDate": "2024-06-30",
      "status": "paid",
      "description": "First quarter fees",
      "installment_number": 1,
    },
    {
      "type": "paymentSchedule",
      "quarter": "Q2 (Jul-Sep)",
      "amount": 15000,
      "dueDate": "2024-09-30",
      "status": "paid",
      "description": "Second quarter fees",
      "installment_number": 2,
    },
    {
      "type": "paymentSchedule",
      "quarter": "Q3 (Oct-Dec)",
      "amount": 12000,
      "dueDate": "2024-11-30",
      "status": "paid",
      "description": "Third quarter fees",
      "installment_number": 3,
    },
    {
      "type": "paymentSchedule",
      "quarter": "Q4 (Jan-Mar)",
      "amount": 3000,
      "dueDate": "2025-03-31",
      "status": "due",
      "description": "Fourth quarter fees",
      "installment_number": 4,
    },
  ];

  // --- State for Filtering ---
  String paymentMethodFilter = 'all';

  List<Map<String, dynamic>> get filteredPaymentHistory {
    return paymentHistory.where((payment) {
      if (paymentMethodFilter == 'all') return true;
      return payment['method'] == paymentMethodFilter;
    }).toList();
  }

  // --- Logic Helpers ---
  void _setReminder() {
    final nearestDue = paymentSchedule
        .where((s) => s['status'] == 'due')
        .toList();

    if (nearestDue.isEmpty) {
      _showMsg("No outstanding dues! Reminders are unnecessary. 🎉");
      return;
    }

    final dueDateString = nearestDue.first['dueDate'] as String;
    final quarter = nearestDue.first['quarter'] as String;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Set Payment Reminder"),
          content: Text(
            "Would you like to set a local reminder for the next payment due ($quarter) on $dueDateString?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showMsg("Reminder set successfully for $dueDateString! 🔔");
              },
              child: const Text("Confirm Reminder"),
            ),
          ],
        );
      },
    );
  }

  Map<String, dynamic> _getNearestDueDateStatus() {
    final now = DateTime.now();
    final nearestDue = paymentSchedule
        .where((s) => s['status'] == 'due')
        .toList();

    if (nearestDue.isEmpty) {
      return {'text': 'All Clear! No Dues.', 'color': const Color(0xff51cf66)};
    }

    final dueDateString = nearestDue.first['dueDate'] as String;
    final dueDate = DateTime.parse(dueDateString);
    final days = dueDate.difference(now).inDays;

    if (days < 0) {
      return {'text': 'OVERDUE!', 'color': Colors.red};
    } else if (days == 0) {
      return {'text': 'DUE TODAY!', 'color': Colors.red.shade700};
    } else if (days <= 7) {
      return {'text': 'Due in $days days', 'color': Colors.orange};
    } else {
      return {
        'text': 'Next Due: $dueDateString',
        'color': const Color(0xff667eea),
      };
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showDownloadStatementModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(25),
          height: 350,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Download Full Statement",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              _modalDetailRow("Format:", "PDF (Recommended)"),
              _modalDetailRow("Period:", "2024 Academic Year"),
              _modalDetailRow("Status:", "Ready to Generate"),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showMsg("Downloading receipt..."),
                  icon: const Icon(Icons.download, color: Colors.white),
                  label: const Text(
                    "Download Now",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff667eea),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _modalDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(value, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  void _showFeeDetailModal(BuildContext context, Map<String, dynamic> item) {
    final currencyFormatter = NumberFormat('#,##0');
    final type = item['type'] as String;

    String getTitle() {
      if (type == 'feeStructure') return item['name'] as String;
      if (type == 'paymentHistory') return item['title'] as String;
      if (type == 'paymentSchedule') return item['quarter'] as String;
      return "Detail View";
    }

    Widget buildSpecificDetails() {
      if (type == 'paymentHistory') {
        return Column(
          children: [
            _modalDetailRow("Transaction ID:", item['transactionId'] as String),
            _modalDetailRow("Payment Method:", item['method'] as String),
            _modalDetailRow(
              "Status:",
              (item['status'] as String).toUpperCase(),
            ),
          ],
        );
      } else if (type == 'paymentSchedule') {
        return Column(
          children: [
            _modalDetailRow("Description:", item['description'] as String),
            _modalDetailRow("Due Date:", item['dueDate'] as String),
            _modalDetailRow(
              "Status:",
              (item['status'] as String).toUpperCase(),
            ),
          ],
        );
      } else if (type == 'feeStructure') {
        return Column(
          children: [
            _modalDetailRow("Annual Due Date:", item['dueDate'] as String),
            _modalDetailRow("Description:", item['description'] as String),
            _modalDetailRow(
              "Status:",
              (item['status'] as String).toUpperCase(),
            ),
          ],
        );
      }
      return const SizedBox.shrink();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Text(
                    getTitle(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Amount:",
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                      Text(
                        "₹${currencyFormatter.format(item['amount'])}",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xff764ba2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  buildSpecificDetails(),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showMsg("Action button clicked for: ${getTitle()}");
                      },
                      icon: const Icon(Icons.payment, color: Colors.white),
                      label: Text(
                        (item['status'] == 'paid' ||
                                item['status'] == 'completed')
                            ? 'View Receipt'
                            : 'Pay Now',
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            (item['status'] == 'paid' ||
                                item['status'] == 'completed')
                            ? const Color(0xff51cf66)
                            : Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String emoji, String text) => Padding(
    padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
    child: Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xff333333),
          ),
        ),
      ],
    ),
  );

  Widget _summaryDetailRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    // Quick actions shown as a vertical stack of full-width buttons.
    final actions = [
          {
            'icon': Icons.payment,
            'text': 'Make Payment',
            'color': const Color(0xff51cf66), // green primary action
            'onTap': () => _showMsg("Processing payment..."),
          },
      {
        'icon': Icons.download,
        'text': 'Download Receipt',
        'color': const Color(0xff667eea), // blue
            'onTap': () => _showMsg("Downloading receipt..."),
      },
      {
        'icon': Icons.list_alt,
        'text': 'View Statement',
        'color': const Color(
          0xff667eea,
        ), // blue (use same tone for visual consistency)
            'onTap': () => _showMsg("Opening statement..."),
      },
      {
        'icon': Icons.message,
        'text': 'Contact Admin',
        'color': const Color(0xff667eea),
            'onTap': () => _showMsg("Contacting admin..."),
      },
      {
        'icon': Icons.notifications_active,
        'text': 'Set Reminder',
        'color': const Color(0xff667eea),
            'onTap': () => _showMsg("Setting reminder..."),
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "⚡ Quick Actions",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xff333333),
            ),
          ),
          const SizedBox(height: 10),
          // Render each action as a full-width button with spacing
          ...actions.asMap().entries.map((entry) {
            final idx = entry.key;
            final action = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: idx == actions.length - 1 ? 0 : 10,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: action['onTap'] as VoidCallback?,
                  icon: Icon(
                    action['icon'] as IconData,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      action['text'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: action['color'] as Color,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalFees = 45000;
    int paidAmount = 42000;
    int dueAmount = 3000;
    int paymentProgress = ((paidAmount / totalFees) * 100).round();
    final primaryColor = const Color(0xff667eea);
    final currencyFormatter = NumberFormat('#,##0');
    final nearestDueStatus = _getNearestDueDateStatus();
      return Scaffold(
      backgroundColor: const Color(0xfff8f9fa),
      appBar: AppBar(
        title: const Text(
          "Fees & Payments 💰",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () => _showMsg("User Profile (Simulated)"),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40.0),
          child: Container(
            color: primaryColor.withValues(alpha: 0.9),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              "🔔 ${nearestDueStatus['text']}",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                backgroundColor: (nearestDueStatus['color'] as Color)
                    .withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildSummaryCard(
              totalFees,
              paidAmount,
              dueAmount,
              paymentProgress,
              currencyFormatter,
            ),
            const SizedBox(height: 16),
            _buildStatCards(
              totalFees,
              paidAmount,
              dueAmount,
              paymentProgress,
              currencyFormatter,
            ),
            const SizedBox(height: 24),

            // 1. Annual Fee Structure
            _sectionTitle("📋", "Annual Fee Structure"),
            _buildFeeStructureList(),

            const SizedBox(height: 24),

            // CORRECTED: Filter History by Method (Moved here)
            _buildPaymentMethodFilters(),

            // 2. Transaction History (Filter should be applied here)
            _sectionTitle("💳", "Transaction History"),
            _buildPaymentHistoryList(),

            // 3. Upcoming Schedule
            _sectionTitle("📅", "Upcoming Schedule"),
            _buildPaymentScheduleList(),

            // 4. Quick Actions (Moved to the end)
            const SizedBox(height: 24),
            _buildQuickActions(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodFilters() {
    final methods = ['all', 'Online Transfer', 'Credit Card', 'Bank Transfer'];
    final primaryColor = const Color(0xff667eea);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Filter History by Method",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xff333333),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Wrap(
              spacing: 10,
              children: methods.map((method) {
                final isActive = paymentMethodFilter == method;
                return ActionChip(
                  label: Text(method == 'all' ? 'All Methods' : method),
                  labelStyle: TextStyle(
                    color: isActive ? Colors.white : primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: isActive ? primaryColor : Colors.white,
                  side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                  onPressed: () {
                    setState(() {
                      paymentMethodFilter = method;
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    int total,
    int paid,
    int due,
    int progress,
    NumberFormat formatter,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff667eea).withValues(alpha: 0.15),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Annual Payment Summary",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const Divider(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Payment Progress",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  "$progress%",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xff667eea),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: progress / 100,
                backgroundColor: const Color(0xffe9ecef),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xff667eea),
                ),
                minHeight: 10,
              ),
            ),
            const Divider(height: 25),
            _summaryDetailRow(
              "Total Annual Fees",
              "₹${formatter.format(total)}",
              Colors.black87,
            ),
            _summaryDetailRow(
              "Amount Paid",
              "₹${formatter.format(paid)}",
              const Color(0xff51cf66),
            ),
            _summaryDetailRow(
              "Remaining Due",
              "₹${formatter.format(due)}",
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCards(
    int totalFees,
    int paidAmount,
    int dueAmount,
    int paymentProgress,
    NumberFormat formatter,
  ) {
    final stats = [
      {
        'emoji': '💸',
        'number': "₹${formatter.format(dueAmount)}",
        'label': 'Amount Due',
        'color': Colors.red,
      },
      {
        'emoji': '✅',
        'number': "₹${formatter.format(paidAmount)}",
        'label': 'Paid',
        'color': const Color(0xff51cf66),
      },
      {
        'emoji': '🗓️',
        'number': "Dec 31",
        'label': 'Next Due Date',
        'color': const Color(0xff764ba2),
      },
      {
        'emoji': '📈',
        'number': "$paymentProgress%",
        'label': 'Progress',
        'color': const Color(0xff667eea),
      },
    ];

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: stats.length,
        itemBuilder: (context, index) {
          final stat = stats[index];
          final Color accentColor = stat['color'] as Color;
          return Container(
            width: 140,
            height: 110, // Matching the requested rectangle look
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Top Bar
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        stat['emoji'] as String,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        stat['number'] as String,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        stat['label'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeeStructureList() {
    final currencyFormatter = NumberFormat('#,##0');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: feeStructure
            .map(
              (fee) => GestureDetector(
                onTap: () => _showMsg("Viewing details for ${fee['name']}"),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.attach_money,
                      color: Color(0xff667eea),
                      size: 30,
                    ),
                    title: Text(
                      fee['name'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      fee['description'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "₹${currencyFormatter.format(fee['amount'])}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: (fee['status'] == 'paid')
                                ? const Color(0xff51cf66)
                                : Colors.red,
                          ),
                        ),
                        Text(
                          (fee['status'] as String).toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildPaymentHistoryList() {
    final currencyFormatter = NumberFormat('#,##0');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: filteredPaymentHistory.map((payment) {
          final isCompleted = payment['status'] == 'completed';
          final statusColor = isCompleted
              ? const Color(0xff51cf66)
              : Colors.orange;

          return GestureDetector(
            onTap: () => _showMsg("Viewing payment details..."),
            child: Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: statusColor.withValues(alpha: 0.3), width: 1),
              ),
              child: ListTile(
                leading: Icon(
                  isCompleted ? Icons.receipt_long : Icons.hourglass_empty,
                  color: statusColor,
                  size: 30,
                ),
                title: Text(
                  payment['title'] as String,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  "${payment['method']} - TXN: ${payment['transactionId']}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "₹${currencyFormatter.format(payment['amount'])}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      payment['date'] as String,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPaymentScheduleList() {
    final currencyFormatter = NumberFormat('#,##0');
    final totalInstallments = paymentSchedule.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: paymentSchedule.asMap().entries.map((entry) {
          final index = entry.key;
          final schedule = entry.value;

          final isPaid = schedule['status'] == 'paid';
          final statusColor = isPaid ? const Color(0xff51cf66) : Colors.red;

          return GestureDetector(
            onTap: () => _showMsg("Viewing schedule details..."),
            child: Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '#${index + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xff764ba2),
                      ),
                    ),
                    Text(
                      'of $totalInstallments',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ],
                ),
                title: Text(
                  schedule['quarter'] as String,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  schedule['description'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "₹${currencyFormatter.format(schedule['amount'])}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      isPaid ? 'PAID' : 'DUE',
                      style: TextStyle(fontSize: 12, color: statusColor),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
