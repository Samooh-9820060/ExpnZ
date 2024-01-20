import 'dart:convert';

import 'package:flutter/material.dart';

import '../database/AccountsDB.dart';

/*class AccountsModel extends ChangeNotifier {
  final db = AccountsDB();
  List<Map<String, dynamic>> accounts = [];

  Future<void> fetchAccounts() async {
    accounts = await db.getAllAccounts();
    notifyListeners();
  }

  Future<Map<int, String>> fetchAllAccountsAsMap() async {
    var allAccounts = await db.getAllAccounts();
    Map<int, String> accountsMap = {};

    for (var account in allAccounts) {
      int accountId = account[AccountsDB.accountId];
      String accountName = account[AccountsDB.accountName];
      accountsMap[accountId] = accountName;
    }

    return accountsMap;
  }

  Future<void> clearAccounts() async {
    final db = AccountsDB();
    await db.deleteAllAccounts();
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

  Future<Object> getAccountDetailsById(int id) async {
    final account = await db.getSelectedAccount(id);
    return account != null ? account : 'Unknown';
  }

  // function to get unique currency codes
  Future<Set<String>> getUniqueCurrencyCodes() async {
    await fetchAccounts();  // Ensure the latest accounts data is fetched
    Set<String> currencyCodes = {};

    for (var account in accounts) {
      String currencyJson = account[AccountsDB.accountCurrency];
      Map<String, dynamic> currencyData = jsonDecode(currencyJson);
      String code = currencyData['code'];
      currencyCodes.add(code);
    }

    return currencyCodes;
  }
}
*/
