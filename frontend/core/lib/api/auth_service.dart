import 'package:core/api/api_service.dart';
import 'package:core/api/endpoints.dart';

/// JWT auth requests
class AuthService {
  final ApiService _apiService = ApiService();

  // Login with role validation
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await _apiService.post(
        Endpoints.roleLogin,
        body: {
          'email': email,
          'password': password,
          'role': role,
        },
      );

      if (response.success && response.data != null) {
        final data = response.data;
        
        // Handle case where data might not be a Map
        if (data is! Map<String, dynamic>) {
          return {
            'success': false,
            'message': 'Invalid response format from server',
          };
        }
        
        final success = data['success'] as bool? ?? false;
        
        if (success) {
          final tokens = data['tokens'] as Map<String, dynamic>?;
          final accessToken = tokens?['access'] as String?;
          final userData = data['user'] as Map<String, dynamic>?;
          final routes = data['routes'] as Map<String, dynamic>?;
          final message = data['message'] as String? ?? 'Login successful';
          final needsPasswordCreation = data['needs_password_creation'] as bool? ?? false;

          if (accessToken != null) {
            await _apiService.setAuthToken(accessToken);
            
            // Store refresh token if available
            final refreshToken = tokens?['refresh'] as String?;
            if (refreshToken != null) {
              await _apiService.setRefreshToken(refreshToken);
            }
            
            // Store user role
            await _apiService.setUserRole(role);

            return {
              'success': true,
              'message': message,
              'user': userData,
              'tokens': tokens,
              'routes': routes,
              'needs_password_creation': needsPasswordCreation,
            };
          } else {
            return {
              'success': false,
              'message': 'Login successful but no access token received',
            };
          }
        } else {
          return {
            'success': false,
            'message': data['message'] as String? ?? 'Login failed',
          };
        }
      }

      // Handle error response
      String errorMessage = 'Login failed. Please check your credentials.';
      if (response.data != null && response.data is Map<String, dynamic>) {
        final errorData = response.data as Map<String, dynamic>;
        errorMessage = errorData['message'] as String? ?? 
                      errorData['error'] as String? ?? 
                      errorMessage;
      } else if (response.error != null) {
        errorMessage = response.error!;
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Register
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String name,
    required String role,
    Map<String, dynamic>? additionalData,
  }) async {
    final body = <String, dynamic>{
      'email': email,
      'password': password,
      'name': name,
      'role': role,
    };

    if (additionalData != null) {
      body.addAll(additionalData);
    }

    final response = await _apiService.post(
      Endpoints.register,
      body: body,
    );

    if (response.success && response.data != null) {
      final token = response.data['token'] as String?;
      final userData = response.data['user'] as Map<String, dynamic>?;

      if (token != null) {
        _apiService.setAuthToken(token);
        return AuthResponse.success(
          token: token,
          user: userData,
        );
      }
    }

    return AuthResponse.error(
      response.error ?? 'Registration failed',
    );
  }

  // Logout
  Future<bool> logout() async {
    try {
      // Get refresh token to blacklist it on server
      final refreshToken = _apiService.refreshToken;
      
      // We set retryOn401: false because if logout fails with 401, 
      // there's no point in trying to refresh the token to log out.
      final response = await _apiService.post(
        Endpoints.logout,
        body: refreshToken != null ? {'refresh_token': refreshToken} : null,
        retryOn401: false,
      );

      // Clear tokens regardless of response
      await _apiService.setAuthToken(null);
      await _apiService.setRefreshToken(null);
      await _apiService.setUserRole(null);

      return response.success;
    } catch (e) {
      // Clear tokens even if request fails
      await _apiService.setAuthToken(null);
      await _apiService.setRefreshToken(null);
      await _apiService.setUserRole(null);
      return false;
    }
  }

  // Refresh token
  Future<AuthResponse> refreshToken() async {
    final refreshToken = _apiService.refreshToken;
    if (refreshToken == null) {
      return AuthResponse.error('No refresh token available');
    }

    final response = await _apiService.post(
      Endpoints.refreshToken,
      body: {'refresh': refreshToken},
    );

    if (response.success && response.data != null) {
      final token = response.data['access'] as String?;

      if (token != null) {
        await _apiService.setAuthToken(token);
        return AuthResponse.success(token: token);
      }
    }

    return AuthResponse.error(
      response.error ?? 'Token refresh failed',
    );
  }

  // Check if user is authenticated
  bool isAuthenticated() {
    return _apiService.authToken != null;
  }

  // Get current token
  String? getCurrentToken() {
    return _apiService.authToken;
  }

  // Request password reset OTP
  Future<Map<String, dynamic>> requestPasswordResetOtp(String email) async {
    try {
      final response = await _apiService.post(
        Endpoints.requestOtp,
        body: {'email': email},
      );
      
      if (response.success) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'OTP sent successfully',
          'email_sent': response.data['email_sent'] ?? false,
        };
      } else {
        return {
          'success': false,
          'message': response.error ?? 'Failed to send OTP',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Reset password with OTP
  Future<Map<String, dynamic>> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await _apiService.post(
        Endpoints.resetPasswordOtp,
        body: {
          'email': email,
          'otp': otp,
          'new_password': newPassword,
        },
      );
      
      if (response.success) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Password reset successfully',
        };
      } else {
        return {
          'success': false,
          'message': response.error ?? 'Failed to reset password',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Change password (requires authentication)
  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _apiService.post(
        Endpoints.changePassword,
        body: {
          'old_password': oldPassword,
          'new_password': newPassword,
          'new_password2': newPassword, // Backend requires confirmation
        },
      );
      
      if (response.success) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Password changed successfully',
        };
      } else {
        return {
          'success': false,
          'message': response.error ?? 'Failed to change password',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
}

/// Auth Response model
class AuthResponse {
  final bool success;
  final String? token;
  final Map<String, dynamic>? user;
  final String? error;

  AuthResponse({
    required this.success,
    this.token,
    this.user,
    this.error,
  });

  factory AuthResponse.success({
    String? token,
    Map<String, dynamic>? user,
  }) {
    return AuthResponse(
      success: true,
      token: token,
      user: user,
    );
  }

  factory AuthResponse.error(String error) {
    return AuthResponse(
      success: false,
      error: error,
    );
  }
}

