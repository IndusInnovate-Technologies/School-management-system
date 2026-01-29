import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RealtimeChatService {
  final String baseWsUrl; // e.g. ws://localhost:8000
  WebSocketChannel? _channel;
  String? _currentRoomId;
  String? _chatType;

  RealtimeChatService({required this.baseWsUrl});

  Stream<dynamic>? get stream => _channel?.stream;
  
  String? get currentRoomId => _currentRoomId;
  String? get chatType => _chatType;
  
  bool get isConnected => _channel != null;

  Future<void> connect({
    required String roomId,
    String chatType = 'teacher-student',
  }) async {
    _currentRoomId = roomId;
    _chatType = chatType;
    
    // Get JWT token for authentication
    String? token;
    try {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('access_token');
    } catch (e) {
      // If SharedPreferences fails, continue without token
    }
    
    // Build URI with token as query parameter
    final uri = token != null
        ? Uri.parse('$baseWsUrl/ws/$chatType/$roomId/?token=$token')
        : Uri.parse('$baseWsUrl/ws/$chatType/$roomId/');
    
    _channel = WebSocketChannel.connect(uri);
  }

  void sendMessage({
    required String sender,
    required String recipient,
    required String message,
    String? timestamp,
  }) {
    if (_channel == null) return;
    
    _channel!.sink.add(jsonEncode({
      'sender': sender,
      'recipient': recipient,
      'message': message,
      'timestamp': timestamp ?? DateTime.now().toUtc().toIso8601String(),
    }));
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _currentRoomId = null;
    _chatType = null;
  }
}

