import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core/api/api_service.dart';
import 'package:main_login/main.dart' as main_login;
import 'admin-schools.dart' as schools;
import 'admin-revenue.dart' as revenue;
import 'admin-billing.dart' as billing;
import 'admin-add-school.dart' as add_school;
import 'admin-school-details.dart' as school_details;
import 'admin-school-management.dart' as school_management;
import 'admin-support-requests.dart' as support_requests;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize ApiService to load stored tokens and handle token refresh
  await ApiService().initialize();
  
  runApp(const AdminDashboardApp());
}

// --- Data Models ---

class School {
  final int id;
  final String name;
  final String location;
  final String status;
  final int students;
  final int teachers;
  final String licenseExpiry;
  final String revenue;
  final String photo; // Avatar initials

  School({
    required this.id,
    required this.name,
    required this.location,
    required this.status,
    required this.students,
    required this.teachers,
    required this.licenseExpiry,
    required this.revenue,
    required this.photo,
  });
}

class Activity {
  final String icon;
  final String title;
  final String description;
  final String time;

  Activity({
    required this.icon,
    required this.title,
    required this.description,
    required this.time,
  });
}

// --- Mock Data ---

final List<School> mockSchools = [
  School(
    id: 1,
    name: "St. Mary's High School",
    location: "New York, NY",
    status: "active",
    students: 1250,
    teachers: 85,
    licenseExpiry: "2024-12-31",
    revenue: "\$125,000",
    photo: "SM",
  ),
  School(
    id: 2,
    name: "Lincoln Academy",
    location: "Los Angeles, CA",
    status: "active",
    students: 980,
    teachers: 65,
    licenseExpiry: "2024-11-15",
    revenue: "\$98,000",
    photo: "LA",
  ),
  School(
    id: 3,
    name: "Riverside School",
    location: "Chicago, IL",
    status: "pending",
    students: 750,
    teachers: 45,
    licenseExpiry: "2024-10-20",
    revenue: "\$75,000",
    photo: "RS",
  ),
  School(
    id: 4,
    name: "Oakwood Preparatory",
    location: "Houston, TX",
    status: "active",
    students: 1100,
    teachers: 72,
    licenseExpiry: "2025-01-15",
    revenue: "\$110,000",
    photo: "OP",
  ),
  School(
    id: 5,
    name: "Sunset Elementary",
    location: "Miami, FL",
    status: "expired",
    students: 600,
    teachers: 38,
    licenseExpiry: "2024-08-30",
    revenue: "\$60,000",
    photo: "SE",
  ),
  School(
    id: 6,
    name: "Eastside High",
    location: "Boston, MA",
    status: "active",
    students: 1050,
    teachers: 70,
    licenseExpiry: "2025-03-20",
    revenue: "\$105,000",
    photo: "EH",
  ),
  School(
    id: 7,
    name: "Westbrook Middle",
    location: "Denver, CO",
    status: "pending",
    students: 820,
    teachers: 55,
    licenseExpiry: "2024-12-05",
    revenue: "\$82,000",
    photo: "WM",
  ),
  School(
    id: 8,
    name: "Central Primary",
    location: "Dallas, TX",
    status: "active",
    students: 450,
    teachers: 25,
    licenseExpiry: "2025-05-10",
    revenue: "\$45,000",
    photo: "CP",
  ),
];

final List<Activity> mockActivities = [
  Activity(
    icon: "🏫",
    title: "New School Registration",
    description: "Lincoln Academy completed registration",
    time: "2 hours ago",
  ),
  Activity(
    icon: "📋",
    title: "License Renewal",
    description: "St. Mary's license renewed for 2025",
    time: "4 hours ago",
  ),
  Activity(
    icon: "💰",
    title: "Payment Received",
    description: "Riverside School payment processed",
    time: "6 hours ago",
  ),
  Activity(
    icon: "⚠️",
    title: "License Expiry Alert",
    description: "Sunset Elementary license expired",
    time: "1 day ago",
  ),
  Activity(
    icon: "📊",
    title: "Monthly Report",
    description: "January revenue report generated",
    time: "1 day ago",
  ),
];

final Map<String, dynamic> mockStats = {
  'schools': mockSchools.length,
  'students': '12,450',
  'teachers': 680,
  'buses': 156,
  'revenue': '\$2.4M',
  'licenses': 28,
};

final List<double> revenueData = const [125, 98, 75, 110, 60, 85, 95];
final List<String> revenueMonths = const [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
];

final List<Map<String, dynamic>> licenseData = [
  {'status': 'Active', 'count': 18, 'color': Colors.blue},
  {'status': 'Pending', 'count': 5, 'color': Colors.amber},
  {'status': 'Expired', 'count': 3, 'color': Colors.red},
  {'status': 'Renewal', 'count': 2, 'color': Colors.orange},
];

// --- Styles/Colors Map (for status-based coloring) ---

Map<String, Color> getStatusColor(String status) {
  switch (status) {
    case 'active':
      return {
        'text': const Color(0xFF28a745),
        'background': const Color(0x1A28a745),
      };
    case 'pending':
      return {
        'text': const Color(0xFFFFC107),
        'background': const Color(0x1AFFC107),
      };
    case 'expired':
      return {
        'text': const Color(0xFFdc3545),
        'background': const Color(0x1Adc3545),
      };
    default:
      return {
        'text': const Color(0xFF333333),
        'background': const Color(0xFFf8f9fa),
      };
  }
}

// --- Main App Widget ---

class AdminDashboardApp extends StatelessWidget {
  const AdminDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Dashboard - School Management System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFf8f9fa),
        textTheme: GoogleFonts.interTextTheme(
          // Use a modern font like Inter for 'Segoe UI' effect
          Theme.of(context).textTheme,
        ),
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue)
            .copyWith(
              secondary: const Color(
                0xFF007bff,
              ), // Primary color for highlights
              surface: const Color(0xFFf8f9fa), // Background color
            ),
      ),
      home: const AdminDashboardScreen(),
    );
  }
}

// --- Dashboard View State Management ---
enum DashboardView { overview, schoolsList }

// --- Dashboard Screen (Stateful for responsiveness) ---

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  DashboardView _currentView = DashboardView.overview;

  void _navigateTo(DashboardView view) {
    setState(() {
      _currentView = view;
    });
  }

  Widget _buildCurrentBody(bool isLargeScreen) {
    switch (_currentView) {
      case DashboardView.overview:
        return const OverviewBody();
      case DashboardView.schoolsList:
        return SchoolsListView(
          // Pass the navigation method down to the list view's header
          onBack: () => _navigateTo(DashboardView.overview),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = context.isLargeScreen;

    return Scaffold(
      body: Row(
        children: [
          if (isLargeScreen) const Sidebar(),
          Expanded(
            child: Column(
              children: [
                // Display the correct header based on the view state
                if (!isLargeScreen)
                  MobileHeader(
                    currentView: _currentView,
                    onBack: () => _navigateTo(DashboardView.overview),
                  ),
                if (isLargeScreen)
                  Header(
                    currentView: _currentView,
                    onBack: () => _navigateTo(DashboardView.overview),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isLargeScreen ? 30.0 : 15.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height - 200,
                      ),
                      child: _buildCurrentBody(isLargeScreen),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // Use a Drawer for the sidebar on mobile
      drawer: isLargeScreen ? null : const Sidebar(),
    );
  }
}

// --- Overview Body Widget ---
class OverviewBody extends StatelessWidget {
  const OverviewBody({super.key});

  @override
  Widget build(BuildContext context) {
    // We need the state to change the view, so we get the state object
    final state = context.findAncestorStateOfType<_AdminDashboardScreenState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StatsGrid(),
        const SizedBox(height: 30),
        // Pass the state navigation to the Schools Section
        LicensedSchoolsSection(
          onViewAll: () => state?._navigateTo(DashboardView.schoolsList),
        ),
        const SizedBox(height: 30),
        const AnalyticsReportsSection(),
        const SizedBox(height: 30),
        const RecentActivitiesSection(),
      ],
    );
  }
}

// --- Sidebar Widget ---

class Sidebar extends StatefulWidget {
  final String initialActiveSection;
  
  const Sidebar({
    super.key,
    this.initialActiveSection = 'overview',
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
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
        // Stay on current screen (overview) - navigate back to home
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
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
        // Navigate to school management for licenses
        targetScreen = const school_management.SchoolDashboard();
        break;
      case 'billing':
        targetScreen = const billing.BillingDashboard();
        break;
      case 'support_requests':
        targetScreen = const support_requests.SupportRequestsDashboard();
        break;
      case 'reports':
        // For now, show a placeholder - you can create admin-reports.dart later
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reports page coming soon')),
        );
        return;
      case 'settings':
        // For now, show a placeholder - you can create admin-settings.dart later
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
                  SidebarNavItem(
                    icon: '📊',
                    title: 'Overview',
                    isActive: activeSection == 'overview',
                    onTap: () => navigateTo('overview'),
                  ),
                  SidebarNavItem(
                    icon: '🏫',
                    title: 'Schools',
                    isActive: activeSection == 'schools',
                    onTap: () => navigateTo('schools'),
                  ),
                  SidebarNavItem(
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
                      // Navigate and wait for result
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const add_school.AddSchoolScreen(),
                        ),
                      );
                      // If school was added successfully, navigate to schools list with refresh flag
                      if (result == true) {
                        // Navigate to schools list and refresh
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const schools.AdminDashboard(refreshOnMount: true),
                          ),
                        );
                      }
                    },
                  ),
                  SidebarNavItem(
                    icon: '📋',
                    title: 'Licenses',
                    isActive: activeSection == 'licenses',
                    onTap: () => navigateTo('licenses'),
                  ),
                  SidebarNavItem(
                    icon: '💰',
                    title: 'Revenue',
                    isActive: activeSection == 'revenue',
                    onTap: () => navigateTo('revenue'),
                  ),
                  SidebarNavItem(
                    icon: '💳',
                    title: 'Billing',
                    isActive: activeSection == 'billing',
                    onTap: () => navigateTo('billing'),
                  ),
                  SidebarNavItem(
                    icon: '📈',
                    title: 'Reports',
                    isActive: activeSection == 'reports',
                    onTap: () => navigateTo('reports'),
                  ),
                  SidebarNavItem(
                    icon: '⚙️',
                    title: 'Settings',
                    isActive: activeSection == 'settings',
                    onTap: () => navigateTo('settings'),
                  ),
                  SidebarNavItem(
                    icon: Icons.contact_support,
                    title: 'Support Requests',
                    isActive: activeSection == 'support_requests',
                    onTap: () => navigateTo('support_requests'),
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

class SidebarNavItem extends StatefulWidget {
  final dynamic icon;
  final String title;
  final bool isActive;
  final VoidCallback onTap;

  const SidebarNavItem({
    super.key,
    required this.icon,
    required this.title,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<SidebarNavItem> {
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
                widget.icon is IconData
                    ? Icon(
                        widget.icon,
                        size: 20,
                        color: widget.isActive ? Colors.white : Colors.black,
                      )
                    : Text(
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

// --- Header Widgets (Updated) ---

class Header extends StatelessWidget {
  final DashboardView currentView;
  final VoidCallback onBack;

  const Header({super.key, required this.currentView, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final isDetailView = currentView != DashboardView.overview;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
      margin: const EdgeInsets.only(bottom: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            offset: Offset(0, 2),
            blurRadius: 10,
          ),
        ],
        border: Border.all(color: const Color(0xFFe9ecef)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isDetailView ? 'Schools List' : 'Admin Dashboard',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          Row(
            children: [
              const UserInfo(),
              const SizedBox(width: 15),
              // Logout button - show on overview page
              if (!isDetailView)
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Logout'),
                        content: const Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              // Navigate to main login page
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const main_login.LoginScreen(),
                                ),
                                (route) => false,
                              );
                            },
                            child: const Text('Logout', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFdc3545),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              if (isDetailView) ...[
                // Logout button - also show on detail views
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Logout'),
                        content: const Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              // Navigate to main login page
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const main_login.LoginScreen(),
                                ),
                                (route) => false,
                              );
                            },
                            child: const Text('Logout', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFdc3545),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
                const SizedBox(width: 15),
                ElevatedButton.icon(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Back to Overview'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6c757d),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// For screens where the sidebar is not visible (mobile/tablet), show a mobile header with a menu button
class MobileHeader extends StatelessWidget {
  final DashboardView currentView;
  final VoidCallback onBack;

  const MobileHeader({
    super.key,
    required this.currentView,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isDetailView = currentView != DashboardView.overview;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            offset: Offset(0, 2),
            blurRadius: 5,
          ),
        ],
        border: Border.all(color: const Color(0xFFe9ecef)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          isDetailView
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: onBack,
                  tooltip: 'Back',
                )
              : IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                  tooltip: 'Menu',
                ),
          Expanded(
            child: Text(
              isDetailView ? 'Schools List' : 'Admin Dashboard',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Logout button for mobile header
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Navigate to main login page
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const main_login.LoginScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      child: const Text('Logout', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Logout',
            color: const Color(0xFFdc3545),
          ),
          if (isDetailView)
            ElevatedButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Back'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6c757d),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
        ],
      ),
    );
  }
}

class UserInfo extends StatelessWidget {
  const UserInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22.5),
            gradient: const LinearGradient(
              colors: [Color(0xFF007bff), Color(0xFF0056b3)],
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
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin User',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            Text(
              'System Administrator',
              style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
            ),
          ],
        ),
      ],
    );
  }
}

// --- Stats Grid Widget (FIXED: childAspectRatio changed from 1.25 to 1.15) ---

class StatsGrid extends StatelessWidget {
  const StatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> statsData = [
      {
        'label': 'Total Schools',
        'number': mockStats['schools'].toString(),
        'icon': '🏫',
        'color': const Color(0xFF007bff),
        'description': 'Click to manage licensed schools',
        'section': 'schools',
      },
      {
        'label': 'Total Students',
        'number': mockStats['students'].toString(),
        'icon': '👥',
        'color': const Color(0xFF28a745),
        'description': 'Across all licensed schools',
        'section': 'students',
      },
      {
        'label': 'Total Teachers',
        'number': mockStats['teachers'].toString(),
        'icon': '👨‍🏫',
        'color': const Color(0xFFFFC107),
        'description': 'Across all licensed schools',
        'section': 'teachers',
      },
      {
        'label': 'Total Buses',
        'number': mockStats['buses'].toString(),
        'icon': '🚌',
        'color': const Color(0xFF17a2b8),
        'description': 'Transportation fleet',
        'section': 'buses',
      },
      {
        'label': 'Total Revenue',
        'number': mockStats['revenue'].toString(),
        'icon': '💰',
        'color': const Color(0xFF6f42c1),
        'description': 'Annual license revenue',
        'section': 'revenue',
      },
      {
        'label': 'Active Licenses',
        'number': mockStats['licenses'].toString(),
        'icon': '📋',
        'color': const Color(0xFFfd7e14),
        'description': 'Valid school licenses',
        'section': 'licenses',
      },
    ];

    // FIX APPLIED HERE: childAspectRatio changed from 1.25 to 1.15
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        int crossAxisCount;
        double childAspectRatio;
        
        if (screenWidth > 1200) {
          crossAxisCount = 6;
          childAspectRatio = 1.15;
        } else if (screenWidth > 900) {
          crossAxisCount = 4;
          childAspectRatio = 1.15;
        } else if (screenWidth > 600) {
          crossAxisCount = 3;
          childAspectRatio = 1.2;
        } else {
          crossAxisCount = 2;
          childAspectRatio = 1.3;
        }
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
          ),
          itemCount: statsData.length,
          itemBuilder: (context, index) {
        final stat = statsData[index];
        return StatCard(
          label: stat['label'],
          number: stat['number'],
          icon: stat['icon'],
          color: stat['color'],
          description: stat['description'],
          onTap: () {
            // Navigate based on section
            final section = stat['section'] as String;
            final state = context.findAncestorStateOfType<_AdminDashboardScreenState>();
            if (state != null) {
              switch (section) {
                case 'schools':
                  state._navigateTo(DashboardView.schoolsList);
                  break;
                case 'students':
                  // Navigate to school management page with students view
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const school_management.SchoolDashboard(
                        initialView: school_management.ContentView.detailStudents,
                      ),
                    ),
                  );
                  break;
                case 'teachers':
                  // Navigate to school management page with teachers view
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const school_management.SchoolDashboard(
                        initialView: school_management.ContentView.detailTeachers,
                      ),
                    ),
                  );
                  break;
                case 'buses':
                  // Navigate to school management page with buses view
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const school_management.SchoolDashboard(
                        initialView: school_management.ContentView.detailBuses,
                      ),
                    ),
                  );
                  break;
                case 'revenue':
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const revenue.RevenueDashboard(),
                    ),
                  );
                  break;
                case 'licenses':
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const school_management.SchoolDashboard(),
                    ),
                  );
                  break;
              }
            }
          },
        );
      },
    );
      },
    );
  }
}

class StatCard extends StatefulWidget {
  final String label;
  final String number;
  final String icon;
  final Color color;
  final String description;
  final VoidCallback onTap;

  const StatCard({
    super.key,
    required this.label,
    required this.number,
    required this.icon,
    required this.color,
    required this.description,
    required this.onTap,
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    // Determine the shadow parameters based on hover state
    final List<BoxShadow> boxShadows = _isHovering
        ? [
            // Prominent shadow on hover (equivalent to higher elevation)
            BoxShadow(
              color: widget.color.withValues(alpha: 0.35),
              offset: const Offset(0, 8),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ]
        : [
            // Default, subtle shadow when not hovering
            const BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.1),
              offset: Offset(0, 2),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ];

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(15),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          margin: EdgeInsets.zero,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: _isHovering ? widget.color : const Color(0xFFe9ecef),
              width: _isHovering ? 2 : 1,
            ),
            // The BoxShadow list now handles the elevation animation
            boxShadow: boxShadows,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.icon,
                style: TextStyle(fontSize: 32, color: widget.color),
              ),
              const SizedBox(height: 10),
              Text(
                widget.number,
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                widget.description,
                style: const TextStyle(color: Color(0xFF888888), fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Licensed Schools Section (Updated with View All callback) ---

class LicensedSchoolsSection extends StatefulWidget {
  final VoidCallback onViewAll;

  const LicensedSchoolsSection({super.key, required this.onViewAll});

  @override
  State<LicensedSchoolsSection> createState() => _LicensedSchoolsSectionState();
}

class _LicensedSchoolsSectionState extends State<LicensedSchoolsSection> {
  String _selectedStatus =
      'All'; // State for selected filter: All, active, pending, expired

  void _showSchoolDetails(BuildContext context, School school) {
    // Navigate to school details page
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const school_details.SchoolDetailsScreen(),
      ),
    );
  }

  List<School> get _filteredSchools {
    // Show only the first 5 schools on the overview
    List<School> schools = mockSchools.take(5).toList();

    if (_selectedStatus == 'All') {
      return schools;
    }

    // Filter by the selected status (case-insensitive)
    return schools
        .where((s) => s.status.toLowerCase() == _selectedStatus.toLowerCase())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final schoolsToShow = _filteredSchools;

    return SectionCard(
      title: '🏫 Licensed Schools',
      // The actions row now holds the Add School, Status Filter, and View All buttons
      actions: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          
          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const add_school.AddSchoolScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add School'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF28a745),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFf8f9fa),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFe9ecef)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedStatus,
                      isExpanded: true,
                      items: const ['All', 'Active', 'Pending', 'Expired']
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(
                                status,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedStatus = newValue;
                          });
                        }
                      },
                      icon: const Icon(
                        Icons.filter_list,
                        size: 16,
                        color: Color(0xFF007bff),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: widget.onViewAll,
                  icon: const Text('View All'),
                  label: const Icon(Icons.arrow_forward, size: 16),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007bff),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            );
          } else {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const add_school.AddSchoolScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add School'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF28a745),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
                const SizedBox(width: 15),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFf8f9fa),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFe9ecef)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedStatus,
                      items: const ['All', 'Active', 'Pending', 'Expired']
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(
                                status,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedStatus = newValue;
                          });
                        }
                      },
                      icon: const Icon(
                        Icons.filter_list,
                        size: 16,
                        color: Color(0xFF007bff),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                ElevatedButton.icon(
                  onPressed: widget.onViewAll,
                  icon: const Text('View All'),
                  label: const Icon(Icons.arrow_forward, size: 16),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007bff),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            );
          }
        },
      ),
      child: Column(
        children: [
          if (schoolsToShow.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(
                child: Text(
                  'No schools match this status on the overview.',
                  style: TextStyle(color: Color(0xFF6c757d)),
                ),
              ),
            ),
          ...schoolsToShow.map(
            (school) => SchoolItem(
              school: school,
              onTap: () => _showSchoolDetails(context, school),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Detail List View (New Component - UPDATED FOR MOBILE STACKING) ---

class SchoolsListView extends StatefulWidget {
  final VoidCallback onBack;

  const SchoolsListView({super.key, required this.onBack});

  @override
  State<SchoolsListView> createState() => _SchoolsListViewState();
}

class _SchoolsListViewState extends State<SchoolsListView> {
  String _searchQuery = '';
  String? _selectedStatus;
  final double _mobileBreakpoint = 600; // Define mobile breakpoint

  List<School> get _filteredSchools {
    List<School> list = mockSchools;

    if (_searchQuery.isNotEmpty) {
      list = list
          .where(
            (school) =>
                school.name.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    if (_selectedStatus != null && _selectedStatus != 'All') {
      list = list
          .where((school) => school.status == _selectedStatus!.toLowerCase())
          .toList();
    }

    return list;
  }

  void _showSchoolDetails(BuildContext context, School school) {
    // Navigate to school details page
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const school_details.SchoolDetailsScreen(),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
      decoration: InputDecoration(
        hintText: 'Search schools by name...',
        prefixIcon: const Icon(Icons.search, color: Color(0xFF007bff)),
        contentPadding: const EdgeInsets.all(15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFe9ecef)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF007bff), width: 2),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFf8f9fa),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFe9ecef)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedStatus ?? 'All',
          items: ['All', 'Active', 'Pending', 'Expired']
              .map(
                (status) =>
                    DropdownMenuItem(value: status, child: Text(status)),
              )
              .toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedStatus = newValue;
            });
          },
          style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < _mobileBreakpoint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!context.isLargeScreen) const SizedBox(height: 20),
        SectionCard(
          title: '🏫 All Licensed Schools (${_filteredSchools.length})',
          actions: ElevatedButton.icon(
            onPressed: () {
              // Navigate to Add School page
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const add_school.AddSchoolScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add School'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF28a745),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Responsive Search and Filter Bar ---
              isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSearchField(),
                        const SizedBox(height: 15),
                        _buildFilterDropdown(),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: _buildSearchField()),
                        const SizedBox(width: 20),
                        _buildFilterDropdown(),
                      ],
                    ),
              // ----------------------------------------
              const SizedBox(height: 20),
              // Schools List
              ..._filteredSchools.map(
                (school) => SchoolItem(
                  school: school,
                  onTap: () => _showSchoolDetails(context, school),
                ),
              ),
              if (_filteredSchools.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Center(
                    child: Text(
                      'No schools match your search criteria.',
                      style: TextStyle(color: Color(0xFF6c757d)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// Detail item helper removed (dialogs/details disabled)

// Detail dialog removed: details are disabled in this trimmed build

class SchoolItem extends StatefulWidget {
  final School school;
  final VoidCallback onTap;

  const SchoolItem({super.key, required this.school, required this.onTap});

  @override
  State<SchoolItem> createState() => _SchoolItemState();
}

class _SchoolItemState extends State<SchoolItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final statusColors = getStatusColor(widget.school.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: _isHovering
                  ? const Color(0xFFe9ecef)
                  : const Color(0xFFf8f9fa),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isHovering
                    ? const Color(0xFFced4da)
                    : const Color(0xFFe9ecef),
                width: 1,
              ),
              boxShadow: _isHovering
                  ? [
                      BoxShadow(
                        color: const Color(0xFF007bff).withValues(alpha: 0.1),
                        offset: const Offset(0, 4),
                        blurRadius: 10,
                      ),
                    ]
                  : const [],
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF007bff), Color(0xFF0056b3)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      widget.school.photo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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
                        widget.school.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${widget.school.location} • ${widget.school.students.toString()} students',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xCC333333),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  margin: const EdgeInsets.only(right: 15),
                  decoration: BoxDecoration(
                    color: statusColors['background'],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.school.status.substring(0, 1).toUpperCase() +
                        widget.school.status.substring(1),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColors['text'],
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Color(0xFF6c757d),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Analytics & Reports Section (Updated for side-by-side charts on wide screens) ---

class AnalyticsReportsSection extends StatelessWidget {
  const AnalyticsReportsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '📊 Analytics & Reports',
      actions: const SizedBox.shrink(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Breakpoint for switching from stacked to side-by-side
          if (constraints.maxWidth > 650) {
            // Side-by-side view (Row)
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: RevenueChartCard(
                    revenueData: revenueData,
                    revenueMonths: revenueMonths,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(child: LicenseStatusCard(licenseData: licenseData)),
              ],
            );
          } else {
            // Stacked view (Column) for smaller screens
            return Column(
              children: [
                RevenueChartCard(
                  revenueData: revenueData,
                  revenueMonths: revenueMonths,
                ),
                const SizedBox(height: 20),
                LicenseStatusCard(licenseData: licenseData),
              ],
            );
          }
        },
      ),
    );
  }
}

class RevenueChartCard extends StatelessWidget {
  final List<double> revenueData;
  final List<String> revenueMonths;

  const RevenueChartCard({
    super.key,
    required this.revenueData,
    required this.revenueMonths,
  });

  @override
  Widget build(BuildContext context) {
    final maxRevenue = revenueData.reduce((a, b) => a > b ? a : b);
    const chartHeight = 250.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            offset: Offset(0, 2),
            blurRadius: 10,
          ),
        ],
        border: Border.all(color: const Color(0xFFe9ecef)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Revenue Overview',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 15),
          Container(
            height: chartHeight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFf8f9fa),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(revenueData.length, (index) {
                final heightFactor = revenueData[index] / maxRevenue;
                final barHeight =
                    chartHeight * 0.8 * heightFactor; // 80% of container height
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: barHeight,
                        width: 30,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF007bff), Color(0xFF0056b3)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(5).copyWith(
                            bottomLeft: Radius.zero,
                            bottomRight: Radius.zero,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        revenueMonths[index],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF666666),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 15), // space for bottom padding
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class LicenseStatusCard extends StatelessWidget {
  final List<Map<String, dynamic>> licenseData;

  const LicenseStatusCard({super.key, required this.licenseData});

  @override
  Widget build(BuildContext context) {
    const totalLicenses = 28.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            offset: Offset(0, 2),
            blurRadius: 10,
          ),
        ],
        border: Border.all(color: const Color(0xFFe9ecef)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'License Status',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 15),
          ...licenseData.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFf8f9fa),
                  borderRadius: BorderRadius.circular(8),
                  border: Border(
                    left: BorderSide(color: item['color'] as Color, width: 4),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item['status'].toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    Row(
                      children: [
                        SizedBox(
                          width: 100,
                          height: 8,
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color.fromRGBO(0, 123, 255, 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: item['count'] / totalLicenses,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF007bff),
                                        Color(0xFF0056b3),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          item['count'].toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: item['color'] as Color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// --- Recent Activities Section ---

class RecentActivitiesSection extends StatelessWidget {
  const RecentActivitiesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '🎯 Recent Activities',
      actions: const SizedBox.shrink(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: mockActivities
            .map((activity) => ActivityItem(activity: activity))
            .toList(),
      ),
    );
  }
}

class ActivityItem extends StatefulWidget {
  final Activity activity;

  const ActivityItem({super.key, required this.activity});

  @override
  State<ActivityItem> createState() => _ActivityItemState();
}

class _ActivityItemState extends State<ActivityItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        child: InkWell(
          onTap: () {
            // Show activity details
            showDialog(
              context: context,
              builder: (BuildContext dialogContext) {
                return AlertDialog(
                  title: Text(widget.activity.title),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.activity.description),
                      const SizedBox(height: 10),
                      Text(
                        'Time: ${widget.activity.time}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                );
              },
            );
          },
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: _isHovering
                  ? const Color(0xFFe9ecef)
                  : const Color(0xFFf8f9fa),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isHovering
                    ? const Color(0xFFced4da)
                    : const Color(0xFFe9ecef),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF007bff), Color(0xFF0056b3)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      widget.activity.icon,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.activity.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${widget.activity.description} • ${widget.activity.time}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Reusable Section Card Wrapper ---

class SectionCard extends StatelessWidget {
  final String title;
  final Widget actions;
  final Widget child;

  const SectionCard({
    super.key,
    required this.title,
    required this.actions,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            offset: Offset(0, 2),
            blurRadius: 10,
          ),
        ],
        border: Border.all(color: const Color(0xFFe9ecef)),
      ),
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              actions,
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

extension on BuildContext {
  bool get isLargeScreen {
    return MediaQuery.of(this).size.width > 768;
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
