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
    if (encodedData != null) {
      final decodedData = json.decode(encodedData);
      if (decodedData is Map) {
        return decodedData.map((key, value) {
          if (value is Map) {
            return MapEntry(key, value.cast<String, dynamic>());
          } else {
            // Handle the case where the value is not a Map
            // Depending on your application's needs, you might log this, throw an exception, etc.
            return MapEntry(key, <String, dynamic>{});
          }
        });
      } else {
        // Handle the case where decodedData is not a Map
        // Log, throw an exception, etc.
        return null;
      }
    } else {
      return null;
    }
  }

  Future<bool> insertTransaction(Map<String, dynamic> data) async {
    String userUid = FirebaseAuth.instance.currentUser!.uid;
    data[uid] = userUid;

    FirebaseFirestore firestore = FirebaseFirestore.instance;

    return firestore.runTransaction((transaction) async {
      // Add the new transaction
      await firestore.collection(collectionName).add(data);
      return true;

    }).catchError((error) {
      print("Transaction failed: $error");
      return false;
    });
  }

  Future<bool> insertTransactions(List<Map<String, dynamic>> transactions) async {
    String userUid = FirebaseAuth.instance.currentUser!.uid;
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Create a write batch
    WriteBatch batch = firestore.batch();

    for (var data in transactions) {
      // Set user UID for each transaction
      data[uid] = userUid;

      // Create a new document reference for each transaction
      DocumentReference docRef = firestore.collection(collectionName).doc();
      batch.set(docRef, data);
    }

    // Commit the batch
    return batch.commit().then((_) {
      print("Batch write successful");
      return true;
    }).catchError((error) {
      print("Batch write failed: $error");
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
    await _firestore.collection(collectionName).doc(documentId).delete();

    // Update the local cache by removing the deleted transaction
    final currentTransactions = transactionsNotifier.value ?? {};
    if (currentTransactions.containsKey(documentId)) {
      currentTransactions.remove(documentId);
      transactionsNotifier.value = currentTransactions;
    }
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


  /*Future<DocumentSnapshot> getSelectedCategory(String documentId) async {
    return await _firestore.collection(collectionName).doc(documentId).get();
  }*/

  //Retrieve income expense functions
  /****************************************************************************************/
  // Function to calculate total income and expense for a given account ID
  Future<Map<String, double>> getTotalIncomeAndExpenseForAccount(String accountId) async {
    final transactions = await getLocalTransactions();
    double totalIncome = 0.0;
    double totalExpense = 0.0;

    if (transactions != null) {
      transactions.forEach((docId, data) {
        if (data[transactionAccountId] == accountId) {
          double amount = double.tryParse(data[transactionAmount].toString()) ?? 0.0;
          if (data[transactionType] == 'income') {
            totalIncome += amount;
          } else if (data[transactionType] == 'expense') {
            totalExpense += amount;
          }
        }
      });
    }
    return {'totalIncome': totalIncome, 'totalExpense': totalExpense};
  }

  Future<Map<String, Map<String, double>>> getIncomeAndExpenseByAccountForCategory(String categoryId) async {
    final transactions = await getLocalTransactions();

    Map<String, Map<String, double>> accountTotals = {};

    if (transactions != null) {
      transactions.forEach((docId, data) {
        var transactionCategories = data[transactionCategoryIDs];
        String accountId = data[transactionAccountId];

        if (transactionCategories != null && transactionCategories.contains(categoryId)) {

          double amount = double.tryParse(data[transactionAmount].toString()) ?? 0.0;

          accountTotals.putIfAbsent(accountId, () => {'totalIncome': 0.0, 'totalExpense': 0.0});

          if (data[transactionType] == 'income') {
            accountTotals[accountId]!['totalIncome'] = (accountTotals[accountId]!['totalIncome'] ?? 0.0) + amount;
          } else if (data[transactionType] == 'expense') {
            accountTotals[accountId]!['totalExpense'] = (accountTotals[accountId]!['totalExpense'] ?? 0.0) + amount;
          }
        }
      });
    }

    return accountTotals;
  }


  Future<Map<String, Map<String, double>>> getIncomeExpenseForAccountsInCategory(String categoryId) async {
    final transactionsData = transactionsNotifier.value;
    Map<String, Map<String, double>> accountTotals = {};

    if (transactionsData != null) {
      for (var transaction in transactionsData.values) {
        var transactionCategories = transaction[transactionCategoryIDs];
        if (transactionCategories != null && transactionCategories.contains(categoryId)) {
          String accountId = transaction[transactionAccountId];
          double amount = double.tryParse(transaction[transactionAmount].toString()) ?? 0.0;

          accountTotals.putIfAbsent(accountId, () => {'totalIncome': 0.0, 'totalExpense': 0.0});

          if (transaction[transactionType] == 'income') {
            accountTotals[accountId]!['totalIncome'] =
                (accountTotals[accountId]!['totalIncome'] ?? 0.0) + amount;
          } else if (transaction[transactionType] == 'expense') {
            accountTotals[accountId]!['totalExpense'] =
                (accountTotals[accountId]!['totalExpense'] ?? 0.0) + amount;
          }
        }
      }
    }

    return accountTotals;
  }

  Future<double> getTotalExpenseForCategory(String categoryId) async {
    final transactionsData = transactionsNotifier.value;
    double totalExpense = 0.0;

    if (transactionsData != null) {
      transactionsData.forEach((docId, transaction) {
        var transactionCategories = transaction[transactionCategoryIDs];
        if (transactionCategories != null && transactionCategories.contains(categoryId)) {
          if (transaction[transactionType] == 'expense') {
            double amount = double.tryParse(transaction[transactionAmount].toString()) ?? 0.0;
            totalExpense += amount;
          }
        }
      });
    }

    return totalExpense;
  }


  // Function to filter transactions on search screen
  Future<List<Map<String, dynamic>>> filterTransactions(String searchText, [List<String>? accountIds]) async {
    final transactionsData = transactionsNotifier.value ?? {};
    final categoriesData = categoriesNotifier.value ?? {};
    List<Map<String, dynamic>> filteredTransactions = [];

    String lowerCaseSearchText = searchText.toLowerCase();

    transactionsData.forEach((docId, transaction) {
      bool matchesSearchText = transaction['name'].toString().toLowerCase().contains(lowerCaseSearchText) ||
          transaction['description'].toString().toLowerCase().contains(lowerCaseSearchText) ||
          transaction['amount'].toString().contains(searchText);

      // Check if any category associated with the transaction matches the search text
      bool matchesCategory = false;
      if (transaction.containsKey('categories')) {
        List<String> categoryIds = transaction['categories'].split(',');
        for (var categoryId in categoryIds) {
          var categoryName = categoriesData[categoryId]?['name'] ?? '';
          if (categoryName.toLowerCase().contains(lowerCaseSearchText)) {
            matchesCategory = true;
            break;
          }
        }
      }

      if ((accountIds == null || accountIds.contains(transaction['account_id'])) &&
          (matchesSearchText || matchesCategory)) {
        // Create a new map for the transaction and include the document ID
        Map<String, dynamic> transactionWithId = Map.from(transaction);
        transactionWithId['documentId'] = docId; // Add the document ID
        filteredTransactions.add(transactionWithId);
      }
    });

    return filteredTransactions;
  }
}