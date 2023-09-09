import 'package:flutter/material.dart';

import '../database/TransactionsDB.dart';

class TransactionsModel extends ChangeNotifier {
  final db = TransactionsDB();
  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> filteredTransactions = [];

  Future<void> fetchTransactions() async {
    transactions = await db.getAllTransaction();
    notifyListeners();
  }

  Future<void> deleteTransactions(int transactionId, String? searchText) async {
    await db.deleteTransaction(transactionId);
    await fetchTransactions();  // Refresh the categories
    if (searchText != null) {
      filterTransactions(searchText!);
    }
    notifyListeners();  // Notify the UI to rebuild
  }

  void filterTransactions(String searchText) {
    if (searchText.isNotEmpty) {
      List<Map<String, dynamic>> tempTransactions = [];
      for (var transaction in transactions) {
        if (transaction.values.any((element) => element.toString().toLowerCase().contains(searchText))) {
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

