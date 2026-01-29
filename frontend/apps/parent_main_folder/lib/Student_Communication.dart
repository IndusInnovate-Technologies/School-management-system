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

class StudentCommunicationScreen extends StatefulWidget {
  const StudentCommunicationScreen({super.key});

  @override
  State<StudentCommunicationScreen> createState() => _StudentCommunicationScreenState();
}

class _StudentCommunicationScreenState extends State<StudentCommunicationScreen> {
  // Data
  final Map<String, ChatContact> _contacts = {};
  final Map<String, List<ChatMessage>> _messages = {};
  final Map<String, int> _unreadCounts = {}; // Track unread messages per contact
  String? _selectedContactId;
  String? _currentStudentUsername;
  String? _currentStudentName; // Student's display name for room ID
  String? _currentStudentUserId;
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
      if (_currentStudentUserId == null) {
        // Wait for student data to load
        await Future.delayed(const Duration(seconds: 2));
        if (_currentStudentUserId == null) {
          debugPrint('Cannot initialize global chat listener: user ID not available');
          return;
        }
      }
      
      debugPrint('Initializing global chat listener for student: $_currentStudentName (ID: $_currentStudentUserId)');
      
      _globalChatService = RealtimeChatService(baseWsUrl: 'ws://localhost:8000');
      await _globalChatService!.connect(
        roomId: 'user_${_currentStudentUserId}',
        chatType: 'user-updates',
      );
      
      _globalChatSubscription = _globalChatService!.stream?.listen((event) {
        try {
          final data = event is String ? jsonDecode(event) : event;
          if (data is Map) {
            final messageType = data['type']?.toString() ?? 'message';
            
            if (messageType == 'message') {
              final senderId = data['sender_id']?.toString() ?? '';
              final recipientId = data['recipient_id']?.toString() ?? '';
              final groupId = data['group_id']?.toString();
              final contactId = groupId ?? senderId;
              
                // Reload data to get latest message preview and unread counts
                if (_selectedContactId != contactId) {
                  _loadData();
                  debugPrint('Reloading data due to new message for $contactId');
                }
            } else if (messageType == 'read_receipt') {
              final messageId = data['message_id']?.toString();
              debugPrint('Read receipt received for message: $messageId');
            }
          }
        } catch (e) {
          debugPrint('Error processing global chat message: $e');
        }
      });
      
      debugPrint('Global chat listener initialized successfully');
    } catch (e) {
      debugPrint('Error initializing global chat listener: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _chatSubscription?.cancel();
    _chatService?.disconnect();
    _globalChatSubscription?.cancel();
    _globalChatService?.disconnect();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load student profile (from parent profile)
      final parentProfile = await api.ApiService.fetchParentProfile();
      String? currentSchoolId;
      if (parentProfile != null) {
        final students = parentProfile['students'];
        if (students is List && students.isNotEmpty) {
          final student = students[0]; // Get first student
          if (student is Map) {
            // CRITICAL: Must use user_id (UUID) for chat, not student_id (internal)
            final userData = student['user'] as Map<String, dynamic>?;
            _currentStudentUserId = userData?['user_id']?.toString() ?? 
                                   student['student_id']?.toString() ?? 
                                   student['id']?.toString();
            
            _currentStudentName = student['student_name']?.toString() ?? student['name']?.toString();
            _currentStudentUsername = userData?['username']?.toString() ?? 
                                     student['email']?.toString() ?? 
                                     student['username']?.toString();
            currentSchoolId = student['school_id']?.toString();
            
            debugPrint('Student loaded: $_currentStudentUsername (ID: $_currentStudentUserId, Name: $_currentStudentName)');
          }
        }
      }

      // Fetch teachers
      debugPrint('Fetching teachers...');
      final teachers = await api.ApiService.fetchTeachers();
      debugPrint('Fetched ${teachers.length} teachers');

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

          if (userId.isNotEmpty && username.isNotEmpty && schoolMatches) {
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
            debugPrint('Skipped teacher - school_id mismatch: teacher=$teacherSchoolId, student=$currentSchoolId');
          }
        } catch (e) {
          debugPrint('Error processing teacher: $e');
        }
      }
      
      // Fetch active conversations (Recent Chats)
      debugPrint('Fetching conversations...');
      try {
        final conversations = await api.ApiService.fetchConversations();
        debugPrint('Fetched ${conversations.length} active conversations');
        debugPrint('Current student user ID: $_currentStudentUserId');
        
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
            
            debugPrint('Conversation contact - userId: $userId, currentStudent: $_currentStudentUserId');
            
            if (userId.isEmpty) {
              debugPrint('WARNING: userId is empty for contact: ${contactData.toString()}');
              continue;
            }
            
            if (userId == _currentStudentUserId) {
              debugPrint('Skipping self-conversation');
              continue;
            }
            
            // If contact doesn't exist yet, add it
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
                type: role.toLowerCase().contains('teacher') ? ContactType.teacher : ContactType.teacher,
                className: '',
                grade: '',
                avatar: _getInitials(name.isNotEmpty ? name : username),
              );
              debugPrint('Added contact from conversation: $name ($userId)');
            } else {
              debugPrint('✓ Successfully matched contact from conversation: ${contactData['username']} (ID: $userId)');
            }
            
            // Update unread count
            _unreadCounts[userId] = unreadCount;
            if (unreadCount > 0) {
              debugPrint('Set unread count for $userId to $unreadCount');
            }
            
            // Update last message if messages list is empty
            if (lastMsgData != null) {
              _messages[userId] ??= [];
              if (_messages[userId]!.isEmpty) {
                final lastMsg = ChatMessage(
                  id: lastMsgData['message_id']?.toString() ?? '',
                  text: lastMsgData['message_text']?.toString() ?? 
                        (lastMsgData['attachment'] != null ? '📎 Attachment' : 
                         (lastMsgData['message'] != null ? lastMsgData['message'].toString() : '')),
                  senderId: (lastMsgData['sender'] as Map?)?['user_id']?.toString() ?? '',
                  isSent: (lastMsgData['sender'] as Map?)?['user_id']?.toString() == _currentStudentUserId,
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

      // Fetch groups from API - only groups where student is a member
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
              lastMsgIsSent = senderData?['user_id']?.toString() == _currentStudentUserId;
              
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
            
            // Debug logging
            debugPrint('Processing group: $groupName');
            debugPrint('  Group ID: $groupId');
            debugPrint('  Member IDs from API: $memberIds');
            debugPrint('  Current Student ID: $_currentStudentUserId');
            debugPrint('  Is student in members? ${memberIds.contains(_currentStudentUserId)}');
            
            // Only add group if student is a member
            if (_currentStudentUserId != null && memberIds.contains(_currentStudentUserId)) {
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
              _messages[groupId] = [];
              
              debugPrint('Added group: $groupName ($groupId) with ${memberIds.length} members - Student is member');
            } else {
              debugPrint('Skipped group: $groupName ($groupId) - Student is not a member');
              debugPrint('  Expected student ID: $_currentStudentUserId');
              debugPrint('  Actual member IDs: $memberIds');
            }
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

  List<ChatContact> get _filteredContacts {
    final filtered = _contacts.values.where((contact) {
      // Search filter
      if (_searchQuery.isNotEmpty && !contact.name.toLowerCase().contains(_searchQuery)) {
        return false;
      }
      
      // Type filter - only filter if Groups is selected
      if (_showGroupsOnly && contact.type != ContactType.group) return false;
      
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
          studentUsername: _currentStudentUsername ?? '',
          studentName: _currentStudentName ?? '',
          studentUserId: _currentStudentUserId ?? '',
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

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
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
          'Student Communication',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
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
                      // Centered filter buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FilterChip(
                            label: const Text('Total Messages', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                            selected: !_showGroupsOnly,
                            onSelected: (v) {
                              if (v) {
                                setState(() {
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
    // If it's a group, delegate to _buildGroupTile or handle it here
    if (contact.type == ContactType.group) {
      final group = _groups[contact.id];
      if (group != null) {
        return _buildGroupTile(group);
      }
    }

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
                              : (contact.subject ?? 'Teacher'),
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

  String _getSenderName(ChatMessage message) {
    if (message.senderName != null && message.senderName!.isNotEmpty) {
      return message.senderName!;
    }
    // Try to find name in contact list
    if (_contacts.containsKey(message.senderId)) {
      return _contacts[message.senderId]!.name;
    }
    
    // Check if it's the current user
    if (message.senderId == _currentStudentUserId) {
      return _currentStudentName ?? "You";
    }
    
    return "Unknown";
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
                              ? (lastMessage.senderId == _currentStudentUserId ? 'You: ' : '${_getSenderName(lastMessage)}: ') + lastMessage.text
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
enum ContactType { teacher, group }

class ChatContact {
  final String id;
  final String name;
  final String username;
  final ContactType type;
  final String avatar;
  String? className;
  String? grade;
  String? subject;

  ChatContact({
    required this.id,
    required this.name,
    required this.username,
    required this.type,
    required this.avatar,
    this.className,
    this.grade,
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

// Chat Screen Widget (simplified version - full implementation would be similar to teacher portal)
class _ChatScreen extends StatefulWidget {
  final ChatContact contact;
  final String studentUsername;
  final String studentName;
  final String studentUserId;
  final List<ChatMessage> messages;
  final Map<String, int> unreadCounts;
  final VoidCallback onMessageSent;

  const _ChatScreen({
    required this.contact,
    required this.studentUsername,
    required this.studentName,
    required this.studentUserId,
    required this.messages,
    required this.unreadCounts,
    required this.onMessageSent,
  });

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
  @override
  void initState() {
    super.initState();
    // Use the messages list passed from parent
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
    _messageController.dispose();
    _scrollController.dispose();
    _chatSubscription?.cancel();
    _chatService?.disconnect();
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
        widget.studentUsername, 
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
            final isSent = senderId == widget.studentUserId || senderUsername == widget.studentUsername;
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
          final existingIds = _messages.map((m) => m.id).toSet();
          final historySentTexts = history.where((h) => h.isSent).map((h) => h.text).toSet();
          
          // Remove temp messages that are now represented in history
          _messages.removeWhere((m) => m.id.startsWith('temp_') && historySentTexts.contains(m.text));
          
          // Add ONLY new messages from history
          for (final msg in history) {
            if (!existingIds.contains(msg.id)) {
              _messages.add(msg);
              existingIds.add(msg.id);
            }
          }
          
          _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          _messageIds.clear();
          _messageIds.addAll(_messages.map((m) => m.id));
          _isLoadingHistory = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Error loading chat history: $e');
      if (mounted) setState(() => _isLoadingHistory = false);
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
        final studentName = normalizeNameForRoomId(widget.studentUsername.isNotEmpty ? widget.studentUsername : widget.studentName);
        final contactName = normalizeNameForRoomId(widget.contact.username.isNotEmpty ? widget.contact.username : widget.contact.name);
        final identifiers = [studentName, contactName]..sort();
        roomId = identifiers.join('_');
        chatType = 'teacher-student'; // From student's perspective, it's always this for direct
      }
      
      debugPrint('Connecting to WS: Room=$roomId, Type=$chatType');
      _chatService = RealtimeChatService(baseWsUrl: 'ws://localhost:8000');
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
                
                final isFromStudent = senderId == widget.studentUserId || senderUsername == widget.studentUsername;
                final isToStudent = recipientId == widget.studentUserId || recipient == widget.studentUsername;
                final isFromContact = senderId == widget.contact.id || senderUsername == widget.contact.username;
                final isToContact = recipientId == widget.contact.id || recipient == widget.contact.username;
                
                forThisChat = (isFromStudent && isToContact) || (isFromContact && isToStudent);
              }
              
              if (!forThisChat) return;
              if (_messageIds.contains(messageId)) return;
              
              final isSent = senderId == widget.studentUserId || senderUsername == widget.studentUsername;
              
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
    setState(() {
      _messages.removeWhere((m) => m.id == message.id);
    });

    final success = await api.ApiService.deleteMessage(message.id);
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete message')),
      );
      _loadChatHistory();
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
            if (message.isSent)
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
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File is local')));
       return;
    }
    
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
         final downloadDir = await getDownloadsDirectory();
         if (downloadDir != null) {
           final savePath = '${downloadDir.path}\\$fileName';
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
      } catch (_) {
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
      if (!mounted) return;
      final bool? shouldSend = await showDialog<bool>(
        context: context,
        builder: (context) => Dialog.fullscreen(
          child: Container(
            color: Colors.black,
            child: Stack(
              children: [
                Center(child: kIsWeb ? Image.network(image.path) : Image.file(File(image.path))),
                Positioned(
                  top: 40, left: 20,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ),
                Positioned(
                  bottom: 30, right: 20,
                  child: FloatingActionButton(
                    backgroundColor: const Color(0xFF075E54),
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
    
    _messageController.clear();
    setState(() {
      _selectedFiles.clear();
      _selectedFileNames.clear();
      _replyingTo = null;
    });

    if (text.isNotEmpty && filesToSend.isEmpty) {
      await _sendSingleMessage(text: text, replyId: replyId);
    } else if (filesToSend.isNotEmpty) {
      for (int i = 0; i < filesToSend.length; i++) {
        final file = filesToSend[i];
        final fileName = fileNamesToSend[i];
        final caption = (i == 0 && text.isNotEmpty) ? text : null;
        await _sendSingleMessage(
          text: caption,
          file: file,
          fileName: fileName,
          replyId: i == 0 ? replyId : null,
        );
      }
    }
  }

  Future<void> _sendSingleMessage({String? text, File? file, String? fileName, String? replyId}) async {
    final messageText = text ?? (file != null ? '[Attachment]' : '');
    if (messageText.isEmpty && file == null) return;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}_${messageText.hashCode}';
    final tempTimestamp = DateTime.now().toUtc().toIso8601String();
    final localFilePath = file?.path;
    
    List<int>? fileBytes;
    if (file != null && kIsWeb) {
      try { fileBytes = await file.readAsBytes(); } catch (_) {}
    }
    
    setState(() {
      _messageIds.add(tempId);
      _messages.add(ChatMessage(
        id: tempId,
        text: messageText,
        senderId: widget.studentUserId,
        senderName: widget.studentName,
        isSent: true,
        timestamp: tempTimestamp,
        attachmentUrl: localFilePath,
        attachmentName: fileName,
        repliedToId: replyId,
      ));
      widget.onMessageSent();
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
              senderId: widget.studentUserId,
              senderName: widget.studentName,
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send message')));
      }
    }
  }

  String _formatMessageTime(String timestamp) {
    if (timestamp.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(timestamp).toLocal();
      return DateFormat('h:mm a').format(dateTime);
    } catch (_) { return ''; }
  }

  String _formatTime(String timestamp) {
    if (timestamp.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(timestamp).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final msgDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
      
      if (msgDate == today) return 'Today';
      if (msgDate == yesterday) return 'Yesterday';
      return DateFormat('MMMM d, yyyy').format(dateTime);
    } catch (_) { return timestamp; }
  }

  bool _isSameDay(String ts1, String ts2) {
    try {
      final d1 = DateTime.parse(ts1).toLocal();
      final d2 = DateTime.parse(ts2).toLocal();
      return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
    } catch (_) { return false; }
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
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1)),
            ],
          ),
          child: Text(
            _formatTime(timestamp),
            style: TextStyle(color: Colors.blue[800], fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
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
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              child: Text(
                widget.contact.avatar,
                style: const TextStyle(color: Color(0xFF667eea), fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.contact.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.contact.type == ContactType.group
                        ? '${widget.contact.className ?? ''} ${widget.contact.grade ?? ''}'.trim().isEmpty
                            ? 'Group'
                            : '${widget.contact.className ?? ''} ${widget.contact.grade ?? ''}'.trim()
                        : (widget.contact.subject != null && widget.contact.subject!.isNotEmpty)
                            ? 'Teacher: ${widget.contact.subject}'
                            : 'Teacher',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: (_isLoadingHistory && _messages.isEmpty)
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text('No messages yet', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                          ],
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
          _buildInputArea(),
        ],
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

  String _getSenderName(ChatMessage message) {
    if (message.senderName != null && message.senderName!.isNotEmpty) {
      return message.senderName!;
    }
    if (message.senderId == widget.studentUserId) {
      return widget.studentName;
    }
    if (widget.contact.type != ContactType.group && message.senderId == widget.contact.id) {
      return widget.contact.name;
    }
    return "Unknown";
  }

  String _getAvatarInitials(String name) {
    if (name.isEmpty || name == "Unknown") return "?";
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return "?";
    
    String initials = parts[0][0].toUpperCase();
    if (parts.length > 1) {
      initials += parts.last[0].toUpperCase();
    }
    return initials;
  }


  Widget _buildMessageBubble(ChatMessage message) {
    final bool isGroup = widget.contact.type == ContactType.group;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: message.isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isSent) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: isGroup 
                  ? _getSenderColor(message.senderId) 
                  : Colors.grey[300],
              child: Text(
                isGroup 
                    ? _getAvatarInitials(_getSenderName(message)) 
                    : widget.contact.avatar,
                style: TextStyle(
                  color: isGroup ? Colors.white : Colors.black87, 
                  fontWeight: FontWeight.bold, 
                  fontSize: 10
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(message),
              child: Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: message.isSent ? const Color(0xFFD9FDD3) : Colors.white,
                  borderRadius: message.isSent
                      ? const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomLeft: Radius.circular(18), bottomRight: Radius.circular(4))
                      : const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomLeft: Radius.circular(4), bottomRight: Radius.circular(18)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isGroup && !message.isSent) ...[
                      Text(
                        _getSenderName(message), 
                        style: TextStyle(
                          color: _getSenderColor(message.senderId), 
                          fontWeight: FontWeight.bold, 
                          fontSize: 12
                        )
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (message.repliedToId != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: const Border(left: BorderSide(color: Color(0xFF667eea), width: 4)),
                        ),
                        child: const Text('Replying to message...', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
                      ),
                    ],
                    if (message.attachmentUrl != null && message.attachmentUrl!.isNotEmpty) ...[
                      _buildAttachment(message),
                      const SizedBox(height: 4),
                    ],
                    if (message.text.isNotEmpty)
                      Text(message.text, style: const TextStyle(color: Colors.black87, fontSize: 15)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_formatMessageTime(message.timestamp), style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                        if (message.isSent) ...[
                          const SizedBox(width: 4),
                          Icon(message.isRead ? Icons.done_all : Icons.done, size: 14, color: message.isRead ? const Color(0xFF34B7F1) : Colors.grey),
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

  Widget _buildAttachment(ChatMessage message) {
    final url = message.attachmentUrl!;
    final isImage = url.toLowerCase().endsWith('.jpg') || url.toLowerCase().endsWith('.png') || url.toLowerCase().endsWith('.jpeg');
    
    return GestureDetector(
      onTap: () => _downloadAttachment(message),
      child: isImage
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: url.startsWith('http') ? Image.network(url, fit: BoxFit.cover) : Image.file(File(url), fit: BoxFit.cover),
            )
          : Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.insert_drive_file, size: 20),
                  const SizedBox(width: 8),
                  Flexible(child: Text(message.attachmentName ?? url.split('/').last, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 4),
                  const Icon(Icons.download, size: 16, color: Colors.grey),
                ],
              ),
            ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, -2))]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyingTo != null) _buildReplyPreview(),
          if (_selectedFileNames.isNotEmpty) _buildFilesPreview(),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.attach_file, color: Color(0xFF667eea)), onPressed: _pickAttachment),
              IconButton(icon: const Icon(Icons.camera_alt, color: Color(0xFF667eea)), onPressed: _openCamera),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(25)),
                  child: TextField(
                    controller: _messageController,
                    textInputAction: TextInputAction.send,
                    decoration: InputDecoration(
                      hintText: _selectedFileNames.isNotEmpty ? 'Add a caption...' : 'Type a message...',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    maxLines: null,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: const BoxDecoration(color: Color(0xFF667eea), shape: BoxShape.circle),
                child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: _sendMessage),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8), border: const Border(left: BorderSide(color: Color(0xFF667eea), width: 4))),
      child: Row(
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Replying to ${_replyingTo!.senderName ?? "Message"}', style: const TextStyle(color: Color(0xFF667eea), fontWeight: FontWeight.bold, fontSize: 12)),
            Text(_replyingTo!.text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ])),
          IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => setState(() => _replyingTo = null)),
        ],
      ),
    );
  }

  Widget _buildFilesPreview() {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedFileNames.length,
        itemBuilder: (context, index) {
          final name = _selectedFileNames[index];
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                const Icon(Icons.attach_file, size: 16, color: Color(0xFF667eea)),
                const SizedBox(width: 4),
                Text(name, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                GestureDetector(onTap: () => setState(() { _selectedFiles.removeAt(index); _selectedFileNames.removeAt(index); }), child: const Icon(Icons.close, size: 16, color: Colors.grey)),
              ],
            ),
          );
        },
      ),
    );
  }
}
