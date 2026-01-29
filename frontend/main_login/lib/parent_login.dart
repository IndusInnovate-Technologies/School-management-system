import 'package:flutter/material.dart';
import 'main.dart';

import 'package:core/api/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parent_app/main.dart' as parent;
import 'create_password.dart';
import 'forgot_password_flow.dart';
import 'dart:math';
import 'dart:developer' as dev;

void main() {
  runApp(const ParentLoginPage());
}

class ParentLoginPage extends StatefulWidget {
  const ParentLoginPage({super.key});

  @override
  State<ParentLoginPage> createState() => _ParentLoginPageState();
}

class _ParentLoginPageState extends State<ParentLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;

    // All validation and login logic is handled by the backend
    setState(() {
      _isLoading = true;
    });

    final authService = AuthService();
    final result = await authService.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      role: 'parent',
    );

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Login attempt completed'),
          backgroundColor: result['success']
              ? const Color(0xFF667EEA)
              : Colors.red,
        ),
      );

      if (result['success']) {
        // Check if user needs to create password
        final needsPasswordCreation = result['needs_password_creation'] as bool? ?? false;
        
        if (needsPasswordCreation) {
          // Navigate to create password page
          final passwordCreated = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreatePasswordPage(
                role: 'parent',
                userData: result['user'],
                tokens: result['tokens'],
                routes: result['routes'],
              ),
            ),
          );
          
          // If password was created successfully, navigate back to role selection
          if (passwordCreated == true && mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const LoginScreen(),
              ),
              (route) => false, // Remove all previous routes
            );
          }
        } else {
          // Cache school details if available
          try {
            final user = result['user'];
            if (user != null && user is Map) {
              final prefs = await SharedPreferences.getInstance();
              
              // Try to extract school name
              String? schoolName = user['school_name']?.toString();
              // If not directly available, check nested school object
              if (schoolName == null && user['school'] is Map) {
                schoolName = user['school']['school_name']?.toString() ?? 
                           user['school']['name']?.toString();
              }
              
              if (schoolName != null && schoolName.isNotEmpty) {
                await prefs.setString('school_name', schoolName);
              }
              
              // Try to extract logo URL
              String? logoUrl = user['logo_url']?.toString();
              if (logoUrl == null && user['school'] is Map) {
                logoUrl = user['school']['logo_url']?.toString();
              }
              
              if (logoUrl != null && logoUrl.isNotEmpty) {
                await prefs.setString('logo_url', logoUrl);
              }
            }
          } catch (e) {
            debugPrint('Error caching school details: $e');
          }

          // Navigate to Parent/Student dashboard
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const parent.SchoolManagementSystemApp(),
              ),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
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
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
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
                    padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Role Name
                        ShaderMask(
                          shaderCallback: (Rect bounds) => const LinearGradient(
                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                          ).createShader(bounds),
                          child: const Text(
                            'Parent Login',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Enter your credentials to continue',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                        const SizedBox(height: 32),

                        // Email Address Field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) {
                            FocusScope.of(context).requestFocus(_passwordFocusNode);
                          },
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            hintText: 'Enter your email',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFF667EEA),
                                width: 2,
                              ),
                            ),
                          ),
                          // Validation is handled by backend
                          validator: (value) => null,
                        ),
                        const SizedBox(height: 20),

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleLogin(),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Enter your password',
                            prefixIcon: const Icon(Icons.lock_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFF667EEA),
                                width: 2,
                              ),
                            ),
                          ),
                          // Validation is handled by backend
                          validator: (value) => null,
                        ),
                        
                        // Forgot Password Link
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // Show forgot password dialog
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Forgot Password'),
                                  content: const Text(
                                    'Please contact your administrator to reset your password.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: Color(0xFF667EEA),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 8),

                        // Login Button
                        SizedBox(
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () async {
                                    // All validation and login logic is handled by the backend
                                    setState(() {
                                      _isLoading = true;
                                    });

                                    final authService = AuthService();
                                    final result = await authService.login(
                                      email: _emailController.text.trim(),
                                      password: _passwordController.text,
                                      role: 'parent',
                                    );

                                    setState(() {
                                      _isLoading = false;
                                    });

                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            result['message'] ??
                                                'Login attempt completed',
                                          ),
                                          backgroundColor: result['success']
                                              ? const Color(0xFF667EEA)
                                              : Colors.red,
                                        ),
                                      );

                                      if (result['success']) {
                                        // Check if user needs to create password
                                        final needsPasswordCreation = result['needs_password_creation'] as bool? ?? false;
                                        
                                        if (needsPasswordCreation) {
                                          // Navigate to create password page
                                          final passwordCreated = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => CreatePasswordPage(
                                                role: 'parent',
                                                userData: result['user'],
                                                tokens: result['tokens'],
                                                routes: result['routes'],
                                              ),
                                            ),
                                          );
                                          
                                          // If password was created successfully, navigate to dashboard
                                          if (passwordCreated == true && mounted) {
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => const parent.SchoolManagementSystemApp(),
                                              ),
                                            );
                                          }
                                        } else {
                                          // Cache school details if available
                                          try {
                                            final user = result['user'];
                                            if (user != null && user is Map) {
                                              final prefs = await SharedPreferences.getInstance();
                                              
                                              // Try to extract school name
                                              String? schoolName = user['school_name']?.toString();
                                              // If not directly available, check nested school object
                                              if (schoolName == null && user['school'] is Map) {
                                                schoolName = user['school']['school_name']?.toString() ?? 
                                                           user['school']['name']?.toString();
                                              }
                                              
                                              if (schoolName != null && schoolName.isNotEmpty) {
                                                await prefs.setString('school_name', schoolName);
                                              }
                                              
                                              // Try to extract logo URL
                                              String? logoUrl = user['logo_url']?.toString();
                                              if (logoUrl == null && user['school'] is Map) {
                                                logoUrl = user['school']['logo_url']?.toString();
                                              }
                                              
                                              if (logoUrl != null && logoUrl.isNotEmpty) {
                                                await prefs.setString('logo_url', logoUrl);
                                              }
                                            }
                                          } catch (e) {
                                            debugPrint('Error caching school details: $e');
                                          }

                                          // Navigate to Parent/Student dashboard
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const parent.SchoolManagementSystemApp(),
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF667EEA),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Login',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: TextButton(
                            onPressed: () => _showForgotPasswordDialog(context),
                            child: const Text(
                              'Forgot password',
                              style: TextStyle(
                                color: Color(0xFF667EEA),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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

  void _showForgotPasswordDialog(BuildContext context) {
    final emailController = TextEditingController(text: _emailController.text);
    bool isDialogLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Forgot Password', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Enter your registered email address to receive a password reset link.', style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 20),
              TextField(
                controller: emailController,
                enabled: !isDialogLoading,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'parent@school.com',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isDialogLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: isDialogLoading
                  ? null
                  : () async {
                      setDialogState(() => isDialogLoading = true);
                      final authService = AuthService();
                      final result = await authService.requestPasswordResetOtp(emailController.text);

                      if (context.mounted) {
                        setDialogState(() => isDialogLoading = false);
                        if (result['success']) {
                          Navigator.pop(context); // Close dialog
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ForgotPasswordFlow(
                                email: emailController.text,
                                role: 'parent',
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result['message']),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                minimumSize: const Size(120, 45),
              ),
              child: isDialogLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Send Reset Link'),
            ),
          ],
        ),
      ),
    );
  }
}
