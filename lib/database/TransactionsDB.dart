import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expnz/utils/global.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TransactionsDB {
  static const String collectionName = 'transactions';

  static const String uid = 'uid';
  static const String transactionType = 'type';
  static const String transactionName = 'name';
  static const String transactionDescription = 'description';
  static const String transactionAmount = 'amount';
  static const String transactionActualPrice = 'actual_price';
  static const String transactionBalance = 'wallet_balance';
  static const String transactionDate = 'date';
  static const String transactionTime = 'time';
  static const String transactionAccountId = 'account_id';
  static const String transactionCategoryIDs = 'categories';
  static const String lastEditedTime = 'lastEditedTime';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void listenToTransactionChanges(String userUid) async {
    final prefs = await SharedPreferences.getInstance();
    // Get the last sync time
    String? lastSyncTimeStr = prefs.getString('lastSyncTime');
    // Ensure that the format of lastSyncTimeStr is consistent with the one in Firestore
    DateTime lastSyncTime = lastSyncTimeStr != null
        ? DateTime.parse(lastSyncTimeStr)
        : DateTime.fromMillisecondsSinceEpoch(0);

    String formattedLastSyncTime = _formatDateTimeForFirestore(lastSyncTime);

    print('Last Sync Time: $formattedLastSyncTime');

    _firestore.collection(collectionName)
        .where(uid, isEqualTo: userUid)
        .where('lastEditedTime', isGreaterThan: formattedLastSyncTime)
        .snapshots()
        .listen((snapshot) async {
      print('Documents fetched: ${snapshot.docs.length}');
      final Map<String, Map<String, dynamic>> newTransactionsData = {};

      for (var doc in snapshot.docs) {
        newTransactionsData[doc.id] = doc.data() as Map<String, dynamic>;
      }

      if (newTransactionsData.isNotEmpty) {
        await cacheTransactionsLocally(newTransactionsData);
        // Store the current time as the last sync time
        await prefs.setString('lastSyncTime', DateTime.now().toIso8601String());
      } else {
        await loadTransactionsFromLocal();
      }
    }, onError: (error) {
      print('Error fetching transactions: $error');
    });
  }

  String _formatDateTimeForFirestore(DateTime dateTime) {
    // Format the DateTime object to an ISO 8601 string
    return dateTime.toIso8601String();
  }

  Future<void> loadTransactionsFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    String? encodedData = prefs.getString('userTransactions');
    if (encodedData != null) {
      Map<String, Map<String, dynamic>> transactionsData = Map<String, Map<String, dynamic>>.from(
        json.decode(encodedData) as Map<String, dynamic>,
      );

      print('Documents stored locally: ${transactionsData.length}');
      transactionsNotifier.value = transactionsData;
    }
  }

  Future<void> cacheTransactionsLocally(Map<String, Map<String, dynamic>> newTransactionsData) async {
    final prefs = await SharedPreferences.getInstance();
    // Fetch existing transactions
    String? existingData = prefs.getString('userTransactions');
    Map<String, Map<String, dynamic>> existingTransactions = existingData != null
        ? Map<String, Map<String, dynamic>>.from(json.decode(existingData))
        : {};

    // Merge new transactions with existing ones
    existingTransactions.addAll(newTransactionsData);

    // Cache the merged transactions
    String encodedData = json.encode(existingTransactions);
    await prefs.setString('userTransactions', encodedData);
    transactionsNotifier.value = existingTransactions;

    print('Cached locally: ${existingTransactions.length} transactions');
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

  Future<void> deleteCategoryFromTransactions(String categoryId) async {
    String userUid = FirebaseAuth.instance.currentUser!.uid;

    // Retrieve all transactions
    QuerySnapshot querySnapshot = await _firestore.collection(collectionName)
        .where(uid, isEqualTo: userUid)
        .get();

    // Process each transaction to remove the category
    for (var doc in querySnapshot.docs) {
      Map<String, dynamic> transaction = doc.data() as Map<String, dynamic>;
      String categoriesString = transaction[transactionCategoryIDs];
      List<String> categories = categoriesString.split(', ');

      // Check if the category is in the transaction
      if (categories.contains(categoryId)) {
        // Remove the category
        categories.remove(categoryId);

        // Update the transaction categories string
        String updatedCategoriesString = categories.join(', ');

        // Handle the case where all categories are removed
        if (categories.isEmpty) {
          // Optionally set to a default value or leave it empty
        }

        // Update the transaction
        await _firestore.collection(collectionName).doc(doc.id).update({transactionCategoryIDs: updatedCategoriesString});
      }
    }
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
    final currentTransactions = transactionsNotifier.value;
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
    final transactions = transactionsNotifier.value;
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
  Future<Map<String, Map<String, double>>> getTotalIncomeAndExpenseForAccounts(List<String> accountIds) async {
    final transactions = await getLocalTransactions();
    Map<String, Map<String, double>> totals = {};

    for (var accountId in accountIds) {
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

      totals[accountId] = {'totalIncome': totalIncome, 'totalExpense': totalExpense};
    }

    return totals;
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

    if (transactionsData != null && transactionsData.isNotEmpty) {
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


  Future<List<Map<String, dynamic>>> filterTransactions(
      String? searchText,
      [List<String>? accountIds,
        DateTime? startDate,
        DateTime? endDate,
        List<Map<String, dynamic>>? includeCategories,
        List<Map<String, dynamic>>? excludeCategories,
      int limit = 30]) async {

    final transactionsData = transactionsNotifier.value ?? {};
    final categoriesData = categoriesNotifier.value ?? {};
    List<Map<String, dynamic>> filteredTransactions = [];
    int count = 0;

    String lowerCaseSearchText = "";
    if (searchText != null) {
      lowerCaseSearchText = searchText.toLowerCase();
    }

    transactionsData.forEach((docId, transaction) {
      // Check if the limit is reached
      if (count >= limit) {
        return; // Exit the forEach loop
      }

      bool matchesSearchText = true;
      if (searchText != null) {
        matchesSearchText = transaction['name'].toString().toLowerCase().contains(lowerCaseSearchText) ||
            transaction['description'].toString().toLowerCase().contains(lowerCaseSearchText) ||
            transaction['amount'].toString().contains(searchText);
      }

      // Filter by category
      List<String> transactionCategories = transaction.containsKey('categories') ? transaction['categories'].split(',') : [];
      bool matchesIncludeCategories = includeCategories == null || includeCategories.isEmpty ||
          transactionCategories.any((categoryId) => includeCategories.any((category) => category['id'] == categoryId));
      bool matchesExcludeCategories = excludeCategories == null || excludeCategories.isEmpty ||
          transactionCategories.every((categoryId) => !excludeCategories.any((category) => category['id'] == categoryId));

      // Filter by date range
      DateTime transactionDate = DateTime.parse(transaction['date']);
      bool isWithinDateRange = (startDate == null || transactionDate.isAfter(startDate)) &&
          (endDate == null || transactionDate.isBefore(endDate));

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
          (matchesSearchText || matchesCategory) &&
          matchesIncludeCategories &&
          matchesExcludeCategories &&
          isWithinDateRange) {
        Map<String, dynamic> transactionWithId = Map.from(transaction);
        transactionWithId['documentId'] = docId; // Add the document ID
        filteredTransactions.add(transactionWithId);
      }
    });

    // Sort the transactions based on the combined date and time
    filteredTransactions.sort((a, b) {
      DateTime dateTimeA = DateTime.parse(a['date'] + " " + a['time']);
      DateTime dateTimeB = DateTime.parse(b['date'] + " " + b['time']);
      return dateTimeB.compareTo(dateTimeA); // For descending order, use dateTimeB.compareTo(dateTimeA)
    });

    return filteredTransactions;
  }
}