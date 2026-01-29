import 'package:flutter/material.dart';
import 'package:core/api/api_service.dart';
import 'package:core/api/endpoints.dart';

/// Dialog for viewing and adding students to a bus stop
class StudentListDialog extends StatefulWidget {
  final String? stopId;
  final String stopName;
  final String routeType;
  final String? busId;
  final List<dynamic>? initialStudents;

  const StudentListDialog({
    super.key,
    required this.stopId,
    required this.stopName,
    required this.routeType,
    this.busId,
    this.initialStudents,
  });

  @override
  State<StudentListDialog> createState() => _StudentListDialogState();
}

class _StudentListDialogState extends State<StudentListDialog> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = false;
  bool _isAdding = false;
  final _studentIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialStudents != null) {
      _students = widget.initialStudents!
          .map((s) => s as Map<String, dynamic>)
          .toList();
    } else if (widget.stopId != null) {
      _loadStudents();
    }
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    if (widget.stopId == null) return;

    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get('${Endpoints.busStops}${widget.stopId}/students/');
      if (response.success && mounted) {
        setState(() {
          _students = (response.data as List?)
                  ?.map((s) => s as Map<String, dynamic>)
                  .toList() ??
              [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading students: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addStudent() async {
    final studentId = _studentIdController.text.trim();
    if (studentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a student ID')),
      );
      return;
    }

    if (widget.stopId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please save the stop first before adding students')),
      );
      return;
    }

    setState(() => _isAdding = true);
    try {
      // First, find the student by student_id
      final studentsResponse = await _apiService.get(Endpoints.students);
      if (!studentsResponse.success) {
        throw Exception('Failed to fetch students');
      }

      List<dynamic> allStudents = [];
      if (studentsResponse.data is List) {
        allStudents = studentsResponse.data as List;
      } else if (studentsResponse.data is Map && (studentsResponse.data as Map)['results'] != null) {
        allStudents = (studentsResponse.data as Map)['results'] as List;
      }

      // Find student by student_id
      final student = allStudents.firstWhere(
        (s) => s['student_id']?.toString() == studentId ||
            s['id']?.toString() == studentId,
        orElse: () => null,
      );

      if (student == null) {
        throw Exception('Student with ID $studentId not found');
      }

      // Add student to stop
      final response = await _apiService.post(
        Endpoints.busStopStudents,
        body: {
          'stop': widget.stopId,
          'student_id': studentId,
        },
      );

      if (response.success && mounted) {
        // Reload students
        await _loadStudents();
        _studentIdController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student added successfully')),
        );
      } else {
        // Check if error contains bus assignment info
        final errorMessage = response.error ?? 'Failed to add student';
        String? assignedBusNumber;
        
        // Try to extract bus number from error message
        if (errorMessage.contains('already assigned to Bus Number')) {
          // Extract bus number from error message
          final busNumberMatch = RegExp(r'Bus Number: ([^\s.]+)').firstMatch(errorMessage);
          if (busNumberMatch != null) {
            assignedBusNumber = busNumberMatch.group(1);
          }
        }
        
        // Also check response data for assigned_bus_number
        if (response.data is Map) {
          final dataMap = response.data as Map;
          if (dataMap['assigned_bus_number'] != null) {
            assignedBusNumber = dataMap['assigned_bus_number'].toString();
          }
        }
        
        // If student is assigned to another bus, show popup
        if (assignedBusNumber != null && assignedBusNumber.isNotEmpty) {
          if (mounted) {
            await showDialog(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 28),
                    SizedBox(width: 10),
                    Text('Student Already Assigned'),
                  ],
                ),
                content: Text(
                  'The student with ID $studentId is already assigned to Bus Number: $assignedBusNumber\n\n'
                  'Please remove the student from that bus first before assigning to this bus.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
          return; // Prevent showing error snackbar
        }
        
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (mounted) {
        // Only show snackbar if it's not a bus assignment error (already handled above)
        final errorStr = e.toString();
        if (!errorStr.contains('already assigned to Bus Number')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding student: $e')),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }

  Future<void> _removeStudent(String studentStopId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Student'),
        content: const Text('Are you sure you want to remove this student from this stop?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final response = await _apiService.delete('${Endpoints.busStopStudents}$studentStopId/');
      if (response.success && mounted) {
        await _loadStudents();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student removed successfully')),
        );
      } else {
        throw Exception(response.error ?? 'Failed to remove student');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing student: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddStudentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Student'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _studentIdController,
              decoration: const InputDecoration(
                labelText: 'Student ID *',
                hintText: 'Enter student ID',
                border: OutlineInputBorder(),
                helperText: 'Enter the student ID to fetch student details',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _studentIdController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isAdding ? null : () async {
              Navigator.pop(context);
              await _addStudent();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
              foregroundColor: Colors.white,
            ),
            child: _isAdding
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Add Student'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.stopName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.routeType == 'morning' ? 'Morning' : 'Afternoon'} Route - Students',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Add Student Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: widget.stopId == null ? null : _showAddStudentDialog,
                      icon: const Icon(Icons.person_add),
                      label: const Text('Add Student'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF51CF66),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Students List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _students.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline,
                                  size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No students assigned',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Click "Add Student" to assign students',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _students.length,
                          itemBuilder: (context, index) {
                            final student = _students[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFF667EEA),
                                  child: Text(
                                    (student['student_name']?[0] ?? 'S')
                                        .toUpperCase(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(
                                  student['student_name'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      'ID: ${student['student_id'] ?? student['student_id_string'] ?? 'N/A'}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      'Class: ${student['student_class'] ?? 'N/A'} | Section: ${student['student_section'] ?? 'N/A'}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => _removeStudent(
                                    student['id']?.toString() ?? '',
                                  ),
                                  tooltip: 'Remove Student',
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

