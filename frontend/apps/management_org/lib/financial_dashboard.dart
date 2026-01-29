import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fees.dart';
import 'financial_profiles.dart';
import 'package:main_login/financial_login.dart';

// InheritedWidget to pass navigation function down the tree
class FinancialDashboardController extends InheritedWidget {
  final Function(String) onViewChanged;
  
  const FinancialDashboardController({
    Key? key,
    required this.onViewChanged,
    required Widget child,
  }) : super(key: key, child: child);
  
  static FinancialDashboardController? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<FinancialDashboardController>();
  }
  
  @override
  bool updateShouldNotify(FinancialDashboardController oldWidget) => false;
}

class FinancialDashboardPage extends StatefulWidget {
  const FinancialDashboardPage({super.key});

  @override
  State<FinancialDashboardPage> createState() => _FinancialDashboardPageState();
}

class _FinancialDashboardPageState extends State<FinancialDashboardPage> {
  String _currentView = 'fees'; // Default view
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void _changeView(String view) {
    print('Changing view to: $view');
    setState(() {
      _currentView = view;
    });
  }

  Widget _buildCurrentView() {
    print('Building view: $_currentView');
    switch (_currentView) {
      case 'fees':
        return const FeesManagementPage();
      case 'financial-profiles':
        return FinancialProfilesPage(
          onBackToFees: () {
            print('Back callback invoked');
            _changeView('fees');
          },
        );
      default:
        return const FeesManagementPage();
    }
  }

  void _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const FinancialLoginPage(),
          ),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradient = const LinearGradient(
      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final showSidebar = constraints.maxWidth >= 1100;
        
        return FinancialDashboardController(
          onViewChanged: _changeView,
          child: Scaffold(
            key: _scaffoldKey,
            drawer: showSidebar
                ? null
                : Drawer(
                    child: _FinancialSidebar(
                      gradient: gradient,
                      currentView: _currentView,
                      onViewChanged: _changeView,
                      onLogout: _handleLogout,
                    ),
                  ),
            body: Row(
              children: [
                if (showSidebar)
                  _FinancialSidebar(
                    gradient: gradient,
                    currentView: _currentView,
                    onViewChanged: _changeView,
                    onLogout: _handleLogout,
                  ),
                Expanded(
                  child: _buildCurrentView(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FinancialSidebar extends StatelessWidget {
  final LinearGradient gradient;
  final String currentView;
  final Function(String) onViewChanged;
  final VoidCallback onLogout;

  const _FinancialSidebar({
    required this.gradient,
    required this.currentView,
    required this.onViewChanged,
    required this.onLogout,
  });

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
                  _SidebarNavItem(
                    icon: '💰',
                    title: 'Fees',
                    isActive: currentView == 'fees',
                    onTap: () => onViewChanged('fees'),
                  ),
                  _SidebarNavItem(
                    icon: '💼',
                    title: 'Financial Staff',
                    isActive: currentView == 'financial-profiles',
                    onTap: () => onViewChanged('financial-profiles'),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: _SidebarNavItem(
                icon: '🚪',
                title: 'Logout',
                isActive: false,
                onTap: onLogout,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarNavItem extends StatefulWidget {
  final String icon;
  final String title;
  final VoidCallback? onTap;
  final bool isActive;

  const _SidebarNavItem({
    required this.icon,
    required this.title,
    this.onTap,
    this.isActive = false,
  });

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    if (widget.isActive) {
      backgroundColor = Colors.white.withOpacity(0.3);
    } else if (_isHovered) {
      backgroundColor = Colors.white.withOpacity(0.2);
    } else {
      backgroundColor = Colors.white.withOpacity(0.1);
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
          ),
        ),
      ),
    );
  }
}
