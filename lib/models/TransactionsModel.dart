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
      List<int>? includeAccounts]
      ) async {

    // Use transactionsToFilter if provided, otherwise use the existing transactions list
    final transList = transactionsToFilter ?? transactions;

    List<Map<String, dynamic>> tempTransactions = [];

    for (var transaction in transList) {
      bool shouldInclude = true;



      // Date-based filtering
      if ((fromDate != null && toDate != null) && shouldInclude == true) {
        DateTime transactionDate = DateTime.parse(transaction['date']);
        if ((transactionDate.isAfter(fromDate) && transactionDate.isBefore(toDate))|| transactionDate == fromDate || transactionDate == toDate) {
          shouldInclude = true;
        } else {
          shouldInclude = false;
        }
      }

      // Category-based filtering
      if (includeCategories != null && shouldInclude == true) {
        if (transaction.containsKey('categories')) {
          final List<int> categoryIds = List<int>.from(
              (transaction['categories'] as String)
                  .split(',')
                  .map((e) => int.tryParse(e.trim()) ?? 0)
          );

          for (int categoryId in categoryIds) {
            if (includeCategories.contains(categoryId)) {
              shouldInclude = true;
            }
          }
        }
      }

      if (excludeCategories != null && shouldInclude == true) {
        if (transaction.containsKey('categories')) {
          final List<int> categoryIds = List<int>.from(
              (transaction['categories'] as String)
                  .split(',')
                  .map((e) => int.tryParse(e.trim()) ?? 0)
          );

          for (int categoryId in categoryIds) {
            if (excludeCategories.contains(categoryId)) {
              shouldInclude = false;  // Exclude this transaction
            }
          }
        }
      }

      // Account-based filtering
      if (includeAccounts != null && includeAccounts.contains(transaction[TransactionsDB.columnAccountId]) && shouldInclude == true) {
        shouldInclude = true;
      } else {
        shouldInclude = false;
      }

      // Text-based filtering
      if (searchText != null && searchText.isNotEmpty) {
        if (transaction.containsKey('categories')) {
          final List<int> categoryIds = List<int>.from(
              (transaction['categories'] as String)
                  .split(',')
                  .map((e) => int.tryParse(e.trim()) ?? 0)
          );

          for (int categoryId in categoryIds) {
            var category = await Provider.of<CategoriesModel>(context, listen: false).getCategoryById(categoryId);
            if (category != null && (category[CategoriesDB.columnName] as String).toLowerCase().contains(searchText)) {
              shouldInclude = true;
            }
          }
        }

        if (!shouldInclude && transaction.values.any((element) => element.toString().toLowerCase().contains(searchText))) {
          shouldInclude = true;
        }

        if (transaction.containsKey(TransactionsDB.columnAccountId)) {
          int accountId = transaction[TransactionsDB.columnAccountId];
          // Access the account name through the other Provider model
          String accountName = await Provider.of<AccountsModel>(context, listen: false).getAccountNameById(accountId);

          if (accountName.toLowerCase().contains(searchText)) {
            shouldInclude = true;
          }
        }
      }

      if (shouldInclude) {
        tempTransactions.add(transaction);
      }
    }

    filteredTransactions = tempTransactions;
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

