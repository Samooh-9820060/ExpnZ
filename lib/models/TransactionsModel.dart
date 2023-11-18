import 'dart:convert';

import 'package:expnz/models/AccountsModel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/AccountsDB.dart';
import '../database/CategoriesDB.dart';
import '../database/TransactionsDB.dart';
import 'CategoriesModel.dart';

class TransactionsModel extends ChangeNotifier {
  final db = TransactionsDB();
  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> filteredTransactions = [];

  Future<void> fetchTransactions() async {
    transactions = await db.getAllTransaction();
    notifyListeners();
  }

  Future<void> clearTransactions() async {
    final db = TransactionsDB();
    await db.deleteAllTransactions();
    notifyListeners();
  }

  Future<void> deleteTransactionsByCategoryId(int categoryId, String? searchText, BuildContext context) async {
    final db = TransactionsDB();

    // Iterate through transactions to find those with the specified category
    for (var transaction in transactions) {

      // Extract category IDs and convert them to a list of strings
      List<dynamic> categoryIds = (transaction[TransactionsDB.columnCategories] ?? '')
          .split(',')
          .map((id) => id.trim())
          .toList();

      // Check if the transaction has the specified category
      if (categoryIds.contains(categoryId.toString())) {
        // Remove the categoryId from the list
        categoryIds.remove(categoryId.toString());

        // Convert the list back to a comma-separated string
        String updatedCategories = categoryIds.join(', ');

        // Create a mutable copy of the transaction
        Map<String, dynamic> mutableTransaction = Map<String, dynamic>.from(transaction);

        // Update the mutable copy of the transaction
        mutableTransaction[TransactionsDB.columnCategories] = updatedCategories;

        // Update the transaction in the database
        await db.updateTransaction(transaction[TransactionsDB.columnId], mutableTransaction);
      }
    }

    await fetchTransactions();

    if (searchText != null) {
      filterTransactions(context, searchText);
    }

    notifyListeners();  // Notify the UI to rebuild
  }

  Future<void> deleteTransactionsByAccountId(int accountId, String? searchText, BuildContext context) async {
    List<Map<String, dynamic>> transactionsToDelete = transactions.where((transaction) {
      return transaction[TransactionsDB.columnAccountId] == accountId;
    }).toList();

    for (var transaction in transactionsToDelete) {
      int transactionId = transaction[TransactionsDB.columnId];
      await db.deleteTransaction(transactionId);
    }

    await fetchTransactions(); // Refresh the transactions list

    if (searchText != null) {
      filterTransactions(context, searchText);
    }

    notifyListeners();  // Notify the UI to rebuild
  }


  Future<void> deleteTransactions(int transactionId, String? searchText, BuildContext context) async {
    await db.deleteTransaction(transactionId);
    await fetchTransactions();  // Refresh the categories
    if (searchText != null) {
      filterTransactions(context, searchText);
    }
    notifyListeners();  // Notify the UI to rebuild
  }

  Future<void> filterTransactions(
      BuildContext context,
      [String? searchText,
      List<Map<String, dynamic>>? transactionsToFilter,
      DateTime? fromDate,
      DateTime? toDate,
      List<int>? includeCategories,
      List<int>? excludeCategories,
      List<int>? includeAccounts,
      int batchSize = 100,
        bool isNewSearch = true,
      ]
      ) async {

    // Use transactionsToFilter if provided, otherwise use the existing transactions list
    final transList = transactionsToFilter ?? transactions;

    // Clear existing filtered transactions if it's a new search
    if (isNewSearch) {
      filteredTransactions.clear();
    }

    var categoriesModel = Provider.of<CategoriesModel>(context, listen: false);
    var accountsModel = Provider.of<AccountsModel>(context, listen: false);

    var categoriesMap = await categoriesModel.fetchAllCategoriesAsMap();
    var accountsMap = await accountsModel.fetchAllAccountsAsMap();

    int processedCount = 0;
    int i = filteredTransactions.length;

    while (processedCount < batchSize && i < transList.length) {
      var transaction = transList[i];
      bool shouldInclude = true;

      print(transaction);

      // Date-based filtering
      if (fromDate != null && toDate != null) {
        DateTime transactionDate = DateTime.parse(transaction['date']);
        shouldInclude = (transactionDate.isAfter(fromDate) && transactionDate.isBefore(toDate)) || transactionDate == fromDate || transactionDate == toDate;
      }
      print('date $shouldInclude');

      // Category-based filtering
      if (shouldInclude && transaction.containsKey('categories')) {
        final categoryIds = transaction['categories'].split(',').map((e) => int.tryParse(e.trim()) ?? 0).toSet();
        if (includeCategories != null) {
          shouldInclude = categoryIds.any((id) => includeCategories.contains(id));
        }
        if (shouldInclude && excludeCategories != null) {
          shouldInclude = !categoryIds.any((id) => excludeCategories.contains(id));
        }
      }

      print('category $shouldInclude');

      // Account-based filtering
      if (shouldInclude && includeAccounts != null) {
        int accountId = transaction[TransactionsDB.columnAccountId];
        shouldInclude = includeAccounts.contains(accountId);
      }

      print('account $shouldInclude');

      // Text-based filtering
      if (shouldInclude && searchText != null && searchText.isNotEmpty) {
        shouldInclude = transaction.values.any((element) => element.toString().toLowerCase().contains(searchText));
        if (!shouldInclude) {
          int categoryId = transaction[TransactionsDB.columnId];
          String? categoryName = categoriesMap[categoryId];
          if (categoryName != null && categoryName.toLowerCase().contains(searchText)) {
            shouldInclude = true;
          }
        }
        if (!shouldInclude) {
          int accountId = transaction[TransactionsDB.columnAccountId];
          String? accountName = accountsMap[accountId];
          if (accountName != null && accountName.toLowerCase().contains(searchText)) {
            shouldInclude = true;
          }
        }
      }

      print('txt $shouldInclude');

      if (shouldInclude) {
        filteredTransactions.add(transaction);
        processedCount++;
      }

      i++;
    }

    notifyListeners();  // Important to notify listeners
  }

  double getTotalIncomeForAccount(int accountId, {DateTime? startDate, DateTime? endDate}) {
    return transactions
        .where((t) {
      // Convert the date string to a DateTime object
      DateTime transactionDate = DateTime.parse(t[TransactionsDB.columnDate]);

      // Check if the transaction date falls within the specified range
      bool isAfterStartDate = startDate == null || transactionDate.isAfter(startDate) || transactionDate.isAtSameMomentAs(startDate);
      bool isBeforeEndDate = endDate == null || transactionDate.isBefore(endDate) || transactionDate.isAtSameMomentAs(endDate);

      return t[TransactionsDB.columnAccountId] == accountId &&
          t[TransactionsDB.columnType] == 'income' &&
          isAfterStartDate &&
          isBeforeEndDate;
    })
        .map((t) => t[TransactionsDB.columnAmount] as double)
        .fold(0.0, (prev, amount) => prev + amount);
  }


  double getTotalExpenseForAccount(int accountId, {DateTime? startDate, DateTime? endDate}) {
    return transactions
        .where((t) {
      // Convert the date string to a DateTime object
      DateTime transactionDate = DateTime.parse(t[TransactionsDB.columnDate]);

      // Check if the transaction date falls within the specified range
      bool isAfterStartDate = startDate == null || transactionDate.isAfter(startDate) || transactionDate.isAtSameMomentAs(startDate);
      bool isBeforeEndDate = endDate == null || transactionDate.isBefore(endDate) || transactionDate.isAtSameMomentAs(endDate);

      return t[TransactionsDB.columnAccountId] == accountId &&
          t[TransactionsDB.columnType] == 'expense' &&
          isAfterStartDate &&
          isBeforeEndDate;
    })
        .map((t) => t[TransactionsDB.columnAmount] as double)
        .fold(0.0, (prev, amount) => prev + amount);
  }


  Future<List<int>> _getAccountIdsForCurrency(String currencyCode) async {
    final accounts = await AccountsDB().getAllAccounts();
    return accounts
        .where((account) {
      final currencyData = jsonDecode(account[AccountsDB.accountCurrency]);
      return currencyData['code'] == currencyCode;
    })
        .map((account) => account[AccountsDB.accountId] as int)
        .toList();
  }

  Future<double> getTotalIncomeForCurrency(String currencyCode, {DateTime? startDate, DateTime? endDate}) async {
    List<int> accountIds = await _getAccountIdsForCurrency(currencyCode);
    double totalIncome = 0.0;

    for (int accountId in accountIds) {
      totalIncome += getTotalIncomeForAccount(accountId, startDate: startDate, endDate: endDate);
    }

    return totalIncome;
  }

  Future<double> getTotalExpenseForCurrency(String currencyCode, {DateTime? startDate, DateTime? endDate}) async {
    List<int> accountIds = await _getAccountIdsForCurrency(currencyCode);
    double totalExpense = 0.0;

    for (int accountId in accountIds) {
      totalExpense += getTotalExpenseForAccount(accountId, startDate: startDate, endDate: endDate);
    }

    return totalExpense;
  }
}

