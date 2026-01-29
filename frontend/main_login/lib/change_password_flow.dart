import 'package:flutter/material.dart';
import 'package:core/api/auth_service.dart';

class ChangePasswordFlow extends StatefulWidget {
  final String email;
  final String role;

  const ChangePasswordFlow({
    super.key,
    required this.email,
    required this.role,
  });

  @override
  State<ChangePasswordFlow> createState() => _ChangePasswordFlowState();
}

class _ChangePasswordFlowState extends State<ChangePasswordFlow> {
  int _currentStep = 0; // 0: Current Password, 1: New Password
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isProcessing = false;
  String? _authToken;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _verifyCurrentPassword() async {
    if (_currentPasswordController.text.isEmpty) {
      _showError('Please enter your current password');
      return;
    }

    setState(() => _isProcessing = true);

    // Login to verify current password and get auth token
    final result = await _authService.login(
      email: widget.email,
      password: _currentPasswordController.text,
      role: widget.role,
    );

    setState(() => _isProcessing = false);

    if (mounted) {
      if (result['success']) {
        // Store the auth token for the change password request
        _authToken = result['tokens']?['access'];
        setState(() => _currentStep = 1);
      } else {
        _showError(result['message'] ?? 'Invalid current password');
      }
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match');
      return;
    }
    if (_newPasswordController.text.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }

    setState(() => _isProcessing = true);

    final result = await _authService.changePassword(
      oldPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );

    setState(() => _isProcessing = false);

    if (mounted) {
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Password changed successfully'),
            backgroundColor: const Color(0xFF667EEA),
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Logout and return to login page
        await _authService.logout();
        Navigator.pop(context);
      } else {
        _showError(result['message'] ?? 'Failed to change password');
        // If old password was invalid, go back to step 0
        if (result['message']?.toLowerCase().contains('password') ?? false) {
          setState(() => _currentStep = 0);
        }
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
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
                    child: _currentStep == 0
                        ? _buildCurrentPasswordStep()
                        : _buildNewPasswordStep(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPasswordStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.lock_outline, size: 64, color: Color(0xFF667EEA)),
        const SizedBox(height: 24),
        const Text(
          'Change Password',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Enter your current password for ${widget.email}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, color: Colors.black54),
        ),
        const SizedBox(height: 32),
        _buildPasswordField(
          'Current Password',
          _currentPasswordController,
          _obscureCurrentPassword,
          () => setState(() => _obscureCurrentPassword = !_obscureCurrentPassword),
        ),
        const SizedBox(height: 32),
        _buildButton('Verify & Continue', _verifyCurrentPassword),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Back to Login',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildNewPasswordStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.lock_reset_rounded, size: 64, color: Color(0xFF764BA2)),
        const SizedBox(height: 24),
        const Text(
          'New Password',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Set a strong password for your account',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: Colors.black54),
        ),
        const SizedBox(height: 32),
        _buildPasswordField(
          'New Password',
          _newPasswordController,
          _obscureNewPassword,
          () => setState(() => _obscureNewPassword = !_obscureNewPassword),
        ),
        const SizedBox(height: 20),
        _buildPasswordField(
          'Confirm Password',
          _confirmPasswordController,
          _obscureConfirmPassword,
          () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
        ),
        const SizedBox(height: 32),
        _buildButton('Change Password', _changePassword),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() => _currentStep = 0),
          child: const Text(
            'Back',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(
    String label,
    TextEditingController controller,
    bool obscure,
    VoidCallback onToggle,
  ) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          ),
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
      onPressed: _isProcessing ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF667EEA),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: _isProcessing
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(
              text,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
    );
  }
}
