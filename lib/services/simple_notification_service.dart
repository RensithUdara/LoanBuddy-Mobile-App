import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// This class completely avoids using any notification styles that might 
/// trigger the problematic bigLargeIcon method in the Android implementation.
class SimpleNotificationService {
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  /// Initialize the notification service with basic settings
  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );
  }

  /// Show a simple notification without any advanced styles
  static Future<void> showSimpleNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    // Create a simple notification with no styles to avoid the issue
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'loanbuddy_channel',
      'Loan Buddy Notifications',
      channelDescription: 'Notifications for Loan Buddy app',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      // Using default style without large icons or big picture style
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
    );
  }
}