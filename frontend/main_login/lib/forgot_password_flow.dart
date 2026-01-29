import 'package:flutter/material.dart';
import 'package:core/api/auth_service.dart';

class ForgotPasswordFlow extends StatefulWidget {
  final String email;
  final String role;

  const ForgotPasswordFlow({
    super.key,
    required this.email,
    required this.role,
  });

  @override
  State<ForgotPasswordFlow> createState() => _ForgotPasswordFlowState();
}

class _ForgotPasswordFlowState extends State<ForgotPasswordFlow> {
  int _currentStep = 0; // 0: OTP, 1: New Password
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isVerifying = false;

  void _verifyOtp() {
    if (_otpController.text.length != 6) {
      _showError('Please enter the 6-digit OTP');
      return;
    }
    
    // In this flow, we proceed to password step first, 
    // and only verify on the final submission to save an API call 
    // OR we can verify now. The backend reset_password_with_otp needs both.
    // Let's just move to next step and do a single call at the end.
    setState(() {
      _currentStep = 1;
    });
  }

  Future<void> _resetPassword() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match');
      return;
    }
    if (_passwordController.text.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }

    setState(() => _isVerifying = true);
    
    final result = await _authService.resetPasswordWithOtp(
      email: widget.email,
      otp: _otpController.text,
      newPassword: _passwordController.text,
    );

    setState(() => _isVerifying = false);

    if (mounted) {
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: const Color(0xFF667EEA),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context); // Back to login
      } else {
        _showError(result['message']);
        // If OTP was invalid, go back to OTP step
        if (result['message'].toLowerCase().contains('otp')) {
          setState(() => _currentStep = 0);
        }
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
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
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: _currentStep == 0 ? _buildOtpStep() : _buildPasswordStep(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.mark_email_unread_outlined, size: 64, color: Color(0xFF667EEA)),
        const SizedBox(height: 24),
        const Text(
          'Verify OTP',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 12),
        Text(
          'An OTP has been sent to ${widget.email}. Please check your terminal to see the code.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, color: Colors.black54),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
          decoration: InputDecoration(
            hintText: '000000',
            hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
            ),
          ),
        ),
        const SizedBox(height: 32),
        _buildButton('Verify & Proceed', _verifyOtp),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Back to Login', style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.lock_reset_rounded, size: 64, color: Color(0xFF764BA2)),
        const SizedBox(height: 24),
        const Text(
          'New Password',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 12),
        const Text(
          'Set a strong password for your account',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: Colors.black54),
        ),
        const SizedBox(height: 32),
        _buildPasswordField('New Password', _passwordController, _obscurePassword, () {
          setState(() => _obscurePassword = !_obscurePassword);
        }),
        const SizedBox(height: 20),
        _buildPasswordField('Confirm Password', _confirmPasswordController, _obscureConfirm, () {
          setState(() => _obscureConfirm = !_obscureConfirm);
        }),
        const SizedBox(height: 32),
        _buildButton('Reset Password', _resetPassword),
      ],
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller, bool obscure, VoidCallback onToggle) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF764BA2), width: 2),
        ),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: _isVerifying ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF667EEA),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: _isVerifying
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }
}
