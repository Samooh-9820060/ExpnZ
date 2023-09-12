import 'dart:convert';

import 'package:expnz/models/AccountsModel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  Future<void> deleteTransactionsByCategoryName(int categoryId, String? searchText, BuildContext context) async {
    final db = TransactionsDB();
    final categoriesDb = CategoriesDB();

    Future<String> getCategoryNameById(int id) async {
      Map<String, dynamic>? category = await categoriesDb.getSelectedCategory(id);
      return category != null ? category[CategoriesDB.columnName] : '';
    }

    final String categoryName = await getCategoryNameById(categoryId);  // Get category name based on its ID


    // Iterate through transactions to find those with the specified category
    for (var transaction in transactions) {
      final List<dynamic> categories = jsonDecode(transaction[TransactionsDB.columnCategories] ?? '[]');

      // Check if the transaction has the specified category
      bool hasCategory = categories.any((category) => category['name'] == categoryName);

      if (hasCategory) {
        int transactionId = transaction[TransactionsDB.columnId]; // Assuming the column for id is named 'id'

        // If the transaction has more than one category, just remove this one
        if (categories.length > 1) {
          categories.removeWhere((category) => category['name'] == categoryName);
        }
        // If the transaction only has this category, set it to "Unassigned"
        else {
          // Create a new map from the existing map
          Map<String, dynamic> newCategory = Map.from(categories[0]);
          newCategory['name'] = 'Unassigned';
          newCategory['icon'] = Icons.help_outline.codePoint;

          // Replace the original map with the modified map
          categories[0] = newCategory;
        }

        // Create a mutable copy of the transaction
        Map<String, dynamic> mutableTransaction = Map<String, dynamic>.from(transaction);

        // Update the mutable copy of the transaction
        mutableTransaction[TransactionsDB.columnCategories] = jsonEncode(categories);

        // Use the mutable copy in the updateTransaction method
        await db.updateTransaction(transactionId, mutableTransaction);
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
    print('all transactions');
    print(transList);

    for (var transaction in transList) {
      bool shouldInclude = true;


      print(transaction);

      print('checking dates');
      // Date-based filtering
      if ((fromDate != null && toDate != null) && shouldInclude == true) {
        DateTime transactionDate = DateTime.parse(transaction['date']);
        if ((transactionDate.isAfter(fromDate) && transactionDate.isBefore(toDate))|| transactionDate == fromDate || transactionDate == toDate) {
          shouldInclude = true;
        } else {
          print('ex' + transactionDate.toString());
          shouldInclude = false;
        }
      }
      print(shouldInclude);

      print('checking include categories');
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
      print(shouldInclude);

      print('checking exclude categories');
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
      print(shouldInclude);

      print('checking accounts');
      // Account-based filtering
      if (includeAccounts != null && includeAccounts.contains(transaction[TransactionsDB.columnAccountId]) && shouldInclude == true) {
        shouldInclude = true;
      } else {
        shouldInclude = false;
      }
      print(shouldInclude);

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
    print('filtered transactions');
    print(filteredTransactions);
    notifyListeners();  // Important to notify listeners
  }

  double getTotalIncomeForAccount(int accountId) {
    return transactions
        .where((t) => t[TransactionsDB.columnAccountId] == accountId && t[TransactionsDB.columnType] == 'income')
        .map((t) => t[TransactionsDB.columnAmount] as double)
        .fold(0.0, (prev, amount) => prev + amount);
  }

  double getTotalExpenseForAccount(int accountId) {
    return transactions
        .where((t) => t[TransactionsDB.columnAccountId] == accountId && t[TransactionsDB.columnType] == 'expense')
        .map((t) => t[TransactionsDB.columnAmount] as double)
        .fold(0.0, (prev, amount) => prev + amount);
  }

  double getBalanceForAccount(int accountId) {
    return getTotalIncomeForAccount(accountId) - getTotalExpenseForAccount(accountId);
  }
}

