import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/loan_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'loanbuddy_channel',
      'Loan Buddy Notifications',
      channelDescription: 'Notifications for Loan Buddy app',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
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

  // Schedule payment reminder notifications
  static Future<void> scheduleLoanReminder(Loan loan) async {
    // Only schedule for active loans
    if (loan.status != LoanStatus.active) return;
    
    // Calculate days remaining to due date
    final daysRemaining = loan.dueDate.difference(DateTime.now()).inDays;
    
    // Schedule notifications based on days remaining
    if (daysRemaining <= 0) {
      // Overdue notification
      await showNotification(
        id: loan.id ?? 0,
        title: 'Loan Overdue',
        body: '${loan.borrowerName}\'s loan is overdue! Tap to see details.',
      );
    } else if (daysRemaining <= 3) {
      // Due soon notification
      await showNotification(
        id: loan.id ?? 0,
        title: 'Loan Due Soon',
        body: '${loan.borrowerName}\'s loan is due in $daysRemaining days.',
      );
    }
  }
  
  // Schedule notifications for all active loans
  static Future<void> scheduleAllReminders(List<Loan> loans) async {
    for (final loan in loans) {
      if (loan.status == LoanStatus.active) {
        await scheduleLoanReminder(loan);
      }
    }
  }
}