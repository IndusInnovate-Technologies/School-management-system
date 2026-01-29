import 'package:flutter/material.dart';
import 'package:core/api/api_service.dart';


import 'routes.dart';
import 'management_routes.dart';
import 'dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize ApiService to load stored tokens
  await ApiService().initialize();
  
  runApp(const SchoolManagementApp());
}

class SchoolManagementApp extends StatelessWidget {
  final String? initialRoute;
  
  const SchoolManagementApp({super.key, this.initialRoute});

  // Global navigator key to ensure routes work even when nested
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Helper method to navigate using the global navigator key
  static void navigateTo(String route, {Object? arguments}) {
    navigatorKey.currentState?.pushReplacementNamed(route, arguments: arguments);
  }

  // Helper to get the navigator - use this instead of Navigator.of(context)
  static NavigatorState? get navigator => navigatorKey.currentState;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'School Management System',
      debugShowCheckedModeBanner: false,
         theme: ThemeData(
           fontFamily: 'NotoSans',
           primarySwatch: Colors.indigo,
           useMaterial3: true,
         ),
      initialRoute: initialRoute ?? ManagementRoutes.dashboard,
      home: const DashboardPage(),
      routes: ManagementRoutePages.routes,
      onUnknownRoute: (settings) {
        // Fallback route handler - redirect to dashboard if route not found
        return MaterialPageRoute(
          builder: (_) => const DashboardPage(),
        );
      },
    );
  }
}
