import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:core/api/endpoints.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Base API handler
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _authToken;
  String? _refreshToken;
  String? _userRole;
  Duration _timeout = const Duration(seconds: 30);
  bool _isRefreshing = false;

  // Initialize - load tokens from storage
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('access_token');
      _refreshToken = prefs.getString('refresh_token');
      _userRole = prefs.getString('user_role');
    } catch (e) {
      // If SharedPreferences fails, continue without stored tokens
      _authToken = null;
      _refreshToken = null;
      _userRole = null;
    }
  }

  // Set user role
  Future<void> setUserRole(String? role) async {
    _userRole = role;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (role != null) {
        await prefs.setString('user_role', role);
      } else {
        await prefs.remove('user_role');
      }
    } catch (e) {
      // Ignore errors
    }
  }

  // Get user role
  String? get userRole => _userRole;

  // Set authentication token
  Future<void> setAuthToken(String? token) async {
    _authToken = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (token != null) {
        await prefs.setString('access_token', token);
      } else {
        await prefs.remove('access_token');
      }
    } catch (e) {
      // If SharedPreferences fails, continue with in-memory token
    }
  }

  // Set refresh token
  Future<void> setRefreshToken(String? token) async {
    _refreshToken = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (token != null) {
        await prefs.setString('refresh_token', token);
      } else {
        await prefs.remove('refresh_token');
      }
    } catch (e) {
      // If SharedPreferences fails, continue with in-memory token
    }
  }

  // Get authentication token
  String? get authToken => _authToken;
  
  // Get refresh token
  String? get refreshToken => _refreshToken;

  // Set request timeout
  void setTimeout(Duration duration) {
    _timeout = duration;
  }

  // Get default headers
  Map<String, String> _getHeaders({Map<String, String>? additionalHeaders, bool isMultipart = false}) {
    final headers = <String, String>{
      if (!isMultipart) 'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  // Refresh access token using refresh token
  Future<bool> _refreshAccessToken() async {
    if (_refreshToken == null || _isRefreshing) {
      return false;
    }

    _isRefreshing = true;
    try {
      final uri = Uri.parse(Endpoints.buildUrl(Endpoints.refreshToken));
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'refresh': _refreshToken}),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final newAccessToken = body['access'] as String?;
        if (newAccessToken != null) {
          await setAuthToken(newAccessToken);
          _isRefreshing = false;
          return true;
        }
      }
    } catch (e) {
      // Refresh failed - will be handled below
    }
    
    _isRefreshing = false;
    // Clear tokens if refresh fails
    await setAuthToken(null);
    await setRefreshToken(null);
    return false;
  }

  // GET request with automatic token refresh
  Future<ApiResponse> get(
    String endpoint, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    bool retryOn401 = true,
  }) async {
    try {
      Uri uri = Uri.parse(Endpoints.buildUrl(endpoint));
      if (queryParameters != null && queryParameters.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParameters);
      }

      final response = await http
          .get(uri, headers: _getHeaders(additionalHeaders: headers))
          .timeout(_timeout);

      // Handle 401 - try to refresh token
      if (response.statusCode == 401 && retryOn401) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          // Retry the request with new token
          return get(
            endpoint,
            queryParameters: queryParameters,
            headers: headers,
            retryOn401: false,
          );
        } else {
          return ApiResponse.error(
            'Session expired. Please login again.',
            statusCode: 401,
          );
        }
      }

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // POST request with automatic token refresh
  Future<ApiResponse> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool retryOn401 = true,
  }) async {
    try {
      final uri = Uri.parse(Endpoints.buildUrl(endpoint));
      final response = await http
          .post(
            uri,
            headers: _getHeaders(additionalHeaders: headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout);

      // Handle 401 - try to refresh token
      if (response.statusCode == 401 && retryOn401) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          // Retry the request with new token
          return post(
            endpoint,
            body: body,
            headers: headers,
            retryOn401: false,
          );
        } else {
          return ApiResponse.error(
            'Session expired. Please login again.',
            statusCode: 401,
          );
        }
      }

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // PUT request with automatic token refresh
  Future<ApiResponse> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool retryOn401 = true,
  }) async {
    try {
      final uri = Uri.parse(Endpoints.buildUrl(endpoint));
      final response = await http
          .put(
            uri,
            headers: _getHeaders(additionalHeaders: headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout);

      // Handle 401 - try to refresh token
      if (response.statusCode == 401 && retryOn401) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          // Retry the request with new token
          return put(
            endpoint,
            body: body,
            headers: headers,
            retryOn401: false,
          );
        } else {
          return ApiResponse.error(
            'Session expired. Please login again.',
            statusCode: 401,
          );
        }
      }

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // PATCH request with automatic token refresh
  Future<ApiResponse> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool retryOn401 = true,
  }) async {
    try {
      final uri = Uri.parse(Endpoints.buildUrl(endpoint));
      final response = await http
          .patch(
            uri,
            headers: _getHeaders(additionalHeaders: headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout);

      // Handle 401 - try to refresh token
      if (response.statusCode == 401 && retryOn401) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          // Retry the request with new token
          return patch(
            endpoint,
            body: body,
            headers: headers,
            retryOn401: false,
          );
        } else {
          return ApiResponse.error(
            'Session expired. Please login again.',
            statusCode: 401,
          );
        }
      }

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // DELETE request with automatic token refresh
  Future<ApiResponse> delete(
    String endpoint, {
    Map<String, String>? headers,
    bool retryOn401 = true,
  }) async {
    try {
      final uri = Uri.parse(Endpoints.buildUrl(endpoint));
      final response = await http
          .delete(uri, headers: _getHeaders(additionalHeaders: headers))
          .timeout(_timeout);

      // Handle 401 - try to refresh token
      if (response.statusCode == 401 && retryOn401) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          // Retry the request with new token
          return delete(
            endpoint,
            headers: headers,
            retryOn401: false,
          );
        } else {
          return ApiResponse.error(
            'Session expired. Please login again.',
            statusCode: 401,
          );
        }
      }

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  /// Send FCM push notification to students and/or teachers (management only).
  /// [audience]: 'all_students' | 'all_teachers' | 'both'
  /// [title]: notification title, [body]: notification body
  Future<ApiResponse> sendPushNotification({
    required String title,
    required String body,
    String audience = 'both',
    String? schoolId,
  }) async {
    final bodyMap = <String, dynamic>{
      'title': title,
      'body': body,
      'audience': audience,
    };
    if (schoolId != null && schoolId.isNotEmpty) {
      bodyMap['school_id'] = schoolId;
    }
    return post(Endpoints.sendPush, body: bodyMap);
  }

  /// Fetch list of sent push notifications (management only).
  /// Returns list of { id, title, body, audience, sent_count, user_count, school_id, created_at }.
  Future<ApiResponse> getPushNotificationLogs() async {
    final response = await get(Endpoints.pushNotificationLogs);
    if (!response.success) return response;
    // DRF may return paginated { results: [...] } or a list
    final data = response.data;
    if (data is List) {
      return ApiResponse.success(data: data, statusCode: response.statusCode);
    }
    if (data is Map<String, dynamic> && data['results'] != null) {
      return ApiResponse.success(data: data['results'] as List, statusCode: response.statusCode);
    }
    return ApiResponse.success(data: <dynamic>[], statusCode: response.statusCode);
  }

  // Handle HTTP response
  ApiResponse _handleResponse(http.Response response) {
    try {
      final statusCode = response.statusCode;
      dynamic body;
      
      if (response.body.isNotEmpty) {
        try {
          body = jsonDecode(response.body);
        } catch (e) {
          // If JSON parsing fails, return the raw body as error
          return ApiResponse.error(
            'Invalid JSON response: ${response.body}',
            statusCode: statusCode,
          );
        }
      }

      if (statusCode >= 200 && statusCode < 300) {
        // For successful responses, body could be Map or List
        return ApiResponse.success(
          data: body,
          statusCode: statusCode,
        );
      } else {
        // For error responses, try to extract error message
        String errorMessage = 'Request failed with status $statusCode';
        if (body is Map<String, dynamic>) {
          errorMessage = body['message'] as String? ??
              body['error'] as String? ??
              (body['errors'] is Map ? 'Validation errors' : errorMessage);
        } else if (body is String) {
          errorMessage = body;
        }
        
        return ApiResponse.error(
          errorMessage,
          statusCode: statusCode,
          data: body,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to parse response: ${e.toString()}');
    }
  }

  // Upload file (multipart/form-data)
  Future<ApiResponse> uploadFile(
    String endpoint, {
    required Uint8List fileBytes,
    required String fileName,
    String method = 'POST',
    String fieldName = 'file',
    Map<String, String>? additionalFields,
    bool retryOn401 = true,
  }) async {
    try {
      final uri = Uri.parse(Endpoints.buildUrl(endpoint));
      
      // Create multipart request
      final request = http.MultipartRequest(method, uri);
      
      // Add headers (without Content-Type, let multipart set it)
      final headers = _getHeaders(isMultipart: true);
      headers.remove('Content-Type'); // Remove Content-Type for multipart
      request.headers.addAll(headers);
      
      // Add file
      final multipartFile = http.MultipartFile.fromBytes(
        fieldName,
        fileBytes,
        filename: fileName,
      );
      request.files.add(multipartFile);
      
      // Add additional fields if provided
      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
      }
      
      // Send request
      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);
      
      // Handle 401 - try to refresh token
      if (response.statusCode == 401 && retryOn401) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          // Retry the request with new token
          return uploadFile(
            endpoint,
            fileBytes: fileBytes,
            fileName: fileName,
            method: method,
            fieldName: fieldName,
            additionalFields: additionalFields,
            retryOn401: false,
          );
        }
      }
      
      // Parse response
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(data: data);
      } else {
        final errorData = jsonDecode(response.body);
        return ApiResponse.error(
          errorData['detail']?.toString() ?? 
          errorData['message']?.toString() ?? 
          'Upload failed with status ${response.statusCode}',
          data: errorData,
        );
      }
    } catch (e) {
      return ApiResponse.error("Upload error: ${e.toString()}");
    }
  }

  // Upload multiple files (multipart/form-data)
  Future<ApiResponse> uploadFiles(
    String endpoint, {
    required List<Uint8List> fileBytesList,
    required List<String> fileNames,
    String method = "POST",
    String fieldName = "files",
    Map<String, String>? additionalFields,
    bool retryOn401 = true,
  }) async {
    try {
      final uri = Uri.parse(Endpoints.buildUrl(endpoint));
      final request = http.MultipartRequest(method, uri);
      final headers = _getHeaders(isMultipart: true);
      headers.remove("Content-Type");
      request.headers.addAll(headers);

      for (int i = 0; i < fileBytesList.length; i++) {
        request.files.add(http.MultipartFile.fromBytes(
          fieldName,
          fileBytesList[i],
          filename: fileNames[i],
        ));
      }

      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
      }

      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 401 && retryOn401) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          return uploadFiles(
            endpoint,
            fileBytesList: fileBytesList,
            fileNames: fileNames,
            method: method,
            fieldName: fieldName,
            additionalFields: additionalFields,
            retryOn401: false,
          );
        }
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(data: data);
      } else {
        final errorData = jsonDecode(response.body);
        return ApiResponse.error(
          errorData["detail"]?.toString() ??
              errorData["message"]?.toString() ??
              "Upload failed with status ${response.statusCode}",
          data: errorData,
        );
      }
    } catch (e) {
      return ApiResponse.error("Upload error: ${e.toString()}");
    }
  }
}

/// API Response model
class ApiResponse {
  final bool success;
  final dynamic data;
  final String? error;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.statusCode,
  });

  factory ApiResponse.success({
    dynamic data,
    int? statusCode,
  }) {
    return ApiResponse(
      success: true,
      data: data,
      statusCode: statusCode,
    );
  }

  factory ApiResponse.error(
    String error, {
    int? statusCode,
    dynamic data,
  }) {
    return ApiResponse(
      success: false,
      error: error,
      statusCode: statusCode,
      data: data,
    );
  }
}

