import 'dart:io';
import 'dart:math';

import 'package:core_utils/core_utils.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_service/permission_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static final NotificationService _notificationService =
      NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  static Future<void> init(FirebaseOptions? options) async {
    await Firebase.initializeApp(
      options: options,
    );
    await Permission.notification.isDenied.then((value) {
      if (value) {
        Permission.notification.request();
      }
    });
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings("@mipmap/ic_launcher");

    DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
            requestSoundPermission: true,
            requestBadgePermission: true,
            requestAlertPermission: true,
            onDidReceiveLocalNotification: (id, title, body, payload) {
              selectNotification(payload);
            });

    InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
      macOS: null,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          onDidReceiveNotificationResponse,
    );
    flutterLocalNotificationsPlugin.cancelAll();

    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
    await onInitState();
  }

  static Future<String?> getFCMToken() async {
    String? fcmToken = await FirebaseMessaging.instance.getToken();
    AppLogs.debugLog("FCM ${fcmToken.toString()}");
    return fcmToken;
  }

  static Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
    AppLogs.responseLog('Background Notification ${message.data}');
    if (Platform.isAndroid) {
      NotificationService.showNotification(
        id: int.parse(message.data['id'] ?? "0"),
        showProgress: false,
        title: message.data['title'],
        body: message.data['body'],
        autoCancel: true,
        importance: Importance.max,
        priority: Priority.high,
        ongoing: false,
        badgeCount: 0,
      );
    }
  }

  static Future<void> onInitState() async {
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {
        // Handle initial message here
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      AppLogs.responseLog('Notification ${message.data}');
      if (Platform.isAndroid) {
        showNotification(
          id: Random().nextInt(100000),
          showProgress: false,
          title: message.data['title'],
          body: message.data['body'],
          autoCancel: true,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          ongoing: false,
          badgeCount: 0,
        );
      }
    });
  }

  static Future onDidReceiveNotificationResponse(
      NotificationResponse response) async {
    var payload = response.payload;
    AppLogs.responseLog("payload $payload");
  }

  static Future selectNotification(String? payload) async {}

  static Future<void> showNotification({
    int pp = 0,
    int max = 0,
    int? id,
    String? title,
    String? body,
    bool? showProgress,
    Importance importance = Importance.max,
    Priority priority = Priority.max,
    bool ongoing = false,
    String? payload,
    int badgeCount = 0,
    bool autoCancel = false,
  }) async {
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      '${Random().nextInt(1000)}',
      'App Notification',
      channelDescription: 'App Notification',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      autoCancel: autoCancel,
      showProgress: showProgress ?? true,
      ongoing: ongoing,
      progress: pp,
      maxProgress: max,
      onlyAlertOnce: true,
      icon: "@mipmap/ic_launcher",
      number: badgeCount,
    );
    DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails(
      threadIdentifier: '12345',
      badgeNumber: badgeCount,
    );

    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      id ?? 12345,
      title ?? "App",
      body ?? "You have new Notification",
      platformChannelSpecifics,
      payload: payload,
    );
  }

  void cancelNotification({int? id}) {
    flutterLocalNotificationsPlugin.cancel(id ?? 12345);
  }
}
