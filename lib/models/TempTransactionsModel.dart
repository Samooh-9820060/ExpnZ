import 'package:expnz/database/TempTransactionsDB.dart';
import 'package:flutter/material.dart';

class TempTransactionsModel extends ChangeNotifier {
  final db = TempTransactionsDB();
  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> filteredTransactions = [];

  Future<void> fetchTransactions() async {
    //transactions = await db.getAllTransaction();
    //notifyListeners();
  }

  Future<void> clearTransactions() async {
    final db = TempTransactionsDB();
    await db.deleteAllTransactions();
    notifyListeners();
  }

  Future<void> deleteTransactions(int transactionId, String? searchText, BuildContext context) async {
    await db.deleteTransaction(transactionId);
    await fetchTransactions();  // Refresh the categories
    notifyListeners();  // Notify the UI to rebuild
  }
}

