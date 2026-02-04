import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Forgot password flow for Driver portal (same as management):
/// Step 0: Enter email → Send OTP (POST /api/auth/request-otp/)
/// Step 1: Enter OTP + new password → Reset (POST /api/auth/reset-password-otp/)
class ForgotPasswordFlowPage extends StatefulWidget {
  const ForgotPasswordFlowPage({super.key});

  @override
  State<ForgotPasswordFlowPage> createState() => _ForgotPasswordFlowPageState();
}

class _ForgotPasswordFlowPageState extends State<ForgotPasswordFlowPage> {
  static const String _baseUrlKey = 'API_BASE_URL';
  static const String _defaultBaseUrl = 'http://10.0.2.2:8000';

  String get _baseUrl =>
      const String.fromEnvironment(_baseUrlKey, defaultValue: _defaultBaseUrl);

  int _step = 0; // 0: email + send OTP, 1: OTP + new password
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email address');
      return;
    }

    _clearError();
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/request-otp/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final data = response.statusCode == 200
          ? (jsonDecode(response.body) as Map<String, dynamic>?)
          : null;

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (response.statusCode == 200 && data != null && data['success'] == true) {
        setState(() {
          _step = 1;
          _errorMessage = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] as String? ?? 'OTP sent to your email'),
            backgroundColor: const Color(0xFF667EEA),
          ),
        );
      } else {
        final message = data?['error'] ?? data?['message'] ?? 'Failed to send OTP';
        setState(() => _errorMessage = message as String);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Network error. Check connection and try again.';
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (otp.length != 6) {
      setState(() => _errorMessage = 'Please enter the 6-digit OTP');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      return;
    }
    if (password != confirm) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    _clearError();
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/reset-password-otp/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'new_password': password,
        }),
      );

      final data = response.statusCode == 200
          ? (jsonDecode(response.body) as Map<String, dynamic>?)
          : null;

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (response.statusCode == 200 && data != null && data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password reset successfully. You can now login with your new password.'),
              backgroundColor: Color(0xFF667EEA),
            ),
          );
          Navigator.pop(context);
        }
      } else {
        final message = data?['error'] ?? data?['message'] ?? 'Failed to reset password';
        setState(() => _errorMessage = message as String);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Network error. Check connection and try again.';
        });
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
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 136, 158, 255),
              Color(0xFF764ba2),
            ],
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: _step == 0 ? _buildEmailStep() : _buildOtpAndPasswordStep(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.lock_reset, size: 56, color: Colors.indigo),
        const SizedBox(height: 16),
        const Text(
          'Forgot Password',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter your driver email to receive a one-time code (OTP) to reset your password.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade800, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          enabled: !_isLoading,
          decoration: InputDecoration(
            labelText: 'Email Address',
            hintText: 'driver@school.com',
            prefixIcon: const Icon(Icons.email_outlined, color: Colors.indigo),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.indigo, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Send OTP',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Back to Login', style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }

  Widget _buildOtpAndPasswordStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.mark_email_unread_outlined, size: 56, color: Colors.indigo),
        const SizedBox(height: 16),
        const Text(
          'Enter OTP & New Password',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'An OTP was sent to ${_emailController.text.trim()}. Enter it below and set a new password.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade800, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          enabled: !_isLoading,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 8),
          decoration: InputDecoration(
            labelText: 'OTP',
            hintText: '000000',
            counterText: '',
            prefixIcon: const Icon(Icons.pin_outlined, color: Colors.indigo),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.indigo, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          enabled: !_isLoading,
          decoration: InputDecoration(
            labelText: 'New Password',
            hintText: 'At least 6 characters',
            prefixIcon: const Icon(Icons.lock_outlined, color: Colors.indigo),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.indigo,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.indigo, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirm,
          enabled: !_isLoading,
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            hintText: 'Re-enter new password',
            prefixIcon: const Icon(Icons.lock_outlined, color: Colors.indigo),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                color: Colors.indigo,
              ),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.indigo, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _resetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Reset Password',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _isLoading ? null : () => setState(() => _step = 0),
          child: const Text('Change email', style: TextStyle(color: Colors.grey)),
        ),
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Back to Login', style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }
}
