import 'package:flutter/material.dart';
import 'admin_login.dart';
import 'management_login.dart';
import 'teacher_login.dart';
import 'parent_login.dart';

void main() {
  runApp(const SchoolApp());
}

class SchoolApp extends StatelessWidget {
  const SchoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'School Management Login',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF667EEA)),
        fontFamily: 'Segoe UI',
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String selectedRole = 'admin';

  final Map<String, String> roleNames = {
    'admin': 'Admin',
    'management': 'Management',
    'teacher': 'Teacher',
    'parent': 'Parent/Student',
  };

  void _navigateToLoginPage(BuildContext context, String role) {
    Widget loginPage;
    
    switch (role) {
      case 'admin':
        loginPage = const AdminLoginPage();
        break;
      case 'management':
        loginPage = const ManagementLoginPage();
        break;
      case 'teacher':
        loginPage = const TeacherLoginPage();
        break;
      case 'parent':
        loginPage = const ParentLoginPage();
        break;
      default:
        loginPage = const AdminLoginPage();
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => loginPage),
    );
  }

  Widget roleTile(String role, IconData icon, String title, String subtitle) {
    final bool active = selectedRole == role;

    return LayoutBuilder(
      builder: (context, constraints) {
        // More aggressive size detection for very small screens
        final isVerySmall = constraints.maxHeight < 50 || constraints.maxWidth < 70;
        final isSmall = constraints.maxHeight < 60 || constraints.maxWidth < 80;
        
        // Calculate sizes based on available space
        final availableHeight = constraints.maxHeight;
        
        // Dynamic sizing based on available space
        final iconSize = isVerySmall 
            ? (availableHeight * 0.35).clamp(14.0, 18.0)
            : isSmall 
                ? 18.0 
                : 22.0;
        final titleSize = isVerySmall
            ? (availableHeight * 0.18).clamp(9.0, 11.0)
            : isSmall 
                ? 11.0 
                : 13.0;
        final subtitleSize = isVerySmall
            ? (availableHeight * 0.15).clamp(8.0, 9.0)
            : isSmall 
                ? 9.0 
                : 10.0;
        final padding = isVerySmall ? 4.0 : (isSmall ? 6.0 : 12.0);
        final spacing = isVerySmall ? 2.0 : (isSmall ? 3.0 : 6.0);
        final checkRadius = isVerySmall ? 6.0 : (isSmall ? 8.0 : 10.0);

        return GestureDetector(
          onTap: () => setState(() => selectedRole = role),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              gradient: active
                  ? const LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    )
                  : const LinearGradient(
                      colors: [Color(0xFFF8F9FA), Color(0xFFE9ECEF)],
                    ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: active ? const Color(0xFF667EEA) : const Color(0xFFDEE2E6),
                width: 2,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: const Color(0xFF667EEA).withOpacity(0.35),
                        blurRadius: 30,
                        offset: const Offset(0, 14),
                      ),
                    ]
                  : [],
            ),
            child: Stack(
              children: [
                Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: availableHeight * 0.9,
                        maxWidth: double.infinity,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            icon,
                            size: iconSize,
                            color: active ? Colors.white : Colors.black87,
                          ),
                          SizedBox(height: spacing),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: titleSize,
                              fontWeight: FontWeight.bold,
                              color: active ? Colors.white : Colors.black,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: isVerySmall ? 0.5 : (isSmall ? 1.0 : 2.0)),
                            child: Text(
                              subtitle,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: subtitleSize,
                                color: active ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (active)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: CircleAvatar(
                      radius: checkRadius,
                      backgroundColor: Colors.white.withOpacity(0.25),
                      child: Icon(Icons.check, size: checkRadius * 1.2, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667EEA), Color(0xFF764BA2), Color(0xFFF093FB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width < 350 
                    ? 12 
                    : MediaQuery.of(context).size.width < 400 
                        ? 16 
                        : 24,
                vertical: MediaQuery.of(context).size.height < 600 ? 12 : 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xF2FFFFFF),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x2E000000),
                        blurRadius: 35,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width < 350 
                          ? 16 
                          : MediaQuery.of(context).size.width < 400 
                              ? 20 
                              : 25,
                      vertical: MediaQuery.of(context).size.height < 600 ? 16 : 20,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ShaderMask(
                        shaderCallback: (Rect bounds) => const LinearGradient(
                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                        ).createShader(bounds),
                        child: Text(
                          'School Management',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width < 350 
                                ? 24 
                                : MediaQuery.of(context).size.width < 400 
                                    ? 28 
                                    : 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      SizedBox(
                        height: MediaQuery.of(context).size.height < 600 ? 4 : 6,
                      ),

                      Text(
                        'Choose your role to continue',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width < 350 
                              ? 12 
                              : MediaQuery.of(context).size.width < 400 
                                  ? 14 
                                  : 16,
                          color: Colors.black54,
                        ),
                      ),

                      SizedBox(
                        height: MediaQuery.of(context).size.height < 600 ? 16 : 20,
                      ),

                      /// Grid UI - Responsive Layout
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final screenWidth = MediaQuery.of(context).size.width;
                          final screenHeight = MediaQuery.of(context).size.height;
                          final isVerySmall = screenWidth < 350;
                          final isSmallScreen = screenHeight < 600;
                          final spacing = isVerySmall ? 8.0 : 12.0;
                          // Calculate aspect ratio based on available width
                          // More space = taller cards, less space = shorter cards
                          final availableWidth = constraints.maxWidth;
                          final cardWidth = (availableWidth - spacing) / 2;
                          // Ensure minimum height for content - increased for very small screens
                          // Use a more conservative approach: ensure cards are tall enough
                          final minHeight = isVerySmall 
                              ? 100.0  // Taller cards for very small screens to prevent overflow
                              : isSmallScreen 
                                  ? 110.0 
                                  : 120.0;
                          // Calculate aspect ratio - smaller ratio = taller cards
                          // For very small screens, use a more conservative ratio
                          final baseAspectRatio = cardWidth / minHeight;
                          // Clamp to ensure cards are tall enough to prevent overflow
                          // Lower aspect ratio = taller cards = more space for content
                          final finalAspectRatio = isVerySmall
                              ? baseAspectRatio.clamp(0.9, 1.3)  // Even more conservative for very small
                              : baseAspectRatio.clamp(1.0, 1.5);

                          return GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: spacing,
                            mainAxisSpacing: spacing,
                            childAspectRatio: finalAspectRatio,
                            children: [
                              roleTile(
                                'admin',
                                Icons.business_center_rounded,
                                'Admin',
                                'Full access',
                              ),
                              roleTile(
                                'management',
                                Icons.apartment_rounded,
                                'Management',
                                'Control access',
                              ),
                              roleTile(
                                'teacher',
                                Icons.school,
                                'Teacher',
                                'Academic access',
                              ),
                              roleTile(
                                'parent',
                                Icons.family_restroom,
                                'Parent',
                                'Student access',
                              ),
                            ],
                          );
                        },
                      ),

                      SizedBox(
                        height: MediaQuery.of(context).size.height < 600 ? 20 : 24,
                      ),

                      /// 🔥 Dynamic Footer Button
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF667EEA),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            // Navigate to the appropriate login page based on selected role
                            _navigateToLoginPage(context, selectedRole);
                          },
                          child: Text(
                            "Login with your ${roleNames[selectedRole]} credentials",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}
