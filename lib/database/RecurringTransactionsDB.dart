import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expnz/utils/notification_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/global.dart';

class RecurringTransactionDB {
  static const String collectionName = 'recurringTransactions'; // Collection name
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();


  // Method to listen to recurring transactions changes
  void listenToRecurringTransactionsChanges(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    // Get the last sync time
    String? lastSyncTimeStr = prefs.getString('lastRecurringTransactionSyncTime');
    DateTime lastSyncTime = lastSyncTimeStr != null
        ? DateTime.parse(lastSyncTimeStr)
        : DateTime.fromMillisecondsSinceEpoch(0);

    _firestore.collection(collectionName)
        .where('userId', isEqualTo: userId)
        .where('lastEditedTime', isGreaterThan: lastSyncTime.toIso8601String())
        .snapshots()
        .listen((snapshot) async {
      final newTransactionsData = <String, Map<String, dynamic>>{};

      for (var doc in snapshot.docs) {
        var data = doc.data();
        data['docKey'] = doc.id;
        newTransactionsData[doc.id] = data;
      }

      if (newTransactionsData.isNotEmpty) {
        await cacheRecurringTransactionsLocally(newTransactionsData);
      } else {
        await loadRecurringTransactionsFromLocal();
      }

      if (recurringTransactionsNotifier.value.isNotEmpty) {
        updateScheduledNotifications();
      }

      await prefs.setString('lastRecurringTransactionSyncTime', DateTime.now().toIso8601String());
    }, onError: (error) {
    });
  }
  Future<void> fetchRecurringTransactionsSince(DateTime sinceTime, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final String formattedSinceTime = sinceTime.toIso8601String();

    try {
      QuerySnapshot snapshot = await _firestore.collection(collectionName)
          .where('userId', isEqualTo: userId)
          .where('lastEditedTime', isGreaterThan: formattedSinceTime)
          .get();

      final newTransactionsData = <String, Map<String, dynamic>>{};

      for (var doc in snapshot.docs) {
        var data = doc.data();
        if (data is Map<String, dynamic>) {
          data['docKey'] = doc.id;
          newTransactionsData[doc.id] = data;
        }
      }

      if (newTransactionsData.isNotEmpty) {
        await cacheRecurringTransactionsLocally(newTransactionsData);
      } else {
        await loadRecurringTransactionsFromLocal();
      }

      await prefs.setString('lastRecurringTransactionSyncTime', DateTime.now().toIso8601String());
    } catch (error) {
      print('Error fetching recurring transactions: $error');
    }
  }

  Future<void> loadRecurringTransactionsFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    String? encodedData = prefs.getString('recurringTransactions');
    if (encodedData != null) {
      Map<String, Map<String, dynamic>> recurringTransactionsData = Map<String, Map<String, dynamic>>.from(
        json.decode(encodedData) as Map<String, dynamic>,
      );
      recurringTransactionsNotifier.value = recurringTransactionsData;
    }
  }

  // Method to cache recurring transactions locally
  Future<void> cacheRecurringTransactionsLocally(Map<String, Map<String, dynamic>> newTransactionsData) async {
    final prefs = await SharedPreferences.getInstance();
    String? existingData = prefs.getString('recurringTransactions');
    Map<String, Map<String, dynamic>> existingTransactions = existingData != null
        ? Map<String, Map<String, dynamic>>.from(json.decode(existingData))
        : {};

    // Update existing transactions with new data
    existingTransactions.addAll(newTransactionsData);

    // Remove soft-deleted categories
    newTransactionsData.forEach((key, value) {
      if (value['isDeleted'] == true) {
        existingTransactions.remove(key);
        NotificationManager().deleteNotification(key);
      }
    });

    // Encode the updated transactions and save them
    String encodedData = json.encode(existingTransactions);
    await prefs.setString('recurringTransactions', encodedData);
    recurringTransactionsNotifier.value = existingTransactions; // Assuming you have a notifier
  }

  // Add a new recurring transaction
  Future<void> addRecurringTransaction(Map<String, dynamic> transactionData) async {
    await _firestore.collection(collectionName).add(transactionData);
  }

  // Update an existing recurring transaction
  Future<void> updateRecurringTransaction(String documentId, Map<String, dynamic> transactionData) async {
    await _firestore.collection(collectionName).doc(documentId).update(transactionData);
  }

  // Soft delete a recurring transaction
  Future<void> softDeleteRecurringTransaction(String documentId) async {
    await _firestore.collection(collectionName).doc(documentId).update({
      'isDeleted': true,
      'lastEditedTime': DateTime.now().toIso8601String(),
    });
  }

  // Fetch recurring transactions
  Future<List<Map<String, dynamic>>> fetchRecurringTransactions(String userId) async {
    QuerySnapshot querySnapshot = await _firestore.collection(collectionName)
        .where('userId', isEqualTo: userId)
        .where('isDeleted', isEqualTo: false) // Fetch only active transactions
        .get();

    return querySnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  void updateScheduledNotifications() async {
    for (var transaction in recurringTransactionsNotifier.value.values) {

      //remove any already outdated notifications
      var payload = await NotificationManager().getNotificationPayload(transaction['docKey']);
      if (payload != null) {
        DateTime notificationTime = DateTime.parse(payload['notificationTime']);
        if (notificationTime.isBefore(DateTime.now())) {
          int? existingNotificationId = await NotificationManager().findNotificationId(transaction['docKey']);
          if (existingNotificationId != null) {
            await flutterLocalNotificationsPlugin.cancel(existingNotificationId);
          }
        }
      }

      if (transaction['scheduleReminder']) {

        //check if access is given for notifications
        bool permissionsGranted = await NotificationManager().requestPermissions();
        if (Platform.isAndroid) {
          await NotificationManager().requestBatteryOptimization();
        }
        if (!permissionsGranted) {
          return;
        }

        DateTime dueDate = DateTime.parse(transaction['dueDate']);
        TimeOfDay dueTime = parseTimeOfDay(transaction['dueTime']);

        // Merge due date and due time
        DateTime fullDueDateTime = DateTime(
          dueDate.year,
          dueDate.month,
          dueDate.day,
          dueTime.hour,
          dueTime.minute,
        );

        DateTime notificationTime = NotificationManager().calculateNotificationTime(
            dueDate,
            dueTime,
            transaction['notificationDaysBefore'],
            transaction['notificationHoursBefore'],
            transaction['notificationMinutesBefore']
        );

        // Await the result of notificationExists
        bool doesExist = await NotificationManager().notificationExists(transaction['docKey']);

        if (transaction['paidThisMonth'] == true) {
          // Calculate the next due date
          fullDueDateTime = NotificationManager().calculateNextDueDate(fullDueDateTime, transaction['frequency']);

          // Update the due date in Firestore
          await updateRecurringTransactionDate(transaction['docKey'], fullDueDateTime);
        }

        if (fullDueDateTime.isBefore(DateTime.now())) {
          if (transaction['paidThisMonth'] == false) {
            //Schedule Notification saying its overdue
            var payload = await NotificationManager().getNotificationPayload(transaction['docKey']);
            if (payload != null) {
              if (payload['type'].toString() != 'overdue') {
                int? existingNotificationId = await NotificationManager().findNotificationId(transaction['docKey']);
                if (existingNotificationId != null) {
                  await flutterLocalNotificationsPlugin.cancel(existingNotificationId);
                }

                //schedule it
                DateTime nextDayReminder = DateTime.now().add(const Duration(days: 1));
                NotificationManager().scheduleNotification(transaction, nextDayReminder, "overdue");
              }
            } else {
              //schedule it
              DateTime nextDayReminder = DateTime.now().add(const Duration(days: 1));
              NotificationManager().scheduleNotification(transaction, nextDayReminder, "overdue");
            }
          }
        } else {
          //clearAllNotifications();
          if (!doesExist) {
            NotificationManager().scheduleNotification(transaction, notificationTime, "normal");
          } else {
            // Retrieve the notification time asynchronously and then compare
            var payload = await NotificationManager().getNotificationPayload(transaction['docKey']);
            String? existingNotificationTimeString = payload?['notificationTime'];
            DateTime? existingNotificationTime = existingNotificationTimeString != null ? DateTime.tryParse(existingNotificationTimeString) : null;

            if (existingNotificationTime != null && existingNotificationTime.isAtSameMomentAs(notificationTime) && payload?['type'] == 'normal') {
              //ok
            } else {
              // The times do not match, delete the old notification and schedule a new one
              int? existingNotificationId = await NotificationManager().findNotificationId(transaction['docKey']);
              if (existingNotificationId != null) {
                await flutterLocalNotificationsPlugin.cancel(existingNotificationId);
              }
              NotificationManager().scheduleNotification(transaction, notificationTime, "normal");
            }
          }
        }
      } else {
        // Await the result of notificationExists
        bool doesExist = await NotificationManager().notificationExists(transaction['docKey']);

        if (doesExist) {
          int? existingNotificationId = await NotificationManager().findNotificationId(transaction['docKey']);
          if (existingNotificationId != null) {
            await flutterLocalNotificationsPlugin.cancel(existingNotificationId);
          }
        }
      }
    }
  }

  Future<void> clearAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> updateRecurringTransactionDate(String transactionId, DateTime newDueDate) async {
    await _firestore.collection(collectionName).doc(transactionId).update({
      'dueDate': newDueDate.toIso8601String(),
      'lastEditedTime': DateTime.now().toIso8601String(),
      'paidThisMonth': false
    });
  }

  Future<void> payRecurringTransaction(String transactionId) async {
    await _firestore.collection(collectionName).doc(transactionId).update({
      'lastEditedTime': DateTime.now().toIso8601String(),
      'paidThisMonth': true
    });
  }

  TimeOfDay parseTimeOfDay(String timeString) {
    final hourMinute = timeString.split(':');
    return TimeOfDay(hour: int.parse(hourMinute[0]), minute: int.parse(hourMinute[1]));
  }
}
