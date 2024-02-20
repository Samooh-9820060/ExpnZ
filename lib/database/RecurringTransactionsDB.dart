import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/global.dart';

class RecurringTransactionDB {
  static const String collectionName = 'recurringTransactions'; // Collection name
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
        var data = doc.data() as Map<String, dynamic>;
        newTransactionsData[doc.id] = data;
      }

      if (newTransactionsData.isNotEmpty) {
        await cacheRecurringTransactionsLocally(newTransactionsData);
      } else {
        await loadRecurringTransactionsFromLocal();
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


}
