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
              // Don't reset _messages[groupId] here - we already populated it above with last message
              
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
                          Flexible(
                            child: FilterChip(
                              label: const Text('All', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
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
                              ? (contact.type == ContactType.group
                                  ? (lastMessage.senderId == _currentStudentUserId ? 'You: ' : '${_getSenderName(lastMessage)}: ') + lastMessage.text
                                  : lastMessage.text)
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
  final bool isEdited;
  final bool isDeleted;
  final String? attachmentUrl;
  final String? attachmentName;
  final String? repliedToId;
  final String? repliedToSenderName;
  final String? repliedToText; // Added for replies
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
    this.isEdited = false,
    this.isDeleted = false,
    this.attachmentUrl,
    this.attachmentName,
    this.repliedToId,
    this.repliedToSenderName,
    this.repliedToText,
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
  String? attachmentName;
  String? repliedToId;
  String? repliedToSenderName;
  String? repliedToText;
  final bool isEdited;
  final bool isDeleted;

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
    this.lastMessageIsSent = false,
    this.unreadCount = 0,
    this.attachmentName,
    this.repliedToId,
    this.repliedToSenderName,
    this.repliedToText,
    this.isEdited = false,
    this.isDeleted = false,
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
  ChatMessage? _replyingTo; // Track message being replied to
  ChatMessage? _editingMessage; // Track message being edited
  Map<String, String> _groupMembers = {}; // Cache for group member names
  bool _isRemoved = false; // Track if user is removed from group
  String? _displayGroupName; // Updated group name from Group Info


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
    
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    if (widget.contact.type == ContactType.group) {
      await _fetchGroupMembers();
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

  Future<void> _fetchGroupMembers() async {
    try {
      final members = await api.ApiService.getGroupMembers(widget.contact.id);
      if (mounted) {
        setState(() {
          _groupMembers.clear();
          bool amIMember = false;
             // Handle both List and Map response format
          List<dynamic> membersList = [];
          if (members is List) {
            membersList = members as List<dynamic>;
          } else if (members is Map) {
            // Backend returns { members: [...], group_name: ... }
            if (members.containsKey('members') && members['members'] is List) {
              membersList = members['members'] as List<dynamic>;
            } else if (members.containsKey('users') && members['users'] is List) {
              membersList = members['users'] as List<dynamic>;
            }
          }

          for (var m in membersList) {
             if (m is! Map) continue;
             final id = m['user_id']?.toString() ?? '';
             final name = m['full_name']?.toString() ?? m['username']?.toString() ?? 'Unknown';
             if (id.isNotEmpty) {
               _groupMembers[id] = name;
               if (id == widget.studentUserId) amIMember = true;
             }
          }
          // Only treat as removed for THIS group when we got a valid member list and current user is not in it
          _isRemoved = membersList.isNotEmpty && !amIMember;
        });
      }
    } catch (e) {
      debugPrint('Error fetching group members: $e');
    }
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
          final List<ChatMessage> history = messages.map<ChatMessage>((msg) {
            final sender = msg['sender'] is Map ? Map<String, dynamic>.from(msg['sender'] as Map) : null;
            final senderId = sender?['user_id']?.toString() ?? '';
            final senderUsername = sender?['username']?.toString() ?? '';
            final isSent = senderId == widget.studentUserId || senderUsername == widget.studentUsername;
            final messageText = msg['message_text']?.toString() ?? msg['message']?.toString() ?? '';
            final messageId = msg['message_id']?.toString() ?? msg['id']?.toString() ?? DateTime.now().toUtc().millisecondsSinceEpoch.toString();
            
            String? rawSenderName = msg['sender_name']?.toString();
            // Try to extract from sender object if sender_name is not available
            if ((rawSenderName == null || rawSenderName.isEmpty || rawSenderName == 'Unknown') && sender != null) {
              final firstName = sender['first_name']?.toString() ?? '';
              final lastName = sender['last_name']?.toString() ?? '';
              if (firstName.isNotEmpty || lastName.isNotEmpty) {
                rawSenderName = '${firstName} ${lastName}'.trim();
              } else {
                final fullName = sender['full_name']?.toString();
                if (fullName != null && fullName.isNotEmpty && fullName != 'null') {
                  rawSenderName = fullName;
                } else {
                  rawSenderName = sender['username']?.toString();
                }
              }
            }
            
            final bool isGroupChat = widget.contact.type == ContactType.group;
            String? senderName;
            if (rawSenderName != null && rawSenderName.trim().isNotEmpty && rawSenderName != 'Unknown') {
              senderName = rawSenderName.trim();
              // Update group members cache for group chats
              if (isGroupChat && senderId.isNotEmpty) {
                _groupMembers[senderId] = senderName;
              }
            } else if (isGroupChat && senderId.isNotEmpty) {
              // Try group members cache first
              senderName = _groupMembers[senderId];
              // If not in cache and we have sender object, try to extract
              if ((senderName == null || senderName.isEmpty || senderName == 'Unknown') && sender != null) {
                final firstName = sender['first_name']?.toString() ?? '';
                final lastName = sender['last_name']?.toString() ?? '';
                if (firstName.isNotEmpty || lastName.isNotEmpty) {
                  senderName = '${firstName} ${lastName}'.trim();
                  _groupMembers[senderId] = senderName;
                } else {
                  final fullName = sender['full_name']?.toString();
                  if (fullName != null && fullName.isNotEmpty && fullName != 'null') {
                    senderName = fullName;
                    _groupMembers[senderId] = senderName;
                  } else {
                    final username = sender['username']?.toString();
                    if (username != null && username.isNotEmpty) {
                      senderName = username;
                      _groupMembers[senderId] = senderName;
                    }
                  }
                }
              }
            }
            
            return ChatMessage(
              id: messageId,
              text: messageText,
              senderId: senderId,
              senderName: senderName,
              isSent: isSent,
              timestamp: msg['created_at'] as String? ?? DateTime.now().toUtc().toIso8601String(),
              isRead: msg['is_read'] == true,
              isEdited: msg['is_edited'] == true,
              isDeleted: msg['is_deleted'] == true,
              attachmentUrl: msg['attachment_url']?.toString(),
              attachmentName: msg['attachment_name']?.toString(),
              repliedToId: msg['replied_to_id']?.toString() ?? msg['replied_to']?.toString(),
              repliedToSenderName: msg['replied_to_sender_name']?.toString(),
              repliedToText: msg['replied_to_text']?.toString(),
              messageType: msg['message_type']?.toString() ?? 'text',
            );
          }).toList().reversed.toList();

          // Merge history safely
          final existingIds = _messages.map((m) => m.id).toSet();
          
          // Match temp messages with history messages more precisely
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
          
          // Add new messages from history or update existing ones with reply metadata
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
                    isEdited: existingMsg.isEdited,
                    isDeleted: existingMsg.isDeleted,
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
                    isEdited: existingMsg.isEdited,
                    isDeleted: existingMsg.isDeleted,
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
                    isEdited: existingMsg.isEdited,
                    isDeleted: existingMsg.isDeleted,
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
                }
                // If still null, try group members cache
                if ((senderName == null || senderName.isEmpty || senderName == 'Unknown') && isGroup && senderId.isNotEmpty) {
                  senderName = _groupMembers[senderId];
                  // If still not found, try to find from existing messages
                  if ((senderName == null || senderName.isEmpty || senderName == 'Unknown')) {
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
                      // Also update group members cache for future use
                      _groupMembers[senderId] = senderName!;
                    }
                  }
                }
              }
              final timestamp = data['timestamp']?.toString() ?? DateTime.now().toUtc().toIso8601String();
              final messageType = data['message_type']?.toString() ?? 'text';
              
              // Allow system messages even if messageText is empty
              if (messageText.isEmpty && messageType != 'system') return;
              
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
              
              final isSent = senderId == widget.studentUserId || senderUsername == widget.studentUsername;
              
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
              }
            } else if (data['type'] == 'chat.message_edited') {
              final messageId = data['message_id']?.toString();
              final newText = data['new_text']?.toString();
              if (messageId != null && newText != null) {
                if (mounted) {
                  setState(() {
                    final index = _messages.indexWhere((m) => m.id == messageId);
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
                        isEdited: true,
                        isDeleted: oldMsg.isDeleted,
                        attachmentUrl: oldMsg.attachmentUrl,
                        attachmentName: oldMsg.attachmentName,
                        repliedToId: oldMsg.repliedToId,
                        repliedToSenderName: oldMsg.repliedToSenderName,
                        repliedToText: oldMsg.repliedToText,
                      );
                    }
                  });
                }
              }
            } else if (eventType == 'message_deleted' || eventType == 'chat.message_deleted') {
              final messageId = data['message_id']?.toString();
              if (messageId != null) {
                if (mounted) {
                  setState(() {
                    final index = _messages.indexWhere((m) => m.id == messageId);
                    if (index != -1) {
                      final oldMsg = _messages[index];
                      _messages[index] = ChatMessage(
                        id: oldMsg.id,
                        text: 'This message was deleted',
                        senderId: oldMsg.senderId,
                        senderName: oldMsg.senderName,
                        isSent: oldMsg.isSent,
                        timestamp: oldMsg.timestamp,
                        isRead: oldMsg.isRead,
                        isEdited: oldMsg.isEdited,
                        isDeleted: true,
                        attachmentUrl: null,
                        attachmentName: null,
                        repliedToId: oldMsg.repliedToId,
                        repliedToSenderName: oldMsg.repliedToSenderName,
                        repliedToText: oldMsg.repliedToText,
                      );
                    }
                  });
                }
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
                        isEdited: m.isEdited,
                        isDeleted: m.isDeleted,
                        attachmentUrl: m.attachmentUrl,
                        attachmentName: m.attachmentName,
                        repliedToId: m.repliedToId,
                        repliedToSenderName: m.repliedToSenderName,
                        repliedToText: m.repliedToText,
                      );
                    }
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
            } else if (data['type'] == 'group_removal') {
              final rid = data['group_id']?.toString();
              final removedUserId = data['user_id']?.toString() ?? data['member_id']?.toString();
              
              if (rid == widget.contact.id) {
                if (removedUserId != null && removedUserId != widget.studentUserId) {
                   debugPrint('Ignored group_removal for another user: $removedUserId (me: ${widget.studentUserId})');
                   return; // Stay in the loop/function, just don't process this event as my removal
                }
                if (mounted) {
                  setState(() {
                    _isRemoved = true;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(data['message'] ?? 'You have been removed from this group')),
                    );
                  });
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
    // Optimistic UI update
    if (mounted) {
      setState(() {
        final index = _messages.indexWhere((m) => m.id == message.id);
        if (index != -1) {
          final oldMsg = _messages[index];
          _messages[index] = ChatMessage(
            id: oldMsg.id,
            text: 'This message was deleted',
            senderId: oldMsg.senderId,
            senderName: oldMsg.senderName,
            isSent: oldMsg.isSent,
            timestamp: oldMsg.timestamp,
            isRead: oldMsg.isRead,
            isEdited: oldMsg.isEdited,
            isDeleted: true,
            attachmentUrl: null,
            attachmentName: null,
            repliedToId: oldMsg.repliedToId,
            repliedToSenderName: oldMsg.repliedToSenderName,
            repliedToText: oldMsg.repliedToText,
          );
        }
      });
    }

    final success = await api.ApiService.deleteMessage(message.id);
    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete message')),
        );
        // On failure, we might want to reload history to revert UI, but for now just show error
      }
    }
  }

  void _showMessageOptions(ChatMessage message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!message.isSent)
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
    
    _messageController.clear();
    setState(() {
      _replyingTo = null;
    });

    if (text.isNotEmpty) {
      await _sendSingleMessage(text: text, replyId: replyId);
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
            isRead: message.isRead,
          );
        }
      });
      
      // Call backend API to edit message
      await api.ApiService.editMessage(message.id, newText);
      
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

  Future<void> _sendSingleMessage({String? text, String? replyId}) async {
    if (text == null || text.isEmpty) return;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}_${text.hashCode}';
    final tempTimestamp = DateTime.now().toUtc().toIso8601String();
    
    setState(() {
      _messageIds.add(tempId);
      _messages.add(ChatMessage(
        id: tempId,
        text: text,
        senderId: widget.studentUserId,
        senderName: widget.studentName,
        isSent: true,
        timestamp: tempTimestamp,
        attachmentUrl: null,
        attachmentName: null,
        repliedToId: replyId,
        repliedToSenderName: _replyingTo != null ? _getSenderName(_replyingTo!) : null,
        repliedToText: _replyingTo?.text,
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
              senderId: widget.studentUserId,
              senderName: widget.studentName,
              isSent: true,
              timestamp: response['created_at'] ?? tempTimestamp,
              attachmentUrl: null,
              attachmentName: null,
              repliedToId: replyId,
              repliedToSenderName: response['replied_to_sender_name']?.toString() ?? oldMsg.repliedToSenderName,
              repliedToText: response['replied_to_text']?.toString() ?? oldMsg.repliedToText,
              messageType: response['message_type']?.toString() ?? 'text',
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
        title: GestureDetector(
          onTap: _showGroupInfo,
          child: Row(
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
                      _displayGroupName ?? widget.contact.name,
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
          _isRemoved
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.red[50],
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.block, color: Colors.red, size: 32),
                      const SizedBox(height: 8),
                      const Text(
                        'You have been removed from this group.',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'You cannot send messages.',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                )
              : _buildInputArea(),
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
    // First check if sender name is already set and valid
    if (message.senderName != null && message.senderName!.isNotEmpty && message.senderName != 'Unknown') {
      return message.senderName!;
    }
    
    // Check if it's the current user
    if (message.senderId == widget.studentUserId) {
      return widget.studentName;
    }
    
    // For non-group chats, use contact name
    if (widget.contact.type != ContactType.group && message.senderId == widget.contact.id) {
      return widget.contact.name;
    }
    
    // For group chats, check group members cache
    if (widget.contact.type == ContactType.group) {
      if (_groupMembers.containsKey(message.senderId)) {
        final name = _groupMembers[message.senderId]!;
        if (name.isNotEmpty && name != 'Unknown') {
          return name;
        }
      }
      // If not in cache, try to get from any existing messages from the same sender
      if (message.senderId.isNotEmpty) {
        // Search through all messages to find sender name
        for (final m in _messages) {
          if (m.senderId == message.senderId && m.senderName != null && m.senderName!.isNotEmpty && m.senderName != 'Unknown') {
            // Update cache for future use
            _groupMembers[message.senderId] = m.senderName!;
            return m.senderName!;
          }
        }
        // If still not found, try to reload group members (async, but will help future messages)
        if (!_groupMembers.containsKey(message.senderId)) {
          _fetchGroupMembers();
        }
      }
    }
    
    // Last resort: return "Unknown" (don't show UUID)
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Dismissible(
        key: Key(message.id),
        direction: DismissDirection.startToEnd,
        confirmDismiss: (direction) async {
          _onReply(message);
          return false;
        },
        background: Container(
          alignment: Alignment.centerLeft,
          child: const Icon(Icons.reply, color: Color(0xFF667eea), size: 28),
        ),
        child: Row(
        mainAxisAlignment: message.isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // Left avatar: group received (sender) OR individual received (contact)
          if (isGroup && !message.isSent) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: _getSenderColor(message.senderId).withOpacity(0.2),
              child: Text(
                message.senderName != null && message.senderName!.isNotEmpty ? message.senderName![0] : '?',
                style: TextStyle(
                  color: _getSenderColor(message.senderId),
                  fontWeight: FontWeight.bold,
                  fontSize: 10
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (!isGroup && !message.isSent) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.grey[300]!,
              child: Text(
                _getAvatarInitials(widget.contact.name),
                style: TextStyle(
                  color: Colors.grey[700],
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
              onSecondaryTap: () => _showMessageOptions(message),
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
                        message.senderName ?? "Unknown", 
                        style: TextStyle(
                          color: _getSenderColor(message.senderId), 
                          fontWeight: FontWeight.bold, 
                          fontSize: 12
                        )
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (message.isDeleted)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '🚫 This message was deleted',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                            fontSize: 14,
                          ),
                        ),
                      )
                    else ...[
                      if ((message.repliedToId != null || message.repliedToSenderName != null || (message.repliedToText != null && message.repliedToText!.isNotEmpty)))
                        _buildReplyPreview(message),

                      if (message.attachmentUrl != null && message.attachmentUrl!.isNotEmpty) ...[
                        _buildAttachment(message),
                        const SizedBox(height: 4),
                      ],
                      if (message.text.isNotEmpty)
                        Text(message.text, style: const TextStyle(color: Colors.black87, fontSize: 15)),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "${_formatMessageTime(message.timestamp)}${message.isEdited && !message.isDeleted ? ' (Edited)' : ''}",
                          style: TextStyle(fontSize: 10, color: Colors.grey[600])
                        ),
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
      ),
    );
  }


  Widget _buildAttachment(ChatMessage message) {
    final url = message.attachmentUrl!;
    final isImage = url.toLowerCase().endsWith('.jpg') || url.toLowerCase().endsWith('.png') ||
        url.toLowerCase().endsWith('.jpeg') || url.toLowerCase().endsWith('.webp') || url.toLowerCase().endsWith('.gif');
    
    return GestureDetector(
      onTap: () => _downloadAttachment(message),
      onLongPress: () {
        // Show attachment options menu
        showModalBottomSheet(
          context: context,
          builder: (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('Download'),
                  onTap: () {
                    Navigator.pop(context);
                    _downloadAttachment(message);
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
      },
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
          if (_editingMessage != null) _buildEditingPreview(),
          if (_replyingTo != null) _buildInputReplyPreview(),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(25)),
                  child: TextField(
                    controller: _messageController,
                    textInputAction: TextInputAction.send,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
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

  Widget _buildInputReplyPreview() {
    final replyToName = _replyingTo!.senderId == widget.studentUserId ? 'You' : (_replyingTo!.senderName ?? _getSenderName(_replyingTo!));
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8), border: const Border(left: BorderSide(color: Color(0xFF667eea), width: 4))),
      child: Row(
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              'Replying to $replyToName',
              style: const TextStyle(color: Color(0xFF667eea), fontWeight: FontWeight.bold, fontSize: 13)
            ),
            Text(_replyingTo!.text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ])),
          IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => setState(() => _replyingTo = null)),
        ],
      ),
    );
  }

  Widget _buildReplyPreview(ChatMessage message) {
    final hasReply = message.repliedToId != null ||
        (message.repliedToSenderName != null && message.repliedToSenderName!.isNotEmpty) ||
        (message.repliedToText != null && message.repliedToText!.isNotEmpty);
    if (!hasReply) return const SizedBox.shrink();

    String replySender = message.repliedToSenderName?.trim().isNotEmpty == true
        ? message.repliedToSenderName!
        : 'Unknown';
    String replyText = message.repliedToText?.trim().isNotEmpty == true
        ? message.repliedToText!
        : 'Attachment';

    // If reply metadata is missing, try to find the original message
    if (replySender == 'Unknown' || replyText.isEmpty) {
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
      
      if (repliedMessage.id != 'unknown') {
        if (replySender == 'Unknown') {
          if (repliedMessage.senderId == widget.studentUserId) {
            replySender = 'You';
          } else if (repliedMessage.senderName != null && repliedMessage.senderName!.isNotEmpty) {
            replySender = repliedMessage.senderName!;
          } else if (widget.contact.type == ContactType.group) {
            replySender = _getSenderName(repliedMessage);
          } else {
            replySender = widget.contact.name;
          }
        }
        
        if (replyText.isEmpty || replyText == 'Attachment') {
          replyText = repliedMessage.text.isNotEmpty
              ? repliedMessage.text
              : (repliedMessage.attachmentUrl != null ? '📷 Photo' : 'Attachment');
        }
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
            replySender,
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
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Editing Message',
                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13)
                ),
                Text(
                  _editingMessage!.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)
                ),
              ],
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


  void _showGroupInfo() {
      if (widget.contact.type != ContactType.group) return;
      showDialog(
        context: context,
        builder: (context) => GroupInfoDialog(
          groupId: widget.contact.id,
          groupName: widget.contact.name,
          currentUserId: widget.studentUserId,
          onNameUpdated: (name) {
            setState(() => _displayGroupName = name);
          },
        ),
      );
  }
}

// Group Info Dialog (Student portal - creator can edit/add/remove; participants view only)
class GroupInfoDialog extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String currentUserId;
  final Function(String) onNameUpdated;

  const GroupInfoDialog({
    Key? key,
    required this.groupId,
    required this.groupName,
    required this.currentUserId,
    required this.onNameUpdated,
  }) : super(key: key);

  @override
  State<GroupInfoDialog> createState() => _GroupInfoDialogState();
}

class _GroupInfoDialogState extends State<GroupInfoDialog> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _members = [];
  String _currentName = '';
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
      final data = await api.ApiService.getGroupMembers(widget.groupId);
      if (data.isNotEmpty) {
        setState(() {
          _members = List<Map<String, dynamic>>.from(data['members'] ?? []);
          _currentName = data['group_name']?.toString() ?? _currentName;
          _isCreator = data['is_creator'] == true;
        });
        final latestName = data['group_name']?.toString() ?? _currentName;
        if (latestName.isNotEmpty) widget.onNameUpdated(latestName);
      }
    } catch (e) {
      debugPrint('Error fetching group members: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _memberSubtext(Map<String, dynamic> member) {
    final role = member['role']?.toString() ?? '';
    if (role == 'student_parent') {
      final cn = member['class_name']?.toString();
      final sec = member['section']?.toString();
      if (cn != null && cn.isNotEmpty) return 'Class $cn${sec != null && sec.isNotEmpty ? ' - $sec' : ''}';
    } else if (role == 'teacher') {
      final sub = member['subject']?.toString();
      if (sub != null && sub.isNotEmpty) return sub;
    }
    return '';
  }

  Future<void> _editName() async {
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final c = TextEditingController(text: _currentName);
        return AlertDialog(
          title: const Text('Edit group name'),
          content: TextField(controller: c, decoration: const InputDecoration(labelText: 'Group name'), autofocus: true),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Save')),
          ],
        );
      },
    );
    if (newName != null && newName.isNotEmpty && newName != _currentName) {
      final ok = await api.ApiService.updateGroupName(widget.groupId, newName);
      if (ok && mounted) {
        setState(() => _currentName = newName);
        widget.onNameUpdated(newName);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Group name updated')));
      }
    }
  }

  Future<void> _addParticipants() async {
    final addable = await api.ApiService.getAddableGroupMembers(widget.groupId);
    if (!mounted) return;
    final selected = await showDialog<List<String>>(
      context: context,
      builder: (ctx) => _AddMembersSheetStudent(users: addable),
    );
    if (selected != null && selected.isNotEmpty) {
      final ok = await api.ApiService.addGroupMembers(widget.groupId, selected);
      if (ok && mounted) {
        _fetchMembers();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Members added')));
      }
    }
  }

  Future<void> _removeMember(String userId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove member'),
        content: Text('Remove $name from the group?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Remove')),
        ],
      ),
    );
    if (confirm == true) {
      final ok = await api.ApiService.removeGroupMember(widget.groupId, userId);
      if (ok && mounted) {
        setState(() => _members.removeWhere((m) => m['user_id']?.toString() == userId));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name removed')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 420,
        height: 640, // Fixed height
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Fixed header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Group info', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(height: 1),
            const SizedBox(height: 12),
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Group name: creator can tap to edit; participants view only
                    GestureDetector(
                      onTap: _isCreator ? _editName : null,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            CircleAvatar(radius: 28, backgroundColor: const Color(0xFF667eea), child: const Icon(Icons.group, color: Colors.white, size: 32)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_currentName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text('${_members.length} participants', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                                  if (_isCreator) Text('Tap to edit name', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                ],
                              ),
                            ),
                            if (_isCreator) const Icon(Icons.edit, size: 20, color: Color(0xFF667eea)),
                          ],
                        ),
                      ),
                    ),
                    if (_isCreator) ...[
                      const SizedBox(height: 12),
                      ListTile(
                        leading: const Icon(Icons.person_add, color: Color(0xFF667eea)),
                        title: const Text('Add participants'),
                        onTap: _addParticipants,
                      ),
                    ],
                    const SizedBox(height: 8),
                    const Align(alignment: Alignment.centerLeft, child: Text('Participants', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF667eea)))),
                    const SizedBox(height: 8),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _members.length,
                            itemBuilder: (context, index) {
                              final member = _members[index];
                              final uid = member['user_id']?.toString() ?? '';
                              final name = member['full_name']?.toString() ?? member['username'] ?? '?';
                              // Students: Class & Section; Teachers: Subject
                              final sub = _memberSubtext(member);
                              final canRemove = _isCreator && uid != widget.currentUserId;
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.grey[300],
                                  child: Text((name.isNotEmpty ? name[0] : '?').toUpperCase(), style: const TextStyle(color: Colors.black87)),
                                ),
                                title: Text(name),
                                subtitle: sub.isNotEmpty ? Text(sub, style: TextStyle(fontSize: 12, color: Colors.grey[600])) : null,
                                trailing: canRemove
                                    ? IconButton(
                                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 22),
                                        onPressed: () => _removeMember(uid, name),
                                      )
                                    : null,
                              );
                            },
                          ),
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

class _AddMembersSheetStudent extends StatefulWidget {
  final List<dynamic> users;

  const _AddMembersSheetStudent({required this.users});

  @override
  State<_AddMembersSheetStudent> createState() => _AddMembersSheetStudentState();
}

class _AddMembersSheetStudentState extends State<_AddMembersSheetStudent> {
  final Set<String> _selected = {};

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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add participants'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.users.length,
          itemBuilder: (ctx, i) {
            final u = widget.users[i] as Map<String, dynamic>;
            final uid = u['user_id']?.toString() ?? '';
            final name = u['full_name']?.toString() ?? u['username'] ?? '?';
            final sub = _subtext(u);
            final isSelected = _selected.contains(uid);
            return CheckboxListTile(
              value: isSelected,
              onChanged: (v) => setState(() {
                if (v == true) _selected.add(uid); else _selected.remove(uid);
              }),
              title: Text(name),
              subtitle: sub.isNotEmpty ? Text(sub, style: TextStyle(fontSize: 12, color: Colors.grey[600])) : null,
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context, _selected.toList()), child: const Text('Add')),
      ],
    );
  }
}

