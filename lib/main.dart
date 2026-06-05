import 'dart:convert';
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'features/core/presentation/app.dart';
import 'features/home/presentation/bloc/home_bloc.dart';
import 'features/home/presentation/bloc/home_event.dart';
import 'models/driver_realtime_payloads.dart';
import 'firebase_options.dart';
import 'injection_container.dart';
import 'services/fcm_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM][Background] Handling message: ${message.messageId}');
  debugPrint('[FCM][Background] Data: ${message.data}');
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint('Firebase initialization error: $e');
    }
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<RemoteMessage>? _foregroundMessageSub;
  StreamSubscription<RemoteMessage>? _messageOpenedAppSub;

  @override
  void initState() {
    super.initState();
    unawaited(_setupFCM());
  }

  Future<void> _setupFCM() async {
    final fcmService = getIt<FCMService>();

    await fcmService.requestPermission();
    await fcmService.initializeLocalNotifications();

    _foregroundMessageSub?.cancel();
    _foregroundMessageSub = FirebaseMessaging.onMessage.listen((message) async {
      debugPrint('[FCM][Foreground] Received: ${message.notification?.title}');
      debugPrint('[FCM][Foreground] Data: ${message.data}');

      final type = message.data['type']?.toString();
      final event = message.data['event']?.toString();
      final orderId = message.data['orderId']?.toString();
      final requestId = message.data['requestId']?.toString();
      final isOrderRequest =
          type == 'new_order_request' || event == 'ORDER_REQUEST';
      if (isOrderRequest && orderId != null && orderId.isNotEmpty) {
        debugPrint('[FCM][Foreground] New order signal received for $orderId');

        await fcmService.showForegroundOrderAlert(
          orderId: orderId,
          title: message.notification?.title,
          body: message.notification?.body,
        );

        _dispatchForegroundOrderSignal(
          orderId,
          requestId: requestId,
          event: event,
          message: message.notification?.body,
          order: _extractOrderPayload(message.data),
          expiresAt: message.data['expiresAt']?.toString(),
          estimatedEarning: _parseDouble(message.data['estimatedEarning']),
        );
      }
    });

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    _messageOpenedAppSub?.cancel();
    _messageOpenedAppSub = FirebaseMessaging.onMessageOpenedApp.listen(
      _handleNotificationTap,
    );
  }

  void _dispatchForegroundOrderSignal(
    String orderId, {
    String? requestId,
    String? event,
    String? message,
    Map<String, dynamic>? order,
    String? expiresAt,
    double? estimatedEarning,
  }) {
    final navigatorState = appNavigatorKey.currentState;
    final context = navigatorState?.context;
    if (context == null) {
      debugPrint('[FCM] Navigator context unavailable for order $orderId');
      return;
    }

    try {
      if (order != null) {
        final payload = DriverRealtimeOrderRequest.fromJson({
          'event': event ?? 'ORDER_REQUEST',
          'message': message,
          'orderId': orderId,
          'requestId': requestId,
          'estimatedEarning': estimatedEarning,
          'expiresAt': expiresAt,
          'order': order,
        });
        context.read<HomeBloc>().add(
          ForegroundFcmOrderSignalReceived(orderId, requestId: payload.requestId),
        );
        return;
      }

      context.read<HomeBloc>().add(
        ForegroundFcmOrderSignalReceived(orderId, requestId: requestId),
      );
    } catch (e) {
      debugPrint('[FCM] Failed to dispatch foreground order signal: $e');
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    final type = message.data['type']?.toString();
    final event = message.data['event']?.toString();
    final orderId = message.data['orderId']?.toString();
    final requestId = message.data['requestId']?.toString();
    debugPrint('[FCM] Notification tapped - type: $type, orderId: $orderId');

    final isOrderRequest =
        type == 'new_order_request' || event == 'ORDER_REQUEST';
    if (isOrderRequest && orderId != null && orderId.isNotEmpty) {
      _dispatchForegroundOrderSignal(
        orderId,
        requestId: requestId,
        event: event,
        message: message.notification?.body,
        order: _extractOrderPayload(message.data),
        expiresAt: message.data['expiresAt']?.toString(),
        estimatedEarning: _parseDouble(message.data['estimatedEarning']),
      );
    }
  }

  Map<String, dynamic>? _extractOrderPayload(Map<String, dynamic> data) {
    final rawOrder = data['order'];
    if (rawOrder is Map<String, dynamic>) {
      return rawOrder;
    }
    if (rawOrder is String && rawOrder.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawOrder);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } catch (_) {}
    }
    return null;
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  @override
  void dispose() {
    _foregroundMessageSub?.cancel();
    _messageOpenedAppSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const App();
  }
}
