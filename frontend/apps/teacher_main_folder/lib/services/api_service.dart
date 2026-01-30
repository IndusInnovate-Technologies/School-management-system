import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const _base = 'http://127.0.0.1:8000/api/management-admin';
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  static String get wsBaseUrl => baseUrl.replaceFirst('http', 'ws').replaceFirst('/api', '');
  static const teachersEndpoint = '$_base/teachers/';
  static const studentsEndpoint = '$_base/students/';
  static const teacherBase = 'http://127.0.0.1:8000/api/teacher';

  static Future<http.Response> authenticatedRequest(String endpoint, {String method = 'GET', Map<String, dynamic>? body}) async {
    final headers = await getAuthHeaders();
    // Helper to ensure we don't double slashes or miss them
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    final uri = Uri.parse('$baseUrl/$cleanEndpoint');
    
    debugPrint('AuthenticatedRequest: $method $uri');

    if (method == 'GET') {
      return await http.get(uri, headers: headers);
    } else if (method == 'POST') {
      return await http.post(uri, headers: headers, body: jsonEncode(body));
    } else if (method == 'PUT') {
      return await http.put(uri, headers: headers, body: jsonEncode(body));
    } else if (method == 'PATCH') {
       return await http.patch(uri, headers: headers, body: jsonEncode(body));
    } else if (method == 'DELETE') {
      return await http.delete(uri, headers: headers);
    }
    
    throw UnimplementedError('Method $method not implemented');
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
      debugPrint('Error getting auth headers: $e');
    }
    
    return headers;
  }

  /// Get authentication headers with token (public)
  static Future<Map<String, String>> getAuthHeaders() async {
    return await _getAuthHeaders();
  }

  static Future<List<dynamic>> fetchStudents() async {
    try {
      final headers = await _getAuthHeaders();
      final resp = await http
          .get(Uri.parse(studentsEndpoint), headers: headers)
          .timeout(const Duration(seconds: 30));
      
      debugPrint('Fetch students status: ${resp.statusCode}');
      final bodyPreview = resp.body.length > 200 ? resp.body.substring(0, 200) : resp.body;
      debugPrint('Fetch students response preview: $bodyPreview');
      
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is List) {
          debugPrint('Fetched ${data.length} students');
          return data;
        }
        if (data is Map && data.containsKey('results')) {
          final results = data['results'] as List;
          debugPrint('Fetched ${results.length} students from paginated response');
          return results;
        }
        debugPrint('No students found in response');
        return [];
      }
      throw Exception('Failed to fetch students: ${resp.statusCode}');
    } catch (e) {
      debugPrint('Error fetching students: $e');
      rethrow;
    }
  }

  static Future<List<dynamic>> fetchTeachers() async {
    try {
      final headers = await _getAuthHeaders();
      final resp = await http
          .get(Uri.parse(teachersEndpoint), headers: headers)
          .timeout(const Duration(seconds: 30));
      
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is List) {
          debugPrint('Fetched ${data.length} teachers');
          return data;
        }
        if (data is Map && data.containsKey('results')) {
          final results = data['results'] as List;
          debugPrint('Fetched ${results.length} teachers from paginated response');
          return results;
        }
        return [];
        return [];
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching teachers: $e');
      rethrow;
    }
  }

  static Future<List<dynamic>> fetchDepartments() async {
    try {
      final headers = await _getAuthHeaders();
      final resp = await http
          .get(Uri.parse('$_base/departments/'), headers: headers)
          .timeout(const Duration(seconds: 30));
      
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is List) {
          debugPrint('Fetched ${data.length} departments');
          return data;
        }
        if (data is Map && data.containsKey('results')) {
          final results = data['results'] as List;
          debugPrint('Fetched ${results.length} departments from paginated response');
          return results;
        }
        return [];
      }
      throw Exception('Failed to fetch departments: ${resp.statusCode}');
    } catch (e) {
      debugPrint('Error fetching departments: $e');
      // Return empty list instead of rethrowing to prevent UI crash, 
      // or rethrow if you want to handle it in UI.
      // Given the offline issues, let's return mock if needed or just empty.
      return []; 
    }
  }

  /// Fetch current logged-in teacher's profile
  static Future<Map<String, dynamic>?> fetchTeacherProfile() async {
    try {
      final headers = await _getAuthHeaders();
      final resp = await http
          .get(Uri.parse('http://127.0.0.1:8000/api/teacher/profile/'), headers: headers)
          .timeout(const Duration(seconds: 30));
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
      debugPrint('Failed to fetch teacher profile: ${resp.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Failed to fetch teacher profile: $e');
      return null;
    }
  }

  /// Fetch classes assigned to the current teacher
  static Future<List<dynamic>> fetchTeacherClasses() async {
    try {
      final headers = await _getAuthHeaders();
      final resp = await http
          .get(Uri.parse('http://127.0.0.1:8000/api/teacher/classes/'), headers: headers)
          .timeout(const Duration(seconds: 30));
      
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is List) return data;
        if (data is Map && data.containsKey('results')) return data['results'] as List;
        return [];
      }
      debugPrint('Failed to fetch teacher classes: ${resp.statusCode}');
      return [];
    } catch (e) {
      debugPrint('Error fetching teacher classes: $e');
      return [];
    }
  }

  /// Fetch students for a specific class ID
  static Future<List<dynamic>> fetchClassStudents(int classId) async {
    try {
      final headers = await _getAuthHeaders();
      final resp = await http
          .get(Uri.parse('http://127.0.0.1:8000/api/teacher/class-students/?class_obj=$classId'), headers: headers)
          .timeout(const Duration(seconds: 30));
      
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is List) return data;
        if (data is Map && data.containsKey('results')) return data['results'] as List;
        return [];
      }
      debugPrint('Failed to fetch class students: ${resp.statusCode}');
      return [];
    } catch (e) {
      debugPrint('Error fetching class students: $e');
      return [];
    }
  }

  /// Fetch all communications for the teacher
  static Future<List<dynamic>> fetchCommunications() async {
    try {
      final headers = await _getAuthHeaders();
      final resp = await http
          .get(Uri.parse('http://127.0.0.1:8000/api/teacher/communications/'), headers: headers)
          .timeout(const Duration(seconds: 30));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is List) return data;
        return [];
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch communications: $e');
    }
  }



  /// Fetch students from teacher's assigned classes via class-students endpoint
  static Future<List<dynamic>> fetchStudentsFromClasses() async {
    try {
      final headers = await _getAuthHeaders();
      final resp = await http
          .get(Uri.parse('http://127.0.0.1:8000/api/teacher/class-students/'), headers: headers)
          .timeout(const Duration(seconds: 15));
      
      debugPrint('Fetch class-students status: ${resp.statusCode}');
      final bodyPreview = resp.body.length > 200 ? resp.body.substring(0, 200) : resp.body;
      debugPrint('Fetch class-students response preview: $bodyPreview');
      
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        List<dynamic> classStudents = [];
        if (data is List) {
          classStudents = data;
        } else if (data is Map && data.containsKey('results')) {
          classStudents = data['results'] as List;
        }
        
        debugPrint('Fetched ${classStudents.length} class-student records');
        
        // Extract unique students from class-student records
        final studentsMap = <String, dynamic>{};
        for (var cs in classStudents) {
          try {
            final student = cs['student'];
            if (student != null && student is Map) {
              // Try multiple possible ID fields
              final studentId = student['id']?.toString() ?? 
                               student['student_id']?.toString() ?? 
                               student['user']?['user_id']?.toString() ?? '';
              
              if (studentId.isNotEmpty && !studentsMap.containsKey(studentId)) {
                // Ensure the student object has all necessary fields
                // If student comes from class-student, it might need user data merged
                final studentData = Map<String, dynamic>.from(student);
                
                // If student doesn't have 'user' field but has user data directly, structure it
                if (!studentData.containsKey('user') && studentData.containsKey('username')) {
                  studentData['user'] = {
                    'user_id': studentData['user_id'] ?? studentData['id'],
                    'username': studentData['username'],
                    'first_name': studentData['first_name'] ?? '',
                    'last_name': studentData['last_name'] ?? '',
                  };
                }
                
                studentsMap[studentId] = studentData;
              }
            }
          } catch (e) {
            debugPrint('Error processing class-student record: $e');
          }
        }
        
        final uniqueStudents = studentsMap.values.toList();
        debugPrint('Extracted ${uniqueStudents.length} unique students from classes');
        return uniqueStudents;
      } else {
        debugPrint('Failed to fetch class-students: ${resp.statusCode} - ${resp.body}');
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching students from classes: $e');
      return [];
    }
  }


  static Future<List<dynamic>> fetchTeacherExams() async {
    final headers = await _getAuthHeaders();
    final resp = await http.get(Uri.parse('$teacherBase/exams/'), headers: headers);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      if (data is List) {
        return data;
      }
      if (data is Map && data.containsKey('results')) {
        return data['results'] as List<dynamic>;
      }
    }
    return [];
  }

  static Future<dynamic> createExam(Map<String, dynamic> data) async {
    final headers = await _getAuthHeaders();
    debugPrint('Creating exam: $data');
    final resp = await http.post(
      Uri.parse('$teacherBase/exams/'),
      headers: headers,
      body: jsonEncode(data),
    );
    if (resp.statusCode == 201) {
      return jsonDecode(resp.body); // Success: Return the created object
    }
    debugPrint('Failed to create exam: ${resp.body}');
    return 'Error ${resp.statusCode}: ${resp.body}';
  }
  
  static Future<bool> deleteExam(int id) async {
    final headers = await _getAuthHeaders();
    final resp = await http.delete(Uri.parse('$teacherBase/exams/$id/'), headers: headers);
    return resp.statusCode == 204;
  }

  /// Fetch timetable for the logged-in teacher
  static Future<List<Map<String, dynamic>>> fetchTimetable() async {
    try {
      final headers = await _getAuthHeaders();
      final resp = await http
          .get(Uri.parse('http://127.0.0.1:8000/api/teacher/timetable/'), headers: headers)
          .timeout(const Duration(seconds: 30));
      
      debugPrint('Fetch timetable status: ${resp.statusCode}');
      
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is List) {
          debugPrint('Fetched ${data.length} timetable entries');
          return List<Map<String, dynamic>>.from(data);
        }
        if (data is Map && data.containsKey('results')) {
          final results = data['results'] as List;
          debugPrint('Fetched ${results.length} timetable entries from paginated response');
          return List<Map<String, dynamic>>.from(results);
        }
        debugPrint('No timetable entries found in response');
        return [];
      }
      debugPrint('Failed to fetch timetable: ${resp.statusCode}');
      return [];
    } catch (e) {
      debugPrint('Error fetching timetable: $e');
      return [];
    }
  }

  // ============================================================================
  // MESSAGING & GROUPS (Added to support Teacher_Communication.dart)
  // ============================================================================

  static Future<List<dynamic>> fetchConversations() async {
    try {
      final headers = await _getAuthHeaders();
      final resp = await http
          .get(Uri.parse('http://127.0.0.1:8000/api/student-parent/conversations/'), headers: headers)
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is List) return data;
        if (data is Map && data.containsKey('results')) return data['results'] as List;
        return [];
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching conversations: $e');
      return [];
    }
  }

  static Future<List<dynamic>> fetchGroups() async {
    try {
      final headers = await _getAuthHeaders();
      final resp = await http
          .get(Uri.parse('http://127.0.0.1:8000/api/student-parent/groups/'), headers: headers)
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is List) return data;
        if (data is Map && data.containsKey('results')) return data['results'] as List;
        return [];
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching groups: $e');
      return [];
    }
  }

  static Future<bool> markGroupRead(String groupId) async {
    try {
      final headers = await _getAuthHeaders();
      final resp = await http
          .post(Uri.parse('http://127.0.0.1:8000/api/student-parent/groups/$groupId/mark_read/'), headers: headers)
          .timeout(const Duration(seconds: 5));
      return resp.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> markConversationRead(String userId) async {
    try {
      final headers = await _getAuthHeaders();
      final resp = await http
          .post(
            Uri.parse('http://127.0.0.1:8000/api/student-parent/conversations/mark_read/'), 
            headers: headers,
            body: jsonEncode({'sender_id': userId}),
          )
          .timeout(const Duration(seconds: 5));
      return resp.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<dynamic> createGroup(Map<String, dynamic> data) async {
    try {
      final headers = await _getAuthHeaders();
      final resp = await http
          .post(
            Uri.parse('http://127.0.0.1:8000/api/student-parent/groups/'),
            headers: headers,
            body: jsonEncode(data),
          );
      if (resp.statusCode == 201) return jsonDecode(resp.body);
      return null;
    } catch (e) {
      debugPrint("Error creating group: $e");
      return null;
    }
  }

  static Future<List<dynamic>> getGroupMembers(String groupId) async {
    try {
      final headers = await _getAuthHeaders();
      // Assuming groups endpoint returns members in detail view
      final resp = await http.get(Uri.parse('http://127.0.0.1:8000/api/student-parent/groups/$groupId/'), headers: headers);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return data['members'] as List? ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> updateGroupName(String groupId, String name) async {
    try {
      final headers = await _getAuthHeaders();
      final resp = await http.patch(
        Uri.parse('http://127.0.0.1:8000/api/student-parent/groups/$groupId/'),
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
        Uri.parse('http://127.0.0.1:8000/api/student-parent/groups/$groupId/remove_member/'),
        headers: headers,
        body: jsonEncode({'user_id': userId}),
      );
      return resp.statusCode == 200;
    } catch (e) {
      return false;
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
      debugPrint('Error editing message: $e');
      return false;
    }
  }

  static Future<bool> deleteMessage(String messageId) async {
    try {
      final headers = await _getAuthHeaders();
      final resp = await http.delete(
        Uri.parse('http://127.0.0.1:8000/api/student-parent/chat-messages/$messageId/'),
        headers: headers,
      );
      return resp.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  static Future<List<dynamic>> fetchChatMessages(String user1, String user2, {String? otherUserId, String? groupId}) async {
    try {
      final headers = await _getAuthHeaders();
      // Use named params if provided, otherwise fallback to positional logic (though backend likely needs specific params)
      // If otherUserId/groupId are provided, we should probably use them in query params?
      // Based on Teacher_Communication usage vs original implementation:
      // The original implementation used 'user1' and 'user2' query params.
      // Teacher_Communication passes 'senderUsername' as user1, 'contactUsername/empty' as user2.
      // And passes 'otherUserId' / 'groupId'.
      
      var uri = Uri.parse('http://127.0.0.1:8000/api/student-parent/chat-messages/');
      final query = <String, String>{
        'user1': user1,
        'user2': user2,
      };
      if (otherUserId != null) query['other_user_id'] = otherUserId;
      if (groupId != null) query['group_id'] = groupId;
      
      uri = uri.replace(queryParameters: query);
      
      final resp = await http.get(uri, headers: headers);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is List) return data;
        if (data is Map && data.containsKey('results')) return data['results'] as List;
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching chat messages: $e');
      return [];
    }
  }

  static Future<List<dynamic>> fetchChatHistory(String contactId) async {
    try {
      final headers = await _getAuthHeaders();
      final resp = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/student-parent/chat-messages/?other_user_id=$contactId'), 
        headers: headers
      );
      if (resp.statusCode == 200) {
         final data = jsonDecode(resp.body);
         if (data is List) return data;
         if (data is Map && data.containsKey('results')) return data['results'] as List;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> sendMessageWithAttachment({
    required String recipient, 
    String? messageText,
    String? filePath,
    List<int>? fileBytes,
    String? fileName,
    String? messageType,
    String? groupId,
    String? otherUserId,
    String? repliedTo,
  }) async {
    try {
      debugPrint('=== sendMessageWithAttachment START ===');
      debugPrint('recipient: $recipient');
      debugPrint('messageText: $messageText');
      debugPrint('groupId: $groupId');
      debugPrint('otherUserId: $otherUserId');
      debugPrint('messageType: $messageType');
      
      final headers = await _getAuthHeaders();
      headers.remove('Content-Type'); 
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://127.0.0.1:8000/api/student-parent/chat-messages/'),
      );
      
      request.headers.addAll(headers);
      
      // Fields expected by usage
      if (recipient.isNotEmpty) {
        request.fields['recipient'] = recipient;
        debugPrint('Added field: recipient = $recipient');
      }
      if (messageText != null && messageText.isNotEmpty) {
        request.fields['message_text'] = messageText;
        debugPrint('Added field: message_text = $messageText');
      }
      if (groupId != null && groupId.isNotEmpty) {
        request.fields['group_id'] = groupId;
        debugPrint('Added field: group_id = $groupId');
      }
      if (otherUserId != null && otherUserId.isNotEmpty) {
        request.fields['recipient_id'] = otherUserId;
        debugPrint('Added field: recipient_id = $otherUserId');
      }
      if (repliedTo != null) {
        request.fields['reply_to'] = repliedTo;
        debugPrint('Added field: reply_to = $repliedTo');
      }
      
      // Handle File
      if (fileBytes != null && fileName != null) {
        // Web or Bytes
        request.files.add(http.MultipartFile.fromBytes(
          'attachment',
          fileBytes,
          filename: fileName,
        ));
        debugPrint('Added file from bytes: $fileName');
      } else if (filePath != null && filePath.isNotEmpty) {
        // Mobile/Desktop File Path
        request.files.add(await http.MultipartFile.fromPath(
          'attachment',
          filePath,
          filename: fileName,
        ));
        debugPrint('Added file from path: $filePath');
      }

      debugPrint('Sending request to backend...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final result = jsonDecode(response.body);
        debugPrint('=== sendMessageWithAttachment SUCCESS ===');
        return result;
      }
      debugPrint('Failed to send message: ${response.statusCode} - ${response.body}');
      debugPrint('=== sendMessageWithAttachment FAILED ===');
      return null;
    } catch (e) {
      debugPrint("Error sending message: $e");
      return null;
    }
  }
}

