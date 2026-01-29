import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'services/api_service.dart' as api;
import 'services/realtime_chat_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

class TeacherCommunicationScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final ThemeMode initialThemeMode;

  const TeacherCommunicationScreen({
    super.key,
    required this.onToggleTheme,
    this.initialThemeMode = ThemeMode.light,
  });

  @override
  State<TeacherCommunicationScreen> createState() => _TeacherCommunicationScreenState();
}

class _TeacherCommunicationScreenState extends State<TeacherCommunicationScreen> {
  // Data
  final Map<String, ChatContact> _contacts = {};
  final Map<String, List<ChatMessage>> _messages = {};
  final Map<String, int> _unreadCounts = {}; // Track unread messages per contact
  String? _selectedContactId;
  String? _currentTeacherUsername;
  String? _currentTeacherName; // Teacher's display name for room ID
  String? _currentTeacherUserId;
  bool _isLoading = true;
  
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
  
  // Search and filters
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showTeachersOnly = false;
  bool _showGroupsOnly = false;
  
  // Groups
  final Map<String, ChatGroup> _groups = {};
  
  // Chat
  final TextEditingController _messageController = TextEditingController();
  RealtimeChatService? _chatService;
  StreamSubscription? _chatSubscription;
  
  // Global chat listener for unread counts
  RealtimeChatService? _globalChatService;
  StreamSubscription? _globalChatSubscription;
  
  // UI
  final ScrollController _scrollController = ScrollController();
  

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
    _loadData();
    _initializeGlobalChatListener();
  }
  
  // Initialize global chat listener to track unread counts
  Future<void> _initializeGlobalChatListener() async {
    try {
      if (_currentTeacherName == null || _currentTeacherName!.isEmpty) {
        // Wait for teacher data to load
        await Future.delayed(const Duration(seconds: 2));
        if (_currentTeacherName == null || _currentTeacherName!.isEmpty) {
          debugPrint('Cannot initialize global chat listener: teacher name not available');
          return;
        }
      }
      
    // Connect to personal user channel for all updates (Groups & Direct)
      if (_currentTeacherUserId == null) {
         debugPrint('Cannot initialize global chat listener: user ID not available');
         return;
      }
      
      _globalChatService = RealtimeChatService(baseWsUrl: 'ws://localhost:8000');
      
      // Use user_{id} format which matches backend consumer
      await _globalChatService!.connect(roomId: _currentTeacherUserId!, chatType: 'user');
      
      _globalChatSubscription = _globalChatService!.stream?.listen((event) {
        try {
          final data = event is String ? jsonDecode(event) : event;
          if (data is Map) {
            final messageType = data['type']?.toString() ?? 'message';
            if (messageType == 'message' || messageType == 'chat.message') {
              final sender = data['sender']?.toString() ?? '';
              final senderUsername = data['sender_username']?.toString() ?? sender;
              final senderId = data['sender_id']?.toString() ?? '';
              final messageText = data['message']?.toString() ?? '';
              final timestamp = data['timestamp']?.toString() ?? DateTime.now().toUtc().toIso8601String();
              final messageId = data['message_id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
              
              if (messageText.isEmpty) return;
              
              // 1. Check for Group Message
              final groupId = data['group_id']?.toString();
              if (groupId != null) {
                // Update existing group or reload if new
                if (_groups.containsKey(groupId)) {
                  if (mounted) {
                    setState(() {
                      // Update sort order logic here if we had a sorted list
                      // For now, reload data to ensure correct order
                      _loadData(); 
                    });
                  }
                } else {
                  // New group discovered
                  _loadData();
                }
                return;
              }

              // 2. Check for Direct Message
              // Check if message is for this teacher (from any contact)
              // Since we are listening on personal channel, we assume it IS for us if we are not the sender
              // However, keep sender check to avoid self-echo if not handled by backend
              
              if (senderId == _currentTeacherUserId) return; // Ignore own messages if echoed
              
              // Find matching contact
              ChatContact? matchedContact;
              for (var contact in _contacts.values) {
                if (senderId == contact.id ||
                    senderUsername == contact.username ||
                    sender == contact.name ||
                    sender.toLowerCase().contains(contact.name.toLowerCase())) {
                  matchedContact = contact;
                  break;
                }
              }
              
              if (matchedContact != null) {
                if (mounted) {
                  setState(() {
                    // Add message to contact's message list
                    _messages[matchedContact!.id] ??= [];
                    
                    // Check for duplicates
                    final isDuplicate = _messages[matchedContact.id]!.any((msg) => 
                      msg.id == messageId || 
                      (msg.text == messageText && msg.timestamp == timestamp)
                    );
                    
                    if (!isDuplicate && messageId.isNotEmpty) {
                      _messages[matchedContact.id]!.add(ChatMessage(
                        id: messageId,
                        text: messageText,
                        senderId: senderId,
                        isSent: false, // Received message
                        timestamp: timestamp,
                      ));
                      
                      // Increment unread count if chat is not open
                      if (_selectedContactId != matchedContact.id) {
                        _unreadCounts[matchedContact.id] = (_unreadCounts[matchedContact.id] ?? 0) + 1;
                        debugPrint('✓ Unread count updated for ${matchedContact.name}: ${_unreadCounts[matchedContact.id]}');
                      }
                    }
                  });
                }
              }
            }
          }
        } catch (e) {
          debugPrint('Error in global chat listener: $e');
        }
      });
    } catch (e) {
      debugPrint('Failed to initialize global chat listener: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _chatService?.disconnect();
    _chatSubscription?.cancel();
    _globalChatService?.disconnect();
    _globalChatSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load teacher profile
      final teacherProfile = await api.ApiService.fetchTeacherProfile();
      String? currentSchoolId;
      if (teacherProfile != null) {
        final user = teacherProfile['user'] as Map<String, dynamic>?;
        _currentTeacherUsername = user?['username'] as String?;
        _currentTeacherUserId = user?['user_id']?.toString();
        
        // Get teacher's display name for room ID (not email/username)
        final teacherFirstName = user?['first_name'] as String? ?? '';
        final teacherLastName = user?['last_name'] as String? ?? '';
        final teacherFullName = '$teacherFirstName $teacherLastName'.trim();
        final teacherName = teacherProfile['name'] as String? ?? '';
        _currentTeacherName = teacherName.isNotEmpty ? teacherName : 
                            (teacherFullName.isNotEmpty ? teacherFullName : 
                            (_currentTeacherUsername ?? 'Teacher'));
        
        debugPrint('Teacher loaded: $_currentTeacherUsername (ID: $_currentTeacherUserId, Name: $_currentTeacherName)');
        
        // Get school_id from teacher profile for filtering
        currentSchoolId = teacherProfile['school_id']?.toString();
        final schoolName = teacherProfile['school_name']?.toString() ?? 'unknown';
        debugPrint('Teacher school - ID: $currentSchoolId, Name: $schoolName');
      }

      // Fetch students - try class-students first, then fallback
      debugPrint('Fetching students...');
      List<dynamic> students = await api.ApiService.fetchStudentsFromClasses();
      debugPrint('Fetched ${students.length} students from class-students');
      
      if (students.isEmpty) {
        try {
          students = await api.ApiService.fetchStudents();
          debugPrint('Fetched ${students.length} students from management-admin');
          if (students.isEmpty) {
            debugPrint('WARNING: No students found. This might mean:');
            debugPrint('1. No students are assigned to this school');
            debugPrint('2. Students are not linked to classes');
            debugPrint('3. School filtering is too restrictive');
          }
        } catch (e) {
          debugPrint('Error fetching students: $e');
        }
      }

      // Fetch teachers
      debugPrint('Fetching teachers...');
      final teachers = await api.ApiService.fetchTeachers();
      debugPrint('Fetched ${teachers.length} teachers');

      // Process students
      for (var studentData in students) {
        try {
          Map<String, dynamic>? user;
          Map<String, dynamic> studentMap = studentData is Map<String, dynamic> ? studentData : {};
          
          // Handle both nested and flat structures
          if (studentMap.containsKey('user') && studentMap['user'] is Map) {
            user = studentMap['user'] as Map<String, dynamic>?;
          } else if (studentMap.containsKey('username') || studentMap.containsKey('first_name')) {
            user = studentMap;
          } else {
            user = {};
          }
          
          // Get student ID - prioritize user_id for chat compatibility
          final studentId = user?['user_id']?.toString() ?? 
                           studentMap['user_id']?.toString() ?? 
                           user?['id']?.toString() ??
                           studentMap['id']?.toString() ??
                           studentMap['student_id']?.toString() ?? 
                           studentMap['email']?.toString() ?? '';
          
          // Use student_name as primary identifier (not username)
          final studentName = studentMap['student_name']?.toString() ?? 
                            studentMap['name']?.toString() ?? '';
          
          // Fallback to user name if student_name not available
          final firstName = user?['first_name'] as String? ?? '';
          final lastName = user?['last_name'] as String? ?? '';
          final userName = '$firstName $lastName'.trim();
          
          // Use student_name, or user name, or email as display name
          final displayName = studentName.isNotEmpty 
              ? studentName 
              : (userName.isNotEmpty ? userName : studentMap['email']?.toString() ?? 'Student');
          
          // Use email or student_id as username for chat
          final username = studentMap['email']?.toString() ?? 
                          user?['email']?.toString() ?? 
                          studentMap['student_id']?.toString() ?? 
                          studentId;
          
          final className = studentMap['applying_class'] as String? ?? 
                           studentMap['class_name'] as String? ?? '';
          final section = studentMap['section'] as String? ?? '';

          // Get student's school_id for filtering
          final studentSchoolId = studentMap['school_id']?.toString();
          
          // Only add students with matching school_id (if currentSchoolId is available)
          final schoolMatches = currentSchoolId == null || studentSchoolId == null || currentSchoolId == studentSchoolId;
          
          // Accept students if we have at least studentId and displayName, and school_id matches
          if (studentId.isNotEmpty && displayName.isNotEmpty && schoolMatches) {
            _contacts[studentId] = ChatContact(
              id: studentId,
              name: displayName,
              username: username.isNotEmpty ? username : studentId,
              type: ContactType.student,
              className: className,
              section: section,
              avatar: _getInitials(displayName),
            );
            _messages[studentId] = [];
            debugPrint('Added student: $displayName (ID: $studentId, School: $studentSchoolId)');
          } else {
            if (!schoolMatches) {
              debugPrint('Skipped student - school_id mismatch: student=$studentSchoolId, teacher=$currentSchoolId');
            } else {
              debugPrint('Skipped student - missing ID or name: studentId=$studentId, displayName=$displayName');
            }
          }
        } catch (e) {
          debugPrint('Error processing student: $e');
        }
      }

      // Process teachers
      for (var teacherData in teachers) {
        try {
          Map<String, dynamic>? user;
          Map<String, dynamic> teacherMap = teacherData is Map<String, dynamic> ? teacherData : {};
          
          if (teacherMap.containsKey('user') && teacherMap['user'] is Map) {
            user = teacherMap['user'] as Map<String, dynamic>?;
          } else if (teacherMap.containsKey('username') || teacherMap.containsKey('first_name')) {
            user = teacherMap;
          } else {
            user = {};
          }
          
          final userId = user?['user_id']?.toString() ?? 
                        teacherMap['user_id']?.toString() ?? '';
          final username = user?['username'] as String? ?? 
                          user?['email'] as String? ?? 
                          teacherMap['username'] as String? ?? '';
          final firstName = user?['first_name'] as String? ?? '';
          final lastName = user?['last_name'] as String? ?? '';
          final name = '$firstName $lastName'.trim();
          final subject = teacherMap['subject'] as String? ?? '';
          final className = teacherMap['class_assigned'] as String? ?? '';
          
          // Get teacher's school_id for filtering
          final teacherSchoolId = teacherMap['school_id']?.toString();
          
          // Only add teachers with matching school_id (if currentSchoolId is available)
          final schoolMatches = currentSchoolId == null || teacherSchoolId == null || currentSchoolId == teacherSchoolId;

          if (userId.isNotEmpty && username.isNotEmpty && userId != _currentTeacherUserId && schoolMatches) {
            _contacts[userId] = ChatContact(
              id: userId,
              name: name.isNotEmpty ? name : username,
              username: username,
              type: ContactType.teacher,
              subject: subject,
              className: className,
              avatar: _getInitials(name.isNotEmpty ? name : username),
            );
            _messages[userId] = [];
            debugPrint('Added teacher: ${name.isNotEmpty ? name : username} (ID: $userId, School: $teacherSchoolId)');
          } else if (!schoolMatches) {
            debugPrint('Skipped teacher - school_id mismatch: teacher=$teacherSchoolId, current=$currentSchoolId');
          }
        } catch (e) {
          debugPrint('Error processing teacher: $e');
        }
      }
      
      // Fetch active conversations (Recent Chats)
      // This provides unread counts and last messages for the "WhatsApp-like" view
      debugPrint('Fetching conversations...');
      try {
        final conversations = await api.ApiService.fetchConversations();
        debugPrint('Fetched ${conversations.length} active conversations');
        debugPrint('Current teacher user ID: $_currentTeacherUserId');
        
        for (var conv in conversations) {
          try {
            debugPrint('Processing conversation: ${conv.toString()}');
            final contactData = conv['contact'] as Map<String, dynamic>?;
            if (contactData == null) {
              debugPrint('WARNING: contact data is null in conversation');
              continue;
            }
            
            final lastMsgData = conv['last_message'] as Map<String, dynamic>?;
            final unreadCount = conv['unread_count'] as int? ?? 0;
            
            // Try multiple possible ID fields from backend
            final userId = contactData['id']?.toString().trim() ?? 
                          contactData['user_id']?.toString().trim() ?? '';
            
            debugPrint('Conversation contact - userId: $userId, currentTeacher: $_currentTeacherUserId');
            
            if (userId.isEmpty) {
              debugPrint('WARNING: userId is empty for contact: ${contactData.toString()}');
              continue;
            }
            
            if (userId == _currentTeacherUserId) {
              debugPrint('Skipping self-conversation');
              continue;
            }
            
            // If contact doesn't exist yet (e.g. might be a parent or filtered out student), add it
            if (!_contacts.containsKey(userId)) {
              final username = contactData['username'] as String? ?? '';
              final firstName = contactData['first_name'] as String? ?? '';
              final lastName = contactData['last_name'] as String? ?? '';
              final name = '$firstName $lastName'.trim();
              final role = contactData['role'] as String? ?? 'User';
              
              _contacts[userId] = ChatContact(
                id: userId,
                name: name.isNotEmpty ? name : username,
                username: username,
                type: role.toLowerCase().contains('student') ? ContactType.student : ContactType.teacher, // Approximation
                className: '', // Details might be missing but that's okay for chat list
                grade: '',
                avatar: _getInitials(name.isNotEmpty ? name : username),
              );
              debugPrint('Added contact from conversation: ${name} ($userId)');
            } else {
              debugPrint('✓ Successfully matched contact from conversation: ${contactData['username']} (ID: $userId)');
            }
            
            // Update unread count - Always update to sync zero counts
            _unreadCounts[userId] = unreadCount;
            if (unreadCount > 0) {
              debugPrint('Set unread count for $userId to $unreadCount');
            }
            
            // Update last message if messages list is empty
            if (lastMsgData != null) {
              _messages[userId] ??= [];
              // Only add if empty to avoid duplicates with real-time updates
              if (_messages[userId]!.isEmpty) {
                final lastMsg = ChatMessage(
                  id: lastMsgData['message_id']?.toString() ?? '',
                  text: lastMsgData['message_text']?.toString() ?? 
                        (lastMsgData['attachment'] != null ? '📎 Attachment' : 
                         (lastMsgData['message'] != null ? lastMsgData['message'].toString() : '')),
                  senderId: (lastMsgData['sender'] as Map?)?['user_id']?.toString() ?? '',
                  isSent: (lastMsgData['sender'] as Map?)?['user_id']?.toString() == _currentTeacherUserId,
                  timestamp: lastMsgData['created_at']?.toString() ?? DateTime.now().toUtc().toIso8601String(),
                  isRead: lastMsgData['is_read'] == true,
                );
                _messages[userId]!.add(lastMsg);
                debugPrint('Added last message for $userId: ${lastMsg.text}');
              }
            }
          } catch (e) {
            debugPrint('Error processing conversation item: $e');
          }
        }
        debugPrint('FINISHED processing conversations. Resulting contact list size: ${_contacts.length}');
        for (var c in _contacts.values) {
          final hasMsg = _messages[c.id]?.isNotEmpty ?? false;
          debugPrint(' CONTACT in list: ${c.name} (ID: ${c.id}, Type: ${c.type}, HasMsg: $hasMsg)');
        }
      } catch (e) {
        debugPrint('Error fetching conversations: $e');
      }

      // Fetch groups from API
      debugPrint('Fetching groups...');
      try {
        final groups = await api.ApiService.fetchGroups();
        debugPrint('Fetched ${groups.length} groups');
        
        for (var groupData in groups) {
          try {
            final groupId = groupData['group_id']?.toString() ?? '';
            final groupName = groupData['name']?.toString() ?? 'Unnamed Group';
            final members = groupData['members'] as List? ?? [];
            final memberIds = members.map((m) => (m as Map)['user_id']?.toString() ?? '').where((id) => id.isNotEmpty).toList();
            
            // Extract creator information
            final createdByData = groupData['created_by'] as Map<String, dynamic>?;
            final createdByName = createdByData?['name']?.toString() ?? 
                                 createdByData?['username']?.toString() ?? 
                                 groupData['created_by_name']?.toString();
            final createdById = createdByData?['user_id']?.toString() ?? 
                               groupData['created_by_id']?.toString();
            
            // Extract latest message info
            final lastMsgData = groupData['last_message'] as Map<String, dynamic>?;
            String? lastMsgText;
            DateTime? lastMsgTime;
            String? lastMsgSender;
            bool lastMsgIsRead = false;
            bool lastMsgIsSent = false;

            if (lastMsgData != null) {
              lastMsgText = lastMsgData['message_text']?.toString() ?? 
                           (lastMsgData['attachment'] != null ? '📎 Attachment' : '');
              
              final timeStr = lastMsgData['created_at']?.toString();
              if (timeStr != null) {
                lastMsgTime = DateTime.parse(timeStr);
              }
              
              final senderData = lastMsgData['sender'] as Map?;
              lastMsgSender = senderData?['first_name']?.toString() ?? senderData?['username']?.toString();
              lastMsgIsRead = lastMsgData['is_read'] == true;
              lastMsgIsSent = senderData?['user_id']?.toString() == _currentTeacherUserId;
              
              // Also update _messages map for this group to ensure consistency
              _messages[groupId] ??= [];
              
              // Always update the last message if we have data, unless we have more recent data locally
              // This fixes the issue where the tile doesn't show the latest message
              if (lastMsgText != null && lastMsgText.isNotEmpty) {
                 final newMsg = ChatMessage(
                  id: lastMsgData['message_id']?.toString() ?? '',
                  text: lastMsgText,
                  senderId: senderData?['user_id']?.toString() ?? '',
                  senderName: lastMsgSender,
                  isSent: lastMsgIsSent,
                  timestamp: timeStr ?? DateTime.now().toUtc().toIso8601String(),
                  isRead: lastMsgIsRead,
                );
                
                if (_messages[groupId]!.isEmpty) {
                   _messages[groupId]!.add(newMsg);
                } else {
                   // Check if this message is newer than what we have (simple check)
                   // or if we just want to ensure the list isn't empty visually
                   final lastLocal = _messages[groupId]!.last;
                   if (lastLocal.timestamp.compareTo(newMsg.timestamp) < 0) {
                      _messages[groupId]!.add(newMsg);
                   }
                }
              }
            }

            final unreadCount = (groupData['unread_count'] as num?)?.toInt() ?? 0;
            _unreadCounts[groupId] = unreadCount;

            final group = ChatGroup(
              id: groupId,
              name: groupName,
              memberIds: memberIds,
              className: groupData['class_name']?.toString(),
              grade: groupData['grade']?.toString(),
              createdBy: createdByName,
              createdById: createdById,
              lastMessage: lastMsgText,
              lastMessageSender: lastMsgSender,
              lastMessageTime: lastMsgTime,
              lastMessageIsRead: lastMsgIsRead,
              lastMessageIsSent: lastMsgIsSent,
              unreadCount: unreadCount,
            );
            
            _groups[groupId] = group;
            
            // Add group as a contact for chat list
            _contacts[groupId] = ChatContact(
              id: groupId,
              name: groupName,
              username: groupId,
              type: ContactType.group,
              className: group.className,
              grade: group.grade,
              avatar: '👥',
            );
            _messages[groupId] ??= [];
            
            debugPrint('Added group: $groupName ($groupId) with ${memberIds.length} members, unread: $unreadCount');
          } catch (e) {
            debugPrint('Error processing group: $e');
          }
        }
      } catch (e) {
        debugPrint('Error fetching groups: $e');
      }

      debugPrint('Total contacts loaded: ${_contacts.length}');
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Load chat history - now handled in ChatScreen widget
  // Keeping this for reference but not called anymore
  @Deprecated('Use ChatScreen widget instead')
  Future<void> _loadChatHistory() async {
    if (_selectedContactId == null || _currentTeacherUserId == null || _currentTeacherUsername == null) return;
    
    final contact = _contacts[_selectedContactId];
    if (contact == null) {
      debugPrint('Contact not found for ID: $_selectedContactId');
      return;
    }
    
    try {
      debugPrint('Loading chat history for: ${contact.name} (${contact.username})');
      debugPrint('Teacher username: $_currentTeacherUsername');
      
      // Use the new ChatMessage API with sender and recipient usernames
      final messages = await api.ApiService.fetchChatMessages(_currentTeacherUsername!, contact.username);
      
      if (messages.isNotEmpty) {
        setState(() {
          _messages[_selectedContactId!] = messages.map((msg) {
            final sender = msg['sender'] is Map ? Map<String, dynamic>.from(msg['sender'] as Map) : null;
            final senderId = sender?['user_id']?.toString() ?? '';
            final senderUsername = sender?['username']?.toString() ?? '';
            
            // Determine if message was sent by current teacher
            final isSent = senderId == _currentTeacherUserId || 
                          senderUsername == _currentTeacherUsername;
            
            // Use message_text from ChatMessage model (fallback to message for backward compatibility)
            final messageText = msg['message_text']?.toString() ?? 
                               msg['message']?.toString() ?? '';
            
            final senderName = msg['sender_name']?.toString() ?? 
                               (sender != null ? '${sender['first_name'] ?? ''} ${sender['last_name'] ?? ''}'.trim() : null);

            return ChatMessage(
              id: msg['message_id']?.toString() ?? 
                  msg['id']?.toString() ?? 
                  DateTime.now().millisecondsSinceEpoch.toString(),
              text: messageText,
              senderId: senderId,
              senderName: senderName,
              isSent: isSent,
              timestamp: msg['created_at'] as String? ?? DateTime.now().toUtc().toIso8601String(),
            );
          }).toList();
        });
        _scrollToBottom();
        debugPrint('Loaded ${_messages[_selectedContactId!]!.length} chat messages');
      } else {
        debugPrint('No chat messages found');
        // Try fallback to old API if new API returns empty
        try {
          debugPrint('Trying fallback to old chat history API...');
          final history = await api.ApiService.fetchChatHistory(_selectedContactId!);
          if (history.isNotEmpty) {
            setState(() {
              _messages[_selectedContactId!] = history.map((msg) {
                final sender = msg['sender'] as Map<String, dynamic>?;
                final senderId = sender?['user_id']?.toString() ?? '';
                return ChatMessage(
                  id: msg['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  text: msg['message'] as String? ?? '',
                  senderId: senderId,
                  isSent: senderId == _currentTeacherUserId,
                  timestamp: msg['created_at'] as String? ?? DateTime.now().toUtc().toIso8601String(),
                );
              }).toList();
            });
            _scrollToBottom();
            debugPrint('Loaded ${_messages[_selectedContactId!]!.length} messages from fallback API');
          }
        } catch (fallbackError) {
          debugPrint('Fallback API also failed: $fallbackError');
        }
      }
    } catch (e) {
      debugPrint('Error loading chat history: $e');
      // Try fallback to old API
      try {
        debugPrint('Trying fallback to old chat history API...');
        final history = await api.ApiService.fetchChatHistory(_selectedContactId!);
        if (history.isNotEmpty) {
          setState(() {
            _messages[_selectedContactId!] = history.map((msg) {
              final sender = msg['sender'] as Map<String, dynamic>?;
              final senderId = sender?['user_id']?.toString() ?? '';
              return ChatMessage(
                id: msg['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
                text: msg['message'] as String? ?? '',
                senderId: senderId,
                isSent: senderId == _currentTeacherUserId,
                timestamp: msg['created_at'] as String? ?? DateTime.now().toUtc().toIso8601String(),
              );
            }).toList();
          });
          _scrollToBottom();
        }
      } catch (fallbackError) {
        debugPrint('Fallback API also failed: $fallbackError');
      }
    }
  }

  List<ChatContact> get _filteredContacts {
    final filtered = _contacts.values.where((contact) {
      // Search filter
      if (_searchQuery.isNotEmpty && !contact.name.toLowerCase().contains(_searchQuery)) {
        return false;
      }
      
      // Type filters
      if (_showTeachersOnly && contact.type != ContactType.teacher) return false;
      if (_showGroupsOnly && contact.type != ContactType.group) return false;
      // If no type filter is selected, show everyone (students, teachers) who matches search
      
      return true;
    }).toList();
    
    // Sort by most recent message time (WhatsApp/Telegram style)
    filtered.sort((a, b) {
      final aMessages = _messages[a.id];
      final bMessages = _messages[b.id];
      
      // Get last message timestamp for each contact
      DateTime? aTime;
      DateTime? bTime;
      
      if (aMessages != null && aMessages.isNotEmpty) {
        try {
          String aTimeStr = aMessages.last.timestamp;
          if (!aTimeStr.endsWith('Z') && !aTimeStr.contains('+')) {
            aTimeStr += 'Z';
          }
          aTime = DateTime.parse(aTimeStr);
        } catch (e) {
          aTime = null;
        }
      }
      
      if (bMessages != null && bMessages.isNotEmpty) {
        try {
          String bTimeStr = bMessages.last.timestamp;
          if (!bTimeStr.endsWith('Z') && !bTimeStr.contains('+')) {
            bTimeStr += 'Z';
          }
          bTime = DateTime.parse(bTimeStr);
        } catch (e) {
          bTime = null;
        }
      }
      
      // Contacts with messages come first, sorted by most recent
      if (aTime != null && bTime != null) {
        return bTime.compareTo(aTime); // Most recent first
      } else if (aTime != null) {
        return -1; // a has messages, b doesn't
      } else if (bTime != null) {
        return 1; // b has messages, a doesn't
      } else {
        // Both have no messages, sort by name
        return a.name.compareTo(b.name);
      }
    });
    
    return filtered;
  }

  List<ChatGroup> get _filteredGroups {
    return _groups.values.where((group) {
      if (_searchQuery.isNotEmpty && !group.name.toLowerCase().contains(_searchQuery)) {
        return false;
      }
      return true;
    }).toList()..sort((a, b) {
      // Sort by last message time
      final aMessages = _messages[a.id];
      final bMessages = _messages[b.id];
      
      DateTime? aTime;
      DateTime? bTime;
      
      if (aMessages != null && aMessages.isNotEmpty) {
        try {
          String aTimeStr = aMessages.last.timestamp;
          if (!aTimeStr.endsWith('Z') && !aTimeStr.contains('+')) aTimeStr += 'Z';
          aTime = DateTime.parse(aTimeStr);
        } catch (_) {}
      }
      
      if (bMessages != null && bMessages.isNotEmpty) {
        try {
          String bTimeStr = bMessages.last.timestamp;
          if (!bTimeStr.endsWith('Z') && !bTimeStr.contains('+')) bTimeStr += 'Z';
          bTime = DateTime.parse(bTimeStr);
        } catch (_) {}
      }
      
      if (aTime != null && bTime != null) {
        return bTime.compareTo(aTime); // Most recent first
      } else if (aTime != null) {
        return -1; 
      } else if (bTime != null) {
        return 1;
      } else {
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
    });
  }

  Future<void> _selectContact(String contactId) async {
    // Navigate to separate chat screen
    final contact = _contacts[contactId];
    if (contact == null) return;
    
    // Reset unread count for the selected contact locally
    setState(() {
      if (_unreadCounts[contactId] != null && _unreadCounts[contactId]! > 0) {
        // Call appropriate API based on contact type
        if (contact.type == ContactType.group) {
          // For groups, mark group messages as read
          api.ApiService.markGroupRead(contactId);
        } else {
          // For 1-to-1 chats, mark conversation as read
          api.ApiService.markConversationRead(contactId);
        }
      }
      _unreadCounts[contactId] = 0;
    });
    
    // Navigate to chat screen
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ChatScreen(
          contact: contact,
          teacherUsername: _currentTeacherUsername ?? '',
          teacherName: _currentTeacherName ?? '',
          teacherUserId: _currentTeacherUserId ?? '',
          messages: _messages[contactId] ?? [],
          unreadCounts: _unreadCounts,
          onMessageSent: () {
            // Trigger rebuild of the contact list when a message is sent
            if (mounted) setState(() {});
          },
        ),
      ),
    );
    
    // Reload data when returning from chat screen to refresh timestamps and message previews
    if (mounted) {
      await _loadData();
      // FORCE reset unread count to 0 to prevent stale data from API showing up
      setState(() {
        _unreadCounts[contactId] = 0;
      });
    }
  }

  // Initialize realtime chat - now handled in ChatScreen widget
  // Keeping this for reference but not called anymore
  @Deprecated('Use ChatScreen widget instead')
  Future<void> _initializeRealtimeChat() async {
    if (_selectedContactId == null || _currentTeacherName == null) {
      debugPrint('Cannot initialize chat: missing contact or teacher name');
      return;
    }
    
    final contact = _contacts[_selectedContactId];
    if (contact == null) {
      debugPrint('Contact not found: $_selectedContactId');
      return;
    }
    
    // Ensure contact has a name (not email/username)
    if (contact.name.isEmpty) {
      debugPrint('Cannot initialize chat: contact name is empty');
      return;
    }
    
    try {
      // Generate room ID using names only (no email fallback)
      final teacherName = normalizeNameForRoomId(_currentTeacherName!);
      final contactName = normalizeNameForRoomId(contact.name);
      
      if (teacherName.isEmpty || contactName.isEmpty) {
        debugPrint('Cannot initialize chat: normalized names are empty (teacher: $teacherName, contact: $contactName)');
        return;
      }
      
      final identifiers = [teacherName, contactName]..sort();
      final roomId = identifiers.join('_');
      
      final chatType = contact.type == ContactType.student 
          ? 'teacher-student' 
          : contact.type == ContactType.teacher 
              ? 'teacher-teacher' 
              : 'teacher-group';
      
      debugPrint('Initializing chat: roomId=$roomId, type=$chatType');
      debugPrint('  Teacher name: $_currentTeacherName -> $teacherName');
      debugPrint('  Contact name: ${contact.name} -> $contactName');
      
      _chatService = RealtimeChatService(baseWsUrl: api.ApiService.wsBaseUrl);
      await _chatService!.connect(roomId: roomId, chatType: chatType);
      
      _chatSubscription = _chatService!.stream?.listen((event) {
        try {
          final data = event is String ? jsonDecode(event) : event;
          if (data is Map) {
            final messageType = data['type']?.toString() ?? 'message';
            
            if (messageType == 'message') {
              final sender = data['sender']?.toString() ?? '';
              final senderUsername = data['sender_username']?.toString() ?? sender;
              final senderId = data['sender_id']?.toString() ?? '';
              final recipient = data['recipient']?.toString() ?? '';
              final recipientId = data['recipient_id']?.toString() ?? '';
              final messageText = data['message']?.toString() ?? '';
              final timestamp = data['timestamp']?.toString() ?? DateTime.now().toUtc().toIso8601String();
              
              if (messageText.isEmpty) return;
              
              // IMPORTANT: Only process messages for the current conversation
              // Check if this message is between the current teacher and the selected contact
              final isFromCurrentContact = (
                senderUsername == contact.username ||
                senderId == contact.id ||
                sender == contact.name
              );
              
              final isToCurrentContact = (
                recipient == contact.username ||
                recipientId == contact.id ||
                recipient == contact.name
              );
              
              final isFromCurrentTeacher = (
                senderUsername == _currentTeacherUsername ||
                senderId == _currentTeacherUserId ||
                sender == _currentTeacherName
              );
              
              final isToCurrentTeacher = (
                recipient == _currentTeacherUsername ||
                recipientId == _currentTeacherUserId
              );
              
              // Message is for this conversation if:
              // 1. From contact to teacher, OR
              // 2. From teacher to contact
              final isForThisConversation = (
                (isFromCurrentContact && isToCurrentTeacher) ||
                (isFromCurrentTeacher && isToCurrentContact)
              );
              
              if (!isForThisConversation) {
                debugPrint('Ignoring message not for this conversation: sender=$senderUsername, recipient=$recipient, contact=${contact.name}');
                return;
              }
              
              // Check for duplicate messages using message_id (most reliable)
              final messageId = data['message_id']?.toString() ?? '';
              final existingMessages = _messages[_selectedContactId!] ?? [];
              final isDuplicate = messageId.isNotEmpty 
                ? existingMessages.any((msg) => msg.id == messageId)
                : existingMessages.any((msg) => 
                    msg.text == messageText && 
                    (isFromCurrentTeacher ? msg.isSent : !msg.isSent) &&
                    (timestamp == msg.timestamp || 
                     (DateTime.tryParse(timestamp) != null && DateTime.tryParse(msg.timestamp) != null &&
                      DateTime.tryParse(timestamp)!.difference(DateTime.tryParse(msg.timestamp)!).inSeconds.abs() < 2))
                  );
              
              // Only process if message is for currently selected contact
              // This ensures messages only appear in the correct conversation
              if (_selectedContactId != contact.id) {
                // Message is not for currently open conversation
                if (!isFromCurrentTeacher) {
                  // Increment unread count for messages from contact
                  setState(() {
                    _unreadCounts[contact.id] = (_unreadCounts[contact.id] ?? 0) + 1;
                  });
                  debugPrint('Unread count for ${contact.name}: ${_unreadCounts[contact.id]}');
                }
                return; // Don't add to UI if conversation is not open
              }
              
              if (!isDuplicate) {
                // Message is for currently open conversation
                setState(() {
                  _messages[_selectedContactId!] ??= [];
                  
                  if (isFromCurrentTeacher && messageId.isNotEmpty) {
                    // Teacher's message - try to update existing temporary message with real message_id
                    // Look for temp message with same text sent within last 5 seconds
                    final now = DateTime.now();
                    final existingIndex = _messages[_selectedContactId!]!.lastIndexWhere((msg) {
                      if (!msg.isSent || msg.text != messageText) return false;
                      if (msg.id.startsWith('temp_')) {
                        try {
                          final msgTime = DateTime.parse(msg.timestamp);
                          final diff = now.difference(msgTime).abs();
                          return diff.inSeconds < 5;
                        } catch (e) {
                          return false;
                        }
                      }
                      return false;
                    });
                    
                    if (existingIndex != -1) {
                      // Update existing temp message with real ID
                      _messages[_selectedContactId!]![existingIndex] = ChatMessage(
                        id: messageId,
                        text: messageText,
                        senderId: _currentTeacherUserId ?? '',
                        isSent: true,
                        timestamp: timestamp,
                      );
                      debugPrint('Updated temp message with real ID: $messageId');
                    } else {
                      // Check if message with this ID already exists
                      final alreadyExists = _messages[_selectedContactId!]!.any((msg) => msg.id == messageId);
                      if (!alreadyExists) {
                        // Add new message
                        _messages[_selectedContactId!]!.add(ChatMessage(
                          id: messageId,
                          text: messageText,
                          senderId: _currentTeacherUserId ?? '',
                          isSent: true,
                          timestamp: timestamp,
                        ));
                      }
                    }
                  } else {
                    // Message from contact - check if already exists
                    final finalMessageId = messageId.isNotEmpty ? messageId : DateTime.now().millisecondsSinceEpoch.toString();
                    final alreadyExists = _messages[_selectedContactId!]!.any((msg) => 
                      msg.id == finalMessageId || (msg.text == messageText && !msg.isSent)
                    );
                    if (!alreadyExists) {
                      _messages[_selectedContactId!]!.add(ChatMessage(
                        id: finalMessageId,
                        text: messageText,
                        senderId: contact.id,
                        isSent: false,
                        timestamp: timestamp,
                      ));
                    }
                  }
                  // Reset unread count for this contact since chat is open
                  setState(() {
                    _unreadCounts[contact.id] = 0;
                  });
                });
                _scrollToBottom();
                debugPrint('Received message for ${contact.name}: ${isFromCurrentTeacher ? "from teacher" : "from contact"} - $messageText');
              } else {
                debugPrint('Duplicate message ignored (ID: $messageId, text: $messageText)');
              }
            }
          }
        } catch (e) {
          debugPrint('Error processing message: $e');
        }
      });
      
      debugPrint('Chat initialized successfully');
    } catch (e) {
      debugPrint('Error initializing realtime chat: $e');
    }
  }

  // _sendMessage is now handled in ChatScreen widget - not needed in main screen

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showCreateGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateGroupDialog(
        contacts: _contacts.values.where((c) => c.type == ContactType.student).toList(),
        onGroupCreated: (group) {
          setState(() {
            _groups[group.id] = group;
            _contacts[group.id] = ChatContact(
              id: group.id,
              name: group.name,
              username: group.id,
              type: ContactType.group,
              className: group.className,
              section: group.section,
              avatar: '👥',
            );
            _messages[group.id] = [];
          });
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Group "${group.name}" created successfully')),
          );
        },
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  // Get total unread count for teachers
  int _getTeacherUnreadCount() {
    int count = 0;
    for (var contact in _contacts.values) {
      if (contact.type == ContactType.teacher) {
        count += _unreadCounts[contact.id] ?? 0;
      }
    }
    return count;
  }

  // Get total unread count for groups
  int _getGroupUnreadCount() {
    int count = 0;
    for (var contact in _contacts.values) {
      if (contact.type == ContactType.group) {
        count += _unreadCounts[contact.id] ?? 0;
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF667eea),
        title: const Text(
          'Teacher Communication',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add, color: Colors.white),
            onPressed: _showCreateGroupDialog,
            tooltip: 'Create Group',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search and filters
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by name...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Centered filter buttons with counts
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FilterChip(
                            label: const Text('Total Messages', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                            selected: !_showTeachersOnly && !_showGroupsOnly,
                            onSelected: (v) {
                              if (v) {
                                setState(() {
                                  _showTeachersOnly = false;
                                  _showGroupsOnly = false;
                                });
                              }
                            },
                            selectedColor: const Color(0xFF667eea),
                            checkmarkColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          const SizedBox(width: 16),
                          FilterChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Teachers', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                if (_getTeacherUnreadCount() > 0) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${_getTeacherUnreadCount()}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            selected: _showTeachersOnly,
                            onSelected: (v) => setState(() {
                              _showTeachersOnly = v;
                              if (v) _showGroupsOnly = false;
                            }),
                            selectedColor: const Color(0xFF667eea),
                            checkmarkColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          const SizedBox(width: 16),
                          FilterChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Groups', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                if (_getGroupUnreadCount() > 0) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${_getGroupUnreadCount()}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            selected: _showGroupsOnly,
                            onSelected: (v) => setState(() {
                              _showGroupsOnly = v;
                              if (v) _showTeachersOnly = false;
                            }),
                            selectedColor: const Color(0xFF667eea),
                            checkmarkColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Contacts list
                Expanded(
                  child: _showGroupsOnly 
                      ? (_filteredGroups.isEmpty
                          ? const Center(child: Text('No groups found'))
                          : ListView.builder(
                              itemCount: _filteredGroups.length,
                              itemBuilder: (context, index) {
                                final group = _filteredGroups[index];
                                return _buildGroupTile(group);
                              },
                            ))
                      : (_filteredContacts.isEmpty
                          ? const Center(child: Text('No contacts found'))
                          : ListView.builder(
                              itemCount: _filteredContacts.length,
                              itemBuilder: (context, index) {
                                final contact = _filteredContacts[index];
                                return _buildContactTile(contact);
                              },
                            )),
                ),
              ],
            ),
    );
  }

  Widget _buildContactTile(ChatContact contact) {
    final lastMessage = _messages[contact.id]?.lastOrNull;
    final unreadCount = _unreadCounts[contact.id] ?? 0;
    
    return InkWell(
      onTap: () => _selectContact(contact.id),
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Profile picture
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey[300],
              child: Text(
                contact.avatar,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Show last message if available, otherwise show contact type info
                  Row(
                    children: [
                      if (lastMessage != null && lastMessage.isSent) ...[
                        Icon(
                          lastMessage.isRead ? Icons.done_all : Icons.done,
                          size: 14,
                          color: lastMessage.isRead ? const Color(0xFF34B7F1) : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          lastMessage != null 
                              ? lastMessage.text
                              : (contact.type == ContactType.student
                                  ? '${contact.className ?? ''} ${contact.grade ?? ''}'.trim().isEmpty
                                      ? 'Student'
                                      : '${contact.className ?? ''} ${contact.grade ?? ''}'.trim()
                                  : contact.subject ?? 'Teacher'),
                          style: TextStyle(
                            fontSize: 13,
                            color: lastMessage != null ? Colors.grey[700] : Colors.grey[600],
                            fontWeight: (unreadCount > 0 && lastMessage != null) ? FontWeight.bold : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Time and unread count
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (lastMessage != null)
                  Text(
                    _formatTime(lastMessage.timestamp),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                if (unreadCount > 0) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: const BoxDecoration(
                      color: Color(0xFF667eea),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupTile(ChatGroup group) {
    final lastMessage = _messages[group.id]?.lastOrNull;
    final unreadCount = _unreadCounts[group.id] ?? 0;
    
    return InkWell(
      onTap: () => _selectContact(group.id),
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Profile picture
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFF667eea),
              child: const Text(
                '👥',
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Show last message if available, otherwise show member count
                  Row(
                    children: [
                      if (lastMessage != null && lastMessage.isSent) ...[
                        Icon(
                          lastMessage.isRead ? Icons.done_all : Icons.done,
                          size: 14,
                          color: lastMessage.isRead ? const Color(0xFF34B7F1) : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          lastMessage != null 
                              ? (lastMessage.senderId == _currentTeacherUserId ? 'You: ' : '${lastMessage.senderName ?? 'Member'}: ') + lastMessage.text
                              : '${group.memberIds.length} members',
                          style: TextStyle(
                            fontSize: 13,
                            color: lastMessage != null ? Colors.grey[700] : Colors.grey[600],
                            fontWeight: (unreadCount > 0 && lastMessage != null) ? FontWeight.bold : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Time and unread count
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (lastMessage != null)
                  Text(
                    _formatTime(lastMessage.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: unreadCount > 0 ? const Color(0xFF25D366) : Colors.grey,
                      fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                if (unreadCount > 0) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: const BoxDecoration(
                      color: Color(0xFF25D366),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Build chat area - now using separate ChatScreen widget
  // Keeping this for reference but not called anymore
  @Deprecated('Use ChatScreen widget instead')
  Widget _buildChatArea() {
    final contact = _contacts[_selectedContactId];
    if (contact == null) return const SizedBox();
    
    final messages = _messages[_selectedContactId] ?? [];
    
    return Column(
      children: [
        // Chat header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              // Profile picture
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF667eea),
                child: Text(
                  contact.avatar,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      contact.type == ContactType.student
                          ? '${contact.className ?? ''} ${contact.section ?? ''}'.trim().isEmpty
                              ? 'Student'
                              : '${contact.className ?? ''} ${contact.section ?? ''}'.trim()
                          : contact.subject ?? 'Teacher',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              // Three dots menu
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onPressed: () {
                  // Add menu functionality here
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Messages
        Expanded(
          child: messages.isEmpty
              ? Container(
                  color: Colors.grey[100],
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start the conversation!',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                )
              : Container(
                  color: Colors.grey[100],
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
                ),
        ),
        // Input area
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      hintStyle: TextStyle(color: Colors.grey[500]),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) {
                      // Send message - handled in ChatScreen widget (this method is deprecated)
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Microphone button
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.mic, color: Colors.white),
                  onPressed: () {
                    // Add voice message functionality
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Send button
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF667eea),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: () {
                    // Send message - handled in ChatScreen widget (this method is deprecated)
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final contact = _contacts[_selectedContactId];
    final bool isGroup = contact?.type == ContactType.group;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: message.isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Profile picture for received messages (left side)
          if (!message.isSent && contact != null) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: isGroup ? Colors.blue[100] : Colors.grey[300],
              child: Text(
                isGroup ? (message.senderName?.substring(0, 1).toUpperCase() ?? '?') : contact.avatar,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Message bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: message.isSent 
                    ? const Color(0xFF667eea) 
                    : Colors.white,
                borderRadius: message.isSent
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(4),
                      )
                    : const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                        bottomLeft: Radius.circular(4),
                        bottomRight: Radius.circular(18),
                      ),
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
                   // Sender Name for Group Messages
                  if (isGroup && !message.isSent && message.senderName != null) ...[
                    Text(
                      message.senderName!,
                      style: const TextStyle(
                        color: Color(0xFF075E54),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  // Reply Snippet
                  if (message.repliedToId != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: message.isSent ? Colors.white.withOpacity(0.1) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border(
                          left: BorderSide(
                            color: message.isSent ? Colors.white70 : const Color(0xFF667eea),
                            width: 4,
                          ),
                        ),
                      ),
                      child: Text(
                        'Replying to...', // We could fetch actual message text if needed
                        style: TextStyle(
                          color: message.isSent ? Colors.white70 : Colors.black54,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  // Attachment
                  if (message.attachmentUrl != null) ...[
                    GestureDetector(
                      onTap: () => _downloadAttachment(message),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: message.isSent ? Colors.black.withOpacity(0.1) : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.attach_file, size: 16),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                message.attachmentName ?? 'Download Attachment',
                                style: const TextStyle(
                                  fontSize: 13,
                                  decoration: TextDecoration.underline,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  // Message Text
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isSent ? Colors.white : Colors.black87,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: message.isSent ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                      if (message.isSent) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 14,
                          color: message.isRead ? Colors.lightBlueAccent : Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadAttachment(ChatMessage message) async {
    if (message.attachmentUrl == null || message.attachmentUrl!.isEmpty) return;
    
    final url = message.attachmentUrl!;
    final fileName = message.attachmentName ?? url.split('/').last;

    if (!url.startsWith('http')) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('File is local'),
        duration: Duration(seconds: 1),
      ));
      return;
    }
    
    try {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Downloading $fileName...'),
        duration: const Duration(seconds: 2),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to download: $e'),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  String _formatTime(String timestamp) {
    if (timestamp.isEmpty) return '';
    try {
      String timeToParse = timestamp;
      
      
      final dateTime = DateTime.parse(timeToParse).toLocal();
      final now = DateTime.now();
      
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final msgDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
      
      if (msgDate == today) {
        return DateFormat('h:mm a').format(dateTime);
      } else if (msgDate == yesterday) {
        return 'Yesterday';
      } else if (today.difference(msgDate).inDays < 7) {
        return DateFormat('EEEE').format(dateTime);
      } else {
        return DateFormat('MMM d').format(dateTime);
      }
    } catch (e) {
      return timestamp;
    }
  }
}

// Data Models
enum ContactType { student, teacher, group }

class ChatContact {
  final String id;
  final String name;
  final String username;
  final ContactType type;
  final String avatar;
  String? className;
  String? grade;
  String? section; // Added section
  String? subject;

  ChatContact({
    required this.id,
    required this.name,
    required this.username,
    required this.type,
    required this.avatar,
    this.className,
    this.grade, // Added grade
    this.section,
    this.subject,
  });
}

class ChatMessage {
  final String id;
  final String text;
  final String senderId;
  final String? senderName; // Added for groups
  final bool isSent;
  final String timestamp;
  final bool isRead;
  final String? attachmentUrl;
  final String? attachmentName;
  final String? repliedToId; // Added for replies

  ChatMessage({
    required this.id,
    required this.text,
    required this.senderId,
    this.senderName,
    required this.isSent,
    required this.timestamp,
    this.isRead = false,
    this.attachmentUrl,
    this.attachmentName,
    this.repliedToId,
  });
}

class ChatGroup {
  final String id;
  final String name;
  final List<String> memberIds;
  String? className;
  String? grade;
  String? section; // Added section
  String? createdBy; // Teacher name who created the group
  String? createdById; // Teacher user ID who created the group
  String? lastMessage;
  String? lastMessageSender;
  DateTime? lastMessageTime;
  bool lastMessageIsRead;
  bool lastMessageIsSent;
  int unreadCount;

  ChatGroup({
    required this.id,
    required this.name,
    required this.memberIds,
    this.className,
    this.grade,
    this.section, // Added section
    this.createdBy,
    this.createdById,
    this.lastMessage,
    this.lastMessageSender,
    this.lastMessageTime,
    this.lastMessageIsRead = false,
    this.lastMessageIsSent = true,
    this.unreadCount = 0,
  });
}

// Create Group Dialog
class CreateGroupDialog extends StatefulWidget {
  final List<ChatContact> contacts;
  final Function(ChatGroup) onGroupCreated;

  const CreateGroupDialog({
    super.key,
    required this.contacts,
    required this.onGroupCreated,
  });

  @override
  State<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedIds = {};
  String _searchQuery = '';
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a group name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one member'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      // Call API to create group
      final groupData = {
        'name': _nameController.text.trim(),
        'description': '',
        'member_ids': _selectedIds.toList(),
      };
      
      final createdGroup = await api.ApiService.createGroup(groupData);
      
      // Create ChatGroup from API response
      final group = ChatGroup(
        id: createdGroup['group_id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: createdGroup['name'] ?? _nameController.text.trim(),
        memberIds: _selectedIds.toList(),
      );

      if (!mounted) return;

      // Show success dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 10),
              Text('Success'),
            ],
          ),
          content: Text('Group "${group.name}" created successfully!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close success dialog
                widget.onGroupCreated(group); // Triggers parent update and close main dialog
              },
              child: const Text('OK', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      
    } catch (e) {
      debugPrint('Error creating group: $e');
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create group: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<ChatContact> get _filteredContacts {
    var filtered = widget.contacts;
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((contact) {
        return contact.name.toLowerCase().contains(_searchQuery);
      }).toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    // Use LayoutBuilder to get available size
    return LayoutBuilder(
      builder: (context, constraints) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 500, // Max width
            height: constraints.maxHeight * 0.8, // Use 80% of screen height
            constraints: const BoxConstraints(maxHeight: 700),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Create New Group',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Close',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Group Name Input
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Group Name',
                    hintText: 'e.g., Class 10 Math Club',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.group),
                  ),
                  enabled: !_isCreating,
                ),
                const SizedBox(height: 20),
                
                // Search Input
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search students...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  enabled: !_isCreating,
                ),
                const SizedBox(height: 16),
                
                // Member Selection Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Members',
                      style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF667eea).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_selectedIds.length} selected',
                        style: const TextStyle(
                          color: Color(0xFF667eea),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                
                // Flexible Student List
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _filteredContacts.isEmpty
                        ? const Center(child: Text('No students found'))
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _filteredContacts.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final contact = _filteredContacts[index];
                              final isSelected = _selectedIds.contains(contact.id);
                              return CheckboxListTile(
                                value: isSelected,
                                onChanged: _isCreating ? null : (checked) {
                                  setState(() {
                                    if (checked == true) {
                                      _selectedIds.add(contact.id);
                                    } else {
                                      _selectedIds.remove(contact.id);
                                    }
                                  });
                                },
                                activeColor: const Color(0xFF667eea),
                                title: Text(
                                  contact.name,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                subtitle: Text(
                                  '${contact.className ?? ''} ${contact.grade ?? ''}'.trim().isEmpty
                                      ? 'Student'
                                      : '${contact.className ?? ''} ${contact.grade ?? ''}'.trim(),
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                secondary: CircleAvatar(
                                  backgroundColor: Colors.grey[200],
                                  child: Text(
                                    contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                                    style: TextStyle(color: Colors.grey[800]),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isCreating ? null : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isCreating ? null : _createGroup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF667eea),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isCreating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Create Group',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Separate Chat Screen Widget
class GroupInfoDialog extends StatefulWidget {
  final String groupId;
  final String groupName;
  final Function(String) onNameUpdated;

  final bool isReadOnly;

  const GroupInfoDialog({
    Key? key,
    required this.groupId,
    required this.groupName,
    required this.onNameUpdated,
    this.isReadOnly = false,
  }) : super(key: key);

  @override
  State<GroupInfoDialog> createState() => _GroupInfoDialogState();
}

class _GroupInfoDialogState extends State<GroupInfoDialog> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _members = [];
  String _currentName = '';
  String? _createdBy; // Teacher who created the group

  @override
  void initState() {
    super.initState();
    _currentName = widget.groupName;
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    setState(() => _isLoading = true);
    try {
      final data = await api.ApiService.getGroupMembers(widget.groupId);
      if (data.isNotEmpty) {
        setState(() {
          _members = List<Map<String, dynamic>>.from(data);
          // extraction of group_name or created_by is confusing here because getGroupMembers only returns members list.
          // We likely cannot get group_name or created_by from getGroupMembers(groupId).
          // We should probably remove that logic or fetch group details separately if needed.
          // For now, I'll comment out the invalid extraction to fix complication.
          /*
          _currentName = data['group_name'] ?? _currentName;
          final creator = data['created_by'];
          if (creator != null && creator.toString().toLowerCase() != 'null') {
            _createdBy = creator.toString();
          } else {
            _createdBy = data['created_by_name']?.toString();
          }
          */
        });
      }
    } catch (e) {
      debugPrint('Error fetching group members: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _editGroupName() async {
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => EditGroupNameDialog(currentName: _currentName),
    );

    if (newName != null && newName.isNotEmpty && newName != _currentName) {
      final success = await api.ApiService.updateGroupName(widget.groupId, newName);
      if (success) {
        setState(() => _currentName = newName);
        widget.onNameUpdated(newName);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group name updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update group name')),
        );
      }
    }
  }

  Future<void> _removeMember(String userId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Are you sure you want to remove $name from the group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await api.ApiService.removeGroupMember(widget.groupId, userId);
      if (success) {
        setState(() {
          _members.removeWhere((m) => m['user_id'].toString() == userId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name removed from group')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to remove member')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        height: 600,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Group Info',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 10),
            // Group Name Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF667eea),
                    child: const Icon(Icons.group, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_members.length} participants',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!widget.isReadOnly)
                  IconButton(
                    icon: const Icon(Icons.edit, color: Color(0xFF667eea)),
                    onPressed: _editGroupName,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Created by section
            if (_createdBy != null && _createdBy!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Created by: ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _createdBy!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Participants',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF667eea),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _members.length,
                      itemBuilder: (context, index) {
                        final member = _members[index];
                        // Build name from parts, filtering out null/None values
                        String name = '';
                        final firstName = member['first_name'];
                        final lastName = member['last_name'];
                        
                        if (firstName != null && firstName.toString().toLowerCase() != 'null' && firstName.toString().toLowerCase() != 'none') {
                          name = firstName.toString();
                        }
                        if (lastName != null && lastName.toString().toLowerCase() != 'null' && lastName.toString().toLowerCase() != 'none') {
                          if (name.isNotEmpty) name += ' ';
                          name += lastName.toString();
                        }
                        
                        // Fallback to full_name or username if name is still empty
                        if (name.isEmpty) {
                          final fullName = member['full_name'];
                          if (fullName != null && fullName.toString().toLowerCase() != 'null' && fullName.toString().toLowerCase() != 'none') {
                            name = fullName.toString();
                          } else {
                            name = member['username'] ?? 'Unknown';
                          }
                        }
                        
                        final className = member['class_name'];
                        final section = member['section'];
                        final grade = member['grade'];
                        
                         final role = member['role']?.toString().toLowerCase() ?? '';

                         final subject = member['subject']?.toString();

                         

                          String sub = '';

                          Color? subColor;

                          

                          // Check if member is a teacher

                          if (role.contains('teacher') || (subject != null && subject.toLowerCase() != 'null' && subject.isNotEmpty)) {

                            // Teacher display: "Teacher: Subject"

                            sub = 'Teacher';

                            if (subject != null && subject.toLowerCase() != 'null' && subject.isNotEmpty) {

                              sub += ': $subject';

                            }

                            subColor = Colors.green[700];

                          } else {

                            // Student display: "Class X-A • Grade Y"

                            if (className != null && className.toString().toLowerCase() != 'null') {

                              sub = 'Class $className';

                              if (section != null && section.toString().toLowerCase() != 'null') sub += '-$section';

                            }

                            if (grade != null && grade.toString().toLowerCase() != 'null') {

                              if (sub.isNotEmpty) sub += ' • ';

                              sub += 'Grade $grade';

                            }

                            subColor = Colors.orange[700];

                          }



                         return ListTile(
                           leading: CircleAvatar(
                             backgroundColor: Colors.grey[300],
                             child: Text(
                               name.isNotEmpty ? name[0].toUpperCase() : '?',
                               style: const TextStyle(color: Colors.black87),
                             ),
                           ),
                           title: Text(name),
                           subtitle: sub.isNotEmpty ? Text(
                              sub,
                              style: TextStyle(
                                color: subColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ) : null,
                           trailing: widget.isReadOnly ? null : PopupMenuButton<String>(
                             onSelected: (val) => _removeMember(member['user_id'].toString(), name),
                             itemBuilder: (context) => [
                               const PopupMenuItem(
                                 value: 'remove',
                                 child: Text('Remove from Group', style: TextStyle(color: Colors.red)),
                               ),
                             ],
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

class EditGroupNameDialog extends StatefulWidget {
  final String currentName;

  const EditGroupNameDialog({Key? key, required this.currentName}) : super(key: key);

  @override
  State<EditGroupNameDialog> createState() => _EditGroupNameDialogState();
}

class _EditGroupNameDialogState extends State<EditGroupNameDialog> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter new subject'),
      content: TextField(
        controller: _nameController,
        decoration: const InputDecoration(
          hintText: 'Group Subject',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _nameController.text.trim()),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

// Separate Chat Screen Widget
class _ChatScreen extends StatefulWidget {
  final ChatContact contact;
  final String teacherUsername;
  final String teacherName;
  final String teacherUserId;
  final List<ChatMessage> messages;
  final Map<String, int> unreadCounts;

  const _ChatScreen({
    required this.contact,
    required this.teacherUsername,
    required this.teacherName,
    required this.teacherUserId,
    required this.messages,
    required this.unreadCounts,
    this.onMessageSent,
  });

  final VoidCallback? onMessageSent;

  @override
  State<_ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<_ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  RealtimeChatService? _chatService;
  StreamSubscription? _chatSubscription;
  final Set<String> _messageIds = {}; // Track message IDs to prevent duplicates
  bool _isLoadingHistory = true;
  List<File> _selectedFiles = [];
  List<String> _selectedFileNames = [];
  ChatMessage? _replyingTo; // Track message being replied to

  @override
  void initState() {
    super.initState();
    // Work directly on the parent list reference to update previews instantly
    _messages = widget.messages;
    _isLoadingHistory = _messages.isEmpty; 
    
    // Mark messages as read immediately when screen opens
    if (widget.contact.type == ContactType.group) {
       api.ApiService.markGroupRead(widget.contact.id);
    } else {
       api.ApiService.markConversationRead(widget.contact.id);
    }
    
    _loadChatHistory();
    _initializeRealtimeChat();
  }

  @override
  void dispose() {
    _chatService?.disconnect();
    _chatSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String normalizeNameForRoomId(String name) {
    if (name.isEmpty) return '';
    return name
        .toLowerCase()
        .trim()
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }

  Future<void> _loadChatHistory() async {
    try {
      // Use otherUserId (widget.contact.id) for more reliable identification in backend
      final messages = await api.ApiService.fetchChatMessages(
        widget.teacherUsername, 
        widget.contact.type == ContactType.group ? '' : widget.contact.username,
        otherUserId: widget.contact.type == ContactType.group ? null : widget.contact.id,
        groupId: widget.contact.type == ContactType.group ? widget.contact.id : null,
      );
      
      if (mounted) {
        setState(() {
          // Process messages from backend
          final List<ChatMessage> history = messages.map((msg) {
            final sender = msg['sender'] is Map ? Map<String, dynamic>.from(msg['sender'] as Map) : null;
            final senderId = sender?['user_id']?.toString() ?? '';
            final senderUsername = sender?['username']?.toString() ?? '';
            final isSent = senderId == widget.teacherUserId || senderUsername == widget.teacherUsername;
            final messageText = msg['message_text']?.toString() ?? msg['message']?.toString() ?? '';
            final messageId = msg['message_id']?.toString() ?? msg['id']?.toString() ?? DateTime.now().toUtc().millisecondsSinceEpoch.toString();
            
            final senderName = msg['sender_name']?.toString() ?? 
                               (sender != null ? '${sender['first_name'] ?? ''} ${sender['last_name'] ?? ''}'.trim() : null);
            
            return ChatMessage(
              id: messageId,
              text: messageText,
              senderId: senderId,
              senderName: senderName,
              isSent: isSent,
              timestamp: msg['created_at'] as String? ?? DateTime.now().toUtc().toIso8601String(),
              isRead: msg['is_read'] == true,
              attachmentUrl: msg['attachment_url']?.toString(),
              attachmentName: msg['attachment_name']?.toString(),
              repliedToId: msg['replied_to_id']?.toString(),
            );
          }).toList().reversed.toList();

          // Merge history safely
          // 1. Identify existing messages to avoid duplicates
          final existingIds = _messages.map((m) => m.id).toSet();
          
          // 2. Identify text of outgoing messages in history to resolve temp messages
          final historySentTexts = history.where((h) => h.isSent).map((h) => h.text).toSet();
          
          // 3. Remove temp messages that are now represented in history
          _messages.removeWhere((m) => m.id.startsWith('temp_') && historySentTexts.contains(m.text));
          
          // 4. Add ONLY new messages from history
          for (final msg in history) {
            if (!existingIds.contains(msg.id)) {
              _messages.add(msg);
              existingIds.add(msg.id);
            }
          }
          
          // 5. Final sort and ID sync
          _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          
          _messageIds.clear();
          _messageIds.addAll(_messages.map((m) => m.id));
          
          _isLoadingHistory = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Error loading chat history: $e');
      if (mounted) {
        if (mounted) setState(() => _isLoadingHistory = false);
      }
    }
  }

  Future<void> _initializeRealtimeChat() async {
    final bool isGroup = widget.contact.type == ContactType.group;
    
    try {
      String roomId;
      String chatType;
      
      if (isGroup) {
        roomId = widget.contact.id;
        chatType = 'group';
      } else {
        final teacherName = normalizeNameForRoomId(widget.teacherUsername.isNotEmpty ? widget.teacherUsername : widget.teacherName);
        final contactName = normalizeNameForRoomId(widget.contact.username.isNotEmpty ? widget.contact.username : widget.contact.name);
        final identifiers = [teacherName, contactName]..sort();
        roomId = identifiers.join('_');
        chatType = widget.contact.type == ContactType.student ? 'teacher-student' : 'teacher-teacher';
      }
      
      debugPrint('Connecting to WS: Room=$roomId, Type=$chatType');
      _chatService = RealtimeChatService(baseWsUrl: api.ApiService.wsBaseUrl);
      await _chatService!.connect(roomId: roomId, chatType: chatType);
      
      _chatSubscription = _chatService!.stream?.listen((event) {
        try {
          final data = event is String ? jsonDecode(event) : event;
          if (data is Map) {
            if (data['type'] == 'chat.message') {
              final messageId = data['message_id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
              final messageText = data['message']?.toString() ?? '';
              final senderId = data['sender_id']?.toString() ?? '';
              final senderUsername = data['sender_username']?.toString() ?? '';
              final senderName = data['sender']?.toString();
              final timestamp = data['timestamp']?.toString() ?? DateTime.now().toUtc().toIso8601String();
              
              if (messageText.isEmpty) return;
              
              // Filtering
              bool forThisChat = false;
              if (isGroup) {
                forThisChat = data['group_id']?.toString() == widget.contact.id;
              } else {
                final recipient = data['recipient']?.toString() ?? '';
                final recipientId = data['recipient_id']?.toString() ?? '';
                
                final isFromTeacher = senderId == widget.teacherUserId || senderUsername == widget.teacherUsername;
                final isToTeacher = recipientId == widget.teacherUserId || recipient == widget.teacherUsername;
                final isFromContact = senderId == widget.contact.id || senderUsername == widget.contact.username;
                final isToContact = recipientId == widget.contact.id || recipient == widget.contact.username;
                
                forThisChat = (isFromTeacher && isToContact) || (isFromContact && isToTeacher);
              }
              
              if (!forThisChat) return;

              if (_messageIds.contains(messageId)) return;
              
              final isSent = senderId == widget.teacherUserId || senderUsername == widget.teacherUsername;
              
              if (mounted) {
                setState(() {
                  _messageIds.add(messageId);
                  _messages.add(ChatMessage(
                    id: messageId,
                    text: messageText,
                    senderId: senderId,
                    senderName: senderName,
                    isSent: isSent,
                    timestamp: timestamp,
                    attachmentUrl: data['attachment_url']?.toString(),
                    attachmentName: data['attachment_name']?.toString(),
                    repliedToId: data['replied_to_id']?.toString(),
                    isRead: false,
                  ));
                  _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
                });
                _scrollToBottom();
                
                 // Mark as read immediately since we are in the chat
                if (isGroup) {
                   api.ApiService.markGroupRead(widget.contact.id);
                } else {
                   api.ApiService.markConversationRead(widget.contact.id);
                }
              }
            }
          }
        } catch (e) {
          debugPrint('WS error: $e');
        }
      });
    } catch (e) {
      debugPrint('Error initializing realtime chat: $e');
    }
  }

  void _onReply(ChatMessage message) {
    setState(() {
      _replyingTo = message;
    });
    // Focus text field handled by UI update
  }

  void _onDelete(ChatMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message?'),
        content: const Text('This will remove the message for everyone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _softDeleteMessage(message);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _softDeleteMessage(ChatMessage message) async {
    // Optimistic update
    setState(() {
      _messages.removeWhere((m) => m.id == message.id);
    });

    final success = await api.ApiService.deleteMessage(message.id);
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete message')),
      );
      _loadChatHistory(); // Reload to restore state
    }
  }

  void _showMessageOptions(ChatMessage message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(context);
                _onReply(message);
              },
            ),
            if (message.isSent) // Only delete own messages check
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _onDelete(message);
                },
              ),
          ],
        ),
      ),
    );
  }


  Future<void> _downloadAttachment(ChatMessage message) async {
    if (message.attachmentUrl == null || message.attachmentUrl!.isEmpty) return;
    
    final url = message.attachmentUrl!;
    final fileName = message.attachmentName ?? url.split('/').last;

    if (!url.startsWith('http')) {
       // Local file
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('File is local'),
        duration: Duration(seconds: 1),
      ));
      return;
    }
    
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
         // Desktop download
         final downloadDir = await getDownloadsDirectory();
         if (downloadDir != null) {
           final savePath = '${downloadDir.path}\\$fileName';
           // Check if exists
           if (File(savePath).existsSync()) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('File exists: $savePath')));
              await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication); 
             return; 
           }
           
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloading...')));
           await Dio().download(url, savePath);
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to $savePath')));
         } else {
           await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
         }
      } else {
        // Mobile Save
        if (['.jpg', '.jpeg', '.png'].any((ext) => url.toLowerCase().endsWith(ext))) {
           var response = await Dio().get(url, options: Options(responseType: ResponseType.bytes));
           final result = await ImageGallerySaver.saveImage(
             Uint8List.fromList(response.data),
             quality: 100, 
             name: fileName
           );
           if (result['isSuccess']) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image saved to Gallery')));
           }
        } else {
           if (await canLaunchUrl(Uri.parse(url))) {
             await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
           }
        }
      }
    } catch (e) {
      debugPrint('Download error: $e');
       try {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } catch (e2) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Download failed: $e')));
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickAttachment() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final ImagePicker picker = ImagePicker();
                  final List<XFile> images = await picker.pickMultiImage();
                  if (images.isNotEmpty) {
                    setState(() {
                      for (var image in images) {
                        _selectedFiles.add(File(image.path));
                        _selectedFileNames.add(image.name);
                      }
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: const Text('Choose Document'),
                onTap: () async {
                  Navigator.pop(context);
                  FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);
                  if (result != null) {
                    setState(() {
                      for (var file in result.files) {
                        if (file.path != null) {
                          _selectedFiles.add(File(file.path!));
                          _selectedFileNames.add(file.name);
                        }
                      }
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      // Show WhatsApp-like preview dialog
      if (!mounted) return;
      
      final bool? shouldSend = await showDialog<bool>(
        context: context,
        builder: (context) => Dialog.fullscreen(
          child: Container(
            color: Colors.black,
            child: Stack(
              children: [
                Center(
                  child: kIsWeb ? Image.network(image.path) : Image.file(File(image.path)),
                ),
                Positioned(
                  top: 40,
                  left: 20,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ),
                Positioned(
                  bottom: 30,
                  right: 20,
                  child: FloatingActionButton(
                    backgroundColor: const Color(0xFF075E54), // WhatsApp color
                    child: const Icon(Icons.send, color: Colors.white),
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      if (shouldSend == true) {
        setState(() {
          _selectedFiles.add(File(image.path));
          _selectedFileNames.add(image.name);
        });
        // Optionally send immediately if it was from camera preview
        _sendMessage();
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && _selectedFiles.isEmpty) return;
    
    final List<File> filesToSend = List.from(_selectedFiles);
    final List<String> fileNamesToSend = List.from(_selectedFileNames);
    final replyId = _replyingTo?.id;
    
    // Clear state immediately
    _messageController.clear();
    setState(() {
      _selectedFiles.clear();
      _selectedFileNames.clear();
      _replyingTo = null;
    });

    // 1. Send text message if no files, or send it separately first if preferred.
    // To match WhatsApp "caption" feel, we'll send the text message first if it exists,
    // or attach it to the first file. Let's send it first if it exists and we have many files.
    if (text.isNotEmpty && filesToSend.isEmpty) {
      await _sendSingleMessage(text: text, replyId: replyId);
    } else if (filesToSend.isNotEmpty) {
      // Send files. If there's text, we can send it with the first file as a "caption"
      for (int i = 0; i < filesToSend.length; i++) {
        final file = filesToSend[i];
        final fileName = fileNamesToSend[i];
        final caption = (i == 0 && text.isNotEmpty) ? text : null;
        
        await _sendSingleMessage(
          text: caption,
          file: file,
          fileName: fileName,
          replyId: i == 0 ? replyId : null, // Only apply reply to the first message/file
        );
      }
    }
  }

  Future<void> _sendSingleMessage({
    String? text,
    File? file,
    String? fileName,
    String? replyId,
  }) async {
    final messageText = text ?? (file != null ? '[Attachment]' : '');
    if (messageText.isEmpty && file == null) return;

    // Optimistically add message
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}_${messageText.hashCode}';
    final tempTimestamp = DateTime.now().toUtc().toIso8601String();
    final localFilePath = file?.path;
    
    // Read file bytes for web platform
    List<int>? fileBytes;
    if (file != null && kIsWeb) {
      try {
        fileBytes = await file.readAsBytes();
      } catch (e) {
        debugPrint('Error reading file bytes: $e');
      }
    }
    
    setState(() {
      _messageIds.add(tempId);
      _messages.add(ChatMessage(
        id: tempId,
        text: messageText,
        senderId: widget.teacherUserId,
        senderName: widget.teacherName, // Own name
        isSent: true,
        timestamp: tempTimestamp,
        attachmentUrl: localFilePath,
        attachmentName: fileName,
        repliedToId: replyId,
      ));
      if (widget.onMessageSent != null) widget.onMessageSent!();
    });
    
    _scrollToBottom();
    
    try {
      String? groupId;
      String? otherUserId;
      if (widget.contact.type == ContactType.group) {
        groupId = widget.contact.id;
      } else {
        otherUserId = widget.contact.id;
      }

      final response = await api.ApiService.sendMessageWithAttachment(
        recipient: widget.contact.username,
        messageText: text,
        filePath: kIsWeb ? null : localFilePath,
        fileBytes: fileBytes,
        fileName: fileName,
        messageType: localFilePath != null ? 
            (localFilePath.toLowerCase().endsWith('.jpg') || 
             localFilePath.toLowerCase().endsWith('.jpeg') || 
             localFilePath.toLowerCase().endsWith('.png') ? 'image' : 'file') : 'text',
        groupId: groupId,
        otherUserId: otherUserId,
        repliedTo: replyId,
      );
      
      if (response != null && mounted) {
        final realId = response['message_id'].toString();
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == tempId);
          if (idx != -1) {
            _messages[idx] = ChatMessage(
              id: realId,
              text: response['message_text'] ?? messageText,
              senderId: widget.teacherUserId,
              senderName: widget.teacherName,
              isSent: true,
              timestamp: response['created_at'] ?? tempTimestamp,
              attachmentUrl: response['attachment_url'] ?? localFilePath,
              attachmentName: response['attachment_name'] ?? fileName,
              repliedToId: replyId,
            );
            _messageIds.remove(tempId);
            _messageIds.add(realId);
          }
        });
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message')),
        );
      }
    }
  }


  String _formatMessageTime(String timestamp) {
    if (timestamp.isEmpty) return '';
    try {
      String timeToParse = timestamp;
      
      final dateTime = DateTime.parse(timeToParse).toLocal();
      return DateFormat('h:mm a').format(dateTime);
    } catch (e) {
      return '';
    }
  }

  String _formatTime(String timestamp) {
    if (timestamp.isEmpty) return '';
    try {
      String timeToParse = timestamp;
      
      
      final dateTime = DateTime.parse(timeToParse).toLocal();
      final now = DateTime.now();
      
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final msgDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
      
      if (msgDate == today) {
        return 'Today';
      } else if (msgDate == yesterday) {
        return 'Yesterday';
      } else {
        return DateFormat('MMMM d, yyyy').format(dateTime);
      }
    } catch (e) {
      return timestamp;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF667eea),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            // Profile picture
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              child: Text(
                widget.contact.avatar,
                style: const TextStyle(
                  color: Color(0xFF667eea),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.contact.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.contact.type == ContactType.student
                        ? (widget.contact.className != null && widget.contact.className!.isNotEmpty)
                            ? '${widget.contact.className} ${widget.contact.grade ?? ''}'.trim()
                            : 'Student'
                        : (widget.contact.subject != null && widget.contact.subject!.isNotEmpty)
                            ? 'Teacher: ${widget.contact.subject}'
                            : 'Teacher',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Three dots menu
            if (widget.contact.type == ContactType.group)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  if (value == 'info') {
                    showDialog(
                      context: context,
                      builder: (context) => GroupInfoDialog(
                        groupId: widget.contact.id,
                        groupName: widget.contact.name,
                        onNameUpdated: (newName) {
                          // Update UI via parent re-fetch or assume name update
                          // Since contact names are passed down, we might need to rely on next load
                        },
                      ),
                    );
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'info',
                    child: Text('Group Info'),
                  ),
                ],
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: (_isLoadingHistory && _messages.isEmpty)
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _messages.isEmpty
                    ? Container(
                        color: Colors.grey[100],
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No messages yet',
                                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start the conversation!',
                                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[100],
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            final bool showDateHeader = index == 0 || !_isSameDay(_messages[index - 1].timestamp, message.timestamp);
                            
                            if (showDateHeader) {
                              return Column(
                                children: [
                                  _buildDateSeparator(message.timestamp),
                                  _buildMessageBubble(message),
                                ],
                              );
                            }
                            return _buildMessageBubble(message);
                          },
                        ),
                      ),
          ),
          // Input area
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_replyingTo != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border(left: BorderSide(color: Color(0xFF667eea), width: 4)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Replying to ${_replyingTo!.senderId == widget.teacherUserId ? "You" : "Sender"}',
                                style: TextStyle(color: Color(0xFF667eea), fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _replyingTo!.text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => setState(() => _replyingTo = null),
                        ),
                      ],
                    ),
                  ),
                if (_selectedFileNames.isNotEmpty)
                  Container(
                    height: 50,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedFileNames.length,
                      itemBuilder: (context, index) {
                        final name = _selectedFileNames[index];
                        final isImage = name.toLowerCase().endsWith('.jpg') || 
                                        name.toLowerCase().endsWith('.jpeg') || 
                                        name.toLowerCase().endsWith('.png');
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(isImage ? Icons.image : Icons.attach_file, 
                                   size: 16, color: const Color(0xFF667eea)),
                              const SizedBox(width: 4),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 120),
                                child: Text(
                                  name,
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedFiles.removeAt(index);
                                    _selectedFileNames.removeAt(index);
                                  });
                                },
                                child: const Icon(Icons.close, size: 16, color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                Row(
                  children: [
                    // Attachment button
                    IconButton(
                      icon: const Icon(Icons.attach_file, color: Color(0xFF667eea)),
                      onPressed: _pickAttachment,
                      tooltip: 'Attach file',
                    ),
                    // Camera button
                    IconButton(
                      icon: const Icon(Icons.camera_alt, color: Color(0xFF667eea)),
                      onPressed: _openCamera,
                      tooltip: 'Camera',
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: _selectedFileNames.isNotEmpty ? 'Add a caption...' : 'Type a message...',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            hintStyle: TextStyle(color: Colors.grey[500]),
                          ),
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Send button
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF667eea),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
          ],
        ),
      ),
    ],
  ),
);
}

  bool _isSameDay(String ts1, String ts2) {
    try {
      String timeToParse1 = ts1;
      
      String timeToParse2 = ts2;
      
      
      final d1 = DateTime.parse(timeToParse1).toLocal();
      final d2 = DateTime.parse(timeToParse2).toLocal();
      return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
    } catch (_) {
      return false;
    }
  }

  Widget _buildDateSeparator(String timestamp) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            _formatTime(timestamp),
            style: TextStyle(
              color: Colors.blue[800],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Color _getSenderColor(String senderId) {
    final colors = [
      Colors.orange, Colors.purple, Colors.pink, Colors.teal, 
      Colors.indigo, Colors.blue, Colors.brown, Colors.red,
      Colors.cyan, Colors.deepOrange, Colors.lime[800]!
    ];
    final hash = senderId.hashCode;
    return colors[hash.abs() % colors.length];
  }

  String _getAvatarInitials(String name) {
    if (name.isEmpty) return "?";
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return "?";
    
    String initials = parts[0][0].toUpperCase();
    if (parts.length > 1) {
      initials += parts.last[0].toUpperCase();
    }
    return initials;
  }


  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: message.isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Profile picture for received messages (left side)
          if (!message.isSent) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: widget.contact.type == ContactType.group 
                  ? _getSenderColor(message.senderId) 
                  : Colors.grey[300],
              child: Text(
                widget.contact.type == ContactType.group 
                    ? _getAvatarInitials(message.senderName ?? "?")
                    : widget.contact.avatar,
                style: TextStyle(
                  color: widget.contact.type == ContactType.group ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Message bubble
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(message),
              child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.65,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: message.isSent 
                    ? const Color(0xFFD9FDD3) // Light green for sender
                    : Colors.white,
                borderRadius: message.isSent
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(4),
                      )
                    : const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                        bottomLeft: Radius.circular(4),
                        bottomRight: Radius.circular(18),
                      ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sender Name for Group Messages
                  if (widget.contact.type == ContactType.group && !message.isSent && message.senderName != null) ...[
                    Text(
                      message.senderName!,
                      style: TextStyle(
                        color: _getSenderColor(message.senderId),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (message.attachmentUrl != null && message.attachmentUrl!.isNotEmpty) ...[
                    if (message.attachmentUrl!.toLowerCase().endsWith('.jpg') ||
                        message.attachmentUrl!.toLowerCase().endsWith('.png') ||
                        message.attachmentUrl!.toLowerCase().endsWith('.jpeg'))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: () => _downloadAttachment(message),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: message.attachmentUrl!.startsWith('http')
                                ? Image.network(
                                    message.attachmentUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      debugPrint('Image load error: $error');
                                      return Container(
                                        height: 100,
                                        width: 100,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.broken_image, size: 50, color: Colors.red),
                                      );
                                    },
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        height: 150,
                                        width: 150,
                                        alignment: Alignment.center,
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                              : null,
                                        ),
                                      );
                                    },
                                  )
                                : Image.file(
                                    File(message.attachmentUrl!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.broken_image, size: 50),
                                  ),
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: () => _downloadAttachment(message),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.insert_drive_file, size: 20),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    message.attachmentUrl!.split('/').last,
                                    style: const TextStyle(fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.download, size: 16, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                  if (message.text.isNotEmpty)
                    Text(
                      message.text,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatMessageTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: message.isSent ? Colors.black54 : Colors.grey[600],
                        ),
                      ),
                      if (message.isSent) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 14,
                          color: message.isRead ? const Color(0xFF34B7F1) : Colors.black54,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          ),
        ],
      ),
    );
  }
}
