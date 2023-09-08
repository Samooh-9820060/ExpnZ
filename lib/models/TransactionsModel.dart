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

  Future<void> deleteTransactions(int transactionId) async {
    await db.deleteTransaction(transactionId);
    await fetchTransactions();  // Refresh the categories
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
}

