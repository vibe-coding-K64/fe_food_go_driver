import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'injection_container.dart';
import 'features/core/presentation/app.dart';
import 'services/fcm_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM][Background] Handling message: ${message.messageId}');
  debugPrint('[FCM][Background] Data: ${message.data}');
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    } catch (e) {
      debugPrint('Firebase initialization error: $e');
    }
  }

  // Register background handler
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
  @override
  void initState() {
    super.initState();
    _setupFCM();
  }

  Future<void> _setupFCM() async {
    final fcmService = getIt<FCMService>();

    // Request permission
    await fcmService.requestPermission();

    // Foreground handler - khi app đang mở, nhận notification sẽ in log
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM][Foreground] Received: ${message.notification?.title}');
      debugPrint('[FCM][Foreground] Data: ${message.data}');
    });

    // App được mở từ notification (app đang tắt hoàn toàn)
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotificationTap(message);
      }
    });

    // App đang chạy nền, user tap notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('[FCM] Notification tapped - type: ${message.data['type']}, orderId: ${message.data['orderId']}');
    // Firestore listener trong HomeBloc sẽ tự động bắt order request mới
    // Không cần xử lý thêm vì driver đã online và đang watch Firestore
  }

  @override
  Widget build(BuildContext context) {
    return const App();
  }
}
