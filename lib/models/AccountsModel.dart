import 'package:flutter/material.dart';

import '../database/AccountsDB.dart';

class AccountsModel extends ChangeNotifier {
  final db = AccountsDB();
  List<Map<String, dynamic>> accounts = [];

  Future<void> fetchAccounts() async {
    accounts = await db.getAllAccounts();
    notifyListeners();
  }

  Future<void> deleteAccount(int accountId) async {
    await db.deleteAccount(accountId);
    await fetchAccounts();  // Refresh the categories
    notifyListeners();  // Notify the UI to rebuild
  }

  Future<String> getAccountNameById(int id) async {
    final account = await db.getSelectedAccount(id);
    return account != null ? account[AccountsDB.accountName].toString() : 'Unknown';
  }
}

