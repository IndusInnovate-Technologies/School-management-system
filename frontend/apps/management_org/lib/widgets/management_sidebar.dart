import 'package:flutter/material.dart';
import '../main.dart' as app;

class ManagementSidebar extends StatelessWidget {
  final LinearGradient gradient;
  final String activeRoute;

  const ManagementSidebar({
    super.key,
    required this.gradient,
    required this.activeRoute,
  });

  // Safe navigation helper for sidebar
  void _navigateToRoute(BuildContext context, String route) {
    final navigator = Navigator.of(context);
    // If we are already on the route (or it's effectively a refresh), just ignore or handle as needed.
    // However, existing code used pushReplacementNamed typically.
    if (activeRoute == route) {
      return; // Do nothing if already on the page
    }
    
    if (navigator.canPop() || route != '/dashboard') {
      navigator.pushReplacementNamed(route);
    } else {
      navigator.pushNamed(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'packages/management_org/assets/Vidyarambh.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback if image is not found
                    return Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.school,
                        size: 56,
                        color: Color(0xFF667EEA),
                      ),
                    );
                  },
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Overview - Always at top
                  SidebarNavItem(
                    icon: '📊',
                    title: 'Overview',
                    isActive: activeRoute == '/dashboard',
                    onTap: () => _navigateToRoute(context, '/dashboard'),
                  ),
                  SidebarNavItem(
                    icon: '👨‍🏫',
                    title: 'Teachers',
                    isActive: activeRoute == '/teachers',
                    onTap: () => _navigateToRoute(context, '/teachers'),
                  ),
                  SidebarNavItem(
                    icon: '👥',
                    title: 'Students',
                    isActive: activeRoute == '/students',
                    onTap: () => _navigateToRoute(context, '/students'),
                  ),
                  SidebarNavItem(
                    icon: '💰',
                    title: 'Fees',
                    isActive: activeRoute == '/fees',
                    onTap: () => _navigateToRoute(context, '/fees'),
                  ),
                  SidebarNavItem(
                    icon: '🚌',
                    title: 'Buses',
                    isActive: activeRoute == '/buses',
                    onTap: () => _navigateToRoute(context, '/buses'),
                  ),
                  SidebarNavItem(
                    icon: '🎯',
                    title: 'Activities',
                    isActive: activeRoute == '/activities',
                    onTap: () => _navigateToRoute(context, '/activities'),
                  ),
                  SidebarNavItem(
                    icon: '📝',
                    title: 'Admissions',
                    isActive: activeRoute == '/admissions',
                    onTap: () => _navigateToRoute(context, '/admissions'),
                  ),
                  SidebarNavItem(
                    icon: '🏆',
                    title: 'Awards',
                    isActive: activeRoute == '/awards',
                    onTap: () => _navigateToRoute(context, '/awards'),
                  ),
                  SidebarNavItem(
                    icon: '🛠️',
                    title: 'Support Required',
                    isActive: activeRoute == '/support-request',
                    onTap: () => _navigateToRoute(context, '/support-request'),
                  ),
                  // B
                  SidebarNavItem(
                    icon: '🚌',
                    title: 'Buses',
                    isActive: activeRoute == '/buses',
                    onTap: () => _navigateToRoute(context, '/buses'),
                  ),
                  SidebarNavItem(
                    icon: '🛣️',
                    title: 'Bus Routes',
                    isActive: activeRoute == '/bus_routes',
                    onTap: () => _navigateToRoute(context, '/bus_routes'),
                  ),
                  // C
                  SidebarNavItem(
                    icon: '📆',
                    title: 'Calendar',
                    isActive: activeRoute == '/calendar',
                    onTap: () => _navigateToRoute(context, '/calendar'),
                  ),
                  SidebarNavItem(
                    icon: '🏫',
                    title: 'Campus Life',
                    isActive: activeRoute == '/campus-life',
                    onTap: () => _navigateToRoute(context, '/campus-life'),
                  ),
                  // D
                  SidebarNavItem(
                    icon: '🏢',
                    title: 'Departments',
                    isActive: activeRoute == '/departments',
                    onTap: () => _navigateToRoute(context, '/departments'),
                  ),
                  // E
                  SidebarNavItem(
                    icon: '📅',
                    title: 'Events',
                    isActive: activeRoute == '/events',
                    onTap: () => _navigateToRoute(context, '/events'),
                  ),
                  SidebarNavItem(
                    icon: '📖',
                    title: 'Examinations',
                    isActive: activeRoute == '/examinations',
                    onTap: () => _navigateToRoute(context, '/examinations'),
                  ),
                  // F
                  SidebarNavItem(
                    icon: '💰',
                    title: 'Fees',
                    isActive: activeRoute == '/fees',
                    onTap: () => _navigateToRoute(context, '/fees'),
                  ),
                  SidebarNavItem(
                    icon: '💼',
                    title: 'Financial Staff',
                    isActive: activeRoute == '/financial-profiles',
                    onTap: () => _navigateToRoute(context, '/financial-profiles'),
                  ),
                  // N
                  SidebarNavItem(
                    icon: '🔔',
                    title: 'Notifications',
                    isActive: activeRoute == '/notifications',
                    onTap: () => _navigateToRoute(context, '/notifications'),
                  ),
                  // P
                  SidebarNavItem(
                    icon: '📸',
                    title: 'Photo Gallery',
                    isActive: activeRoute == '/gallery',
                    onTap: () => _navigateToRoute(context, '/gallery'),
                  ),
                  // R
                  SidebarNavItem(
                    icon: '📋',
                    title: 'RTI Act',
                    isActive: activeRoute == '/rti-act',
                    onTap: () => _navigateToRoute(context, '/rti-act'),
                  ),
                  // S
                  SidebarNavItem(
                    icon: '👥',
                    title: 'Students',
                    isActive: activeRoute == '/students',
                    onTap: () => _navigateToRoute(context, '/students'),
                  ),
                  // T
                  SidebarNavItem(
                    icon: '👨‍🏫',
                    title: 'Teachers',
                    isActive: activeRoute == '/teachers',
                    onTap: () => _navigateToRoute(context, '/teachers'),
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

class SidebarNavItem extends StatefulWidget {
  final String icon;
  final String title;
  final VoidCallback? onTap;
  final bool isActive;

  const SidebarNavItem({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
    this.isActive = false,
  });

  @override
  State<SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<SidebarNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Determine background color based on state
    Color backgroundColor;
    if (widget.isActive) {
      backgroundColor = Colors.white.withOpacity(0.3);
    } else if (_isHovered) {
      backgroundColor = Colors.white.withOpacity(0.2); // Hover effect
    } else {
      backgroundColor = Colors.white.withOpacity(0.1); // Default
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: ListTile(
            leading: Text(
              widget.icon,
              style: const TextStyle(fontSize: 18),
            ),
            title: Text(
              widget.title,
              style: TextStyle(
                color: Colors.white,
                fontWeight: widget.isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            // We handle tap in GestureDetector for entire container
          ),
        ),
      ),
    );
  }
}
