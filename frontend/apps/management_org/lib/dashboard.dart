import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:main_login/main.dart' as main_login;
import 'package:core/api/api_service.dart';
import 'package:core/api/endpoints.dart';
import 'main.dart' as app;
import 'widgets/school_profile_header.dart';
import 'widgets/management_sidebar.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  // Safe navigation helper that ensures context is valid
  void _navigateToRoute(String route) {
    // Use the global navigator key to ensure correct navigation
    final navigator = app.SchoolManagementApp.navigatorKey.currentState;
    if (navigator != null) {
      if (navigator.canPop() || route != '/dashboard') {
        navigator.pushReplacementNamed(route);
      } else {
        navigator.pushNamed(route);
      }
    }
  }

  List<Map<String, dynamic>> _recentTeachers = [];
  List<Map<String, dynamic>> _recentStudents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkFinancialRedirect();
    _fetchDashboardData();
  }

  void _checkFinancialRedirect() {
    final userRole = ApiService().userRole;
    if (userRole == 'financial') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToRoute('/fees');
      });
    }
  }

  Future<void> _fetchDashboardData() async {
    final api = ApiService();
    try {
      final responses = await Future.wait([
        api.get(Endpoints.teachers),
        api.get(Endpoints.students),
        api.get(Endpoints.gallery),
      ]);

      if (mounted) {
        setState(() {
          // Process Teachers
          if (responses[0].success && responses[0].data != null) {
            final data = responses[0].data;
            final List<dynamic> list = data is List ? data : (data['results'] is List ? data['results'] : []);
            
            _recentTeachers = list.take(5).map((t) {
              final Map<String, dynamic> user = t['user'] is Map ? t['user'] : {};
              final String firstName = t['first_name'] ?? user['first_name'] ?? '';
              final String lastName = t['last_name'] ?? user['last_name'] ?? '';
              final String fullName = '$firstName $lastName'.trim();
              final String name = fullName.isNotEmpty ? fullName : (t['name'] ?? 'Unknown Teacher');
              
              final String initials = name.isNotEmpty 
                  ? name.split(' ').take(2).map((e) => e.isNotEmpty ? e[0] : '').join()
                  : 'T';

              return {
                'name': name,
                'designation': t['subject'] ?? t['designation'] ?? 'Teacher',
                'initials': initials.toUpperCase(),
              };
            }).toList().cast<Map<String, dynamic>>();
          }

          // Process Students
          if (responses[1].success && responses[1].data != null) {
             final data = responses[1].data;
            final List<dynamic> list = data is List ? data : (data['results'] is List ? data['results'] : []);

            _recentStudents = list.take(5).map((s) {
              final Map<String, dynamic> user = s['user'] is Map ? s['user'] : {};
              final String firstName = s['first_name'] ?? user['first_name'] ?? '';
              final String lastName = s['last_name'] ?? user['last_name'] ?? '';
              final String fullName = '$firstName $lastName'.trim();
              final String name = fullName.isNotEmpty ? fullName : (s['student_name'] ?? s['name'] ?? 'Unknown Student');

              final String initials = name.isNotEmpty 
                  ? name.split(' ').take(2).map((e) => e.isNotEmpty ? e[0] : '').join()
                  : 'S';

              return {
                'name': name,
                'class': s['class_name'] ?? s['applying_class'] ?? '',
                'section': s['section'] ?? '',
                'initials': initials.toUpperCase(),
              };
            }).toList().cast<Map<String, dynamic>>();
          }

          // Process Gallery
          if (responses[2].success && responses[2].data != null) {
            final data = responses[2].data;
            final List<dynamic> list = data is List ? data : (data['results'] is List ? data['results'] : []);
            
            _galleryItems = list.take(3).map((item) {
              String imageUrl = '';
              if (item['images'] != null && (item['images'] as List).isNotEmpty) {
                final firstImage = (item['images'] as List).first;
                imageUrl = firstImage['image'] ?? '';
                // Fix relative URLs from backend
                if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
                  final baseUrl = Endpoints.baseUrl.split('/api')[0];
                  imageUrl = '$baseUrl$imageUrl';
                }
              }
              
              return {
                'id': item['id'],
                'title': item['title'] ?? 'Untitled Gallery',
                'category': item['category'] ?? 'General',
                'image': imageUrl.isNotEmpty ? imageUrl : 'https://via.placeholder.com/150',
                'date': item['date'] ?? '',
              };
            }).toList().cast<Map<String, dynamic>>();
          }
           _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching dashboard data: $e');
       if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showImageDialog(BuildContext context, Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                color: Colors.black.withValues(alpha: 0.7),
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      item['image'],
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(40),
                        child: const Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Column(
                    children: [
                      Text(
                        item['title'],
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      Text(
                        '${item['category']} • ${item['date']}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  final List<Map<String, dynamic>> _recentActivities = [
    {
      'icon': '🏀',
      'title': 'Basketball Practice',
      'description': 'Team practice session completed',
      'time': '2 hours ago',
    },
    {
      'icon': '🔬',
      'title': 'Science Club Meeting',
      'description': 'New experiment planning session',
      'time': '4 hours ago',
    },
    {
      'icon': '🎵',
      'title': 'Music Band Rehearsal',
      'description': 'Spring concert preparation',
      'time': '6 hours ago',
    },
    {
      'icon': '📚',
      'title': 'Debate Club',
      'description': 'Regional competition preparation',
      'time': '1 day ago',
    },
    {
      'icon': '♟️',
      'title': 'Chess Tournament',
      'description': 'Inter-school chess competition',
      'time': '1 day ago',
    },
  ];

  final List<Map<String, dynamic>> _recentNotifications = [
    {
      'icon': '⚠️',
      'title': 'Bus Delay',
      'description': 'Bus #1 running 10 minutes late',
      'time': '1 hour ago',
    },
    {
      'icon': '📝',
      'title': 'Exam Schedule',
      'description': 'Mid-term exam schedule updated',
      'time': '3 hours ago',
    },
    {
      'icon': '👨‍🏫',
      'title': 'Teacher Absence',
      'description': 'Ms. White will be absent tomorrow',
      'time': '4 hours ago',
    },
    {
      'icon': '📚',
      'title': 'Library Notice',
      'description': 'New books available in library',
      'time': '1 day ago',
    },
    {
      'icon': '🎯',
      'title': 'Sports Event',
      'description': 'Annual sports day next week',
      'time': '1 day ago',
    },
  ];

  final List<Map<String, dynamic>> _recentAwards = [
    {
      'name': 'Best Academic Performance',
      'student': 'Alice Brown',
      'category': 'Academic',
      'date': '2024-01-15',
    },
    {
      'name': 'Sports Excellence',
      'student': 'Charlie Wilson',
      'category': 'Sports',
      'date': '2024-01-20',
    },
    {
      'name': 'Cultural Achievement',
      'student': 'Diana Davis',
      'category': 'Cultural',
      'date': '2024-01-25',
    },
    {
      'name': 'Leadership Award',
      'student': 'Ethan Miller',
      'category': 'Leadership',
      'date': '2024-01-30',
    },
  ];

  List<Map<String, dynamic>> _galleryItems = [];

  final List<Map<String, dynamic>> _recentAdmissions = [
    {
      'name': 'Rahul Sharma',
      'class': '10th',
      'status': 'Approved',
      'date': '2024-01-28',
    },
    {
      'name': 'Priya Patel',
      'class': '9th',
      'status': 'Pending',
      'date': '2024-01-27',
    },
    {
      'name': 'Amit Kumar',
      'class': '11th',
      'status': 'Approved',
      'date': '2024-01-26',
    },
    {
      'name': 'Neha Singh',
      'class': '12th',
      'status': 'Under Review',
      'date': '2024-01-25',
    },
  ];

  final List<Map<String, dynamic>> _rtiRequests = [
    {
      'id': 1,
      'title': 'Student Records Request',
      'requester': 'Mr. Robert Brown',
      'status': 'Pending',
      'date': '2024-01-28',
    },
    {
      'id': 2,
      'title': 'Financial Information',
      'requester': 'Ms. Sarah Wilson',
      'status': 'Approved',
      'date': '2024-01-25',
    },
    {
      'id': 3,
      'title': 'Infrastructure Details',
      'requester': 'Mr. David Davis',
      'status': 'In Progress',
      'date': '2024-01-22',
    },
  ];


  @override
  Widget build(BuildContext context) {
    final gradient = const LinearGradient(
      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Check if Android platform
        final isAndroid = defaultTargetPlatform == TargetPlatform.android;
        // For desktop, use width-based check; for Android, always show drawer
        final showSidebar = !isAndroid && constraints.maxWidth >= 1100;
        final showDrawer = isAndroid || (!isAndroid && constraints.maxWidth < 1100);
        
        return Scaffold(
          key: _scaffoldKey,
          drawer: showDrawer
              ? Drawer(
                  child: SizedBox(
                    width: 280,
                    child: ManagementSidebar(
                      gradient: gradient,
                      activeRoute: '/dashboard',
                    ),
                  ),
                )
              : null,
          body: isAndroid
              ? Container(
                  color: const Color(0xFFF5F6FA),
                  child: SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _Header(
                            showMenuButton: showDrawer,
                            onMenuTap: () =>
                                _scaffoldKey.currentState?.openDrawer(),
                            onLogout: () {
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
                          ),
                          const SizedBox(height: 12),
                          _StatsGrid(
                            onNavigate: (section) {
                              _navigateToRoute('/$section');
                            },
                            isAndroid: isAndroid,
                          ),
                          const SizedBox(height: 12),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _RecentTeachersSection(
                                teachers: _recentTeachers,
                              ),
                              const SizedBox(height: 12),
                              _RecentStudentsSection(
                                students: _recentStudents,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _AnalyticsSection(),
                          const SizedBox(height: 12),
                          _RecentActivitiesSection(
                            activities: _recentActivities,
                          ),
                          const SizedBox(height: 12),
                          _RecentNotificationsSection(
                            notifications: _recentNotifications,
                          ),
                          const SizedBox(height: 12),
                          _RecentAwardsSection(
                            awards: _recentAwards,
                          ),
                          const SizedBox(height: 12),
                          _GallerySection(
                            galleryItems: _galleryItems,
                            onItemTap: (item) => _showImageDialog(context, item),
                          ),
                          const SizedBox(height: 12),
                          _RecentAdmissionsSection(
                            admissions: _recentAdmissions,
                          ),
                          const SizedBox(height: 12),
                          _RTISection(
                            rtiRequests: _rtiRequests,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : Row(
                  children: [
                    if (showSidebar)
                      ManagementSidebar(
                        gradient: gradient,
                        activeRoute: '/dashboard',
                      ),
                    Expanded(
                      child: Container(
                        color: const Color(0xFFF5F6FA),
                        child: SafeArea(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                          _Header(
                            showMenuButton: showDrawer,
                            onMenuTap: () =>
                                _scaffoldKey.currentState?.openDrawer(),
                            onLogout: () {
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
                          ),
                          SizedBox(height: isAndroid ? 16 : 24),
                          _StatsGrid(
                            onNavigate: (section) {
                              _navigateToRoute('/$section');
                            },
                            isAndroid: isAndroid,
                          ),
                          SizedBox(height: isAndroid ? 16 : 24),
                          LayoutBuilder(
                            builder: (context, inner) {
                              final stacked = inner.maxWidth < 800;
                              return Flex(
                                mainAxisSize: MainAxisSize.min,
                                direction:
                                    stacked ? Axis.vertical : Axis.horizontal,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _RecentTeachersSection(
                                      teachers: _recentTeachers,
                                    ),
                                  ),
                                  SizedBox(
                                    width: stacked ? 0 : 24,
                                    height: stacked ? 24 : 0,
                                  ),
                                  Expanded(
                                    child: _RecentStudentsSection(
                                      students: _recentStudents,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          _AnalyticsSection(),
                          const SizedBox(height: 24),
                          _RecentActivitiesSection(
                            activities: _recentActivities,
                          ),
                          const SizedBox(height: 24),
                          _RecentNotificationsSection(
                            notifications: _recentNotifications,
                          ),
                          const SizedBox(height: 24),
                          _RecentAwardsSection(
                            awards: _recentAwards,
                          ),
                          const SizedBox(height: 24),
                          _GallerySection(
                            galleryItems: _galleryItems,
                            onItemTap: (item) => _showImageDialog(context, item),
                          ),
                          const SizedBox(height: 24),
                          _RecentAdmissionsSection(
                            admissions: _recentAdmissions,
                          ),
                          const SizedBox(height: 24),
                          _RTISection(
                            rtiRequests: _rtiRequests,
                          ),
                        ],
                      ),
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
}





class _Header extends StatelessWidget {
  final bool showMenuButton;
  final VoidCallback? onMenuTap;
  final VoidCallback onLogout;

  const _Header({
    required this.showMenuButton,
    this.onMenuTap,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    
    return Container(
      padding: EdgeInsets.all(isAndroid ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(isAndroid ? 12 : 15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: isAndroid ? 12 : 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (showMenuButton)
                IconButton(
                  onPressed: onMenuTap,
                  icon: Icon(
                    Icons.menu,
                    color: Colors.black87,
                    size: isAndroid ? 24 : 28,
                  ),
                ),
              Text(
                'Management Dashboard',
                style: TextStyle(
                  fontSize: isAndroid ? 20 : 28,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          Row(
            children: [
              SchoolProfileHeader(apiService: ApiService()),
              const SizedBox(width: 15),
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
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B6B),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatefulWidget {
  final ValueChanged<String> onNavigate;
  final bool isAndroid;

  const _StatsGrid({
    required this.onNavigate,
    this.isAndroid = false,
  });

  @override
  State<_StatsGrid> createState() => _StatsGridState();
}

class _StatsGridState extends State<_StatsGrid> {
  Map<String, String> _counts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    final api = ApiService();
    final Map<String, String> newCounts = {};

    Future<void> fetchCount(String key, String endpoint) async {
      try {
        final response = await api.get(endpoint);
        if (response.success && response.data != null) {
          if (response.data is List) {
            newCounts[key] = (response.data as List).length.toString();
          } else if (response.data is Map) {
            if (response.data.containsKey('count')) {
              newCounts[key] = response.data['count'].toString();
            } else if (response.data.containsKey('results') && response.data['results'] is List) {
              newCounts[key] = (response.data['results'] as List).length.toString();
            }
          }
        }
      } catch (e) {
        debugPrint('Error fetching $key: $e');
      }
    }

    await Future.wait([
      fetchCount('admissions', Endpoints.admissions),
      fetchCount('teachers', Endpoints.teachers),
      fetchCount('students', Endpoints.students),
      fetchCount('buses', Endpoints.buses),
      fetchCount('examinations', Endpoints.examinations),
      fetchCount('fees', Endpoints.fees),
      fetchCount('notifications', Endpoints.pushNotificationLogs),
      fetchCount('activities', Endpoints.activities),
      fetchCount('bus_routes', Endpoints.busRoutes),
      fetchCount('events', Endpoints.events),
      fetchCount('calendar', Endpoints.calendar),
      fetchCount('awards', Endpoints.awards),
      fetchCount('gallery', Endpoints.gallery),
      fetchCount('campus_life', Endpoints.campusLife),
      fetchCount('departments', Endpoints.departments),
      fetchCount('financial_staff', Endpoints.financialUsers),
    ]);

    if (mounted) {
      setState(() {
        _counts = newCounts;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = [
      {
        'icon': '🎓',
        'number': _isLoading ? '...' : (_counts['admissions'] ?? '0'),
        'label': 'Admissions',
        'description': 'Click to manage new admissions',
        'color': const Color(0xFFFF6347),
        'route': 'admissions',
      },
      {
        'icon': '👨‍🏫',
        'number': _isLoading ? '...' : (_counts['teachers'] ?? '0'),
        'label': 'Total Teachers',
        'description': 'Click to manage teachers',
        'color': const Color(0xFF667EEA),
        'route': 'teachers',
      },
      {
        'icon': '👥',
        'number': _isLoading ? '...' : (_counts['students'] ?? '0'),
        'label': 'Total Students',
        'description': 'Click to manage students',
        'color': const Color(0xFF764BA2),
        'route': 'students',
      },
      {
        'icon': '🚌',
        'number': _isLoading ? '...' : (_counts['buses'] ?? '0'),
        'label': 'Total Buses',
        'description': 'Click to manage bus routes',
        'color': const Color(0xFF4FACFE),
        'route': 'buses',
      },
      {
        'icon': '📝',
        'number': _isLoading ? '...' : (_counts['examinations'] ?? '0'),
        'label': 'Examination Section',
        'description': 'Click to manage exams',
        'color': const Color(0xFFFF6B35),
        'route': 'examinations',
      },
      {
        'icon': '💼',
        'number': _isLoading ? '...' : (_counts['financial_staff'] ?? '0'),
        'label': 'Financial Staff',
        'description': 'Click to view profiles',
        'color': const Color(0xFF607D8B),
        'route': 'financial-profiles',
      },
      {
        'icon': '💰',
        'number': _isLoading ? '...' : (_counts['fees'] ?? '0'),
        'label': 'Fees',
        'description': 'Click to manage fee structure',
        'color': const Color(0xFF28A745),
        'route': 'fees',
      },
      {
        'icon': '🔔',
        'number': _isLoading ? '...' : (_counts['notifications'] ?? '0'),
        'label': 'Notifications',
        'description': 'Important updates',
        'color': const Color(0xFFFED6E3),
        'route': 'notifications',
      },
      {
        'icon': '🎯',
        'number': _isLoading ? '...' : (_counts['activities'] ?? '0'),
        'label': 'Activities',
        'description': 'Click to manage activities',
        'color': const Color(0xFFA8EDEA),
        'route': 'activities',
      },
      {
        'icon': '📅',
        'number': _isLoading ? '...' : (_counts['events'] ?? '0'),
        'label': 'Events',
        'description': 'Click to manage events',
        'color': const Color(0xFFFA709A),
        'route': 'events',
      },
      {
        'icon': '📊',
        'number': _isLoading ? '...' : (_counts['calendar'] ?? '0'),
        'label': 'Calendar Events',
        'description': 'Upcoming activities',
        'color': const Color(0xFF43E97B),
        'route': 'calendar',
      },
      {
        'icon': '🏆',
        'number': _isLoading ? '...' : (_counts['awards'] ?? '0'),
        'label': 'Awards',
        'description': 'Click to manage awards',
        'color': const Color(0xFFFFD700),
        'route': 'awards',
      },
      {
        'icon': '📸',
        'number': _isLoading ? '...' : (_counts['gallery'] ?? '0'),
        'label': 'Photo Gallery',
        'description': 'Click to manage photos',
        'color': const Color(0xFFFF69B4),
        'route': 'gallery',
      },
      {
        'icon': '📋',
        'number': '3', // Keep hardcoded as no endpoint found
        'label': 'RTI Act',
        'description': 'Right to Information',
        'color': const Color(0xFF20B2AA),
        'route': null,
      },
      {
        'icon': '🏫',
        'number': _isLoading ? '...' : (_counts['campus_life'] ?? '0'),
        'label': 'Campus Life',
        'description': 'Campus speciality',
        'color': const Color(0xFF32CD32),
        'route': 'campus-life',
      },
      {
        'icon': '🏢',
        'number': _isLoading ? '...' : (_counts['departments'] ?? '0'),
        'label': 'Departments',
        'description': 'Academic departments',
        'color': const Color(0xFF6F42C1),
        'route': 'departments',
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Validate constraints - ensure they're bounded
        // Use MediaQuery as fallback if constraints are invalid
        final screenWidth = MediaQuery.of(context).size.width;
        final validWidth = constraints.maxWidth.isInfinite || constraints.maxWidth <= 0
            ? screenWidth
            : constraints.maxWidth;
        
        // Calculate responsive columns based on screen width
        int crossAxisCount;
        double childAspectRatio;
        double crossAxisSpacing;
        double mainAxisSpacing;
        
        if (widget.isAndroid) {
          // Android-specific layout - 2 columns with optimized spacing
          crossAxisCount = 2;
          // Use a more conservative aspect ratio for Android - taller cards to prevent overflow
          // Calculate based on available width to ensure cards are tall enough
          final cardWidth = (validWidth - 8) / 2;
          final minCardHeight = 120.0; // Minimum height to prevent overflow
          childAspectRatio = (cardWidth / minCardHeight).clamp(0.85, 1.0);
          crossAxisSpacing = 8; // Further reduced spacing for Android
          mainAxisSpacing = 8;
        } else {
          // Desktop layout - existing logic
          final width = validWidth;
          if (width > 1600) {
            crossAxisCount = 6;
            childAspectRatio = 1.4;
          } else if (width > 1200) {
            crossAxisCount = 4;
            childAspectRatio = 1.4;
          } else if (width > 900) {
            crossAxisCount = 3;
            childAspectRatio = 1.4;
          } else if (width > 600) {
            crossAxisCount = 2;
            childAspectRatio = 1.3;
          } else {
            crossAxisCount = 1;
            childAspectRatio = 1.5;
          }
          crossAxisSpacing = 20;
          mainAxisSpacing = 15;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: mainAxisSpacing,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) {
            final stat = stats[index];
            return _StatCard(
              icon: stat['icon'] as String,
              number: stat['number'] as String,
              label: stat['label'] as String,
              description: stat['description'] as String,
              color: stat['color'] as Color,
              onTap: stat['route'] != null
                  ? () => widget.onNavigate(stat['route'] as String)
                  : null,
              isAndroid: widget.isAndroid,
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatefulWidget {
  final String icon;
  final String number;
  final String label;
  final String description;
  final Color color;
  final VoidCallback? onTap;
  final bool isAndroid;

  const _StatCard({
    required this.icon,
    required this.number,
    required this.label,
    required this.description,
    required this.color,
    this.onTap,
    this.isAndroid = false,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
          cursor: widget.isAndroid ? SystemMouseCursors.basic : SystemMouseCursors.click,
          onEnter: (_) {
            if (!widget.isAndroid) setState(() => _isHovered = true);
          },
          onExit: (_) {
            if (!widget.isAndroid) setState(() => _isHovered = false);
          },
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              transform: Matrix4.identity()
                ..translate(0.0, (!widget.isAndroid && _isHovered) ? -8.0 : 0.0),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(widget.isAndroid ? 12 : 15),
                border: Border(
                  left: BorderSide(
                    color: widget.color,
                    width: widget.isAndroid ? 4 : 5,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: (!widget.isAndroid && _isHovered) ? 0.15 : 0.1,
                    ),
                    blurRadius: (!widget.isAndroid && _isHovered) ? 16 : 12,
                    offset: Offset(0, (!widget.isAndroid && _isHovered) ? 6 : 4),
                  ),
                ],
              ),
          child: Stack(
            children: [
              if (!widget.isAndroid && _isHovered)
                Positioned(
                  top: 0,
                  left: 5,
                  right: 0,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.color,
                          const Color(0xFF667EEA),
                          const Color(0xFF764BA2),
                        ],
                        stops: const [0.0, 0.3, 1.0],
                        begin: Alignment.topLeft,
                        end: Alignment.topRight,
                      ),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(widget.isAndroid ? 12 : 15),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.all(widget.isAndroid ? 10 : 16),
                child: LayoutBuilder(
                  builder: (context, cardConstraints) {
                    return FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: cardConstraints.maxHeight * 0.95,
                          maxWidth: cardConstraints.maxWidth * 0.95,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.icon,
                              style: TextStyle(
                                fontSize: widget.isAndroid ? 24 : 32,
                              ),
                            ),
                            SizedBox(height: widget.isAndroid ? 6 : 10),
                            Text(
                              widget.number,
                              style: TextStyle(
                                fontSize: widget.isAndroid ? 22 : 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: widget.isAndroid ? 2 : 4),
                            Text(
                              widget.label,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: widget.isAndroid ? 12 : 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: widget.isAndroid ? 1 : 6),
                            Text(
                              widget.description,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: widget.isAndroid ? 9 : 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentTeachersSection extends StatelessWidget {
  final List<Map<String, dynamic>> teachers;

  const _RecentTeachersSection({required this.teachers});

  @override
  Widget build(BuildContext context) {

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text('👨‍🏫', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 10),
                  Text(
                    'Recent Teachers',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton(
                  onPressed: () {
                    app.SchoolManagementApp.navigatorKey.currentState?.pushReplacementNamed('/teachers');
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('View All'),
                      SizedBox(width: 5),
                      Icon(Icons.arrow_forward, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...teachers.map((teacher) => _ListItem(
                avatar: teacher['initials'] as String,
                title: teacher['name'] as String,
                subtitle: teacher['designation'] as String,
                onTap: () {
                  app.SchoolManagementApp.navigatorKey.currentState?.pushReplacementNamed('/teachers');
                },
              )),
        ],
      ),
    );
  }
}

class _RecentStudentsSection extends StatelessWidget {
  final List<Map<String, dynamic>> students;

  const _RecentStudentsSection({required this.students});

  @override
  Widget build(BuildContext context) {

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text('👥', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 10),
                  Text(
                    'Recent Students',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton(
                  onPressed: () {
                    app.SchoolManagementApp.navigatorKey.currentState?.pushReplacementNamed('/students');
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('View All'),
                      SizedBox(width: 5),
                      Icon(Icons.arrow_forward, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...students.map((student) => _ListItem(
                avatar: student['initials'] as String,
                title: student['name'] as String,
                subtitle:
                    '${student['class']} • Section ${student['section']}',
                onTap: () {
                  app.SchoolManagementApp.navigatorKey.currentState?.pushReplacementNamed('/students');
                },
              )),
        ],
      ),
    );
  }
}

class _ListItem extends StatefulWidget {
  final String avatar;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ListItem({
    required this.avatar,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  State<_ListItem> createState() => _ListItemState();
}

class _ListItemState extends State<_ListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: _isHovered
                ? null
                : Colors.white.withValues(alpha: 0.7),
            gradient: _isHovered
                ? const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  )
                : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                ),
                child: Center(
                  child: Text(
                    widget.avatar,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _isHovered ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: _isHovered ? Colors.white70 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalyticsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('📊 Analytics & Reports', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 800;
              return Flex(
                mainAxisSize: MainAxisSize.min,
                direction: stacked ? Axis.vertical : Axis.horizontal,
                children: [
                  Expanded(
                    child: _AttendanceChart(),
                  ),
                  if (!stacked) const SizedBox(width: 20),
                  if (stacked) const SizedBox(height: 20),
                  Expanded(
                    child: _PerformanceChart(),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AttendanceChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Adjusted data to match image: medium, lower, highest, lower, lowest, medium, medium
    final data = [75, 65, 95, 80, 55, 70, 75];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attendance Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(data.length, (index) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: double.infinity,
                          height: data[index] * 1.8,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          days[index],
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
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

class _PerformanceChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final data = [
      {'subject': 'Mathematics', 'score': 85},
      {'subject': 'Science', 'score': 92},
      {'subject': 'English', 'score': 78},
      {'subject': 'History', 'score': 88},
      {'subject': 'Computer Science', 'score': 95},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Academic Performance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          ...data.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        item['subject'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: (item['score'] as int) / 100,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 45,
                      child: Text(
                        '${item['score']}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF667EEA),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _RecentActivitiesSection extends StatelessWidget {
  final List<Map<String, dynamic>> activities;

  const _RecentActivitiesSection({required this.activities});

  @override
  Widget build(BuildContext context) {

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text('🎯', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 10),
                  Text(
                    'Recent Activities',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton(
                  onPressed: () {
                    app.SchoolManagementApp.navigatorKey.currentState?.pushReplacementNamed('/activities');
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('View All'),
                      SizedBox(width: 5),
                      Icon(Icons.arrow_forward, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...activities.map((activity) => _ActivityItem(
                icon: activity['icon'] as String,
                title: activity['title'] as String,
                description: activity['description'] as String,
                time: activity['time'] as String,
              )),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatefulWidget {
  final String icon;
  final String title;
  final String description;
  final String time;

  const _ActivityItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.time,
  });

  @override
  State<_ActivityItem> createState() => _ActivityItemState();
}

class _ActivityItemState extends State<_ActivityItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        padding: const EdgeInsets.all(15),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _isHovered
              ? null
              : Colors.white.withValues(alpha: 0.7),
          gradient: _isHovered
              ? const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                )
              : null,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
              ),
              child: Center(
                child: Text(
                  widget.icon,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _isHovered ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${widget.description} • ${widget.time}',
                    style: TextStyle(
                      fontSize: 12,
                      color: _isHovered ? Colors.white70 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _RecentNotificationsSection extends StatelessWidget {
  final List<Map<String, dynamic>> notifications;

  const _RecentNotificationsSection({required this.notifications});

  @override
  Widget build(BuildContext context) {

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Text('🔔', style: TextStyle(fontSize: 20)),
              SizedBox(width: 10),
              Text(
                'Recent Notifications',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...notifications.map((notification) => _NotificationItem(
                icon: notification['icon'] as String,
                title: notification['title'] as String,
                description: notification['description'] as String,
                time: notification['time'] as String,
              )),
        ],
      ),
    );
  }
}

class _NotificationItem extends StatefulWidget {
  final String icon;
  final String title;
  final String description;
  final String time;

  const _NotificationItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.time,
  });

  @override
  State<_NotificationItem> createState() => _NotificationItemState();
}

class _NotificationItemState extends State<_NotificationItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: _isHovered
              ? null
              : Colors.white.withValues(alpha: 0.7),
          gradient: _isHovered
              ? const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                )
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B6B), Color(0xFFEE5A52)],
                ),
              ),
              child: Center(
                child: Text(
                  widget.icon,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _isHovered ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${widget.description} • ${widget.time}',
                    style: TextStyle(
                      fontSize: 11,
                      color: _isHovered ? Colors.white70 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentAwardsSection extends StatelessWidget {
  final List<Map<String, dynamic>> awards;

  const _RecentAwardsSection({required this.awards});

  @override
  Widget build(BuildContext context) {

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text('🏆', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 10),
                  Text(
                    'Recent Awards',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton(
                  onPressed: () {
                    app.SchoolManagementApp.navigatorKey.currentState?.pushReplacementNamed('/awards');
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('View All'),
                      SizedBox(width: 5),
                      Icon(Icons.arrow_forward, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...awards.map((award) => _ListItem(
                avatar: '🏆',
                title: award['name'] as String,
                subtitle:
                    '${award['student']} • ${award['category']} • ${award['date']}',
                onTap: () {
                  app.SchoolManagementApp.navigatorKey.currentState?.pushReplacementNamed('/awards');
                },
              )),
        ],
      ),
    );
  }
}

class _GallerySection extends StatelessWidget {
  final List<Map<String, dynamic>> galleryItems;
  final Function(Map<String, dynamic>) onItemTap;

  const _GallerySection({required this.galleryItems, required this.onItemTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text('📸', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 10),
                  Text(
                    'Photo Gallery',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton(
                  onPressed: () {
                    app.SchoolManagementApp.navigatorKey.currentState?.pushReplacementNamed('/gallery');
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('View All'),
                      SizedBox(width: 5),
                      Icon(Icons.arrow_forward, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 800 ? 3 : constraints.maxWidth > 500 ? 2 : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 0.8,
                ),
                itemCount: galleryItems.length,
                itemBuilder: (context, index) => _GalleryItem(
                  item: galleryItems[index],
                  onTap: () => onItemTap(galleryItems[index]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GalleryItem extends StatefulWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;

  const _GalleryItem({required this.item, required this.onTap});

  @override
  State<_GalleryItem> createState() => _GalleryItemState();
}

class _GalleryItemState extends State<_GalleryItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: _isHovered
              ? (Matrix4.identity()..translate(0, -5))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              Expanded(
                flex: 3,
                child: Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.network(
                      widget.item['image'],
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.image_not_supported, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Content Section
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.item['title'] as String,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.item['date'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF667EEA).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.item['category'] as String,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF667EEA),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentAdmissionsSection extends StatelessWidget {
  final List<Map<String, dynamic>> admissions;

  const _RecentAdmissionsSection({required this.admissions});

  @override
  Widget build(BuildContext context) {

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text('🎓', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 10),
                  Text(
                    'Recent Admissions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton(
                  onPressed: () {
                    app.SchoolManagementApp.navigatorKey.currentState?.pushReplacementNamed('/admissions');
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('View All'),
                      SizedBox(width: 5),
                      Icon(Icons.arrow_forward, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...admissions.map((admission) => _ListItem(
                avatar: '🎓',
                title: admission['name'] as String,
                subtitle:
                    'Class ${admission['class']} • ${admission['status']} • ${admission['date']}',
                onTap: () {
                  app.SchoolManagementApp.navigatorKey.currentState?.pushReplacementNamed('/admissions');
                },
              )),
        ],
      ),
    );
  }
}

class _RTISection extends StatelessWidget {
  final List<Map<String, dynamic>> rtiRequests;

  const _RTISection({required this.rtiRequests});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text('📋', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 10),
                  Text(
                    'Right to Information Act',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton(
                  onPressed: () {
                    // RTI page can be added later if needed
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('RTI requests feature coming soon')),
                    );
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('View All'),
                      SizedBox(width: 5),
                      Icon(Icons.arrow_forward, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...rtiRequests.map((rti) => _RTIItem(
                title: rti['title'] as String,
                requester: rti['requester'] as String,
                status: rti['status'] as String,
                date: rti['date'] as String,
              )),
        ],
      ),
    );
  }
}

class _RTIItem extends StatefulWidget {
  final String title;
  final String requester;
  final String status;
  final String date;

  const _RTIItem({
    required this.title,
    required this.requester,
    required this.status,
    required this.date,
  });

  @override
  State<_RTIItem> createState() => _RTIItemState();
}

class _RTIItemState extends State<_RTIItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: _isHovered
              ? null
              : Colors.white.withValues(alpha: 0.7),
          gradient: _isHovered
              ? const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                )
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF667EEA),
              ),
              child: const Center(
                child: Icon(
                  Icons.description,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _isHovered ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${widget.requester} • ${widget.status} • ${widget.date}',
                    style: TextStyle(
                      fontSize: 12,
                      color: _isHovered ? Colors.white70 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


