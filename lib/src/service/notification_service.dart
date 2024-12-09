import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:core_utils/core_utils.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_service/permission_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> Function(String?)? onNotificationClickAction;

  static final NotificationService _notificationService =
      NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  static Future<void> init({
    required FirebaseOptions options,
    required Future<void> Function(String?) onClickAction,
  }) async {
    onNotificationClickAction = onClickAction;
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
        AndroidInitializationSettings("app_icon");

    DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
      onDidReceiveLocalNotification: (id, title, body, payload) {
        _notificationClicked(
          payload,
        );
      },
    );

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

    FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage message) {
        AppLogs.debugLog(
          'Message Opened App: ${message.data}',
          runtimeType: FirebaseMessaging,
        );
        _notificationClicked(message.data['payload']);
      },
    );

    await onInitState();
  }

  static Future<String?> getFCMToken() async {
    String? fcmToken = await FirebaseMessaging.instance.getToken();
    AppLogs.debugLog("FCM ${fcmToken.toString()}");
    return fcmToken;
  }

  static void subscribeToTopics({
    required List<String> topics,
  }) {
    for (String topic in topics) {
      FirebaseMessaging.instance.subscribeToTopic(topic).then((_) {
        AppLogs.debugLog("Subscribe To Topic $topic");
      });
    }
  }

  static Future<void> firebaseBackgroundHandler(
    RemoteMessage message,
  ) async {
    AppLogs.responseLog('Notification ${message.notification?.toMap()}');
    if (Platform.isAndroid) {
      NotificationService.showNotification(
        id: Random().nextInt(100000),
        showProgress: false,
        title: message.notification?.title ?? "",
        body: message.notification?.body ?? "",
        imageUrl: message.notification?.android?.imageUrl,
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
        AppLogs.debugLog(
          'GetInitialMessage: ${message.data}',
          runtimeType: FirebaseMessaging,
        );
        _notificationClicked(message.data['payload']);
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      AppLogs.responseLog('Notification ${message.notification?.toMap()}');
      if (Platform.isAndroid) {
        showNotification(
          id: Random().nextInt(100000),
          showProgress: false,
          title: message.notification?.title ?? "",
          body: message.notification?.body ?? "",
          imageUrl: message.notification?.android?.imageUrl,
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
    if (payload != null) {
      _notificationClicked(response.payload);
    }
  }

  static Future<void> onNotificationClick(String? payload) async {
    if (onNotificationClickAction != null) {
      await onNotificationClickAction!(payload);
    } else {
      AppLogs.debugLog("No action defined for notification click");
    }
  }

  static Future<void> _notificationClicked(String? payload) async {
    await onNotificationClick(payload);
  }

  static Future<void> showNotification({
    int progress = 0,
    int maxProgress = 0,
    int? id,
    String? title,
    String? body,
    String? imageUrl,
    bool? showProgress,
    Importance importance = Importance.max,
    Priority priority = Priority.max,
    bool ongoing = false,
    String? payload,
    int badgeCount = 0,
    bool autoCancel = false,
  }) async {
    BigPictureStyleInformation? bigPictureStyleInformation;
    if (imageUrl != null && imageUrl != "") {
      final String largeIconPath =
          await _downloadAndSaveImage(imageUrl, 'largeIcon');

      bigPictureStyleInformation = BigPictureStyleInformation(
        FilePathAndroidBitmap(largeIconPath),
        largeIcon: const DrawableResourceAndroidBitmap('app_icon'),
        contentTitle: title,
        summaryText: body,
      );
    }
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
      styleInformation: bigPictureStyleInformation,
      progress: progress,
      maxProgress: maxProgress,
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

  static Future<String> _downloadAndSaveImage(
    String url,
    String fileName,
  ) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/$fileName';
    final http.Response response = await http.get(Uri.parse(url));
    final File file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }
}
