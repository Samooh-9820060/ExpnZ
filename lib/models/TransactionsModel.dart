import 'package:flutter/material.dart';

import '../database/TransactionsDB.dart';

class TransactionsModel extends ChangeNotifier {
  final db = TransactionsDB();
  List<Map<String, dynamic>> transactions = [];

  Future<void> fetchTransactions() async {
    transactions = await db.getAllTransaction();
    notifyListeners();
  }

  Future<void> deleteTransactions(int transactionId) async {
    await db.deleteTransaction(transactionId);
    await fetchTransactions();  // Refresh the categories
    notifyListeners();  // Notify the UI to rebuild
  }
}

