import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart' as main_dashboard;
import 'admin-schools.dart' as schools;
import 'admin-revenue.dart' as revenue;
import 'admin-billing.dart' as billing;
import 'admin-add-school.dart' as add_school;
import 'admin-school-management.dart' as school_management;

void main() {
  runApp(const SchoolManagementApp());
}

class SchoolManagementApp extends StatelessWidget {
  const SchoolManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'School Management System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA), // Light gray bg
        fontFamily: 'Segoe UI',
        useMaterial3: true,
      ),
      home: const SchoolDetailsScreen(),
    );
  }
}

// --- 1. MAIN SCREEN ---
class SchoolDetailsScreen extends StatelessWidget {
  const SchoolDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Responsive Layout Builder
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth > 1000;

        return Scaffold(
          appBar: !isDesktop
              ? AppBar(
                  title: const Text("School Details"),
                  backgroundColor: Colors.white,
                  elevation: 1,
                  iconTheme: const IconThemeData(color: Colors.black),
                  titleTextStyle: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 24, // Increased
                  ),
                )
              : null,
          drawer: !isDesktop ? const Drawer(child: UnifiedSidebar(initialActiveSection: 'schools')) : null,
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sidebar (Visible on Desktop)
              if (isDesktop)
                const UnifiedSidebar(initialActiveSection: 'schools'),
              // Main Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(30), // Increased padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Top Header (Navigation & User Profile)
                      const TopHeader(),
                      const SizedBox(height: 30),

                      // 2. School Identity Card (Top Banner)
                      const SchoolIdentityCard(),
                      const SizedBox(height: 30),

                      // 3. Content Grid

                      // Responsive layout based on screen width
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isMobile = constraints.maxWidth < 800;
                          
                          if (isMobile) {
                            // Stack all sections vertically on mobile
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildNotificationsSection(context),
                                const SizedBox(height: 20),
                                _buildAdmissionsSection(context),
                                const SizedBox(height: 20),
                                _buildDepartmentsSection(context),
                                const SizedBox(height: 20),
                                _buildExtracurricularsSection(context),
                                const SizedBox(height: 20),
                                _buildFeeStructureSection(context),
                                const SizedBox(height: 20),
                                _buildBusRoutesSection(context),
                                const SizedBox(height: 20),
                                _buildPhotoGallerySection(context),
                                const SizedBox(height: 20),
                                _buildAwardsSection(context),
                                const SizedBox(height: 20),
                                _buildEventsAndCalendarSection(context),
                                const SizedBox(height: 20),
                                _buildCampusLifeSection(context),
                                const SizedBox(height: 20),
                                _buildRTIActSection(context),
                              ],
                            );
                          } else {
                            // Desktop layout with rows
                            return Column(
                              children: [
                                // ROW A: Notifications & Admissions
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: _buildNotificationsSection(context)),
                                    const SizedBox(width: 30),
                                    Expanded(child: _buildAdmissionsSection(context)),
                                  ],
                                ),
                                const SizedBox(height: 30),

                                // ROW B: Academics (Departments) & Activities
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(flex: 2, child: _buildDepartmentsSection(context)),
                                    const SizedBox(width: 30),
                                    Expanded(
                                      flex: 1,
                                      child: _buildExtracurricularsSection(context),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 30),

                                // ROW C: Logistics (Fees & Bus Routes)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: _buildFeeStructureSection(context)),
                                    const SizedBox(width: 30),
                                    Expanded(child: _buildBusRoutesSection(context)),
                                  ],
                                ),
                                const SizedBox(height: 30),

                                // ROW D: Media (Gallery & Awards)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(flex: 2, child: _buildPhotoGallerySection(context)),
                                    const SizedBox(width: 30),
                                    Expanded(flex: 1, child: _buildAwardsSection(context)),
                                  ],
                                ),
                                const SizedBox(height: 30),

                                // ROW E: Events & Calendar
                                _buildEventsAndCalendarSection(context),
                                const SizedBox(height: 30),

                                // ROW F: Footer Info (Campus Life & RTI)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: _buildCampusLifeSection(context)),
                                    const SizedBox(width: 30),
                                    Expanded(child: _buildRTIActSection(context)),
                                  ],
                                ),
                              ],
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 50), // Bottom padding
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- SECTION WIDGET BUILDERS (Updated Font Sizes) ---

  Widget _buildNotificationsSection(BuildContext context) {
    return ContentCard(
      title: "Notifications",
      icon: Icons.notifications_active,
      onViewAll: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Viewing all Notifications')),
        );
      },
      child: Column(
        children: [
          _buildNotificationItem(
            "School Closed",
            "Heavy rain forecast for tomorrow.",
            "Nov 20, 8:00 AM",
            isAlert: true,
          ),
          _buildNotificationItem(
            "Exam Schedule",
            "Mid-term dates released.",
            "Nov 18, 2:30 PM",
          ),
          _buildNotificationItem(
            "Sports Day",
            "Registration opens next week.",
            "Nov 15, 10:00 AM",
          ),
        ],
      ),
    );
  }

  Widget _buildAdmissionsSection(BuildContext context) {
    return ContentCard(
      title: "Admissions",
      icon: Icons.assignment_ind,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD), // Light Blue
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF90CAF9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Status: OPEN",
                  style: TextStyle(
                    color: Color(0xFF0D47A1),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ), // Increased
                SizedBox(height: 8),
                Text(
                  "Academic Year 2025-2026",
                  style: TextStyle(fontSize: 16),
                ), // Increased
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildDetailRow("Application Deadline", "Dec 31, 2024"),
          _buildDetailRow("Entrance Exam", "Jan 15, 2025"),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening application management')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007BFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                ), // Larger button
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text(
                "Manage Applications",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ), // Increased
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentsSection(BuildContext context) {
    return ContentCard(
      title: "Departments",
      icon: Icons.category,
      onViewAll: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Viewing all Departments')),
        );
      },
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _buildChip("Science", Icons.science),
          _buildChip("Mathematics", Icons.calculate),
          _buildChip("Languages", Icons.translate),
          _buildChip("Arts & Music", Icons.palette),
          _buildChip("Physical Ed", Icons.sports_soccer),
          _buildChip("Computer Sci", Icons.computer),
          _buildChip("Social Studies", Icons.public),
        ],
      ),
    );
  }

  Widget _buildExtracurricularsSection(BuildContext context) {
    return ContentCard(
      title: "Extracurriculars",
      icon: Icons.sports_handball,
      child: Column(
        children: [
          _buildBulletItem("Robotics Club"),
          _buildBulletItem("Debate Team"),
          _buildBulletItem("Drama Society"),
          _buildBulletItem("Chess Club"),
          _buildBulletItem("Eco Warriors"),
        ],
      ),
    );
  }

  Widget _buildFeeStructureSection(BuildContext context) {
    return ContentCard(
      title: "Fee Structure",
      icon: Icons.attach_money,
      onViewAll: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Viewing all Fee Structure')),
        );
      },
      child: Table(
        border: TableBorder.all(color: const Color(0xFFE9ECEF)),
        columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(1)},
        children: const [
          TableRow(
            children: [
              Padding(
                padding: EdgeInsets.all(15),
                child: Text(
                  "Grade",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(15),
                child: Text(
                  "Annual Fee",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          TableRow(
            children: [
              Padding(
                padding: EdgeInsets.all(15),
                child: Text("Primary (1-5)", style: TextStyle(fontSize: 15)),
              ),
              Padding(
                padding: EdgeInsets.all(15),
                child: Text("\$5,000", style: TextStyle(fontSize: 15)),
              ),
            ],
          ),
          TableRow(
            children: [
              Padding(
                padding: EdgeInsets.all(15),
                child: Text("Middle (6-8)", style: TextStyle(fontSize: 15)),
              ),
              Padding(
                padding: EdgeInsets.all(15),
                child: Text("\$6,500", style: TextStyle(fontSize: 15)),
              ),
            ],
          ),
          TableRow(
            children: [
              Padding(
                padding: EdgeInsets.all(15),
                child: Text("High (9-12)", style: TextStyle(fontSize: 15)),
              ),
              Padding(
                padding: EdgeInsets.all(15),
                child: Text("\$8,000", style: TextStyle(fontSize: 15)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBusRoutesSection(BuildContext context) {
    return ContentCard(
      title: "Bus Routes",
      icon: Icons.directions_bus,
      onViewAll: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Viewing all Bus Routes')),
        );
      },
      child: Column(
        children: [
          _buildBusRouteItem(context, "Route 101", "Downtown -> School"),
          _buildBusRouteItem(context, "Route 102", "West End -> School"),
          _buildBusRouteItem(context, "Route 103", "North Hills -> School"),
        ],
      ),
    );
  }

  Widget _buildPhotoGallerySection(BuildContext context) {
    return ContentCard(
      title: "Photo Gallery",
      icon: Icons.photo_library,
      onViewAll: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Viewing all Photo Gallery')),
        );
      },
      child: SizedBox(
        height: 140, // Increased height
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 5,
          separatorBuilder: (ctx, i) => const SizedBox(width: 15),
          itemBuilder: (ctx, i) {
            return Container(
              width: 200, // Wider images
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
                image: const DecorationImage(
                  image: NetworkImage('https://via.placeholder.com/200x140'),
                  fit: BoxFit.cover,
                ),
              ),
              child: const Center(
                child: Icon(Icons.image, color: Colors.white54, size: 50),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAwardsSection(BuildContext context) {
    return ContentCard(
      title: "Awards",
      icon: Icons.emoji_events,
      child: Column(
        children: [
          _buildAwardItem("Best STEM School", "National Board, 2024"),
          _buildAwardItem("Excellence in Sports", "State Championship, 2023"),
        ],
      ),
    );
  }

  Widget _buildEventsAndCalendarSection(BuildContext context) {
    return ContentCard(
      title: "Events & Calendar",
      icon: Icons.calendar_month,
      onViewAll: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Viewing all Events & Calendar')),
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 15),
                  child: Text(
                    "Upcoming Events",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ), // Increased
                ),
                _buildCalendarItem(
                  "Dec 12",
                  "Annual Science Fair",
                  "Auditorium",
                ),
                _buildCalendarItem("Dec 20", "Winter Concert", "Main Hall"),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 120,
            color: Colors.grey.shade300,
            margin: const EdgeInsets.symmetric(horizontal: 30),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 15),
                  child: Text(
                    "Academic Calendar",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ), // Increased
                ),
                _buildDetailRow("Term Ends", "Dec 22, 2024"),
                _buildDetailRow("Next Term Starts", "Jan 06, 2025"),
                _buildDetailRow("Total Working Days", "220 Days"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampusLifeSection(BuildContext context) {
    return ContentCard(
      title: "Campus Life",
      icon: Icons.deck,
      onViewAll: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Viewing all Campus Life')),
        );
      },
      child: const Text(
        "Our campus spans 25 acres featuring smart classrooms, Olympic-sized swimming pool, advanced science labs, and a digital library with 10,000+ resources. We prioritize a holistic environment combining academic rigor with student well-being.",
        style: TextStyle(
          height: 1.6,
          color: Color(0xFF555555),
          fontSize: 16,
        ), // Increased
      ),
    );
  }

  Widget _buildRTIActSection(BuildContext context) {
    return ContentCard(
      title: "RTI Act Compliance",
      icon: Icons.gavel,
      onViewAll: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Viewing all RTI Act Compliance')),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "This institution falls under the Right to Information Act.",
            style: TextStyle(fontSize: 15, color: Colors.grey),
          ), // Increased
          const SizedBox(height: 15),
          _buildDetailRow("Public Info Officer", "Mr. John Doe"),
          _buildDetailRow("Contact", "rti@stmarys.edu"),
          _buildDetailRow(
            "Appellate Authority",
            "Dr. Sarah Johnson (Principal)",
          ),
        ],
      ),
    );
  }

  // --- HELPER ITEM BUILDERS (With Larger Fonts) ---

  Widget _buildNotificationItem(
    String title,
    String desc,
    String time, {
    bool isAlert = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(
              Icons.circle,
              size: 12,
              color: isAlert ? Colors.red : Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ), // Increased
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF555555),
                  ),
                ), // Increased
              ],
            ),
          ),
          // Detail View Action
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ), // Increased
              const SizedBox(height: 6),
              const Text(
                "View",
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF007BFF),
                  fontWeight: FontWeight.bold,
                ),
              ), // Increased
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF666666), fontSize: 15),
          ), // Increased
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
              fontSize: 16,
            ),
          ), // Increased
        ],
      ),
    );
  }

  Widget _buildChip(String label, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 18, color: const Color(0xFF007BFF)),
      label: Text(label, style: const TextStyle(fontSize: 14)), // Increased
      backgroundColor: const Color(0xFFF0F8FF),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildBulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.check, size: 20, color: Colors.green),
              const SizedBox(width: 10),
              Text(text, style: const TextStyle(fontSize: 15)), // Increased
            ],
          ),
          const Icon(Icons.info_outline, size: 20, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildBusRouteItem(BuildContext context, String route, String path) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.directions_bus,
              color: Colors.orange,
              size: 22,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  route,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ), // Increased
                Text(
                  path,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ), // Increased
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.map, color: Color(0xFF007BFF), size: 24),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Opening map for $route')),
              );
            },
            tooltip: "View on Map",
          ),
        ],
      ),
    );
  }

  Widget _buildAwardItem(String title, String issuer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ), // Increased
                Text(
                  issuer,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ), // Increased
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 22),
        ],
      ),
    );
  }

  Widget _buildCalendarItem(String date, String event, String location) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF007BFF),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              date,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ), // Increased
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ), // Increased
                Text(
                  location,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ), // Increased
              ],
            ),
          ),
          const Icon(Icons.visibility, color: Color(0xFF007BFF), size: 20),
        ],
      ),
    );
  }
}

// --- 2. TOP HEADER WIDGET ---
class TopHeader extends StatelessWidget {
  const TopHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE9ECEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "School Details",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ), // Increased
          Row(
            children: [
              // User Profile
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE9ECEF)),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(0xFF007BFF),
                      child: Text(
                        "A",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ), // Increased
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Admin User",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ), // Increased
                        Text(
                          "Administrator",
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ), // Increased
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Buttons
              _headerButton(context, "Back to Schools", true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerButton(BuildContext context, String text, bool dark) {
    return ElevatedButton.icon(
      onPressed: () {
        // Navigate back to schools list
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const schools.AdminDashboard(),
          ),
        );
      },
      icon: const Icon(Icons.arrow_back, size: 18),
      label: Text(text, style: const TextStyle(fontSize: 15)), // Increased
      style: ElevatedButton.styleFrom(
        backgroundColor: dark
            ? const Color(0xFF555555)
            : const Color(0xFFF8F9FA),
        foregroundColor: dark ? Colors.white : const Color(0xFF555555),
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ), // Larger
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}

// --- 3. SCHOOL IDENTITY CARD ---
class SchoolIdentityCard extends StatelessWidget {
  const SchoolIdentityCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30), // Increased padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE9ECEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80, // Larger Logo
            height: 80,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF007BFF), Color(0xFF0056B3)],
              ),
            ),
            alignment: Alignment.center,
            child: const Text(
              "SM",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 28,
              ),
            ), // Increased
          ),
          const SizedBox(width: 25),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "St. Mary's High School",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ), // Increased
                SizedBox(height: 8),
                Text(
                  "New York, NY � Private School � K-12",
                  style: TextStyle(color: Color(0xFF6C757D), fontSize: 16),
                ), // Increased
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "Active",
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ), // Increased
          ),
        ],
      ),
    );
  }
}

// --- 4. GENERIC CONTENT CARD WRAPPER ---
class ContentCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final VoidCallback? onViewAll;

  const ContentCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25), // Increased Padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE9ECEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF007BFF),
                size: 24,
              ), // Larger Icon
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ), // Increased
              const Spacer(),
              // Clickable Detail View Action
              if (onViewAll != null)
                InkWell(
                  onTap: onViewAll,
                  child: const Row(
                    children: [
                      Text(
                        "View All",
                        style: TextStyle(
                          color: Color(0xFF007BFF),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ), // Increased
                      Icon(
                        Icons.arrow_forward,
                        size: 14,
                        color: Color(0xFF007BFF),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const Divider(height: 40, color: Color(0xFFE9ECEF)),
          child,
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
