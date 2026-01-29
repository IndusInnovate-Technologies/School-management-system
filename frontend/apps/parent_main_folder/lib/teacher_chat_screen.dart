import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'dart:convert';
import 'dart:async';
import 'services/api_service.dart' as api;
import 'services/realtime_chat_service.dart';

// Const for consistency
const Color primaryPurple = Color(0xFF6200EE);

class TeacherChatScreen extends StatefulWidget {
  final Map<String, dynamic> teacher;
  const TeacherChatScreen({Key? key, required this.teacher}) : super(key: key);

  @override
  State<TeacherChatScreen> createState() => _TeacherChatScreenState();
}

class _TeacherChatScreenState extends State<TeacherChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoadingMessages = true;

  // State variable to track if text field is empty
  bool _isTextFieldEmpty = true;
  RealtimeChatService? _chatService;
  StreamSubscription? _chatSubscription;
  String? _chatRoomId;
  String? _studentUsername; // Display name (used for room ID)
  String? _teacherUsername; // Display name (used for room ID)
  String? _studentEmail; // Student email/username for API calls and message saving
  String? _teacherEmail; // Teacher email/username for API calls and message saving
  
  // Helper function to normalize names for room IDs
  String normalizeNameForRoomId(String name) {
    if (name.isEmpty) return '';
    // Convert to lowercase, replace spaces with underscores, remove special characters
    return name
        .toLowerCase()
        .trim()
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), ''); // Keep only alphanumeric and underscore
  }

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_updateTextFieldState);
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.removeListener(_updateTextFieldState);
    _messageController.dispose();
    _chatSubscription?.cancel();
    _chatService?.disconnect();
    super.dispose();
  }

  void _updateTextFieldState() {
    final isEmpty = _messageController.text.isEmpty;
    if (_isTextFieldEmpty != isEmpty) {
      setState(() {
        _isTextFieldEmpty = isEmpty;
      });
    }
  }

  void _sendMessage() {
    final trimmed = _messageController.text.trim();
    if (trimmed.isEmpty) return;
    
    if (_studentUsername == null || _studentUsername!.isEmpty) {
      debugPrint('Cannot send message: student name not initialized');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait, initializing chat...')),
      );
      _initializeChat(); // Retry initialization
      return;
    }
    
    if (_teacherUsername == null || _teacherUsername!.isEmpty) {
      debugPrint('Cannot send message: teacher username not initialized');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Teacher information not available.')),
      );
      return;
    }
    
    // Add to UI immediately
    setState(() {
      _messages.add({
        'text': trimmed,
        'isTeacher': false,
        'time': intl.DateFormat('hh:mm a').format(DateTime.now()),
      });
      _messageController.clear();
    });
    
    if (_chatService == null) {
      debugPrint('Cannot send message: chat service not initialized');
      _initializeRealtimeChat().catchError((error) {
        debugPrint('Failed to reconnect: $error');
      });
      return;
    }
    
    try {
      if (_chatService!.isConnected) {
        // Use emails/usernames for message saving (backend expects usernames)
        // But room ID uses names (already set)
        final senderForWs = _studentEmail ?? _studentUsername!;
        final recipientForWs = _teacherEmail ?? _teacherUsername!;
        
        _chatService!.sendMessage(
          sender: senderForWs,
          recipient: recipientForWs,
          message: trimmed,
        );
        debugPrint('Message sent: student name=$_studentUsername, teacher=$_teacherUsername');
        debugPrint('WebSocket sender=$senderForWs, recipient=$recipientForWs');
      } else {
        debugPrint('Chat service not connected, reconnecting...');
        _initializeRealtimeChat();
      }
    } catch (error) {
      debugPrint('Realtime chat send error: $error');
    }
  }

  void _sendVoiceMessage() {
    _showSnackBar("Recording voice message...");
    // Implement actual recording logic here (start/stop)
  }

  Future<void> _initializeChat() async {
    try {
      setState(() {
        _isLoadingMessages = true;
      });
      
      // Fetch parent profile to get student data
      Map<String, dynamic>? parentData = await api.ApiService.fetchParentProfile();
      debugPrint('Parent data received: ${parentData?.keys}');
      
      // If parent profile is null, try to fetch student profile as fallback
      // (since parent and student are in same portal)
      if (parentData == null) {
        debugPrint('Parent profile is null, trying student profile as fallback...');
        try {
          final studentData = await api.ApiService.fetchStudentProfile();
          if (studentData != null) {
            debugPrint('Found student profile, converting to parent-like structure');
            debugPrint('Student data keys: ${studentData.keys}');
            debugPrint('Student name from profile: ${studentData['student_name']}');
            
            // Convert student data to parent-like structure
            parentData = {
              'user': studentData['user'],
              'students': [studentData], // Wrap student in students array
              'school_id': studentData['school_id'],
              'school_name': studentData['school_name'],
              // Add student_name at top level for easier access
              'student_name': studentData['student_name'],
            };
            debugPrint('Converted student profile to parent-like structure');
            debugPrint('Student name in converted data: ${parentData['student_name']}');
          } else {
            debugPrint('Student profile is also null');
          }
        } catch (e) {
          debugPrint('Failed to fetch student profile as fallback: $e');
        }
      }
      
      if (parentData != null) {
        // First, try to get student_name directly from parentData (for student profile fallback)
        if (parentData.containsKey('student_name')) {
          final studentNameValue = parentData['student_name'];
          final directStudentName = studentNameValue?.toString().trim();
          if (directStudentName != null && directStudentName.isNotEmpty && directStudentName != 'null') {
            debugPrint('✓ Found student_name directly in parentData: $directStudentName');
            _studentUsername = directStudentName;
            
            // Also extract username/email for room ID
        final students = parentData['students'];
        if (students is List && students.isNotEmpty) {
              final firstStudent = students[0] as Map<String, dynamic>?;
              if (firstStudent != null) {
                // Room ID will use student name (no email needed)
                debugPrint('  Student name for room ID: $_studentUsername');
              }
            }
          }
        }
        
        final students = parentData['students'];
        debugPrint('Students in parent data: ${students is List ? students.length : 'not a list'}');
        
        if (students is List && students.isNotEmpty) {
          // Iterate through all students to find one with valid name
          Map<String, dynamic>? validStudentData;
          String? extractedStudentName;
          
          debugPrint('Processing ${students.length} students from parent profile...');
          
          for (var studentItem in students) {
            if (studentItem is Map<String, dynamic>) {
              debugPrint('Student item keys: ${studentItem.keys}');
              final studentUser = studentItem['user'] as Map<String, dynamic>?;
              
              // Try to get student name - check multiple fields
              String studentName = '';
              
              // Priority 1: student_name field (MOST IMPORTANT - this is the actual student name like "rakesh")
              if (studentItem['student_name'] != null) {
                final studentNameValue = studentItem['student_name'].toString().trim();
                if (studentNameValue.isNotEmpty && studentNameValue != 'null' && studentNameValue.toLowerCase() != 'null') {
                  studentName = studentNameValue;
                  debugPrint('✓ Found student_name: $studentName');
                }
              }
              
              // Priority 2: name field
              if (studentName.isEmpty && studentItem['name'] != null) {
                final nameValue = studentItem['name'].toString().trim();
                if (nameValue.isNotEmpty && nameValue != 'null') {
                  studentName = nameValue;
                  debugPrint('Found name field: $studentName');
                }
              }
              
              // Priority 3: user's first_name + last_name
              if (studentName.isEmpty && studentUser != null) {
                final firstName = (studentUser['first_name'] as String? ?? '').trim();
                final lastName = (studentUser['last_name'] as String? ?? '').trim();
                if (firstName.isNotEmpty || lastName.isNotEmpty) {
                  studentName = '$firstName $lastName'.trim();
                  debugPrint('Found name from user: $studentName');
                }
              }
              
              // Use the first student with a valid name
              if (studentName.isNotEmpty) {
                validStudentData = studentItem;
                extractedStudentName = studentName;
                debugPrint('✓ Selected student: $studentName');
                break;
              } else {
                debugPrint('✗ Skipped student - no valid name found');
              }
            } else {
              debugPrint('✗ Student item is not a Map: ${studentItem.runtimeType}');
            }
          }
          
          if (validStudentData != null && extractedStudentName != null) {
            _studentUsername = extractedStudentName;
            
            // Get teacher username/name/email
            final teacherUser = widget.teacher['user'] as Map<String, dynamic>?;
            String teacherFirstName = '';
            String teacherLastName = '';
            String teacherEmail = '';
            String teacherUsername = '';
            if (teacherUser != null) {
              teacherFirstName = (teacherUser['first_name'] as String? ?? '').trim();
              teacherLastName = (teacherUser['last_name'] as String? ?? '').trim();
              teacherEmail = teacherUser['email'] as String? ?? '';
              teacherUsername = teacherUser['username'] as String? ?? '';
            }
            final teacherFullName = '$teacherFirstName $teacherLastName'.trim();
            final teacherName = (widget.teacher['name'] as String? ?? '').trim();
            final finalTeacherName = teacherName.isNotEmpty ? teacherName : teacherFullName;
            
            _teacherUsername = finalTeacherName.isNotEmpty 
                ? finalTeacherName 
                : 'Teacher';
            
            // Store emails/usernames for API calls and message saving
            final studentUser = validStudentData['user'] as Map<String, dynamic>?;
            final studentEmailValue = validStudentData['email']?.toString() ?? 
                                     studentUser?['email']?.toString() ?? '';
            final studentUsernameValue = studentUser?['username']?.toString();
            _studentEmail = studentUsernameValue ?? 
                          (studentEmailValue.isNotEmpty ? studentEmailValue : '');
            
            _teacherEmail = teacherUsername.isNotEmpty ? teacherUsername : 
                          (teacherEmail.isNotEmpty ? teacherEmail : '');
            
            debugPrint('Student name set: $_studentUsername, Teacher: $_teacherUsername');
            debugPrint('Student email/username for API: $_studentEmail, Teacher email/username: $_teacherEmail');
            
            // Create room ID using names only (no email fallback)
            if ((_studentUsername != null && _studentUsername!.isNotEmpty) &&
                (_teacherUsername != null && _teacherUsername!.isNotEmpty)) {
              final normalizedStudentName = normalizeNameForRoomId(_studentUsername!);
              final normalizedTeacherName = normalizeNameForRoomId(_teacherUsername!);
              
              if (normalizedStudentName.isNotEmpty && normalizedTeacherName.isNotEmpty) {
                final identifiers = [normalizedStudentName, normalizedTeacherName]..sort();
                _chatRoomId = identifiers.join('_');
                debugPrint('Room ID using names - Student: $_studentUsername -> $normalizedStudentName');
                debugPrint('  Teacher: $_teacherUsername -> $normalizedTeacherName');
                debugPrint('  Final room ID: $_chatRoomId');
            } else {
                debugPrint('ERROR: Normalized names are empty (student: $normalizedStudentName, teacher: $normalizedTeacherName)');
                _chatRoomId = null;
              }
            } else {
              debugPrint('ERROR: Student or teacher name is missing (student: $_studentUsername, teacher: $_teacherUsername)');
              _chatRoomId = null;
            }
            
            debugPrint('Chat initialized - student: $_studentUsername, teacher: $_teacherUsername, room: $_chatRoomId');
            
            // Load existing messages from API
            await _loadExistingMessages();
            
            // Initialize real-time chat
            _initializeRealtimeChat();
            
            setState(() {
              _isLoadingMessages = false;
            });
            return;
          } else {
            debugPrint('No valid student found with name in students list');
        }
        } else {
          debugPrint('No students found in parent profile. Students: $students');
          
          // Try to find student data in a different structure or retry with better extraction
          // Check if students might be in a different format
          if (students == null || (students is List && students.isEmpty)) {
            debugPrint('Students list is empty or null, checking alternative data structures...');
            
            // Try to get student from any available source
            Map<String, dynamic>? alternativeStudentData;
            
            // Check if there's student data elsewhere in parentData
            if (parentData.containsKey('student')) {
              alternativeStudentData = parentData['student'] as Map<String, dynamic>?;
              debugPrint('Found student data in parentData[\'student\']');
            }
            
            // If still no student found, use parent as last resort but try to get student name from elsewhere
            if (alternativeStudentData == null) {
              debugPrint('No alternative student data found, will use parent info but prefer student name if available');
            } else {
              // Process alternative student data
              final studentUser = alternativeStudentData['user'] as Map<String, dynamic>?;
              String studentName = '';
              if (alternativeStudentData['student_name'] != null && 
                  alternativeStudentData['student_name'].toString().trim().isNotEmpty) {
                studentName = alternativeStudentData['student_name'].toString().trim();
              } else if (studentUser != null) {
                final firstName = (studentUser['first_name'] as String? ?? '').trim();
                final lastName = (studentUser['last_name'] as String? ?? '').trim();
                studentName = '$firstName $lastName'.trim();
              }
              
              if (studentName.isNotEmpty) {
                _studentUsername = studentName;
                
                // Get student email/username for API calls
                final studentEmailValue = alternativeStudentData['email']?.toString() ?? 
                                         studentUser?['email']?.toString() ?? '';
                final studentUsernameValue = studentUser?['username']?.toString();
                _studentEmail = studentUsernameValue ?? 
                              (studentEmailValue.isNotEmpty ? studentEmailValue : '');
                
                // Get teacher info
                final teacherUser = widget.teacher['user'] as Map<String, dynamic>?;
                String teacherFirstName = '';
                String teacherLastName = '';
                String teacherEmail = '';
                String teacherUsername = '';
                if (teacherUser != null) {
                  teacherFirstName = (teacherUser['first_name'] as String? ?? '').trim();
                  teacherLastName = (teacherUser['last_name'] as String? ?? '').trim();
                  teacherEmail = teacherUser['email'] as String? ?? '';
                  teacherUsername = teacherUser['username'] as String? ?? '';
                }
                final teacherFullName = '$teacherFirstName $teacherLastName'.trim();
                final teacherName = (widget.teacher['name'] as String? ?? '').trim();
                final finalTeacherName = teacherName.isNotEmpty ? teacherName : teacherFullName;
                
                _teacherUsername = finalTeacherName.isNotEmpty 
                    ? finalTeacherName 
                    : 'Teacher';
                
                _teacherEmail = teacherUsername.isNotEmpty ? teacherUsername : 
                              (teacherEmail.isNotEmpty ? teacherEmail : '');
                
                // Create room ID using names only (no email fallback)
                if ((_studentUsername != null && _studentUsername!.isNotEmpty) &&
                    (_teacherUsername != null && _teacherUsername!.isNotEmpty)) {
                  final normalizedStudentName = normalizeNameForRoomId(_studentUsername!);
                  final normalizedTeacherName = normalizeNameForRoomId(_teacherUsername!);
                  
                  if (normalizedStudentName.isNotEmpty && normalizedTeacherName.isNotEmpty) {
                    final identifiers = [normalizedStudentName, normalizedTeacherName]..sort();
                    _chatRoomId = identifiers.join('_');
                  } else {
                    _chatRoomId = null;
                  }
                  
                  debugPrint('Using alternative student data - student: $_studentUsername, teacher: $_teacherUsername');
                  debugPrint('Room ID: $_chatRoomId');
                  await _loadExistingMessages();
      _initializeRealtimeChat();
      setState(() {
        _isLoadingMessages = false;
      });
                  return;
                }
              }
            }
          }
          
          // Since parent and student are in same portal, try to use parent user as fallback
          // But first, try to extract student name from any available source
          final parentUser = parentData['user'] as Map<String, dynamic>?;
          final parentEmail = parentUser?['email']?.toString() ?? '';
          final parentFirstName = parentUser?['first_name']?.toString() ?? '';
          final parentLastName = parentUser?['last_name']?.toString() ?? '';
          final parentName = '$parentFirstName $parentLastName'.trim();
          
          // Try to get student name from parent profile if available
          String? studentNameFromParent;
          if (parentData.containsKey('student_name')) {
            studentNameFromParent = (parentData['student_name'] as String?)?.trim();
            if (studentNameFromParent != null && studentNameFromParent.isNotEmpty) {
              debugPrint('Found student_name in parent profile: $studentNameFromParent');
            }
          }
          
          if (parentEmail.isNotEmpty || parentName.isNotEmpty) {
            // Use student name if found, otherwise use parent name, but never use "Parent" as default
            _studentUsername = studentNameFromParent ?? (parentName.isNotEmpty ? parentName : 'Student');
            
            final teacherUser = widget.teacher['user'] as Map<String, dynamic>?;
            String teacherFirstName = '';
            String teacherLastName = '';
            if (teacherUser != null) {
              teacherFirstName = (teacherUser['first_name'] as String? ?? '').trim();
              teacherLastName = (teacherUser['last_name'] as String? ?? '').trim();
            }
            final teacherFullName = '$teacherFirstName $teacherLastName'.trim();
            final teacherName = (widget.teacher['name'] as String? ?? '').trim();
            final finalTeacherName = teacherName.isNotEmpty ? teacherName : teacherFullName;
            
            _teacherUsername = finalTeacherName.isNotEmpty 
                ? finalTeacherName 
                : 'Teacher';
            
            // Create room ID using names only (no email fallback)
            if ((_studentUsername != null && _studentUsername!.isNotEmpty) &&
                (_teacherUsername != null && _teacherUsername!.isNotEmpty)) {
              final normalizedStudentName = normalizeNameForRoomId(_studentUsername!);
              final normalizedTeacherName = normalizeNameForRoomId(_teacherUsername!);
              
              if (normalizedStudentName.isNotEmpty && normalizedTeacherName.isNotEmpty) {
                final identifiers = [normalizedStudentName, normalizedTeacherName]..sort();
                _chatRoomId = identifiers.join('_');
              } else {
                _chatRoomId = null;
              }
              
              debugPrint('Using parent as fallback - student: $_studentUsername, teacher: $_teacherUsername');
              await _loadExistingMessages();
              _initializeRealtimeChat();
              setState(() {
                _isLoadingMessages = false;
              });
              return;
            }
          }
        }
      } else {
        debugPrint('Parent data is null');
      }
      
      // Final fallback: retry student extraction with more thorough checking
      debugPrint('Using final fallback for chat initialization - retrying student extraction');
      try {
        Map<String, dynamic>? parentData = await api.ApiService.fetchParentProfile();
        
        // If parent profile is null, try student profile as fallback
        if (parentData == null) {
          debugPrint('Parent profile is null in final fallback, trying student profile...');
          try {
            final studentData = await api.ApiService.fetchStudentProfile();
            if (studentData != null) {
              debugPrint('Found student profile in final fallback');
              debugPrint('Student name from profile: ${studentData['student_name']}');
              debugPrint('Student email: ${studentData['email']}');
              
              parentData = {
                'user': studentData['user'],
                'students': [studentData],
                'school_id': studentData['school_id'],
                'school_name': studentData['school_name'],
                'student_name': studentData['student_name'], // Add for direct access
              };
              
              // Immediately try to extract student name from the converted data
              if (studentData['student_name'] != null) {
                final name = studentData['student_name'].toString().trim();
                if (name.isNotEmpty && name != 'null') {
                  _studentUsername = name;
                  debugPrint('✓ Set student name from student profile: $_studentUsername');
                  
                  debugPrint('  Student name for room ID: $_studentUsername');
                }
              }
            }
    } catch (e) {
            debugPrint('Failed to fetch student profile in final fallback: $e');
          }
        }
        
        if (parentData != null) {
          // Retry students extraction with more thorough checking
          final students = parentData['students'];
          debugPrint('Final fallback - Students type: ${students.runtimeType}, is List: ${students is List}');
          
          if (students is List && students.isNotEmpty) {
            debugPrint('Final fallback - Found ${students.length} students, retrying extraction...');
            
            for (var studentItem in students) {
              if (studentItem is Map<String, dynamic>) {
                debugPrint('Final fallback - Student keys: ${studentItem.keys}');
                final studentUser = studentItem['user'] as Map<String, dynamic>?;
                
                // Try multiple ways to get student name
                String studentName = '';
                
                // Check student_name (MOST IMPORTANT - actual student name like "rakesh")
                if (studentItem['student_name'] != null) {
                  final val = studentItem['student_name'].toString().trim();
                  if (val.isNotEmpty && val != 'null' && val.toLowerCase() != 'null') {
                    studentName = val;
                    debugPrint('✓ Final fallback - Found student_name: $studentName');
                  }
                }
                
                // Check name field
                if (studentName.isEmpty && studentItem['name'] != null) {
                  final val = studentItem['name'].toString().trim();
                  if (val.isNotEmpty && val != 'null') studentName = val;
                }
                
                // Check user first_name + last_name
                if (studentName.isEmpty && studentUser != null) {
                  final firstName = (studentUser['first_name'] as String? ?? '').trim();
                  final lastName = (studentUser['last_name'] as String? ?? '').trim();
                  if (firstName.isNotEmpty || lastName.isNotEmpty) {
                    studentName = '$firstName $lastName'.trim();
                  }
                }
                
                if (studentName.isNotEmpty) {
                  _studentUsername = studentName;
                  debugPrint('✓ Final fallback - Found student: $_studentUsername');
                  break;
                }
              }
            }
          }
          
          // If still no student name found, check if parent profile has student_name directly
          if ((_studentUsername == null || _studentUsername!.isEmpty) && parentData.containsKey('student_name')) {
            final studentNameFromProfile = (parentData['student_name'] as String?)?.trim();
            if (studentNameFromProfile != null && studentNameFromProfile.isNotEmpty && studentNameFromProfile != 'null') {
              _studentUsername = studentNameFromProfile;
              debugPrint('✓ Found student_name in parent profile: $_studentUsername');
            }
          }
          
          // Last resort: use parent name but log warning
          if (_studentUsername == null || _studentUsername!.isEmpty) {
            final parentUser = parentData['user'] as Map<String, dynamic>?;
            if (parentUser != null) {
              final parentFirstName = (parentUser['first_name'] as String? ?? '').trim();
              final parentLastName = (parentUser['last_name'] as String? ?? '').trim();
              final parentName = '$parentFirstName $parentLastName'.trim();
              _studentUsername = parentName.isNotEmpty ? parentName : 'Student';
              debugPrint('⚠ WARNING: Using parent name as student name: $_studentUsername');
            } else {
              _studentUsername = 'Student';
            }
          }
        } else {
          _studentUsername = 'Student';
        }
      } catch (e) {
        debugPrint('Error in final fallback: $e');
        _studentUsername = 'Student';
      }
      
      // Get teacher info for final fallback
      final teacherUser = widget.teacher['user'] as Map<String, dynamic>?;
      String teacherFirstName = '';
      String teacherLastName = '';
      if (teacherUser != null) {
        teacherFirstName = (teacherUser['first_name'] as String? ?? '').trim();
        teacherLastName = (teacherUser['last_name'] as String? ?? '').trim();
      }
      final teacherFullName = '$teacherFirstName $teacherLastName'.trim();
      final teacherName = (widget.teacher['name'] as String? ?? '').trim();
      final finalTeacherName = teacherName.isNotEmpty ? teacherName : (teacherFullName.isNotEmpty ? teacherFullName : 'Teacher');
      _teacherUsername = finalTeacherName;
      
      // Create room ID using names only (no email fallback)
      if ((_studentUsername != null && _studentUsername!.isNotEmpty) &&
          (_teacherUsername != null && _teacherUsername!.isNotEmpty)) {
        final normalizedStudentName = normalizeNameForRoomId(_studentUsername!);
        final normalizedTeacherName = normalizeNameForRoomId(_teacherUsername!);
        
        if (normalizedStudentName.isNotEmpty && normalizedTeacherName.isNotEmpty) {
          final identifiers = [normalizedStudentName, normalizedTeacherName]..sort();
          _chatRoomId = identifiers.join('_');
          debugPrint('Final fallback room ID: $_chatRoomId');
          debugPrint('  Student: $_studentUsername -> $normalizedStudentName');
          debugPrint('  Teacher: $_teacherUsername -> $normalizedTeacherName');
        } else {
          _chatRoomId = null;
          debugPrint('ERROR: Normalized names are empty (student: $normalizedStudentName, teacher: $normalizedTeacherName)');
        }
      } else {
        _chatRoomId = null;
        debugPrint('ERROR: Student or teacher name is missing (student: $_studentUsername, teacher: $_teacherUsername)');
      }
      
      _initializeRealtimeChat();
      setState(() {
        _isLoadingMessages = false;
      });
    } catch (e, stackTrace) {
      debugPrint('Error initializing chat: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _isLoadingMessages = false;
      });
    }
  }

  Future<void> _loadExistingMessages() async {
    if (_studentEmail == null || _teacherEmail == null) {
      debugPrint('Cannot load messages: missing email/username (student: $_studentEmail, teacher: $_teacherEmail)');
      return;
    }
    
    try {
      // Fetch messages using email/username identifiers (backend expects usernames/emails)
      final messages = await api.ApiService.fetchCommunications(_studentEmail!, _teacherEmail!);
      
      debugPrint('Loaded ${messages.length} existing messages');
      
      setState(() {
        _messages = messages.map((msg) {
          final sender = msg['sender'] as Map<String, dynamic>?;
          final senderUsername = sender?['username']?.toString() ?? '';
          final senderEmail = sender?['email']?.toString() ?? '';
          final senderFirstName = sender?['first_name']?.toString() ?? '';
          final senderLastName = sender?['last_name']?.toString() ?? '';
          final senderName = '$senderFirstName $senderLastName'.trim();
          
          // Check if sender is teacher by comparing username, email, or name
          final isTeacher = senderUsername == _teacherUsername || 
                           senderEmail == _teacherUsername ||
                           senderName == _teacherUsername ||
                           (widget.teacher['user'] != null && 
                            (widget.teacher['user'] as Map)['username']?.toString() == senderUsername);
          
          return {
            'text': msg['message']?.toString() ?? msg['subject']?.toString() ?? '',
            'isTeacher': isTeacher,
            'time': _formatMessageTime(msg['created_at']?.toString()),
          };
        }).toList();
      });
      
      debugPrint('Processed ${_messages.length} messages for display');
    } catch (e) {
      debugPrint('Failed to load existing messages: $e');
    }
  }

  String _formatMessageTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) {
      return intl.DateFormat('hh:mm a').format(DateTime.now());
    }
    try {
      final dateTime = DateTime.parse(timeStr);
      return intl.DateFormat('hh:mm a').format(dateTime);
    } catch (e) {
      return intl.DateFormat('hh:mm a').format(DateTime.now());
    }
  }

  Future<void> _initializeRealtimeChat() async {
    if (_chatRoomId == null || _studentUsername == null || _teacherUsername == null) return;
    
    try {
      debugPrint('=== Student Chat Connection ===');
      debugPrint('Room ID: $_chatRoomId');
      debugPrint('Student name: $_studentUsername');
      debugPrint('Teacher username: $_teacherUsername');
      debugPrint('Chat type: teacher-student');
      
      _chatService = RealtimeChatService(baseWsUrl: api.ApiService.wsBaseUrl); // Use dynamic base URL
      await _chatService!.connect(roomId: _chatRoomId!, chatType: 'teacher-student');
      _chatSubscription = _chatService!.stream?.listen((event) {
        try {
          final payload = event is String ? event : event.toString();
          final decoded = jsonDecode(payload) as Map<String, dynamic>;
          
          final messageType = decoded['type']?.toString() ?? 'message';
          
          // Handle connection messages
          if (messageType == 'connection') {
            debugPrint('Connected to chat: ${decoded['user']}');
            return;
          }
          
          // Only process actual messages
          if (messageType == 'message') {
            final messageText = decoded['message']?.toString() ?? '';
            if (messageText.isEmpty) return;
            
            final sender = decoded['sender']?.toString() ?? '';
            
            // Determine if sender is teacher by comparing with teacher's username/email
            final teacherUser = widget.teacher['user'] as Map<String, dynamic>?;
            final teacherUsername = teacherUser?['username']?.toString() ?? '';
            final teacherEmail = teacherUser?['email']?.toString() ?? '';
            final teacherName = widget.teacher['name']?.toString() ?? '';
            
            final isTeacher = sender == teacherUsername || 
                            sender == teacherEmail ||
                            sender == teacherName ||
                            sender == _teacherUsername ||
                            sender == 'teacher';
            
            debugPrint('Received message from: $sender (isTeacher: $isTeacher, message: $messageText)');
            
            // Check if message already exists to avoid duplicates
            final messageExists = _messages.any((msg) => 
              msg['text'] == messageText && 
              msg['isTeacher'] == isTeacher
            );
            
            if (!messageExists) {
            setState(() {
              _messages.add({
                'text': messageText,
                'isTeacher': isTeacher,
                'time': intl.DateFormat('hh:mm a').format(DateTime.now()),
              });
            });
              debugPrint('Added new message to list (total: ${_messages.length})');
            } else {
              debugPrint('Message already exists, skipping duplicate');
            }
          } else if (messageType == 'error') {
            debugPrint('Chat error: ${decoded['message']}');
          }
        } catch (error) {
          debugPrint('Realtime chat parse error: $error');
        }
      });
    } catch (e) {
      debugPrint('Failed to initialize realtime chat: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryPurple,
                    Color(0xFF764BA2),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Text(
                    widget.teacher['name'] ?? 'Teacher',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.teacher['name'] ?? 'Teacher',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        if (widget.teacher['subject'] != null)
                          Text(
                            'Subject: ${widget.teacher['subject']}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        if (widget.teacher['class_assigned'] != null || widget.teacher['classes_assigned'] != null)
                          Text(
                            'Class Assigned: ${widget.teacher['class_assigned'] ?? widget.teacher['classes_assigned'] ?? 'N/A'}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        if (widget.teacher['subject'] == null && widget.teacher['class_assigned'] == null && widget.teacher['classes_assigned'] == null)
                          Text(
                            widget.teacher['online'] ? 'Online' : 'Offline',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Removed video and audio call buttons as requested.
                ],
              ),
            ),
            // Messages
            Expanded(
              child: Container(
                color: Colors.grey.shade50,
                child: _isLoadingMessages
                    ? const Center(child: CircularProgressIndicator())
                    : _messages.isEmpty
                        ? const Center(
                            child: Text(
                              'No messages yet. Start the conversation!',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return _buildMessage(
                      message['text'],
                      message['isTeacher'],
                      message['time'],
                    );
                  },
                ),
              ),
            ),
            // Input
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.attach_file,
                      color: primaryPurple,
                    ),
                    onPressed: () => _showSnackBar("Attach file dialog"),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) {
                        // Only handle submission if the send button is active (text mode)
                        if (!_isTextFieldEmpty) {
                          _sendMessage();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Voice/Send Button logic
                  _isTextFieldEmpty
                      ? // Show voice button if text field is empty
                        GestureDetector(
                          onLongPress: _sendVoiceMessage,
                          onLongPressUp: () => _showSnackBar(
                            "Voice recording stopped. Message sent!",
                          ),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primaryPurple,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.mic, color: Colors.white),
                          ),
                        )
                      : // Show send button if text field has text
                        FloatingActionButton(
                          mini: true,
                          onPressed: _sendMessage,
                          backgroundColor:
                              primaryPurple,
                          child: const Icon(Icons.send, color: Colors.white),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(String text, bool isTeacher, String time) {
    return Align(
      alignment: isTeacher ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 350),
        decoration: BoxDecoration(
          color: isTeacher
              ? Colors.white
              : primaryPurple,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                // UPDATED: Changed text color to pure black/white for maximum contrast
                color: isTeacher ? Colors.black : Colors.white,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                // UPDATED: Increased contrast on timestamps
                color: isTeacher ? Colors.black54 : Colors.white,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
