import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expnz/utils/global.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TransactionsDB {
  static const String collectionName = 'transactions';
  static const String usersCollection = 'users';

  static const String uid = 'uid';
  static const String transactionType = 'type';
  static const String transactionName = 'name';
  static const String transactionDescription = 'description';
  static const String transactionAmount = 'amount';
  static const String transactionDate = 'date';
  static const String transactionTime = 'time';
  static const String transactionAccountId = 'account_id';
  static const String transactionCategoryIDs = 'categories';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void listenToTransactionChanges(String userUid) {
    _firestore.collection(collectionName)
        .where(uid, isEqualTo: userUid)
        .snapshots()
        .listen((snapshot) {
      final Map<String, Map<String, dynamic>> newTransactionsData = {};

      // Add all existing accounts to the new map
      for (var doc in snapshot.docs) {
        newTransactionsData[doc.id] = doc.data() as Map<String, dynamic>;
      }

      // Check and remove any deleted accounts from the local cache
      final currentTransactions = transactionsNotifier.value ?? {};
      for (var docId in currentTransactions.keys) {
        if (!newTransactionsData.containsKey(docId)) {
          newTransactionsData.remove(docId);
        }
      }

      cacheTransactionsLocally(newTransactionsData);
    });
  }

  Future<void> cacheTransactionsLocally(Map<String, Map<String, dynamic>> transactionsData) async {
    final prefs = await SharedPreferences.getInstance();
    String encodedData = json.encode(transactionsData);
    await prefs.setString('userTransactions', encodedData);
    transactionsNotifier.value = transactionsData;
  }

  Future<Map<String, Map<String, dynamic>>?> getLocalTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    String? encodedData = prefs.getString('userTransactions');
    return encodedData != null ? json.decode(encodedData) as Map<String, Map<String, dynamic>> : null;
  }

  Future<bool> insertTransaction(Map<String, dynamic> data) async {
    String userUid = FirebaseAuth.instance.currentUser!.uid;
    data[uid] = userUid;

    // Add the new account to the accounts collection
    try {
      DocumentReference transactionsRef = await _firestore.collection(collectionName).add(data);
      return true;
      // Initialize account-specific aggregate data under the user's document
      /*await _firestore.collection(usersCollection).doc(userUid).set({
      'accounts': {
        data.id: {
          'totalIncome': 0.0,
          'totalExpense': 0.0,
        }
      }
    }, SetOptions(merge: true));*/
    } catch (e){
      return false;
    }
  }

  // Deletes all categories for the current user
  Future<void> deleteAllTransactions() async {
    String userUid = FirebaseAuth.instance.currentUser!.uid;
    var snapshot = await _firestore.collection(collectionName)
        .where(uid, isEqualTo: userUid)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> deleteTransaction(String documentId) async {
    String userUid = FirebaseAuth.instance.currentUser!.uid;
    await _firestore.collection(collectionName).doc(documentId).delete();

    // Update the user's document to remove the account's aggregate data
    /*await _firestore.collection(usersCollection).doc(userUid).update({
      'categories.$documentId': FieldValue.delete(),
    });*/
  }

  //method to update transaction by its id
  Future<bool> updateTransaction(String documentId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(collectionName).doc(documentId).update(data);
      return true;
    } catch (e) {
      return false;
    }
  }


  Future<DocumentSnapshot> getSelectedCategory(String documentId) async {
    return await _firestore.collection(collectionName).doc(documentId).get();
  }
}