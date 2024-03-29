import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:expnz/screens/RecurringTransactionsPage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../database/RecurringTransactionsDB.dart';
import '../screens/AddTransaction.dart';

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

    await flutterLocalNotificationsPlugin.initialize(initializationSettings,);
  }

  Future<void> requestBatteryOptimization() async {
    if (Platform.isAndroid) {
      final AndroidIntent intent = AndroidIntent(
        action: 'android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
        data: 'package:com.techNova.ExpnZ.expnz', // Replace with your package name
      );
      await intent.launch();
    }
  }

  Future<bool> requestPermissions() async {
    if (Platform.isIOS || Platform.isMacOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return true;
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      final bool? grantedNotificationPermission =
      await androidImplementation?.requestNotificationsPermission();
      return grantedNotificationPermission ?? false;
    }

    return false;
  }

  // Schedule a zoned notification
  // Add an additional parameter `notificationType`
  Future<void> scheduleNotification(Map<String, dynamic> transaction, DateTime notificationTime, String notificationType) async {
    String notificationTitle = "Reminder: ${transaction['name']}";
    String notificationBody = "It's time for your ${transaction['frequency']} transaction '${transaction['name']}'.";

    // Add the amount to the notification body only if it's not null, not empty, and can be converted to a double
    String? amountString = transaction['amount'];
    double? amount = amountString != null && amountString.isNotEmpty
        ? double.tryParse(amountString)
        : null;

    if (amount != null) {
      // Append amount to the notification body
      notificationBody += "\nAmount: ${amount.toStringAsFixed(2)}";
    }

    // Modify the title and body based on the type of notification
    if (notificationType == "overdue") {
      notificationTitle = "Overdue: ${transaction['name']}";
      notificationBody = "Your ${transaction['frequency']} transaction '${transaction['name']}' is overdue!";
      if (amount != null) {
        notificationBody += "\nAmount: ${amount.toStringAsFixed(2)}";
      }
    }

    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'recurring_transactions_channel',
      'Recurring Transactions',
      channelDescription: 'Notification channel for recurring transaction reminders',
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(
        notificationBody,
        htmlFormatBigText: true,
      ),
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
      'type': notificationType, // Include the type in the payload
    };
    String payload = json.encode(payloadMap);
    
    await flutterLocalNotificationsPlugin.zonedSchedule(
      transaction.hashCode,
      notificationTitle,
      notificationBody,
      tz.TZDateTime.from(notificationTime, tz.local),
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
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

  Future<Map<String, dynamic>?> getNotificationPayload(String id) async {
    List<PendingNotificationRequest> pendingNotifications =
    await flutterLocalNotificationsPlugin.pendingNotificationRequests();

    for (var notification in pendingNotifications) {
      try {
        Map<String, dynamic> payloadData = json.decode(notification.payload!);
        if (payloadData['docKey'] == id) {
          return payloadData; // Return the entire payload as a map
        }
      } catch (e) {
        // Handle or log error
      }
    }

    return null;
  }

  Future<bool> notificationExists(String transactionId) async {
    List<PendingNotificationRequest> pendingNotifications = await flutterLocalNotificationsPlugin.pendingNotificationRequests();

    for (var notification in pendingNotifications) {
      try {
        Map<String, dynamic> payloadData = json.decode(notification.payload!);
        if (payloadData['docKey'] == transactionId) {
          return true;
        }
      } catch (e) {
        // Handle or log error if payload is not a valid JSON or doesn't contain expected fields
      }
    }

    return false;
  }

  DateTime calculateNextDueDate(DateTime currentDueDate, String frequency) {
    switch (frequency) {
      case 'Daily':
        return currentDueDate.add(Duration(days: 1));
      case 'Weekly':
        return currentDueDate.add(Duration(days: 7));
      case 'Monthly':
        int year = currentDueDate.year;
        int month = currentDueDate.month;
        int day = currentDueDate.day;

        month += 1;
        if (month > 12) {
          month = 1;
          year += 1;
        }

        int lastDayOfMonth = DateTime(year, month + 1, 0).day;
        if (day > lastDayOfMonth) {
          day = lastDayOfMonth;
        }

        return DateTime(year, month, day);
      case 'Yearly':
        return DateTime(currentDueDate.year + 1, currentDueDate.month, currentDueDate.day);
      default:
        return currentDueDate;
    }
  }

  DateTime calculateNotificationTime(DateTime dueDate, TimeOfDay dueTime, int daysBefore, int hoursBefore, int minutesBefore) {
    DateTime fullDueDate = DateTime(
        dueDate.year,
        dueDate.month,
        dueDate.day,
        dueTime.hour,
        dueTime.minute
    );
    return fullDueDate.subtract(Duration(days: daysBefore, hours: hoursBefore, minutes: minutesBefore));
  }

  Future<void> deleteNotification(String docKey) async {
    // The times do not match, delete the old notification and schedule a new one
    int? existingNotificationId = await NotificationManager().findNotificationId(docKey);
    if (existingNotificationId != null) {
      await flutterLocalNotificationsPlugin.cancel(existingNotificationId);
    }
  }
}