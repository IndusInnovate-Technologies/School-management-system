import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart' as api;

/// Handles FCM token registration and message handling for push notifications.
class FcmService {
  static const _keyLastToken = 'fcm_last_registered_token';

  static String get _platform {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  static Future<void> requestPermission() async {
    if (kIsWeb) return;
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint('FCM requestPermission: $e');
    }
  }

  static Future<String?> getToken() async {
    if (kIsWeb) return null;
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('FCM getToken: $e');
      return null;
    }
  }

  static Future<void> registerTokenIfNeeded() async {
    if (kIsWeb) return;
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return;
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      if (accessToken == null || accessToken.isEmpty) return;
      final last = prefs.getString(_keyLastToken);
      if (last == token) return;
      final ok = await api.ApiService.registerFcmToken(token, _platform);
      if (ok) await prefs.setString(_keyLastToken, token);
    } catch (e) {
      debugPrint('FCM registerTokenIfNeeded: $e');
    }
  }

  static Future<void> unregisterToken([String? token]) async {
    if (kIsWeb) return;
    try {
      final t = token ?? await getToken();
      if (t != null && t.isNotEmpty) {
        await api.ApiService.unregisterFcmToken(t);
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_keyLastToken);
      }
    } catch (e) {
      debugPrint('FCM unregisterToken: $e');
    }
  }

  static void setupHandlers({
    void Function(RemoteMessage message)? onForegroundMessage,
  }) {
    if (kIsWeb) return;
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (onForegroundMessage != null) {
        onForegroundMessage(message);
      } else {
        debugPrint('FCM foreground: ${message.notification?.title} ${message.notification?.body}');
      }
    });
    FirebaseMessaging.instance.onTokenRefresh.listen((String newToken) {
      api.ApiService.registerFcmToken(newToken, _platform);
    });
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('FCM background: ${message.notification?.title}');
}
