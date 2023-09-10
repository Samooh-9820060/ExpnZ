import 'package:expnz/models/AccountsModel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/TransactionsDB.dart';

class TransactionsModel extends ChangeNotifier {
  final db = TransactionsDB();
  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> filteredTransactions = [];

  Future<void> fetchTransactions() async {
    transactions = await db.getAllTransaction();
    notifyListeners();
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
        bool shouldInclude = transaction.values.any((element) => element.toString().toLowerCase().contains(searchText));

        if (transaction.containsKey(TransactionsDB.columnAccountId)) {
          int accountId = transaction[TransactionsDB.columnAccountId];

          // Access the account name through the other Provider model
          String accountName = await Provider.of<AccountsModel>(context, listen: false).getAccountNameById(accountId);

          if (accountName.toLowerCase().contains(searchText)) {
            shouldInclude = true;
          }
        }

        if (transaction.values.any((element) => element.toString().toLowerCase().contains(searchText))) {
          shouldInclude = true;
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

