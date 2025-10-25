## 🔔 Notification Service

A powerful, production-ready Flutter notification manager that integrates Firebase Cloud Messaging (FCM) with Local Notifications, supporting background handling, click actions, and rich image notifications — all in one lightweight service.

## 🚀 Features

✅ Initialize Firebase and local notifications seamlessly\
✅ Handle foreground, background, and terminated notifications\
✅ Show notifications with images, titles, and payloads\
✅ Handle click actions and deep links\
✅ Auto-request notification permissions\
✅ Supports custom notification colors and Android/iOS compatibility\
✅ Utility for downloading remote images for big-picture style\
✅ Centralized FCM token management and topic subscriptions

## ⚙️ Installation

Add the package to your pubspec.yaml:
```dart
dependencies:
  notification_service:
    git:
      url: https://github.com/AhmedShawkyAhmed/notification_service.git
```

Then, run:
```bash
flutter pub get
```

## 🧩 Setup & Usage
1️⃣ Initialize Notification Service

In your main file (e.g. main.dart):
```dart
import 'package:notification_service/notification_service.dart';
import 'firebase_options.dart'; // Your Firebase config file

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.init(
    options: DefaultFirebaseOptions.currentPlatform,
    color: Colors.orange,
    onClickAction: (payload) async {
      print("Notification clicked: $payload");
      // Navigate or handle action here
    },
  );

  runApp(MyApp());
}
```
2️⃣ Get FCM Token
```dart
final token = await NotificationService.getFCMToken();
print("FCM Token: $token");
```
3️⃣ Subscribe to Topics
```dart
NotificationService.subscribeToTopics(['news', 'updates']);
```
4️⃣ Cancel Notifications
```dart
NotificationService.cancelNotification(id: 101);
```
5️⃣ Handle Click Actions
Pass your custom callback when initializing the service:
```dart
onClickAction: (payload) async {
  if (payload != null) {
    // Example: Navigate to details page
    Navigator.pushNamed(context, '/details', arguments: payload);
  }
}
```
## Author

**Ahmed Shawky**  
Senior Mobile Engineer  
📧 [shawkyahmed392@gmail.com](mailto:shawkyahmed392@gmail.com)  
🌐 [AhmedShawkyAhmed](https://github.com/AhmedShawkyAhmed)
