import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'driver.dart';
import 'create_password.dart';
import 'forgot_password_flow.dart';



void main() {
  runApp(const DriverLoginApp());
}

class DriverLoginApp extends StatelessWidget {
  const DriverLoginApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Driver Portal - School Management System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        // Using the same background color from the original code
        scaffoldBackgroundColor: const Color.fromARGB(255, 102, 126, 234),
        fontFamily: 'Inter',
      ),
      home: const DriverLoginScreen(),
    );
  }
}

class DriverLoginScreen extends StatefulWidget {
  const DriverLoginScreen({super.key});

  @override
  State<DriverLoginScreen> createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends State<DriverLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _checkIfLoggedIn();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkIfLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final user = prefs.getString('user');
    if (token != null && user != null) {
      // Check if user is a driver (assuming this logic persists)
      try {
        final userData = jsonDecode(user);
        if (userData['role'] == 'driver') {
          _redirectToDashboard();
        }
      } catch (e) {
        // Handle malformed stored JSON
        print('Error decoding user data: $e');
      }
    }
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = "Please enter email and password (or temporary PIN)";
        _isLoading = false;
      });
      return;
    }

    // API call: role-login validates driver role; backend may return needs_password_creation for first login with PIN
    try {
      // Replace with your backend base URL (e.g. http://10.0.2.2:8000 for Android emulator)
      const baseUrl = String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://10.0.2.2:8000',
      );
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/role-login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'role': 'driver',
        }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        final tokens = data['tokens'] as Map<String, dynamic>?;
        final accessToken = tokens != null ? (tokens['access'] as String?) : null;
        if (accessToken != null) {
          await prefs.setString('token', accessToken);
        }
        final userMap = Map<String, dynamic>.from(data['user'] as Map<String, dynamic>? ?? {});
        userMap['role'] = data['role'] ?? 'driver';
        userMap['needs_password_creation'] = data['needs_password_creation'] == true;
        await prefs.setString('user', jsonEncode(userMap));

        setState(() {
          _successMessage = 'Login successful! Redirecting...';
        });

        final needsPasswordCreation = data['needs_password_creation'] == true;
        if (needsPasswordCreation && mounted) {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const CreatePasswordPage()),
          );
          if (mounted && result == true) {
            _redirectToDashboard();
          }
        } else {
          Future.delayed(const Duration(milliseconds: 400), _redirectToDashboard);
        }
      } else {
        setState(() {
          _errorMessage = data['message'] as String? ?? 'Login failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred during login. Check server URL/connection.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _redirectToDashboard() {
    // Navigate to the full-featured dashboard defined in driver_features.dart
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DriverPortalScreen()),
    );
  }

  void _openForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ForgotPasswordFlowPage()),
    );
  }

  Widget _buildMessageCard(String message, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(bgColor == Colors.red.shade50 ? Icons.error_outline : Icons.check_circle_outline, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black26, blurRadius: 20, offset: Offset(0, 10))
              ],
            ),
            constraints: const BoxConstraints(maxWidth: 450),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color.fromARGB(255, 136, 158, 255), Color(0xFF764ba2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 65),
                  child: Column(
                    children: const [
                      Icon(Icons.directions_bus, size: 70, color: Colors.yellow),
                      SizedBox(height: 10),
                      Text(
                        'Driver Portal',
                        style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Securely access your bus management dashboard',
                        style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    children: [
                      if (_errorMessage != null)
                        _buildMessageCard(_errorMessage!, Colors.red.shade800, Colors.red.shade50),
                      if (_successMessage != null)
                        _buildMessageCard(_successMessage!, Colors.green.shade800, Colors.green.shade50),

                      // Email
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: const Icon(Icons.email, color: Colors.indigo),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.indigo, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Password (or temporary 6-digit PIN for first login)
                      TextField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Password or temporary PIN',
                          prefixIcon: const Icon(Icons.lock, color: Colors.indigo),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                              color: Colors.indigo,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.indigo, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Login Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          minimumSize: const Size(double.infinity, 50),
                          elevation: 8,
                          shadowColor: Colors.indigo.shade300,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                          'Login',
                          style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),

                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: _isLoading ? null : _openForgotPassword,
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(color: Colors.indigo.shade600, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
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