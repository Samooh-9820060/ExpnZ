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

  Future<void> filterTransactions(BuildContext context, String searchText) async {
    if (searchText.isNotEmpty) {
      List<Map<String, dynamic>> tempTransactions = [];
      for (var transaction in transactions) {
        bool shouldInclude = false;

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
              break;
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

        if (shouldInclude) {
          tempTransactions.add(transaction);
        }
      }
      filteredTransactions = tempTransactions;
    } else {
      filteredTransactions = [];
    }
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

