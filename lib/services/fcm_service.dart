import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      debugPrint('[FCMService] getToken - token: ${token != null ? "${token.substring(0, 20)}..." : "NULL"}');
      return token;
    } catch (e) {
      debugPrint('[FCMService] getToken error: $e');
      return null;
    }
  }

  Future<void> onTokenRefresh(void Function(String token) onToken) async {
    _messaging.onTokenRefresh.listen((token) {
      debugPrint('[FCMService] onTokenRefresh - new token: ${token.substring(0, 20)}...');
      onToken(token);
    });
  }

  Future<NotificationSettings> requestPermission() async {
    try {
      final settings = await _messaging.requestPermission();
      debugPrint('[FCMService] requestPermission - status: ${settings.authorizationStatus}');
      return settings;
    } catch (e) {
      debugPrint('[FCMService] requestPermission error: $e');
      return NotificationSettings(
        alert: AppleNotificationSetting.enabled,
        announcement: AppleNotificationSetting.notSupported,
        authorizationStatus: AuthorizationStatus.notDetermined,
        badge: AppleNotificationSetting.notSupported,
        carPlay: AppleNotificationSetting.notSupported,
        lockScreen: AppleNotificationSetting.notSupported,
        notificationCenter: AppleNotificationSetting.notSupported,
        showPreviews: AppleShowPreviewSetting.always,
        timeSensitive: AppleNotificationSetting.notSupported,
        criticalAlert: AppleNotificationSetting.notSupported,
        sound: AppleNotificationSetting.notSupported,
        providesAppNotificationSettings: AppleNotificationSetting.notSupported,
      );
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('[FCMService] subscribed to topic: $topic');
    } catch (e) {
      debugPrint('[FCMService] subscribeToTopic($topic) error: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('[FCMService] unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('[FCMService] unsubscribeFromTopic($topic) error: $e');
    }
  }

  void setForegroundMessageHandler(Future<void> Function(RemoteMessage message) handler) {
    FirebaseMessaging.onMessage.listen(handler);
  }

  void setBackgroundMessageHandler(Future<void> Function(RemoteMessage message) handler) {
    FirebaseMessaging.onBackgroundMessage(handler);
  }
}
