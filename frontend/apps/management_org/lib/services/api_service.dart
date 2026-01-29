import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:core/api/endpoints.dart';

class ApiService {
  static const _base = 'http://localhost:8000/api/management-admin';
  static const String teachersEndpoint = '$_base/teachers/';
  static const String studentsEndpoint = '$_base/students/';
  static const String studentParentBase = 'http://localhost:8000/api/student-parent';

  /// Fetch all teachers from the backend
  static Future<List<dynamic>> fetchTeachers() async {
    try {
      final response = await http.get(
        Uri.parse(teachersEndpoint),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Handle both direct list and paginated response
        if (data is List) {
          return data;
        } else if (data is Map && data.containsKey('results')) {
          return data['results'] as List;
        }
        return [];
      } else {
        throw Exception('Failed to fetch teachers: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching teachers: $e');
    }
  }

  /// Fetch all students from the backend
  static Future<List<dynamic>> fetchStudents() async {
    try {
      final response = await http.get(
        Uri.parse(studentsEndpoint),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Handle both direct list and paginated response
        if (data is List) {
          return data;
        } else if (data is Map && data.containsKey('results')) {
          return data['results'] as List;
        }
        return [];
      } else {
        throw Exception('Failed to fetch students: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching students: $e');
    }
  }

  /// Create a new teacher
  static Future<Map<String, dynamic>> createTeacher(
    Map<String, dynamic> teacherData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(teachersEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(teacherData),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorBody = response.body.isNotEmpty ? response.body : 'No error details';
        throw Exception('Failed to create teacher: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      throw Exception('Error creating teacher: $e');
    }
  }

  /// Create a new student
  static Future<Map<String, dynamic>> createStudent(
    Map<String, dynamic> studentData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(studentsEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(studentData),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorBody = response.body.isNotEmpty ? response.body : 'No error details';
        throw Exception('Failed to create student: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      throw Exception('Error creating student: $e');
    }
  }

  /// Update a teacher
  static Future<Map<String, dynamic>> updateTeacher(
    int teacherId,
    Map<String, dynamic> teacherData,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$teachersEndpoint$teacherId/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(teacherData),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update teacher: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating teacher: $e');
    }
  }

  /// Fetch a single teacher by id
  static Future<Map<String, dynamic>> fetchTeacherById(int teacherId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$teachersEndpoint$teacherId/'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      throw Exception(
        'Failed to fetch teacher: ${response.statusCode} ${response.body}',
      );
    } catch (e) {
      throw Exception('Error fetching teacher: $e');
    }
  }

  /// Update a student
  static Future<Map<String, dynamic>> updateStudent(
    int studentId,
    Map<String, dynamic> studentData,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$studentsEndpoint$studentId/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(studentData),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update student: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating student: $e');
    }
  }

  /// Delete a student
  static Future<void> deleteStudent(int id) async {
    final url = Uri.parse('$_base/students/$id/');
    final resp = await http.delete(url);
    if (resp.statusCode != 200 && resp.statusCode != 204) {
      throw Exception('Failed to delete student: ${resp.statusCode} ${resp.body}');
    }
  }

  /// Delete a teacher
  static Future<void> deleteTeacher(int id) async {
    final url = Uri.parse('$_base/teachers/$id/');
    final resp = await http.delete(url);
    if (resp.statusCode != 200 && resp.statusCode != 204) {
      throw Exception('Failed to delete teacher: ${resp.statusCode} ${resp.body}');
    }
  }

  /// Fetch a single student by id
  static Future<Map<String, dynamic>> fetchStudentById(int studentId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$studentsEndpoint$studentId/'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      throw Exception(
        'Failed to fetch student: ${response.statusCode} ${response.body}',
      );
    } catch (e) {
      throw Exception('Error fetching student: $e');
    }
  }
  static Future<void> deleteExamination(int id) async {
    final url = Uri.parse('${Endpoints.examinations}$id/');
    final resp = await http.delete(url);
    if (resp.statusCode != 200 && resp.statusCode != 204) {
      throw Exception('Failed to delete examination: ${resp.statusCode} ${resp.body}');
    }
  }

  static Future<Map<String, dynamic>> updateExamination(
    int id,
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse('${Endpoints.examinations}$id/');
    final resp = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data)
    );
     if (resp.statusCode == 200) {
        return jsonDecode(resp.body);
      } else {
        throw Exception('Failed to update examination: ${resp.statusCode}');
      }
  }
}
