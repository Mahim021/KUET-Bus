import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'features/schedule/pending_schedule_screen.dart';

// ── Local notifications plugin (global so FCM foreground handler can use it) ──
final FlutterLocalNotificationsPlugin localNotifications =
    FlutterLocalNotificationsPlugin();

const _kChannelId = 'kuet_bus_channel';
const _kChannelName = 'KUET Bus Notifications';

// ── FCM background handler — must be top-level ────────────────────────────────
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Background messages are shown automatically by FCM on Android.
  // No local notification needed here.
}

// ── Entry point ───────────────────────────────────────────────────────────────
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Register background handler before anything else.
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await _initLocalNotifications();
  await _initFCM();

  runApp(const KuetBusApp());
}

// ── Local notifications setup ─────────────────────────────────────────────────
Future<void> _initLocalNotifications() async {
  const androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );
  const settings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await localNotifications.initialize(
    settings,
    onDidReceiveNotificationResponse: _onLocalNotificationTap,
  );

  // Create the Android notification channel.
  const channel = AndroidNotificationChannel(
    _kChannelId,
    _kChannelName,
    importance: Importance.high,
  );
  await localNotifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

// ── FCM setup ─────────────────────────────────────────────────────────────────
Future<void> _initFCM() async {
  final messaging = FirebaseMessaging.instance;

  // Request permissions (required on iOS, needed for Android 13+).
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Subscribe every device to the shared topic.
  await messaging.subscribeToTopic('all_users');

  // Foreground messages — show as a local notification.
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    _showLocalNotification(
      title: notification.title ?? 'KUET Bus',
      body: notification.body ?? '',
      payload: _payloadFromData(message.data),
    );
  });

  // User tapped a notification while app was in background.
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    _handleNotificationTap(message.data);
  });

  // App was launched from a terminated state via notification tap.
  final initial = await messaging.getInitialMessage();
  if (initial != null) {
    // Delay until the first frame so the navigator is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleNotificationTap(initial.data);
    });
  }
}

// ── Show a local notification ─────────────────────────────────────────────────
void _showLocalNotification({
  required String title,
  required String body,
  String? payload,
}) {
  localNotifications.show(
    title.hashCode,
    title,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        _kChannelId,
        _kChannelName,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    ),
    payload: payload,
  );
}

// ── Handle local notification tap (from tray, foreground local notif) ─────────
void _onLocalNotificationTap(NotificationResponse response) {
  if (response.payload == null) return;
  final parts = response.payload!.split(':');
  if (parts.length == 2 && parts[0] == 'schedule_update') {
    _navigateToPendingSchedule(parts[1]);
  }
}

// ── Handle FCM notification tap ───────────────────────────────────────────────
void _handleNotificationTap(Map<String, dynamic> data) {
  if (data['type'] == 'schedule_update') {
    final date = data['date'] as String?;
    if (date != null) _navigateToPendingSchedule(date);
  }
}

void _navigateToPendingSchedule(String date) {
  navigatorKey.currentState?.push(
    MaterialPageRoute(
      builder: (_) => PendingScheduleScreen(date: date),
    ),
  );
}

String? _payloadFromData(Map<String, dynamic> data) {
  if (data['type'] == 'schedule_update' && data['date'] != null) {
    return 'schedule_update:${data['date']}';
  }
  return null;
}
