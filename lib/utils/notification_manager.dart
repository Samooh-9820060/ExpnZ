import 'dart:async';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class ReceivedNotification {
  ReceivedNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int id;
  final String? title;
  final String? body;
  final String? payload;
}

class NotificationManager {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final StreamController<ReceivedNotification> didReceiveLocalNotificationStream =
  StreamController<ReceivedNotification>.broadcast();

  // Constructor
  NotificationManager() {
    initializeNotifications();
  }

  // Initialize notification settings
  void initializeNotifications() async {
    var initializationSettingsAndroid = const AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      onDidReceiveLocalNotification: (int id, String? title, String? body, String? payload) async {
        didReceiveLocalNotificationStream.add(
          ReceivedNotification(
            id: id,
            title: title,
            body: body,
            payload: payload,
          ),
        );
      },
    );
    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Schedule a zoned notification
  Future<void> scheduleNotification(Map<String, dynamic> transaction, DateTime notificationTime) async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      transaction.keys.first,
      'Recurring Transactions',
      channelDescription: 'Notification channel for recurring transaction reminders',
      importance: Importance.max,
      priority: Priority.high,
    );
    const DarwinNotificationDetails darwinNotificationDetails = DarwinNotificationDetails(
      sound: 'slow_spring_board.aiff',
    );


    var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: darwinNotificationDetails,
    );

    Map<String, dynamic> payloadMap = {
      'docKey': transaction['docKey'],
      'notificationTime': notificationTime.toIso8601String(),
    };
    String payload = json.encode(payloadMap);
    await flutterLocalNotificationsPlugin.zonedSchedule(
      transaction.hashCode,
      transaction['name'],
      transaction['description'],
      tz.TZDateTime.from(notificationTime, tz.local),
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  Future<int?> findNotificationId(String transactionId) async {
    List<PendingNotificationRequest> pendingNotifications =
    await flutterLocalNotificationsPlugin.pendingNotificationRequests();

    for (var notification in pendingNotifications) {
      Map<String, dynamic> payloadData = json.decode(notification.payload!);
      if (payloadData['docKey'] == transactionId) {
          return notification.id;
      }
    }
    return null;
  }

  Future<String?> getNotificationTime(String id) async {
    List<PendingNotificationRequest> pendingNotifications =
    await flutterLocalNotificationsPlugin.pendingNotificationRequests();

    for (var notification in pendingNotifications) {
      try {
        Map<String, dynamic> payloadData = json.decode(notification.payload!);
        if (payloadData['docKey'] == id) {
          return payloadData['notificationTime']; // Return the notification time
        }
      } catch (e) {
        // Handle or log error
      }
    }

    return null;
  }

  Future<bool> notificationExists(String transactionId) async {
    List<PendingNotificationRequest> pendingNotifications = await flutterLocalNotificationsPlugin.pendingNotificationRequests();

    print(pendingNotifications.length);
    for (var notification in pendingNotifications) {
      try {
        Map<String, dynamic> payloadData = json.decode(notification.payload!);
        if (payloadData['docKey'] == transactionId) {
          print(payloadData['notificationTime']);
          return true;
        }
      } catch (e) {
        // Handle or log error if payload is not a valid JSON or doesn't contain expected fields
      }
    }

    return false;
  }
}