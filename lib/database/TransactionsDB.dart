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

    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentReference userDocRef = firestore.collection(usersCollection).doc(userUid);

    return firestore.runTransaction((transaction) async {
      // Get the user's account data
      DocumentSnapshot userSnapshot = await transaction.get(userDocRef);
      Map<String, dynamic> userData = userSnapshot.data() as Map<String, dynamic>;

      // Update totalIncome or totalExpense based on transaction type for the accounts
      String accountId = data[transactionAccountId];
      double transactionAmountDouble = (data[transactionAmount] as num).toDouble();

      double totalIncome = (userData['accounts'][accountId]['totalIncome'] ?? 0).toDouble();
      double totalExpense = (userData['accounts'][accountId]['totalExpense'] ?? 0).toDouble();

      if (data[transactionType] == "income") {
        totalIncome += transactionAmountDouble;
        userData['accounts'][accountId]['totalIncome'] = totalIncome;
      } else if (data[transactionType] == "expense") {
        totalExpense += transactionAmountDouble;
        userData['accounts'][accountId]['totalExpense'] = totalExpense;
      }

      // Update totalIncome or totalExpense based on transaction type for categories
      List<String> categoryIds = data[transactionCategoryIDs].split(', ');
      for (String categoryId in categoryIds) {
        // Check if the category ID exists in user's data
        if (!userData['categories'].containsKey(categoryId)) {
          // Initialize the category with default values
          userData['categories'][categoryId] = {
            accountId: {'totalIncome': 0.0, 'totalExpense': 0.0}
          };
        }

        Map<String, dynamic> categoryData = userData['categories'][categoryId];

        // Check if the account ID exists within the category
        if (!categoryData.containsKey(accountId)) {
          categoryData[accountId] = {'totalIncome': 0.0, 'totalExpense': 0.0};
        }

        // Update totalIncome or totalExpense
        double categoryTotalIncome = (categoryData[accountId]['totalIncome'] ?? 0).toDouble();
        double categoryTotalExpense = (categoryData[accountId]['totalExpense'] ?? 0).toDouble();

        if (data[TransactionsDB.transactionType] == "income") {
          categoryTotalIncome += transactionAmountDouble;
          categoryData[accountId]['totalIncome'] = categoryTotalIncome;
        } else if (data[TransactionsDB.transactionType] == "expense") {
          categoryTotalExpense += transactionAmountDouble;
          categoryData[accountId]['totalExpense'] = categoryTotalExpense;
        }

        // Update the category data in userData
        userData['categories'][categoryId] = categoryData;
      }


      // Update the user's document
      transaction.set(userDocRef, userData, SetOptions(merge: true));

      // Add the new transaction
      await firestore.collection(collectionName).add(data);

      return true;
    }).catchError((error) {
      print("Transaction failed: $error");
      return false;
    });
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