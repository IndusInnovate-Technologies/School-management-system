import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class ApiService {


  static const baseUrl = 'http://localhost:8000/api';
  static String get wsBaseUrl => baseUrl.replaceFirst('http', 'ws').replaceFirst('/api', '');
  
  /// Fetch bus details for a student by student ID (legacy endpoint if exists)
  static Future<Map<String, dynamic>?> fetchStudentBusDetails(String studentId) async {
    final headers = await _getAuthHeaders();
    final resp = await http.get(
      Uri.parse('$baseUrl/management-admin/student/$studentId/bus-details/'),
      headers: headers,
    );
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    return null;
  }

  /// Fetch bus details for dashboard/stat card: uses bus-stop-students, returns map for _BusDetailsCard or {} if no bus assigned
  static Future<Map<String, dynamic>> fetchBusDetailsForDashboard(String? studentId) async {
    if (studentId == null || studentId.isEmpty) return {};
    final headers = await _getAuthHeaders();
    final resp = await http.get(
      Uri.parse('$baseUrl/management-admin/bus-stop-students/?search=${Uri.encodeComponent(studentId)}'),
      headers: headers,
    );
    if (resp.statusCode != 200) return {};
    dynamic data;
    try {
      data = jsonDecode(resp.body);
    } catch (_) {
      return {};
    }
    List<dynamic> results = [];
    if (data is List) {
      results = data;
    } else if (data is Map && data['results'] != null) {
      results = data['results'] as List<dynamic>;
    }
    if (results.isEmpty) return {};
    // Filter by this student
    final filtered = results.where((a) {
      final m = a is Map ? a as Map<String, dynamic> : null;
      if (m == null) return false;
      final sid = m['student_id_string']?.toString() ?? m['student_id']?.toString();
      final nested = m['student'];
      String? nestedSid;
      if (nested is Map) {
        nestedSid = nested['student_id']?.toString() ?? nested['id']?.toString();
      } else if (nested is String) nestedSid = nested;
      return sid == studentId || nestedSid == studentId;
    }).toList();
    if (filtered.isEmpty) return {};
    // Prefer a morning assignment so pickup_time = morning stop, dropoff_time = afternoon stop
    Map<String, dynamic> chosen = filtered.first as Map<String, dynamic>;
    for (final a in filtered) {
      final m = a as Map<String, dynamic>;
      final routeType = (m['stop_details'] as Map<String, dynamic>?)?['route_type']?.toString();
      if (routeType == 'morning') {
        chosen = m;
        break;
      }
    }
    final busDetails = chosen['bus_details'] as Map<String, dynamic>?;
    if (busDetails == null) return {};
    final pickupTime = chosen['pickup_time']?.toString();
    final dropoffTime = chosen['dropoff_time']?.toString();
    return {
      'busNumber': busDetails['bus_number']?.toString() ?? 'N/A',
      'route': busDetails['route']?.toString() ?? 'N/A',
      'driver': busDetails['driver_name']?.toString() ?? 'N/A',
      'pickupTime': pickupTime != null && pickupTime.isNotEmpty ? pickupTime.split('.').first : 'N/A',
      'dropTime': dropoffTime != null && dropoffTime.isNotEmpty ? dropoffTime.split('.').first : 'N/A',
    };
  }

  static const _base = '$baseUrl/management-admin';
  static const teachersEndpoint = '$_base/teachers/';
  static const studentsEndpoint = '$_base/students/';
  static const communicationsEndpoint = '$baseUrl/student-parent/communications/';
  static const chatMessagesEndpoint = '$baseUrl/student-parent/chat-messages/';
  static const parentBase = '$baseUrl/student-parent';
  static const parentEndpoint = '$parentBase/parent/';
  static const teacherBase = '$baseUrl/teacher';

  static Future<List<dynamic>> fetchTeacherClasses() async {
    final headers = await _getAuthHeaders();
    final resp = await http.get(Uri.parse('$teacherBase/classes/'), headers: headers);
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as List<dynamic>;
    }
    return [];
  }

  static Future<List<dynamic>> fetchTeacherExams() async {
    final headers = await _getAuthHeaders();
    final resp = await http.get(Uri.parse('$teacherBase/exams/'), headers: headers);
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as List<dynamic>;
    }
    return [];
  }

  static Future<bool> createExam(Map<String, dynamic> data) async {
    final headers = await _getAuthHeaders();
    print('Creating exam: $data');
    final resp = await http.post(
      Uri.parse('$teacherBase/exams/'),
      headers: headers,
      body: jsonEncode(data),
    );
    if (resp.statusCode != 201) {
      print('Failed to create exam: ${resp.body}');
    }
    return resp.statusCode == 201;
  }
  
  static Future<bool> deleteExam(int id) async {
    final headers = await _getAuthHeaders();
    final resp = await http.delete(Uri.parse('$teacherBase/exams/$id/'), headers: headers);
    return resp.statusCode == 204;
  }

  /// Get authentication headers with token (private)
  static Future<Map<String, String>> _getAuthHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    } catch (e) {
      // If SharedPreferences fails, continue without token
    }
    
    return headers;
  }

  /// Get authentication headers with token (public)
  static Future<Map<String, String>> getAuthHeaders() async {
    return await _getAuthHeaders();
  }

  /// Register FCM token for push notifications (call after login)
  static Future<bool> registerFcmToken(String token, String platform) async {
    try {
      final headers = await _getAuthHeaders();
      final uri = Uri.parse('$baseUrl/auth/fcm/register/');
      final resp = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({'token': token, 'platform': platform}),
      ).timeout(const Duration(seconds: 15));
      return resp.statusCode == 200;
    } catch (e) {
      print('Error registering FCM token: $e');
      return false;
    }
  }

  /// Unregister FCM token (e.g. on logout)
  static Future<bool> unregisterFcmToken(String token) async {
    try {
      final headers = await _getAuthHeaders();
      final uri = Uri.parse('$baseUrl/auth/fcm/unregister/');
      final resp = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({'token': token}),
      ).timeout(const Duration(seconds: 10));
      return resp.statusCode == 200;
    } catch (e) {
      print('Error unregistering FCM token: $e');
      return false;
    }
  }

  /// Fetch my push notifications (for student/parent portal) - returns list and unread count
  static Future<Map<String, dynamic>> getMyPushNotifications() async {
    try {
      final headers = await _getAuthHeaders();
      final resp = await http.get(
        Uri.parse('$baseUrl/auth/my-push-notifications/'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return {
          'notifications': data['notifications'] is List ? List<Map<String, dynamic>>.from(data['notifications'] as List) : <Map<String, dynamic>>[],
          'unread_count': data['unread_count'] is int ? data['unread_count'] as int : 0,
        };
      }
    } catch (e) {
      print('Error fetching my push notifications: $e');
    }
    return {'notifications': <Map<String, dynamic>>[], 'unread_count': 0};
  }

  /// Mark my push notifications as read (resets unread count)
  static Future<bool> markMyPushNotificationsRead() async {
    try {
      final headers = await _getAuthHeaders();
      final resp = await http.post(
        Uri.parse('$baseUrl/auth/my-push-notifications/mark-read/'),
        headers: headers,
        body: jsonEncode({}),
      ).timeout(const Duration(seconds: 10));
      return resp.statusCode == 200;
    } catch (e) {
      print('Error marking push notifications read: $e');
      return false;
    }
  }

  /// Fetch chat messages between two users using ChatMessage API (new WhatsApp/Telegram-like chat)
  /// Uses the new ChatMessage model endpoint for real-time chat history
  static Future<List<Map<String, dynamic>>> fetchChatMessages(String senderUsername, String recipientUsername, {String? otherUserId, String? groupId}) async {
    String url = '$chatMessagesEndpoint?sender=$senderUsername&recipient=$recipientUsername';
    if (otherUserId != null) {
      url += '&other_user_id=$otherUserId';
    }
    if (groupId != null) {
      url += '&group_id=$groupId';
    }
    final uri = Uri.parse(url);
    final headers = await _getAuthHeaders();
    final resp = await http.get(uri, headers: headers).timeout(const Duration(seconds: 30));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      if (data is List) return List<Map<String, dynamic>>.from(data);
      if (data is Map && data.containsKey('results')) {
        return List<Map<String, dynamic>>.from(data['results'] as List);
      }
      return [];
    }
    throw Exception('Failed to fetch chat messages: ${resp.statusCode}');
  }

  /// Fetch list of active conversations with unread counts
  static Future<List<Map<String, dynamic>>> fetchConversations() async {
    try {
      final headers = await _getAuthHeaders();
      final uri = Uri.parse('${chatMessagesEndpoint}conversations/');
      final resp = await http.get(uri, headers: headers).timeout(const Duration(seconds: 30));
      
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        return [];
      }
      return [];
    } catch (e) {
      print('Error fetching conversations: $e');
      return [];
    }
  }

  /// Mark all messages in a conversation as read
  static Future<bool> markConversationRead(String senderId) async {
    try {
      final headers = await _getAuthHeaders();
      final resp = await http.post(
        Uri.parse('${chatMessagesEndpoint}mark_conversation_read/'),
        headers: headers,
        body: jsonEncode({'other_user_id': senderId}),
      ).timeout(const Duration(seconds: 30));
      
      if (resp.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      print('Error marking conversation read: $e');
      return false;
    }
  }

  /// Mark all messages in a group as read (WhatsApp-like: opening chat clears unread)
  static Future<bool> markGroupRead(String groupId) async {
    try {
      final headers = await _getAuthHeaders();
      final resp = await http.post(
        Uri.parse('$baseUrl/student-parent/chat-groups/$groupId/mark_read/'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));
      
      if (resp.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      print('Error marking group read: $e');
      return false;
    }
  }

  /// Fetch chat messages between two users (sender and recipient usernames)
  /// @deprecated Use fetchChatMessages instead for real-time chat. This is kept for backward compatibility.
  static Future<List<Map<String, dynamic>>> fetchCommunications(String senderUsername, String recipientUsername) async {
    final uri = Uri.parse('$communicationsEndpoint?sender=$senderUsername&recipient=$recipientUsername');
    final headers = await _getAuthHeaders();
    final resp = await http.get(uri, headers: headers).timeout(const Duration(seconds: 30));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      if (data is List) return List<Map<String, dynamic>>.from(data);
      if (data is Map && data.containsKey('results')) {
        return List<Map<String, dynamic>>.from(data['results'] as List);
      }
      return [];
    }
    throw Exception('Failed to fetch communications: ${resp.statusCode}');
  }

  static Future<List<dynamic>> fetchTeachers() async {
    final headers = await _getAuthHeaders();
    final resp = await http
        .get(Uri.parse(teachersEndpoint), headers: headers)
        .timeout(const Duration(seconds: 10));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      if (data is List) return data;
      if (data is Map && data.containsKey('results')) {
        return data['results'] as List;
      }
      return [];
    }
    throw Exception('Failed to fetch teachers: ${resp.statusCode}');
  }

  static Future<List<dynamic>> fetchStudents() async {
    final headers = await _getAuthHeaders();
    final resp = await http
        .get(Uri.parse(studentsEndpoint), headers: headers)
        .timeout(const Duration(seconds: 30));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      if (data is List) return data;
      if (data is Map && data.containsKey('results')) {
        return data['results'] as List;
      }
      return [];
    }
    throw Exception('Failed to fetch students: ${resp.statusCode}');
  }

  /// Fetch parent profile data
  static Future<Map<String, dynamic>?> fetchParentProfile() async {
    try {
      final headers = await _getAuthHeaders();
      final resp = await http
          .get(Uri.parse(parentEndpoint), headers: headers)
          .timeout(const Duration(seconds: 30));
      
      // Log response for debugging
      print('Parent profile API response: status=${resp.statusCode}, body=${resp.body}');
      
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is List && data.isNotEmpty) {
          return Map<String, dynamic>.from(data[0] as Map);
        }
        if (data is Map) {
          // Check if it's an error response
          if (data.containsKey('error')) {
            print('Parent profile API returned error: ${data['error']}');
            return null;
          }
          return Map<String, dynamic>.from(data);
        }
      } else if (resp.statusCode == 404) {
        print('Parent profile not found (404)');
        return null;
      } else {
        print('Parent profile API error: status=${resp.statusCode}, body=${resp.body}');
        return null;
      }
      return null;
    } catch (e) {
      print('Exception fetching parent profile: $e');
      return null; // Return null instead of throwing to allow fallback handling
    }
  }

  /// Fetch student data by student ID
  static Future<Map<String, dynamic>?> fetchStudentById(int studentId) async {
    try {
      final headers = await _getAuthHeaders();
      final resp = await http
          .get(Uri.parse('$studentsEndpoint$studentId/'), headers: headers)
          .timeout(const Duration(seconds: 30));
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch student: $e');
    }
  }

  /// Fetch current logged-in student's profile
  static Future<Map<String, dynamic>?> fetchStudentProfile() async {
    try {
      final headers = await _getAuthHeaders();
      final resp = await http
          .get(Uri.parse('$parentBase/student-profile/'), headers: headers)
          .timeout(const Duration(seconds: 30));
      
      print('Student profile API response: status=${resp.statusCode}');
      
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        print('Student profile data keys: ${data is Map<String, dynamic> ? data.keys : 'not a map'}');
        if (data is Map) {
          print('Student name in profile: ${data['student_name']}');
          print('Student email in profile: ${data['email']}');
          return Map<String, dynamic>.from(data);
        }
      } else {
        print('Student profile API error: status=${resp.statusCode}, body=${resp.body}');
      }
      return null;
    } catch (e) {
      print('Exception fetching student profile: $e');
      return null; // Return null instead of throwing to allow fallback handling
    }
  }

  /// Fetch all awards for the school
  static Future<List<dynamic>> fetchAllAwards() async {
    try {
      final headers = await _getAuthHeaders();
      final resp = await http
          .get(Uri.parse('$_base/awards/'), headers: headers)
          .timeout(const Duration(seconds: 30));
      
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is List) return data;
        if (data is Map && data.containsKey('results')) {
          return data['results'] as List;
        }
        return [];
      }
      return [];
    } catch (e) {
      print('Exception fetching all awards: $e');
      return [];
    }
  }
  // Fetch chat groups for current user
  static Future<List<Map<String, dynamic>>> fetchGroups() async {
    try {
      final headers = await _getAuthHeaders();
      final uri = Uri.parse('http://localhost:8000/api/student-parent/chat-groups/');
      
      final resp = await http.get(uri, headers: headers).timeout(const Duration(seconds: 15));
      
      print('Fetch groups status: ${resp.statusCode}');
      
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        print('Fetch groups decoded data type: ${data.runtimeType}');
        
        // Handle paginated response format: {count, next, previous, results: [...]}
        if (data is Map && data.containsKey('results')) {
          final results = data['results'];
          if (results is List) {
            print('Fetch groups - returning ${results.length} groups from paginated response');
            return List<Map<String, dynamic>>.from(results);
          }
        }
        
        // Handle direct list response (fallback)
        if (data is List) {
          print('Fetch groups - returning ${data.length} groups from direct list');
          return List<Map<String, dynamic>>.from(data);
        }
        
        print('Fetch groups - unexpected format, returning empty');
        return [];
      }
      return [];
    } catch (e) {
      print('Error fetching groups: $e');
      return [];
    }
  }

  /// Delete a message (soft delete)
  static Future<bool> deleteMessage(String messageId) async {
    try {
      final headers = await _getAuthHeaders();
      final uri = Uri.parse('http://localhost:8000/api/student-parent/chat-messages/$messageId/delete_message/');
      
      final resp = await http.post(uri, headers: headers).timeout(const Duration(seconds: 30));
      return resp.statusCode == 200;
    } catch (e) {
      print('Error deleting message: $e');
      return false;
    }
  }

  /// Get detailed group members (with Class/Section, Subject, is_creator)
  static Future<Map<String, dynamic>> getGroupMembers(String groupId) async {
    try {
      final headers = await _getAuthHeaders();
      final uri = Uri.parse('http://localhost:8000/api/student-parent/chat-groups/$groupId/get_members/');
      final resp = await http.get(uri, headers: headers).timeout(const Duration(seconds: 30));
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      print('Error fetching group members: $e');
      return {};
    }
  }

  static Future<bool> updateGroupName(String groupId, String name) async {
    try {
      final headers = await _getAuthHeaders();
      final resp = await http.patch(
        Uri.parse('http://localhost:8000/api/student-parent/chat-groups/$groupId/'),
        headers: headers,
        body: jsonEncode({'name': name}),
      );
      return resp.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> removeGroupMember(String groupId, String userId) async {
    try {
      final headers = await _getAuthHeaders();
      final resp = await http.post(
        Uri.parse('http://localhost:8000/api/student-parent/chat-groups/$groupId/remove_members/'),
        headers: headers,
        body: jsonEncode({'member_ids': [userId]}),
      );
      return resp.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<List<dynamic>> getAddableGroupMembers(String groupId) async {
    try {
      final headers = await _getAuthHeaders();
      final resp = await http.get(Uri.parse('http://localhost:8000/api/student-parent/chat-groups/$groupId/list_addable_members/'), headers: headers);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return data['users'] as List<dynamic>? ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> addGroupMembers(String groupId, List<String> userIds) async {
    try {
      final headers = await _getAuthHeaders();
      final resp = await http.post(
        Uri.parse('http://localhost:8000/api/student-parent/chat-groups/$groupId/add_members/'),
        headers: headers,
        body: jsonEncode({'member_ids': userIds}),
      );
      return resp.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Send a message with an optional attachment via REST API
  static Future<Map<String, dynamic>?> sendMessageWithAttachment({
    required String recipient,
    String? messageText,
    String? filePath,
    List<int>? fileBytes,
    String? fileName,
    String messageType = 'text',
    String? otherUserId,
    String? groupId,
    String? repliedTo,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      // Remove Content-Type from headers as MultipartRequest will set its own
      final authHeaders = Map<String, String>.from(headers)..remove('Content-Type');
      
      final uri = Uri.parse('http://localhost:8000/api/student-parent/chat-messages/');
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(authHeaders);
      
      // Add text fields
      if (groupId != null && groupId.isNotEmpty) {
        request.fields['group_id'] = groupId;
      } else {
        // For 1-to-1 messages, recipient or recipient_id is required
        if (recipient.isNotEmpty) {
          request.fields['recipient'] = recipient;
        }
        if (otherUserId != null && otherUserId.isNotEmpty) {
          request.fields['recipient_id'] = otherUserId;
        }
      }
      
      request.fields['message_text'] = messageText ?? ''; // Always send (empty for attachment-only)
      
      // Only set message_type to image/file/video if a file is actually attached
      // If no file is attached, force message_type to 'text'
      if (fileBytes != null || (filePath != null && filePath.isNotEmpty)) {
        // Auto-detect type from filename if available
        if (fileName != null) {
          final ext = fileName.toLowerCase().split('.').last;
          if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) {
            messageType = 'image';
          } else if (['mp4', 'avi', 'mov', 'mkv'].contains(ext)) {
            messageType = 'video';
          } else {
            messageType = 'file';
          }
        } else {
          messageType = 'file';
        }
      } else {
        // No file attached, must be text message
        messageType = 'text';
      }
      request.fields['message_type'] = messageType;
      
      if (repliedTo != null) {
        request.fields['replied_to'] = repliedTo;
      }
      
      // Platform-specific file handling
      if (fileBytes != null && fileName != null) {
        // Web platform: use bytes
        try {
          request.files.add(http.MultipartFile.fromBytes(
            'attachment',
            fileBytes,
            filename: fileName,
          ));
          print('Added attachment from bytes: $fileName (${fileBytes.length} bytes)');
        } catch (e) {
          print('Error adding file from bytes: $e');
          return null;
        }
      } else if (filePath != null && filePath.isNotEmpty) {
        // Mobile/Desktop platform: use file path
        try {
          final file = await http.MultipartFile.fromPath('attachment', filePath);
          request.files.add(file);
          print('Added attachment from path: $filePath');
        } catch (e) {
          print('Error adding file from path: $e');
          return null;
        }
      }
      
      // Debug: Log request details
      print('Sending message with ${request.files.length} file(s)');
      print('Message type: $messageType');
      print('Message text: ${messageText ?? "(empty)"}');
      print('Recipient: $recipient');
      print('Group ID: $groupId');
      print('Other User ID: $otherUserId');
      
      final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
      final resp = await http.Response.fromStream(streamedResponse);
      
      if (resp.statusCode == 201 || resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      } else {
        // Log error for debugging
        print('Failed to send message with attachment: ${resp.statusCode}');
        print('Response body: ${resp.body}');
        print('Request fields: ${request.fields}');
        print('Request files count: ${request.files.length}');
      }
      return null;
    } catch (e) {
      print('Error sending message with attachment: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> fetchAttendanceHistory({String? studentId}) async {
    try {
      final headers = await _getAuthHeaders();
      String url = '$parentBase/dashboard/attendance_history/';
      if (studentId != null) {
        url += '?student_id=$studentId';
      }
      final resp = await http.get(Uri.parse(url), headers: headers);
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error fetching attendance history: $e');
      return null;
    }
  }
  static Future<Map<String, dynamic>?> fetchDayDetails({
    required DateTime date,
    required String studentId,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final url = '$parentBase/dashboard/day_details/?date=$dateStr&student_id=$studentId';
      
      print('Fetching day details: $url');
      final resp = await http.get(Uri.parse(url), headers: headers);
      
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      } else {
        print('Error fetching day details: ${resp.body}');
      }
      return null;
    } catch (e) {
      print('Exception fetching day details: $e');
      return null;
    }
  }


  static Future<List<dynamic>?> fetchStudentExams({
    String? studentId,
    String? classId,
    String? sectionId,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      String url = '$parentBase/dashboard/student_exams/';
      
      List<String> queryParams = [];
      if (studentId != null && studentId.isNotEmpty) queryParams.add('student_id=$studentId');
      if (classId != null && classId.isNotEmpty) queryParams.add('class_id=$classId');
      if (sectionId != null && sectionId.isNotEmpty) queryParams.add('section_id=$sectionId');
      
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }
      
      print('Fetching student exams: $url');
      final resp = await http.get(Uri.parse(url), headers: headers);
      
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as List<dynamic>;
      } else {
        print('Error fetching student exams: ${resp.body}');
      }
      return null;
    } catch (e) {
      print('Exception fetching student exams: $e');
      return null;
    }
  }

  static Future<List<dynamic>?> fetchAllExams({String? studentId}) async {
    try {
      final headers = await _getAuthHeaders();
      String url = '$parentBase/dashboard/all_exams/';
      if (studentId != null) url += '?student_id=$studentId';
      
      print('Fetching ALL exams: $url');
      final resp = await http.get(Uri.parse(url), headers: headers);
      
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as List<dynamic>;
      } else {
        print('Error fetching all exams: ${resp.body}');
      }
      return null;
    } catch (e) {
      print('Exception fetching all exams: $e');
      return null;
    }
  }

  static Future<List<dynamic>?> fetchRecentEvents({String? studentId}) async {
    try {
      final headers = await _getAuthHeaders();
      // Using existing dashboard base URL pattern
      String url = '$parentBase/dashboard/recent_events/';
      
      if (studentId != null && studentId.isNotEmpty) {
        url += '?student_id=$studentId';
      }
      
      print('Fetching recent events: $url');
      final resp = await http.get(Uri.parse(url), headers: headers);
      
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as List<dynamic>;
      } else {
        print('Error fetching recent events: ${resp.body}');
      }
      return null;
    } catch (e) {
      print('Exception fetching recent events: $e');
      return null;
    }
  }

  static Future<List<dynamic>?> fetchAllEvents({String? studentId}) async {
    try {
      final headers = await _getAuthHeaders();
      String url = '$parentBase/dashboard/all_events/';
      
      if (studentId != null && studentId.isNotEmpty) {
        url += '?student_id=$studentId';
      }
      
      print('Fetching all events: $url');
      final resp = await http.get(Uri.parse(url), headers: headers);
      
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as List<dynamic>;
      } else {
        print('Error fetching all events: ${resp.body}');
      }
      return null;
    } catch (e) {
      print('Exception fetching all events: $e');
      return null;
    }
  }

  static Future<List<dynamic>?> fetchActivities({String? studentId}) async {
    try {
      final headers = await _getAuthHeaders();
      String url = '$parentBase/dashboard/activities/';
      
      if (studentId != null && studentId.isNotEmpty) {
        url += '?student_id=$studentId';
      }
      
      print('Fetching activities: $url');
      final resp = await http.get(Uri.parse(url), headers: headers);
      
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as List<dynamic>;
      } else {
        print('Error fetching activities: ${resp.body}');
      }
      return null;
    } catch (e) {
      print('Exception fetching activities: $e');
      return null;
    }
  }

  /// Fetch homework for a student
  static Future<List<dynamic>?> fetchHomework({String? studentId}) async {
    try {
      final headers = await _getAuthHeaders();
      String url = '$parentBase/dashboard/homework/';
      if (studentId != null && studentId.isNotEmpty) {
        url += '?student_id=$studentId';
      }
      
      print('Fetching homework: $url');
      final resp = await http.get(Uri.parse(url), headers: headers);
      
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as List<dynamic>;
      } else {
        print('Error fetching homework: ${resp.body}');
      }
      return null;
    } catch (e) {
      print('Exception fetching homework: $e');
      return null;
    }
  }
  static Future<http.Response> authenticatedRequest(String endpoint, {String method = 'GET', Map<String, dynamic>? body}) async {
    final headers = await _getAuthHeaders();
    final urlStr = endpoint.startsWith('http') ? endpoint : '$baseUrl/$endpoint';
    final url = Uri.parse(urlStr);
    
    switch (method.toUpperCase()) {
      case 'POST':
        return await http.post(url, headers: headers, body: jsonEncode(body));
      case 'PUT':
        return await http.put(url, headers: headers, body: jsonEncode(body));
      case 'PATCH':
        return await http.patch(url, headers: headers, body: jsonEncode(body));
      case 'DELETE':
        return await http.delete(url, headers: headers);
      case 'GET':
      default:
        return await http.get(url, headers: headers);
    }
  }
  static Future<bool> editMessage(String messageId, String newText) async {
    try {
      final headers = await _getAuthHeaders();
      final resp = await http.patch(
        Uri.parse('http://127.0.0.1:8000/api/student-parent/chat-messages/$messageId/'),
        headers: headers,
        body: jsonEncode({'message_text': newText}),
      );
      return resp.statusCode == 200;
    } catch (e) {
      print('Error editing message: $e');
      return false;
    }
  }
}
