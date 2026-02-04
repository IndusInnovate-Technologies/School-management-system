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
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

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
  ChatMessage? _replyingTo; // For reply functionality
  ChatMessage? _editingMessage; // For edit functionality
  
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
              attachmentUrl: msg['attachment_url']?.toString(),
              attachmentName: msg['attachment_name']?.toString(),
              repliedToId: msg['replied_to_id']?.toString() ?? msg['replied_to']?.toString(),
              repliedToSenderName: msg['replied_to_sender_name']?.toString(), // Parse updated field
              repliedToText: msg['replied_to_text']?.toString(),             // Parse updated field
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
                        attachmentUrl: data['attachment_url']?.toString(),
                        attachmentName: data['attachment_name']?.toString(),
                        repliedToId: data['replied_to_id']?.toString(),
                        repliedToSenderName: data['replied_to_sender_name']?.toString(),
                        repliedToText: data['replied_to_text']?.toString(),
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
                          attachmentUrl: data['attachment_url']?.toString(),
                          attachmentName: data['attachment_name']?.toString(),
                          repliedToId: data['replied_to_id']?.toString(),
                          repliedToSenderName: data['replied_to_sender_name']?.toString(),
                          repliedToText: data['replied_to_text']?.toString(),
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
                        attachmentUrl: data['attachment_url']?.toString(),
                        attachmentName: data['attachment_name']?.toString(),
                        repliedToId: data['replied_to_id']?.toString(),
                        repliedToSenderName: data['replied_to_sender_name']?.toString(),
                        repliedToText: data['replied_to_text']?.toString(),
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
            } else if (messageType == 'message_edited') {
              final messageId = data['message_id']?.toString() ?? '';
              final newText = data['message']?.toString() ?? '';
              
              if (messageId.isNotEmpty) {
                setState(() {
                  final messages = _messages[_selectedContactId!] ?? [];
                  final index = messages.indexWhere((msg) => msg.id == messageId);
                  if (index != -1) {
                    final oldMsg = messages[index];
                    messages[index] = ChatMessage(
                      id: oldMsg.id,
                      text: newText,
                      senderId: oldMsg.senderId,
                      senderName: oldMsg.senderName,
                      isSent: oldMsg.isSent,
                      timestamp: oldMsg.timestamp,
                      isRead: oldMsg.isRead,
                      attachmentUrl: oldMsg.attachmentUrl,
                      attachmentName: oldMsg.attachmentName,
                      repliedToId: oldMsg.repliedToId,
                      repliedToSenderName: oldMsg.repliedToSenderName,
                      repliedToText: oldMsg.repliedToText,
                      isEdited: true,
                      isDeleted: oldMsg.isDeleted,
                    );
                  }
                });
              }
            } else if (messageType == 'message_deleted') {
              final messageId = data['message_id']?.toString() ?? '';
              if (messageId.isNotEmpty) {
                setState(() {
                  final messages = _messages[_selectedContactId!] ?? [];
                  final index = messages.indexWhere((msg) => msg.id == messageId);
                  if (index != -1) {
                    final oldMsg = messages[index];
                    messages[index] = ChatMessage(
                      id: oldMsg.id,
                      text: "This message was deleted",
                      senderId: oldMsg.senderId,
                      senderName: oldMsg.senderName,
                      isSent: oldMsg.isSent,
                      timestamp: oldMsg.timestamp,
                      isRead: oldMsg.isRead,
                      attachmentUrl: null,
                      attachmentName: null,
                      repliedToId: oldMsg.repliedToId,
                      repliedToSenderName: oldMsg.repliedToSenderName,
                      repliedToText: oldMsg.repliedToText,
                      isEdited: oldMsg.isEdited,
                      isDeleted: true,
                    );
                  }
                });
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

  // Reply to a message
  void _onReply(ChatMessage message) {
    setState(() {
      _replyingTo = message;
      _editingMessage = null; // Clear editing mode when replying
    });
  }

  // Edit a message
  void _onEdit(ChatMessage message) {
    setState(() {
      _editingMessage = message;
      _messageController.text = message.text;
      _replyingTo = null; // Clear reply mode when editing
    });
  }

  void _onDelete(ChatMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
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
      if (_messages[_selectedContactId] != null) {
        final index = _messages[_selectedContactId]!.indexWhere((m) => m.id == message.id);
        if (index != -1) {
          final oldMsg = _messages[_selectedContactId]![index];
          _messages[_selectedContactId]![index] = ChatMessage(
            id: oldMsg.id,
            text: "This message was deleted",
            senderId: oldMsg.senderId,
            senderName: oldMsg.senderName,
            isSent: oldMsg.isSent,
            timestamp: oldMsg.timestamp,
            isRead: oldMsg.isRead,
            attachmentUrl: null,
            attachmentName: null,
            repliedToId: oldMsg.repliedToId,
            repliedToSenderName: oldMsg.repliedToSenderName,
            repliedToText: oldMsg.repliedToText,
            isEdited: oldMsg.isEdited,
            isDeleted: true,
          );
        }
      }
    });

    final success = await api.ApiService.deleteMessage(message.id);
    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete message')),
        );
        _loadData(); // Reload to restore state
      }
    }
  }


  // Build editing preview widget
  Widget _buildEditingPreview() {
    if (_editingMessage == null) return const SizedBox();
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: const Border(
          left: BorderSide(color: Colors.orange, width: 4)
        )
      ),
      child: Row(
        children: [
          const Icon(Icons.edit, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Edit Message',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 13
                  )
                ),
                Text(
                  _editingMessage!.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12
                  )
                ),
              ]
            )
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () => setState(() {
              _editingMessage = null;
              _messageController.clear();
            })
          ),
        ],
      ),
    );
  }

  // Build reply preview widget (actual sender name + quoted text)
  Widget _buildReplyPreview() {
    final contact = _selectedContactId != null ? _contacts[_selectedContactId] : null;
    final replyToName = _replyingTo!.senderId == _currentTeacherUserId
        ? 'You'
        : (_replyingTo!.senderName ?? contact?.name ?? 'Unknown');
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: const Border(
          left: BorderSide(color: Color(0xFF667eea), width: 4)
        )
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to $replyToName',
                  style: const TextStyle(
                    color: Color(0xFF667eea),
                    fontWeight: FontWeight.bold,
                    fontSize: 13
                  )
                ),
                Text(
                  _replyingTo!.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12
                  )
                ),
              ]
            )
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () => setState(() => _replyingTo = null)
          ),
        ],
      ),
    );
  }

  // Show message options menu (Reply, Edit, Delete)
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
            if (message.isSent) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  _onEdit(message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _onDelete(message);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCreateGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateGroupDialog(
        contacts: _contacts.values.where((c) => c.type == ContactType.student || c.type == ContactType.teacher).toList(),
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
                          Flexible(
                            child: FilterChip(
                              label: const Text('All', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
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
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: FilterChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Teachers',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (_getTeacherUnreadCount() > 0) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${_getTeacherUnreadCount()}',
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
                              selected: _showTeachersOnly,
                              onSelected: (v) => setState(() {
                                _showTeachersOnly = v;
                                if (v) _showGroupsOnly = false;
                              }),
                              selectedColor: const Color(0xFF667eea),
                              checkmarkColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: FilterChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Groups',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (_getGroupUnreadCount() > 0) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${_getGroupUnreadCount()}',
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
                              selected: _showGroupsOnly,
                              onSelected: (v) => setState(() {
                                _showGroupsOnly = v;
                                if (v) _showTeachersOnly = false;
                              }),
                              selectedColor: const Color(0xFF667eea),
                              checkmarkColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
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
                              ? (contact.type == ContactType.group
                                  ? (lastMessage.senderId == _currentTeacherUserId ? 'You: ' : '${lastMessage.senderName ?? 'Member'}: ') + lastMessage.text
                                  : lastMessage.text)
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_editingMessage != null)
                _buildEditingPreview(),
              if (_replyingTo != null)
                _buildReplyPreview(),
              Row(
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
    );
  }


  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    // Handle editing mode
    if (_editingMessage != null) {
      await _editMessageText(_editingMessage!, text);
      _messageController.clear();
      setState(() {
        _editingMessage = null;
      });
      return;
    }
    
    final replyId = _replyingTo?.id;
    
    // Clear state immediately
    _messageController.clear();
    setState(() {
      _replyingTo = null;
    });

    try {
      if (text.isNotEmpty) {
        await _sendSingleMessageInline(text: text, replyId: replyId);
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  Future<void> _sendSingleMessageInline({
    String? text,
    String? replyId,
  }) async {
    final contact = _contacts[_selectedContactId];
    if (contact == null) return;

    String? groupId;
    String? otherUserId;
    if (contact.type == ContactType.group) {
      groupId = contact.id;
    } else {
      otherUserId = contact.id;
    }

    final response = await api.ApiService.sendMessageWithAttachment(
      recipient: contact.type == ContactType.group ? '' : contact.username,
      messageText: text,
      filePath: null,
      fileBytes: null,
      fileName: null,
      messageType: 'text',
      groupId: groupId,
      otherUserId: otherUserId,
      repliedTo: replyId,
    );
    
    if (response != null) {
      _loadData(); // Refresh to show new message
    }
  }

  // Edit message text
  Future<void> _editMessageText(ChatMessage message, String newText) async {
    if (newText.trim().isEmpty) return;
    
    try {
      // Update UI optimistically
      setState(() {
        final contactId = _selectedContactId;
        final list = _messages[contactId];
        if (list != null) {
          final idx = list.indexWhere((m) => m.id == message.id);
          if (idx != -1) {
            list[idx] = ChatMessage(
              id: message.id,
              text: newText,
              senderId: message.senderId,
              senderName: message.senderName,
              isSent: message.isSent,
              timestamp: message.timestamp,
              attachmentUrl: message.attachmentUrl,
              attachmentName: message.attachmentName,
              repliedToId: message.repliedToId,
              isRead: message.isRead,
            );
          }
        }
      });
      
      final success = await api.ApiService.editMessage(message.id, newText);
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Message edited')),
          );
        }
      } else {
        throw Exception('Failed to edit');
      }
    } catch (e) {
      debugPrint('Error editing message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to edit message')),
        );
      }
    }
  }

  Color _getSenderColorForList(String senderId) {
    const colors = [
      Color(0xFFE53935), Color(0xFFD81B60), Color(0xFF8E24AA), Color(0xFF5E35B1),
      Color(0xFF3949AB), Color(0xFF1E88E5), Color(0xFF43A047), Color(0xFFFB8C00),
    ];
    final hash = senderId.hashCode;
    return colors[hash.abs() % colors.length];
  }

  String _getSenderNameForMessage(ChatMessage message, ChatContact? contact) {
    // First check if sender name is already set and valid
    if (message.senderName != null && message.senderName!.isNotEmpty && message.senderName != 'Unknown') {
      return message.senderName!;
    }
    
    // Check if it's the current user
    if (message.senderId == _currentTeacherUserId) {
      return _currentTeacherName ?? 'You';
    }
    
    // For non-group chats, use contact name
    if (contact != null && contact.type != ContactType.group && message.senderId == contact.id) {
      return contact.name;
    }
    
    // For group chats, try to extract from senderId or use a fallback
    if (contact != null && contact.type == ContactType.group && message.senderId.isNotEmpty) {
      // Try to get from any existing messages from the same sender
      final conversationMessages = _messages[_selectedContactId] ?? [];
      final existingMessage = conversationMessages.firstWhere(
        (m) => m.senderId == message.senderId && m.senderName != null && m.senderName!.isNotEmpty && m.senderName != 'Unknown',
        orElse: () => ChatMessage(
          id: '',
          text: '',
          senderId: '',
          isSent: false,
          timestamp: '',
        ),
      );
      if (existingMessage.senderName != null && existingMessage.senderName!.isNotEmpty) {
        return existingMessage.senderName!;
      }
    }
    
    // Last resort: return senderId if available and not a UUID, otherwise "Unknown"
    if (message.senderId.isNotEmpty) {
      // If senderId looks like a UUID, don't display it - return "Unknown" instead
      if (message.senderId.contains('-') && message.senderId.length > 20) {
        return "Unknown";
      }
      return message.senderId;
    }
    return "Unknown";
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final contact = _contacts[_selectedContactId];
    final bool isGroup = contact?.type == ContactType.group;
    final Color senderColor = _getSenderColorForList(message.senderId);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: Key(message.id),
        direction: DismissDirection.startToEnd,
        confirmDismiss: (direction) async {
          // Trigger reply when swiped right
          _onReply(message);
          return false; // Don't actually dismiss the message
        },
        background: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 20),
          child: const Icon(
            Icons.reply,
            color: Color(0xFF667eea),
            size: 28,
          ),
        ),
        child: Row(
        mainAxisAlignment: message.isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Profile picture for received messages (left side)
          if (!message.isSent && contact != null) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: isGroup ? senderColor.withOpacity(0.2) : Colors.grey[300],
              child: Text(
                isGroup ? (message.senderName?.substring(0, 1).toUpperCase() ?? '?') : contact.avatar,
                style: TextStyle(
                  color: isGroup ? senderColor : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
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
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                // Same as student chat: sent = light green, received = white
                color: message.isSent
                    ? const Color(0xFFD9FDD3)
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
                  if (isGroup && !message.isSent) ...[
                    Text(
                      _getSenderNameForMessage(message, contact),
                      style: TextStyle(
                        color: senderColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  // Reply block: same as student chat (blue bar, blue sender name, quoted text)
                  if (message.repliedToId != null || (message.repliedToSenderName != null && message.repliedToSenderName!.isNotEmpty) || (message.repliedToText != null && message.repliedToText!.isNotEmpty)) ...[
                    Builder(
                      builder: (context) {
                        String replySenderName = message.repliedToSenderName ?? "Unknown";
                        String replyText = message.repliedToText ?? "";
                        if (replySenderName == "Unknown" || replyText.isEmpty) {
                           final conversationMessages = _messages[_selectedContactId] ?? [];
                           final repliedMessage = conversationMessages.firstWhere(
                             (m) => m.id == message.repliedToId,
                             orElse: () => ChatMessage(
                               id: 'unknown',
                               text: 'Message not found',
                               senderId: 'unknown',
                               isSent: false,
                               timestamp: '',
                             ),
                           );
                           if (replySenderName == "Unknown") {
                             if (repliedMessage.senderId == _currentTeacherUserId) {
                               replySenderName = "You";
                             } else if (repliedMessage.senderName != null) {
                               replySenderName = repliedMessage.senderName!;
                             } else if (contact != null && repliedMessage.senderId == contact.id) {
                                replySenderName = contact.name;
                             }
                           }
                           if (replyText.isEmpty) {
                              replyText = repliedMessage.text.isNotEmpty
                                ? repliedMessage.text
                                : (repliedMessage.attachmentUrl != null ? '📷 Photo' : '');
                           }
                        }
                        return Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border(
                              left: BorderSide(
                                color: message.isSent ? const Color(0xFF667eea) : const Color(0xFF667eea),
                                width: 4,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                replySenderName,
                                style: const TextStyle(
                                  color: Color(0xFF667eea),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                replyText,
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      }
                    ),
                  ],
                  // Attachment
                  if (message.attachmentUrl != null) ...[
                    GestureDetector(
                      onTap: () => _showImageViewer(message),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: message.isSent ? Colors.black.withOpacity(0.08) : Colors.grey[200],
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
                  // Message Text (same deleted UI for sender & receiver: 🚫 + grey italic)
                  Text(
                    message.isDeleted ? '🚫 This message was deleted' : message.text,
                    style: TextStyle(
                      color: message.isDeleted ? Colors.grey[500] : Colors.black87,
                      fontSize: 15,
                      height: 1.4,
                      fontStyle: message.isDeleted ? FontStyle.italic : FontStyle.normal,
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
                          color: Colors.grey[600],
                        ),
                      ),
                      if (message.isSent) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 14,
                          color: message.isRead ? const Color(0xFF34B7F1) : Colors.grey,
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
      ), // Close Dismissible
    );
  }

  void _showImageViewer(ChatMessage message) {
    if (message.attachmentUrl == null || message.attachmentUrl!.isEmpty) return;
    
    final isImage = message.attachmentUrl!.toLowerCase().endsWith('.jpg') ||
                    message.attachmentUrl!.toLowerCase().endsWith('.jpeg') ||
                    message.attachmentUrl!.toLowerCase().endsWith('.png') ||
                    message.attachmentUrl!.toLowerCase().endsWith('.webp') ||
                    message.attachmentUrl!.toLowerCase().endsWith('.gif');

    if (!isImage) {
      _downloadAttachment(message);
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(message.attachmentName ?? 'Image', style: const TextStyle(color: Colors.white)),
            actions: [
              IconButton(
                icon: const Icon(Icons.download, color: Colors.white),
                onPressed: () => _downloadAttachment(message),
              ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: message.attachmentUrl!.startsWith('http')
                  ? Image.network(
                      message.attachmentUrl!,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator(color: Colors.white));
                      },
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 100, color: Colors.white),
                    )
                  : Image.file(File(message.attachmentUrl!), fit: BoxFit.contain),
            ),
          ),
        ),
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
  final String? repliedToId;
  final String? repliedToSenderName; // New field
  final String? repliedToText;       // New field
  final bool isEdited;
  final bool isDeleted;
  final String? messageType; // Added for system messages

  ChatMessage({
    required this.id,
    required this.text,
    required this.senderId,
    this.senderName,
    this.messageType,
    required this.isSent,
    required this.timestamp,
    this.isRead = false,
    this.attachmentUrl,
    this.attachmentName,
    this.repliedToId,
    this.repliedToSenderName,
    this.repliedToText,
    this.isEdited = false,
    this.isDeleted = false,
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
            height: constraints.maxHeight * 0.9, // Increased height to 90%
            constraints: const BoxConstraints(maxHeight: 800), // Increased max height
            padding: const EdgeInsets.all(20), // Slightly reduced padding
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
                    hintText: 'e.g., Math Club',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.group),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                  enabled: !_isCreating,
                ),
                const SizedBox(height: 12),
                
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                  enabled: !_isCreating,
                ),
                const SizedBox(height: 12),
                
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
                              
                              String subtitle = '';
                              if (contact.type == ContactType.teacher) {
                                String subName = contact.subject ?? '';
                                if (subName.toLowerCase() == 'null' || subName.toLowerCase() == 'none') subName = '';
                                subtitle = subName.isNotEmpty ? '$subName Teacher' : 'Teacher';
                              } else {
                                String classStr = contact.className ?? contact.grade ?? '';
                                if (classStr.toLowerCase() == 'null' || classStr.toLowerCase() == 'none') classStr = '';
                                
                                String sectionStr = contact.section ?? '';
                                if (sectionStr.toLowerCase() == 'null' || sectionStr.toLowerCase() == 'none') sectionStr = '';
                                
                                if (classStr.isNotEmpty && sectionStr.isNotEmpty) {
                                  subtitle = '$classStr & $sectionStr';
                                } else if (classStr.isNotEmpty) {
                                  subtitle = classStr;
                                } else if (sectionStr.isNotEmpty) {
                                  subtitle = sectionStr;
                                } else {
                                  subtitle = 'Student';
                                }
                              }
                              
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
                                  subtitle,
                                  style: TextStyle(color: contact.type == ContactType.teacher ? Colors.green[700] : Colors.grey[600]),
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
  final String currentUserId;
  final bool isReadOnly;

  const GroupInfoDialog({
    Key? key,
    required this.groupId,
    required this.groupName,
    required this.onNameUpdated,
    required this.currentUserId,
    this.isReadOnly = false,
  }) : super(key: key);

  @override
  State<GroupInfoDialog> createState() => _GroupInfoDialogState();
}

class _GroupInfoDialogState extends State<GroupInfoDialog> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _members = [];
  String _currentName = '';
  String? _createdBy;
  bool _isCreator = false;

  @override
  void initState() {
    super.initState();
    _currentName = widget.groupName;
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    setState(() => _isLoading = true);
    try {
      final data = await api.ApiService.getGroupDetails(widget.groupId);
      if (data != null) {
        setState(() {
          final membersList = data['members'] as List? ?? [];
          _members = List<Map<String, dynamic>>.from(membersList);
          final nameFromApi = data['group_name']?.toString();
          if (nameFromApi != null && nameFromApi.isNotEmpty) _currentName = nameFromApi;
          _createdBy = data['created_by']?.toString();
          _isCreator = data['is_creator'] == true || (data['created_by_id']?.toString() == widget.currentUserId);
        });
        final latestName = data['group_name']?.toString() ?? _currentName;
        if (latestName.isNotEmpty) widget.onNameUpdated(latestName);
      }
    } catch (e) {
      debugPrint('Error fetching group details: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addParticipants() async {
    final addable = await api.ApiService.getAddableGroupMembers(widget.groupId);
    if (!mounted) return;
    // Get current member IDs for checking
    final currentMemberIds = _members.map((m) => m['user_id'].toString()).toSet();
    final selected = await showDialog<List<String>>(
      context: context,
      builder: (ctx) => _AddMembersSheetTeacher(
        users: addable,
        currentMemberIds: currentMemberIds,
      ),
    );
    if (selected != null && selected.isNotEmpty) {
      final ok = await api.ApiService.addGroupMembers(widget.groupId, selected);
      if (ok && mounted) {
        _fetchMembers();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Members added')));
      }
    }
  }

  Future<void> _deleteGroup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: const Text('Are you sure you want to delete this group? This action cannot be undone and all messages will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final success = await api.ApiService.deleteGroup(widget.groupId);
      if (success && mounted) {
        Navigator.pop(context, 'deleted'); // Signal deletion to caller
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group deleted successfully')),
        );
      } else if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete group')),
        );
      }
    }
  }

  Future<void> _editGroupName() async {
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => EditGroupNameDialog(currentName: _currentName),
    );

    if (newName != null && newName.isNotEmpty && newName != _currentName) {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        final success = await api.ApiService.updateGroupName(widget.groupId, newName);
        
        // Close loading dialog
        if (mounted) {
          Navigator.of(context).pop();
        }

        if (success && mounted) {
          setState(() => _currentName = newName);
          widget.onNameUpdated(newName);
          
          // Show success popup
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 24),
                  SizedBox(width: 8),
                  Text('Success'),
                ],
              ),
              content: const Text('Group name updated successfully'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else if (mounted) {
          // Show error popup
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.error, color: Colors.red, size: 24),
                  SizedBox(width: 8),
                  Text('Error'),
                ],
              ),
              content: const Text('Failed to update group name'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        // Close loading dialog if still open
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        
        // Show error popup
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.error, color: Colors.red, size: 24),
                  SizedBox(width: 8),
                  Text('Error'),
                ],
              ),
              content: Text('Failed to update group name: $e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
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
        height: 640, // Fixed height
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Fixed header
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
            const SizedBox(height: 12),
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Group Name Header (creator can tap to edit; participants view only)
                    GestureDetector(
                      onTap: (_isCreator && !widget.isReadOnly) ? _editGroupName : null,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: const Color(0xFF667eea),
                              child: const Icon(Icons.group, color: Colors.white, size: 32),
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
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_members.length} participants',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (_isCreator && !widget.isReadOnly)
                                    Text(
                                      'Tap to edit group name',
                                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                    ),
                                ],
                              ),
                            ),
                            if (_isCreator && !widget.isReadOnly)
                              const Icon(Icons.edit, size: 20, color: Color(0xFF667eea)),
                          ],
                        ),
                      ),
                    ),
                    // Add participants (creator only; participants cannot add)
                    if (_isCreator && !widget.isReadOnly) ...[
                      const SizedBox(height: 12),
                      ListTile(
                        leading: const Icon(Icons.person_add, color: Color(0xFF667eea)),
                        title: const Text('Add participants'),
                        onTap: _addParticipants,
                      ),
                    ],
                    const SizedBox(height: 12),
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
                    _isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _members.length,
                            itemBuilder: (context, index) {
                              final member = _members[index];
                              // Build name
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
                              
                              if (name.isEmpty) {
                                final fullName = member['full_name'];
                                if (fullName != null && fullName.toString().toLowerCase() != 'null' && fullName.toString().toLowerCase() != 'none') {
                                  name = fullName.toString();
                                } else {
                                  name = member['username'] ?? 'Unknown';
                                }
                              }
                              
                              final role = member['role']?.toString().toLowerCase() ?? '';
                               final subject = member['subject']?.toString();

                                String sub = '';
                                Color? subColor;

                                // Teachers: show Subject in subtext
                                if (role.contains('teacher') || (subject != null && subject.toLowerCase() != 'null' && subject.isNotEmpty)) {
                                  String subName = subject ?? '';
                                  if (subName.toLowerCase() == 'null' || subName.toLowerCase() == 'none') subName = '';
                                  sub = subName.isNotEmpty ? subName : 'Teacher';
                                  subColor = Colors.green[700];
                                } else {
                                   // Students: show Class and Section in subtext
                                   String classStr = member['class_name']?.toString() ?? 
                                                     member['class_assigned']?.toString() ?? 
                                                     member['grade']?.toString() ?? '';
                                   if (classStr.toLowerCase() == 'null' || classStr.toLowerCase() == 'none') classStr = '';
                                   
                                   String sectionStr = member['section']?.toString() ?? '';
                                   if (sectionStr.toLowerCase() == 'null' || sectionStr.toLowerCase() == 'none') sectionStr = '';
                                   
                                   if (classStr.isNotEmpty && sectionStr.isNotEmpty) {
                                     sub = 'Class $classStr - $sectionStr';
                                   } else if (classStr.isNotEmpty) {
                                     sub = 'Class $classStr';
                                   } else if (sectionStr.isNotEmpty) {
                                     sub = sectionStr;
                                   } else {
                                     sub = 'Student';
                                   }
                                   subColor = Colors.blue[700];
                                }
                              
                              final userId = member['user_id'].toString();
                              
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.grey[200],
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                                    style: TextStyle(color: Colors.grey[800]),
                                  ),
                                ),
                                title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                                subtitle: sub.isNotEmpty 
                                  ? Text(sub, style: TextStyle(color: subColor, fontSize: 12))
                                  : null,
                                trailing: (!widget.isReadOnly && _isCreator && userId != widget.currentUserId)
                                    ? PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert, size: 20),
                                        onSelected: (value) {
                                          if (value == 'remove') {
                                            _removeMember(userId, name);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'remove',
                                            child: Text('Remove from Group', style: TextStyle(color: Colors.red, fontSize: 13)),
                                          ),
                                        ],
                                      )
                                    : null,
                              );



                            },
                          ),
                    if (!widget.isReadOnly && _isCreator) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _deleteGroup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Delete Group', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ],
                ),
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
      title: const Text('Edit group name'),
      content: TextField(
        controller: _nameController,
        decoration: const InputDecoration(
          labelText: 'Group name',
          hintText: 'Group name',
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _nameController.text.trim()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Add members sheet: students shown with Class & Section, teachers with Subject.
class _AddMembersSheetTeacher extends StatefulWidget {
  final List<dynamic> users;
  final Set<String> currentMemberIds;

  const _AddMembersSheetTeacher({
    required this.users,
    required this.currentMemberIds,
  });

  @override
  State<_AddMembersSheetTeacher> createState() => _AddMembersSheetTeacherState();
}

class _AddMembersSheetTeacherState extends State<_AddMembersSheetTeacher> {
  final Set<String> _selected = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _subtext(dynamic u) {
    final role = u['role']?.toString() ?? '';
    if (role == 'student_parent') {
      final cn = u['class_name']?.toString();
      final sec = u['section']?.toString();
      if (cn != null && cn.isNotEmpty) return 'Class $cn${sec != null && sec.isNotEmpty ? ' - $sec' : ''}';
    } else if (role == 'teacher') {
      final sub = u['subject']?.toString();
      if (sub != null && sub.isNotEmpty) return sub;
    }
    return '';
  }

  List<dynamic> get _filteredUsers {
    if (_searchQuery.isEmpty) return widget.users;
    return widget.users.where((u) {
      final name = (u['full_name']?.toString() ?? u['username'] ?? '').toLowerCase();
      final username = (u['username']?.toString() ?? '').toLowerCase();
      return name.contains(_searchQuery) || username.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _filteredUsers;
    
    return AlertDialog(
      title: const Text('Add participants'),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(height: 12),
            // Users list - fully scrollable
            Expanded(
              child: filteredUsers.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          _searchQuery.isEmpty 
                              ? 'No participants available'
                              : 'No results found',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredUsers.length,
                      itemBuilder: (ctx, i) {
                        final u = filteredUsers[i] as Map<String, dynamic>;
                        final uid = u['user_id']?.toString() ?? '';
                        final name = u['full_name']?.toString() ?? u['username'] ?? '?';
                        final sub = _subtext(u);
                        final isSelected = _selected.contains(uid);
                        final isAlreadyInGroup = widget.currentMemberIds.contains(uid);
                        
                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: isAlreadyInGroup ? null : (v) => setState(() {
                            if (v == true) _selected.add(uid); else _selected.remove(uid);
                          }),
                          title: Text(name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (sub.isNotEmpty)
                                Text(sub, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                              if (isAlreadyInGroup)
                                Text(
                                  'Already in group',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange[700],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                          enabled: !isAlreadyInGroup,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: _selected.isEmpty 
              ? null 
              : () => Navigator.pop(context, _selected.toList()),
          child: Text('Add (${_selected.length})'),
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
  ChatMessage? _replyingTo; // Track message being replied to
  ChatMessage? _editingMessage; // Track message being edited
  String? _displayGroupName; // Updated group name from Group Info

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
              repliedToSenderName: msg['replied_to_sender_name']?.toString(),
              repliedToText: msg['replied_to_text']?.toString(),
              messageType: msg['message_type']?.toString() ?? 'text',
            );
          }).toList().reversed.toList();

          // Merge history safely
          // 1. Identify existing messages to avoid duplicates
          final existingIds = _messages.map((m) => m.id).toSet();
          
          // 2. Match temp messages with history messages more precisely
          final tempMessages = _messages.where((m) => m.id.startsWith('temp_')).toList();
          for (final tempMsg in tempMessages) {
            final tempText = tempMsg.text;
            final tempReplyId = tempMsg.repliedToId;
            final tempTimestamp = tempMsg.timestamp;
            
            // Find matching message in history (same text, same reply context, and recent timestamp)
            final matchingHistory = history.firstWhere(
              (h) {
                if (!h.isSent) return false; // Only match sent messages
                if (h.text != tempText) return false;
                if (tempReplyId != null && h.repliedToId != tempReplyId) return false;
                // Check if timestamps are close (within 30 seconds)
                try {
                  final tempTime = DateTime.tryParse(tempTimestamp);
                  final hTime = DateTime.tryParse(h.timestamp);
                  if (tempTime != null && hTime != null) {
                    final diff = tempTime.difference(hTime).abs().inSeconds;
                    if (diff > 30) return false;
                  }
                } catch (e) {}
                return true;
              },
              orElse: () => ChatMessage(
                id: '',
                text: '',
                senderId: '',
                isSent: false,
                timestamp: '',
              ),
            );
            
            // If found, remove temp message (the real one from history will be added)
            if (matchingHistory.id.isNotEmpty) {
              _messages.removeWhere((m) => m.id == tempMsg.id);
              _messageIds.remove(tempMsg.id);
            }
          }
          
          // 3. Add new messages from history or update existing ones with reply metadata
          for (final msg in history) {
            if (existingIds.contains(msg.id)) {
              // Update existing message with reply metadata if it's missing
              final existingIdx = _messages.indexWhere((m) => m.id == msg.id);
              if (existingIdx != -1) {
                final existingMsg = _messages[existingIdx];
                // Preserve reply metadata from API if it exists and existing is missing
                if (msg.repliedToId != null && existingMsg.repliedToId == null) {
                  _messages[existingIdx] = ChatMessage(
                    id: existingMsg.id,
                    text: existingMsg.text,
                    senderId: existingMsg.senderId,
                    senderName: existingMsg.senderName,
                    isSent: existingMsg.isSent,
                    timestamp: existingMsg.timestamp,
                    isRead: existingMsg.isRead,
                    attachmentUrl: existingMsg.attachmentUrl,
                    attachmentName: existingMsg.attachmentName,
                    repliedToId: msg.repliedToId,
                    repliedToSenderName: msg.repliedToSenderName ?? existingMsg.repliedToSenderName,
                    repliedToText: msg.repliedToText ?? existingMsg.repliedToText,
                  );
                } else if (msg.repliedToSenderName != null && existingMsg.repliedToSenderName == null) {
                  _messages[existingIdx] = ChatMessage(
                    id: existingMsg.id,
                    text: existingMsg.text,
                    senderId: existingMsg.senderId,
                    senderName: existingMsg.senderName,
                    isSent: existingMsg.isSent,
                    timestamp: existingMsg.timestamp,
                    isRead: existingMsg.isRead,
                    attachmentUrl: existingMsg.attachmentUrl,
                    attachmentName: existingMsg.attachmentName,
                    repliedToId: existingMsg.repliedToId ?? msg.repliedToId,
                    repliedToSenderName: msg.repliedToSenderName,
                    repliedToText: existingMsg.repliedToText ?? msg.repliedToText,
                  );
                } else if (msg.repliedToText != null && existingMsg.repliedToText == null) {
                  _messages[existingIdx] = ChatMessage(
                    id: existingMsg.id,
                    text: existingMsg.text,
                    senderId: existingMsg.senderId,
                    senderName: existingMsg.senderName,
                    isSent: existingMsg.isSent,
                    timestamp: existingMsg.timestamp,
                    isRead: existingMsg.isRead,
                    attachmentUrl: existingMsg.attachmentUrl,
                    attachmentName: existingMsg.attachmentName,
                    repliedToId: existingMsg.repliedToId ?? msg.repliedToId,
                    repliedToSenderName: existingMsg.repliedToSenderName ?? msg.repliedToSenderName,
                    repliedToText: msg.repliedToText,
                  );
                }
              }
            } else {
              // Add new message
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
            final eventType = data['type']?.toString();
            if (eventType == 'message' || eventType == 'chat.message') {
              final messageId = data['message_id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
              final messageText = data['message']?.toString() ?? '';
              final senderId = data['sender_id']?.toString() ?? '';
              final senderUsername = data['sender_username']?.toString() ?? '';
              String? senderName = data['sender_name']?.toString();
              if (senderName == null || senderName.isEmpty || senderName == 'Unknown') {
                // Try to get from sender object if it's a Map
                if (data['sender'] is Map) {
                  final sender = data['sender'] as Map;
                  final firstName = sender['first_name']?.toString() ?? '';
                  final lastName = sender['last_name']?.toString() ?? '';
                  if (firstName.isNotEmpty || lastName.isNotEmpty) {
                    senderName = '${firstName} ${lastName}'.trim();
                  } else {
                    final fullName = sender['full_name']?.toString();
                    if (fullName != null && fullName.isNotEmpty && fullName != 'null') {
                      senderName = fullName;
                    } else {
                      senderName = sender['username']?.toString();
                    }
                  }
                } else if (data['sender'] is String) {
                  senderName = data['sender'] as String;
                }
                // If still null and it's a group chat, try to find from existing messages
                if ((senderName == null || senderName.isEmpty || senderName == 'Unknown') && isGroup && senderId.isNotEmpty) {
                  final existingMsg = _messages.firstWhere(
                    (m) => m.senderId == senderId && m.senderName != null && m.senderName!.isNotEmpty && m.senderName != 'Unknown',
                    orElse: () => ChatMessage(
                      id: '',
                      text: '',
                      senderId: '',
                      isSent: false,
                      timestamp: '',
                    ),
                  );
                  if (existingMsg.senderName != null && existingMsg.senderName!.isNotEmpty) {
                    senderName = existingMsg.senderName;
                  }
                }
              }
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
              
              final isSent = senderId == widget.teacherUserId || senderUsername == widget.teacherUsername;
              
              // For sent messages, check if there's a temp message that should be updated
              if (isSent && messageId.isNotEmpty) {
                // Check if we already have this message (by ID)
                if (_messageIds.contains(messageId) || _messages.any((msg) => msg.id == messageId)) {
                  debugPrint('Message already exists with ID: $messageId, skipping duplicate');
                  return;
                }
                
                // Check for matching temp message (same text, same sender, recent timestamp)
                final tempMatchIndex = _messages.indexWhere((msg) {
                  if (!msg.isSent) return false;
                  if (!msg.id.startsWith('temp_')) return false;
                  if (msg.text != messageText) return false;
                  try {
                    final msgTime = DateTime.tryParse(msg.timestamp);
                    if (msgTime != null) {
                      final newTime = DateTime.tryParse(timestamp);
                      if (newTime != null) {
                        final diff = msgTime.difference(newTime).abs().inSeconds;
                        if (diff <= 30) return true; // Within 30 seconds
                      }
                    }
                  } catch (e) {}
                  return false;
                });
                
                if (tempMatchIndex != -1) {
                  // Update the temp message with real ID
                  if (mounted) {
                    setState(() {
                      final oldTempId = _messages[tempMatchIndex].id;
                      final messageType = data['message_type']?.toString() ?? 'text';
                      _messages[tempMatchIndex] = ChatMessage(
                        id: messageId,
                        text: messageText,
                        senderId: senderId,
                        senderName: senderName,
                        isSent: isSent,
                        timestamp: timestamp,
                        attachmentUrl: data['attachment_url']?.toString(),
                        attachmentName: data['attachment_name']?.toString(),
                        repliedToId: data['replied_to_id']?.toString() ?? _messages[tempMatchIndex].repliedToId,
                        repliedToSenderName: data['replied_to_sender_name']?.toString() ?? _messages[tempMatchIndex].repliedToSenderName,
                        repliedToText: data['replied_to_text']?.toString() ?? _messages[tempMatchIndex].repliedToText,
                        messageType: messageType,
                        isRead: false,
                      );
                      _messageIds.remove(oldTempId);
                      _messageIds.add(messageId);
                      _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
                    });
                    debugPrint('Updated temp message with real ID from WebSocket: $messageId');
                  }
                  return;
                }
              }
              
              // Check if message already exists (prevent duplicates)
              if (_messageIds.contains(messageId) || _messages.any((msg) => msg.id == messageId)) {
                debugPrint('Message already exists with ID: $messageId, skipping duplicate');
                return;
              }
              
              if (mounted) {
                setState(() {
                  final messageType = data['message_type']?.toString() ?? 'text';
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
                    repliedToSenderName: data['replied_to_sender_name']?.toString(),
                    repliedToText: data['replied_to_text']?.toString(),
                    messageType: messageType,
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
            } else if (eventType == 'message_edited' || eventType == 'chat.message_edited') {
              final messageId = data['message_id']?.toString() ?? '';
              final newText = data['message']?.toString() ?? data['new_text']?.toString() ?? '';
              
              if (messageId.isNotEmpty) {
                setState(() {
                  final index = _messages.indexWhere((msg) => msg.id == messageId);
                  if (index != -1) {
                    final oldMsg = _messages[index];
                    _messages[index] = ChatMessage(
                      id: oldMsg.id,
                      text: newText,
                      senderId: oldMsg.senderId,
                      senderName: oldMsg.senderName,
                      isSent: oldMsg.isSent,
                      timestamp: oldMsg.timestamp,
                      isRead: oldMsg.isRead,
                      attachmentUrl: oldMsg.attachmentUrl,
                      attachmentName: oldMsg.attachmentName,
                      repliedToId: oldMsg.repliedToId,
                      repliedToSenderName: oldMsg.repliedToSenderName,
                      repliedToText: oldMsg.repliedToText,
                      isEdited: true,
                      isDeleted: oldMsg.isDeleted,
                    );
                  }
                });
              }
            } else if (eventType == 'chat.messages_read') {
              // WhatsApp-like double tick: other party read my messages
              final readByUserId = data['read_by_user_id']?.toString() ?? '';
              final eventGroupId = data['group_id']?.toString() ?? '';
              final bool forThisChat = isGroup
                  ? (eventGroupId == widget.contact.id)
                  : (readByUserId == widget.contact.id);
              if (forThisChat && mounted) {
                setState(() {
                  for (int i = 0; i < _messages.length; i++) {
                    final m = _messages[i];
                    if (m.isSent) {
                      _messages[i] = ChatMessage(
                        id: m.id,
                        text: m.text,
                        senderId: m.senderId,
                        senderName: m.senderName,
                        isSent: m.isSent,
                        timestamp: m.timestamp,
                        isRead: true,
                        attachmentUrl: m.attachmentUrl,
                        attachmentName: m.attachmentName,
                        repliedToId: m.repliedToId,
                        repliedToSenderName: m.repliedToSenderName,
                        repliedToText: m.repliedToText,
                        isEdited: m.isEdited,
                        isDeleted: m.isDeleted,
                      );
                    }
                  }
                });
              }
            } else if (eventType == 'message_deleted' || eventType == 'chat.message_deleted') {
              final messageId = data['message_id']?.toString() ?? '';
              if (messageId.isNotEmpty) {
                setState(() {
                  final index = _messages.indexWhere((msg) => msg.id == messageId);
                  if (index != -1) {
                    final oldMsg = _messages[index];
                    _messages[index] = ChatMessage(
                      id: oldMsg.id,
                      text: "This message was deleted",
                      senderId: oldMsg.senderId,
                      senderName: oldMsg.senderName,
                      isSent: oldMsg.isSent,
                      timestamp: oldMsg.timestamp,
                      isRead: oldMsg.isRead,
                      attachmentUrl: null,
                      attachmentName: null,
                      repliedToId: oldMsg.repliedToId,
                      repliedToSenderName: oldMsg.repliedToSenderName,
                      repliedToText: oldMsg.repliedToText,
                      isEdited: oldMsg.isEdited,
                      isDeleted: true,
                    );
                  }
                });
              }
            } else if (eventType == 'chat.group_updated') {
              // Participants see updated group name / new members (like WhatsApp)
              final eventGroupId = data['group_id']?.toString() ?? '';
              if (isGroup && eventGroupId == widget.contact.id && mounted) {
                final updatedType = data['updated_type']?.toString() ?? '';
                final newName = data['group_name']?.toString();
                if (newName != null && newName.isNotEmpty) {
                  setState(() => _displayGroupName = newName);
                }
                if (updatedType == 'name') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Group name updated')),
                  );
                } else if (updatedType == 'members_added') {
                  // System messages are created by backend, reload chat history to show them
                  _loadChatHistory();
                } else if (updatedType == 'members_removed') {
                  // System messages are created by backend, reload chat history to show them
                  _loadChatHistory();
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
      _editingMessage = null; // Clear editing mode when replying
    });
    // Focus text field handled by UI update
  }

  // Edit a message
  void _onEdit(ChatMessage message) {
    setState(() {
      _editingMessage = message;
      _messageController.text = message.text;
      _replyingTo = null; // Clear reply mode when editing
    });
  }

  void _onDelete(ChatMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
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
      final index = _messages.indexWhere((m) => m.id == message.id);
      if (index != -1) {
        final oldMsg = _messages[index];
        _messages[index] = ChatMessage(
          id: oldMsg.id,
          text: "This message was deleted",
          senderId: oldMsg.senderId,
          senderName: oldMsg.senderName,
          isSent: oldMsg.isSent,
          timestamp: oldMsg.timestamp,
          isRead: oldMsg.isRead,
          attachmentUrl: null,
          attachmentName: null,
          repliedToId: oldMsg.repliedToId,
          repliedToSenderName: oldMsg.repliedToSenderName,
          repliedToText: oldMsg.repliedToText,
          isEdited: oldMsg.isEdited,
          isDeleted: true,
        );
      }
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
            if (message.attachmentUrl != null && message.attachmentUrl!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Download'),
                onTap: () {
                  Navigator.pop(context);
                  _downloadAttachment(message);
                },
              ),
            if (message.isSent) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  _onEdit(message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _onDelete(message);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }


  void _showImageViewer(ChatMessage message) {
    if (message.attachmentUrl == null || message.attachmentUrl!.isEmpty) return;
    
    final isImage = message.attachmentUrl!.toLowerCase().endsWith('.jpg') ||
                    message.attachmentUrl!.toLowerCase().endsWith('.jpeg') ||
                    message.attachmentUrl!.toLowerCase().endsWith('.png') ||
                    message.attachmentUrl!.toLowerCase().endsWith('.webp') ||
                    message.attachmentUrl!.toLowerCase().endsWith('.gif');

    if (!isImage) {
      _downloadAttachment(message);
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(message.attachmentName ?? 'Image', style: const TextStyle(color: Colors.white)),
            actions: [
              IconButton(
                icon: const Icon(Icons.download, color: Colors.white),
                onPressed: () => _downloadAttachment(message),
              ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4,
              child: message.attachmentUrl!.startsWith('http')
                  ? Image.network(
                      message.attachmentUrl!,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 100, color: Colors.white),
                    )
                  : Image.file(File(message.attachmentUrl!), fit: BoxFit.contain),
            ),
          ),
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
           final result = await ImageGallerySaverPlus.saveImage(
             Uint8List.fromList(response.data),
             quality: 100, 
             name: fileName
           );
           if (result != null && result['isSuccess'] == true) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image saved to Gallery')));
           }
        } else {
           try {
             await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
           } catch (_) {}
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


  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    // Handle editing mode
    if (_editingMessage != null) {
      await _editMessageText(_editingMessage!, text);
      _messageController.clear();
      setState(() {
        _editingMessage = null;
      });
      return;
    }
    
    final replyId = _replyingTo?.id;
    final repliedToSenderName = _replyingTo != null
        ? (_replyingTo!.senderId == widget.teacherUserId ? 'You' : (_replyingTo!.senderName ?? 'Unknown'))
        : null;
    final repliedToText = _replyingTo?.text;
    
    // Clear state immediately
    _messageController.clear();
    setState(() {
      _replyingTo = null;
    });

    if (text.isNotEmpty) {
      await _sendSingleMessage(
        text: text,
        replyId: replyId,
        repliedToSenderName: repliedToSenderName,
        repliedToText: repliedToText,
      );
    }
  }

  // Edit message text
  Future<void> _editMessageText(ChatMessage message, String newText) async {
    if (newText.trim().isEmpty) return;
    
    try {
      // Update UI optimistically
      setState(() {
        final idx = _messages.indexWhere((m) => m.id == message.id);
        if (idx != -1) {
          _messages[idx] = ChatMessage(
            id: message.id,
            text: newText,
            senderId: message.senderId,
            senderName: message.senderName,
            isSent: message.isSent,
            timestamp: message.timestamp,
            attachmentUrl: message.attachmentUrl,
            attachmentName: message.attachmentName,
            repliedToId: message.repliedToId,
            repliedToSenderName: message.repliedToSenderName,
            repliedToText: message.repliedToText,
            isRead: message.isRead,
          );
        }
      });
      
      final success = await api.ApiService.editMessage(message.id, newText);
      
      if (!success) {
        throw Exception('Failed to edit on backend');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message edited')),
        );
      }
    } catch (e) {
      debugPrint('Error editing message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to edit message')),
        );
      }
    }
  }

  Future<void> _sendSingleMessage({
    String? text,
    String? replyId,
    String? repliedToSenderName,
    String? repliedToText,
  }) async {
    if (text == null || text.isEmpty) return;

    // Optimistically add message (include reply preview so sender sees same as receiver)
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}_${text.hashCode}';
    final tempTimestamp = DateTime.now().toUtc().toIso8601String();
    
    setState(() {
      _messageIds.add(tempId);
      _messages.add(ChatMessage(
        id: tempId,
        text: text,
        senderId: widget.teacherUserId,
        senderName: widget.teacherName,
        isSent: true,
        timestamp: tempTimestamp,
        attachmentUrl: null,
        attachmentName: null,
        repliedToId: replyId,
        repliedToSenderName: repliedToSenderName,
        repliedToText: repliedToText,
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
        filePath: null,
        fileBytes: null,
        fileName: null,
        messageType: 'text',
        groupId: groupId,
        otherUserId: otherUserId,
        repliedTo: replyId,
      );
      
      if (response != null && mounted) {
        final realId = response['message_id'].toString();
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == tempId);
          if (idx != -1) {
            final oldMsg = _messages[idx];
            _messages[idx] = ChatMessage(
              id: realId,
              text: response['message_text'] ?? text,
              senderId: widget.teacherUserId,
              senderName: widget.teacherName,
              isSent: true,
              timestamp: response['created_at'] ?? tempTimestamp,
              attachmentUrl: null,
              attachmentName: null,
              repliedToId: response['replied_to_id']?.toString() ?? replyId ?? oldMsg.repliedToId,
              repliedToSenderName: response['replied_to_sender_name']?.toString() ?? oldMsg.repliedToSenderName,
              repliedToText: response['replied_to_text']?.toString() ?? oldMsg.repliedToText,
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

  // Build editing preview widget
  Widget _buildEditingPreview() {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: const Border(
          left: BorderSide(color: Colors.orange, width: 4)
        )
      ),
      child: Row(
        children: [
          const Icon(Icons.edit, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Edit Message',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 13
                  )
                ),
                Text(
                  _editingMessage!.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12
                  )
                ),
              ]
            )
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () => setState(() {
              _editingMessage = null;
              _messageController.clear();
            })
          ),
        ],
      ),
    );
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
                    _displayGroupName ?? widget.contact.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.contact.type == ContactType.group
                        ? '(Group)'
                        : widget.contact.type == ContactType.student
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
                        currentUserId: widget.teacherUserId,
                        onNameUpdated: (newName) {
                          setState(() => _displayGroupName = newName);
                        },
                      ),
                    ).then((result) {
                      if (result == 'deleted' && mounted) {
                        Navigator.pop(context); // Close chat screen if group deleted
                      }
                    });
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
                if (_editingMessage != null)
                  _buildEditingPreview(),
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
                                'Replying to ${_replyingTo!.senderId == widget.teacherUserId ? "You" : (_replyingTo!.senderName ?? widget.contact.name ?? "Unknown")}',
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
                Row(
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

  String _getSenderNameForMessageFullScreen(ChatMessage message) {
    // First check if sender name is already set and valid
    if (message.senderName != null && message.senderName!.isNotEmpty && message.senderName != 'Unknown') {
      return message.senderName!;
    }
    
    // Check if it's the current user
    if (message.senderId == widget.teacherUserId) {
      return widget.teacherName;
    }
    
    // For non-group chats, use contact name
    if (widget.contact.type != ContactType.group && message.senderId == widget.contact.id) {
      return widget.contact.name;
    }
    
    // For group chats, try to get from any existing messages from the same sender
    if (widget.contact.type == ContactType.group && message.senderId.isNotEmpty) {
      // Search through all messages to find sender name
      for (final m in _messages) {
        if (m.senderId == message.senderId && m.senderName != null && m.senderName!.isNotEmpty && m.senderName != 'Unknown') {
          return m.senderName!;
        }
      }
    }
    
    // Last resort: return "Unknown" (don't show UUID)
    return "Unknown";
  }


  Widget _buildMessageBubble(ChatMessage message) {
    final bool isSystem = message.messageType == 'system';
    
    // System messages: centered, gray, italic (like WhatsApp)
    if (isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Center(
          child: Text(
            message.text,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: Key(message.id),
        direction: DismissDirection.startToEnd,
        confirmDismiss: (direction) async {
          _onReply(message);
          return false;
        },
        background: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 20),
          child: const Icon(Icons.reply, color: Color(0xFF667eea), size: 28),
        ),
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
              onSecondaryTap: () => _showMessageOptions(message),
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
                  if (widget.contact.type == ContactType.group && !message.isSent) ...[
                    Text(
                      _getSenderNameForMessageFullScreen(message),
                      style: TextStyle(
                        color: _getSenderColor(message.senderId),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  // Reply block: same as student chat (blue bar, blue sender name, quoted text)
                  if (message.repliedToId != null || (message.repliedToSenderName != null && message.repliedToSenderName!.isNotEmpty) || (message.repliedToText != null && message.repliedToText!.isNotEmpty)) ...[
                    Builder(
                      builder: (context) {
                        String replySenderName = message.repliedToSenderName ?? 'Unknown';
                        String replyText = message.repliedToText ?? '';
                        
                        // If reply metadata is missing, try to find the original message
                        if (replySenderName == 'Unknown' || replyText.isEmpty) {
                          final repliedMessage = _messages.firstWhere(
                            (m) => m.id == message.repliedToId,
                            orElse: () => ChatMessage(
                              id: 'unknown',
                              text: 'Message not found',
                              senderId: 'unknown',
                              isSent: false,
                              timestamp: '',
                            ),
                          );
                          
                          if (replySenderName == 'Unknown') {
                            if (repliedMessage.senderId == widget.teacherUserId) {
                              replySenderName = 'You';
                            } else if (repliedMessage.senderName != null && repliedMessage.senderName!.isNotEmpty) {
                              replySenderName = repliedMessage.senderName!;
                            } else if (widget.contact.type == ContactType.group) {
                              replySenderName = 'Unknown';
                            } else {
                              replySenderName = widget.contact.name;
                            }
                          }
                          
                          if (replyText.isEmpty) {
                            replyText = repliedMessage.text.isNotEmpty
                                ? repliedMessage.text
                                : (repliedMessage.attachmentUrl != null ? '📷 Photo' : 'Attachment');
                          }
                        }
                        
                        return Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: const Border(
                              left: BorderSide(
                                color: Color(0xFF667eea),
                                width: 4,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                replySenderName,
                                style: const TextStyle(
                                  color: Color(0xFF667eea),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                replyText.trim().isNotEmpty ? replyText : 'Attachment',
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                  if (message.attachmentUrl != null && message.attachmentUrl!.isNotEmpty) ...[
                    if (message.attachmentUrl!.toLowerCase().endsWith('.jpg') ||
                        message.attachmentUrl!.toLowerCase().endsWith('.png') ||
                        message.attachmentUrl!.toLowerCase().endsWith('.jpeg') ||
                        message.attachmentUrl!.toLowerCase().endsWith('.webp') ||
                        message.attachmentUrl!.toLowerCase().endsWith('.gif'))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: () => _showImageViewer(message),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.5,
                                maxHeight: 300,
                              ),
                              child: message.attachmentUrl!.startsWith('http')
                                  ? Image.network(
                                      message.attachmentUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        debugPrint('Image load error: $error');
                                        return Container(
                                          height: 200,
                                          width: 200,
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.broken_image, size: 50, color: Colors.red),
                                        );
                                      },
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          height: 200,
                                          width: 200,
                                          alignment: Alignment.center,
                                          color: Colors.grey[100],
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
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        height: 200,
                                        width: 200,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.broken_image, size: 50),
                                      ),
                                    ),
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
                                    message.attachmentName ?? message.attachmentUrl!.split('/').last,
                                    style: const TextStyle(fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.download, size: 16, color: Color(0xFF667eea)),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                  if (message.text.isNotEmpty)
                    Text(
                      message.isDeleted ? "🚫 This message was deleted" : message.text,
                      style: TextStyle(
                        color: message.isDeleted ? Colors.grey[500] : Colors.black87,
                        fontSize: 15,
                        height: 1.4,
                        fontStyle: message.isDeleted ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${_formatMessageTime(message.timestamp)}${message.isEdited && !message.isDeleted ? ' (Edited)' : ''}",
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
      ),
    );
  }
}
