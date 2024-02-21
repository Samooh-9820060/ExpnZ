import 'dart:convert';

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
      print('Error listening to recurring transactions changes: $error');
    });
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
        deleteNotification(key);
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
      if (transaction['scheduleReminder']) {
        DateTime dueDate = DateTime.parse(transaction['dueDate']);
        TimeOfDay dueTime = parseTimeOfDay(transaction['dueTime']);

        if (dueDate.isBefore(DateTime.now())) {
          if (transaction['paidThisMonth'] == true) {
            // Calculate the next due date
            dueDate = calculateNextDueDate(dueDate, transaction['frequency']);

            // Update the due date in Firestore
            await updateRecurringTransactionDate(transaction['id'], dueDate);
          } else {
            // Handle overdue payments
          }
        }

        DateTime notificationTime = calculateNotificationTime(
            dueDate,
            dueTime,
            transaction['notificationDaysBefore'],
            transaction['notificationHoursBefore'],
            transaction['notificationMinutesBefore']
        );

        // Await the result of notificationExists
        bool doesExist = await NotificationManager().notificationExists(transaction['docKey']);
        //clearAllNotifications();
        if (!doesExist) {
          NotificationManager().scheduleNotification(transaction, notificationTime);
        } else {
          // Retrieve the notification time asynchronously and then compare
          String? existingNotificationTimeString = await NotificationManager().getNotificationTime(transaction['docKey']);
          DateTime? existingNotificationTime = existingNotificationTimeString != null ? DateTime.tryParse(existingNotificationTimeString) : null;

          if (existingNotificationTime != null && existingNotificationTime.isAtSameMomentAs(notificationTime)) {

          } else {
            // The times do not match, delete the old notification and schedule a new one
            int? existingNotificationId = await NotificationManager().findNotificationId(transaction['docKey']);
            if (existingNotificationId != null) {
              await flutterLocalNotificationsPlugin.cancel(existingNotificationId);
            }
            NotificationManager().scheduleNotification(transaction, notificationTime);
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


  TimeOfDay parseTimeOfDay(String timeString) {
    final hourMinute = timeString.split(':');
    return TimeOfDay(hour: int.parse(hourMinute[0]), minute: int.parse(hourMinute[1]));
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
