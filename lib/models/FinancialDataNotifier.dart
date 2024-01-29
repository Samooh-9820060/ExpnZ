import 'dart:convert';

import 'package:flutter/material.dart';

import '../database/AccountsDB.dart';
import '../utils/global.dart';

class FinancialDataNotifier extends ChangeNotifier {
  Map<String, dynamic> _financialData = {};
  Map<String, dynamic> currencyMap = {};
  List<String> currencyCodes = [];
  bool _isLoading = false;

  Map<String, dynamic> get financialData => _financialData;
  bool get isLoading => _isLoading;

  void setFinancialData(Map<String, dynamic> newData) {
    _financialData = newData;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> loadFinancialData([String? currencyCode]) async {
    setLoading(true);
    try {
      var accountsData = accountsNotifier.value;

      if (accountsData.isEmpty) {
        // If accounts data is not available, set a listener
        accountsNotifier.addListener(() => loadData(currencyCode));
        return;
      }

      // If accounts data is already available, load financial data
      await loadData(currencyCode);
    } finally {
      setLoading(false);
    }
  }

  Future<void> loadData(String? currencyCode) async {
    var accountsData = accountsNotifier.value;
    // Check if accountsData is now available and load financial data
    if (accountsData.isNotEmpty) {
      String usedCurrencyCode;
      Map<String, dynamic> selectedCurrencyData;

      if (currencyCode != null) {
        // Find the account with the matching currency code
        var matchingAccount = accountsData.entries.firstWhere(
              (entry) => jsonDecode(entry.value[AccountsDB.accountCurrency])['code'] == currencyCode,
          orElse: () => accountsData.entries.first, // Fallback to first account if no match found
        );
        selectedCurrencyData = jsonDecode(matchingAccount.value[AccountsDB.accountCurrency]);
        usedCurrencyCode = currencyCode;
      } else {
        // Fallback to first account's currency if no currencyCode is provided
        final account = accountsData.entries.first.value;
        selectedCurrencyData = jsonDecode(account[AccountsDB.accountCurrency]);
        usedCurrencyCode = selectedCurrencyData['code'];
      }

      currencyMap = selectedCurrencyData;

      Set<String> uniqueCurrencyCodesSet = await AccountsDB().getUniqueCurrencyCodes();
      currencyCodes = uniqueCurrencyCodesSet.toList();

      DateTime now = DateTime.now();
      DateTime startDate = DateTime(now.year, now.month, 1);
      DateTime firstDayNextMonth = DateTime(now.year, now.month + 1, 1);
      DateTime endDate = firstDayNextMonth.subtract(const Duration(days: 1));

      Map<String, dynamic> financialData = {};
      try {
        List<dynamic> finalResults = await Future.wait([
          // Replace these methods with your actual implementation
          getTotalForCurrency(usedCurrencyCode, 'income'),
          getTotalForCurrency(usedCurrencyCode, 'expense'),
          getTotalForCurrency(usedCurrencyCode, 'income', startDate: startDate, endDate: endDate),
          getTotalForCurrency(usedCurrencyCode, 'expense', startDate: startDate, endDate: endDate),
          generateGraphData(usedCurrencyCode, 'income', startDate, endDate),
          generateGraphData(usedCurrencyCode, 'expense', startDate, endDate)
        ]);

        financialData = {
          'income': finalResults[0] as double,
          'expense': finalResults[1] as double,
          'balance': (finalResults[0] as double) - (finalResults[1] as double),
          'periodIncome': finalResults[2] as double,
          'periodExpense': finalResults[3] as double,
          'graphDataIncome': finalResults[4] as List<double>,
          'graphDataExpense': finalResults[5] as List<double>,
        };
        setFinancialData(financialData);
      } catch (error) {
        //print("Error fetching financial data: $error");
      }
      // After loading data, remove the listener
      //accountsNotifier.removeListener(loadData);
    }
  }

  Future<double> getTotalForCurrency(String currencyCode, String type, {DateTime? startDate, DateTime? endDate}) async {
    final transactionsData = transactionsNotifier.value;
    final accountsData = accountsNotifier.value;
    double total = 0.0;

    transactionsData.forEach((transactionId, transaction) {
      if (transaction['type'] == type) {
        String accountId = transaction['account_id'];
        if (accountsData.containsKey(accountId)) {
          String accountCurrencyCode = jsonDecode(accountsData[accountId]?['currency'])['code'];
          if (accountCurrencyCode == currencyCode) {
            DateTime transactionDate = DateTime.parse(transaction['date']);
            bool isWithinRange = (startDate == null || transactionDate.isAfter(startDate) || transactionDate.isAtSameMomentAs(startDate)) &&
                (endDate == null || transactionDate.isBefore(endDate) || transactionDate.isAtSameMomentAs(endDate));

            if (isWithinRange) {
              double amount = (transaction['amount'] as num).toDouble();
              total += amount;
            }
          }
        }
      }
    });
    return total;
  }

  Future<List<double>> generateGraphData(String currencyCode, String type,
      DateTime startDate, DateTime endDate) async {
    final transactionsData = transactionsNotifier.value;
    final accountsData = accountsNotifier.value;
    int totalDays = endDate.difference(startDate).inDays + 1;
    int intervals = totalDays > 15 ? 15 : totalDays;
    List<double> graphData = List.generate(intervals, (_) => 0.0);

    for (int i = 0; i < intervals; i++) {
      DateTime intervalStart = i == 0 ? startDate : startDate.add(Duration(days: (totalDays / intervals * i).round()));
      DateTime intervalEnd = i == intervals - 1 ? endDate : startDate.add(Duration(days: (totalDays / intervals * (i + 1)).round() - 1));

      double totalForInterval = 0.0;
      transactionsData.forEach((transactionId, transaction) {
        if (transaction['type'] == type) {
          String accountId = transaction['account_id'];
          if (accountsData.containsKey(accountId)) {
            String accountCurrencyCode =
            jsonDecode(accountsData[accountId]?['currency'])['code'];
            if (accountCurrencyCode == currencyCode) {
              String dateTimeString = '${transaction['date']} ${transaction['time']}';
              DateTime transactionDate = DateTime.parse(dateTimeString);

              if (transactionDate.isAfter(intervalStart.subtract(const Duration(days: 1))) &&
                  transactionDate.isBefore(intervalEnd.add(const Duration(days: 1)))) {
                totalForInterval += transaction['amount'];
              }
            }
          }
        }
      });

      graphData[i] =
          totalForInterval / (intervalEnd.difference(intervalStart).inDays + 1);
    }

    return graphData;
  }
}
