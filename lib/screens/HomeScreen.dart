import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:expnz/database/TempTransactionsDB.dart';
import 'package:expnz/screens/AddTransaction.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/AccountsDB.dart';
import '../models/AccountsModel.dart';
import '../models/TempTransactionsModel.dart';
import '../models/TransactionsModel.dart';
import '../widgets/AppWidgets/FinanceCard.dart';
import '../widgets/AppWidgets/NotificationsCard.dart';
import '../widgets/AppWidgets/SummaryMonthCardWidget.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _nameController;
  late AnimationController _cardController;
  late AnimationController _incomeCardController;
  late AnimationController _expenseCardController;
  late AnimationController _notificationCardController;
  late String selectedCurrencyCode;
  static final CurrencyService currencyService = CurrencyService();
  Map<String, dynamic> financialData = {
    'balance': 0.0,
    'income': 0.0,
    'expense': 0.0,
    'graphDataIncome': [
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0
    ],
    'graphDataExpense': [
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0
    ],
  };
  Map<String, dynamic> currencyMap = {};
  Set<String> currencyCodes = {};
  String userName = '';

  // Function to fetch user's name from Firestore
  void fetchUserName() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final fetchedName = userData['name'] ?? '';
          setState(() {
            userName = fetchedName;
          });
        }
      }
    } catch (e) {
      // Handle any errors while fetching the name
      print(e.toString());
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUserName();
    _fetchData();
    _nameController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _incomeCardController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _expenseCardController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _notificationCardController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameController.forward();
      _cardController.forward();
      _incomeCardController.forward();
      _expenseCardController.forward();
      _notificationCardController.forward();
    });
  }

  Future<void> _fetchData() async {
    final accountsModel = Provider.of<AccountsModel>(context, listen: false);
    await accountsModel.fetchAccounts();
    if (accountsModel.accounts.isNotEmpty) {
      final account = accountsModel.accounts.first;
      currencyMap = jsonDecode(account[AccountsDB.accountCurrency]);

      currencyCodes = await accountsModel.getUniqueCurrencyCodes();
      financialData =
          await fetchFinancialData(currencyMap['code'], accountsModel);
    }

    setState(() {
      // Update the state to trigger a rebuild
    });
  }

  Future<void> updateFinancialData(
      String currencyCode, AccountsModel accountsModel) async {
    var newFinancialData =
        await fetchFinancialData(currencyCode, accountsModel);
    setState(() {
      selectedCurrencyCode = currencyCode;
      financialData = newFinancialData;
      Currency? currencyObj = currencyService.findByCode(currencyCode);
      if (currencyObj != null) {
        currencyMap = {
          'code': currencyObj.code,
          'name': currencyObj.name,
          'symbol': currencyObj.symbol,
          'flag': currencyObj.flag,
          'decimalDigits': currencyObj.decimalDigits,
          'decimalSeparator': currencyObj.decimalSeparator,
          'namePlural': currencyObj.namePlural,
          'number': currencyObj.number,
          'spaceBetweenAmountAndSymbol':
              currencyObj.spaceBetweenAmountAndSymbol,
          'symbolOnLeft': currencyObj.symbolOnLeft,
          'thousandsSeparator': currencyObj.thousandsSeparator,
        };
      } else {
        currencyMap = {}; // or some default values
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cardController.dispose();
    _incomeCardController.dispose();
    _expenseCardController.dispose();
    _notificationCardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double cardWidth = MediaQuery.of(context).size.width /
        2.25; // About half of the screen width, adjust the divisor as needed
    final accountsModel = Provider.of<AccountsModel>(context, listen: false);

    if (financialData.isNotEmpty &&
        currencyMap.isNotEmpty &&
        currencyCodes.isNotEmpty) {
      // Build the UI with the loaded data
      return Container(
        color: Colors.blueGrey[900],
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Animated "Name" and "Welcome Back!"
              AnimatedBuilder(
                animation: _nameController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(-300 * (1 - _nameController.value), 0),
                    child: Opacity(
                      opacity: _nameController.value,
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(30.0, 10.0, 16.0, 0.0),
                  // Reduced top padding to 50
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                            fontSize: 25, // Reduced font size
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Welcome Back!',
                        style: TextStyle(
                          fontSize: 15, // Reduced font size
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Animated Balance Card
              FinanceCard(
                cardController: _cardController,
                totalBalance: financialData['balance'].toString(),
                income: financialData['income'].toString(),
                expense: financialData['expense'].toString(),
                optionalIcon: Icons.credit_card,
                currencyMap: currencyMap,
                currencyCodes: currencyCodes,
                onCurrencyChange: (selectedCurrency) {
                  updateFinancialData(selectedCurrency, accountsModel);
                },
              ),

              const SizedBox(height: 10), // Add some space below the card

              AnimatedBuilder(
                animation: _nameController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(-300 * (1 - _nameController.value), 0),
                    child: Opacity(
                      opacity: _nameController.value,
                      child: child,
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(30.0, 0.0, 0.0, 0.0),
                  child: Text(
                    'This Month',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Income Card
                    AnimatedBuilder(
                      animation: _incomeCardController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(
                              -300 * (1 - _incomeCardController.value), 0),
                          child: Opacity(
                            opacity: _incomeCardController.value,
                            child: child,
                          ),
                        );
                      },
                      child: SummaryMonthCardWidget(
                        width: cardWidth,
                        title: 'Income',
                        total: financialData['periodIncome'].toString(),
                        currencyMap: currencyMap,
                        data: financialData['graphDataIncome'],
                        graphLineColor: Colors.green,
                        iconData: Icons.arrow_upward,
                      ),
                    ),

                    // Expense Card
                    AnimatedBuilder(
                      animation: _expenseCardController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(
                              300 * (1 - _expenseCardController.value), 0),
                          child: Opacity(
                            opacity: _expenseCardController.value,
                            child: child,
                          ),
                        );
                      },
                      child: SummaryMonthCardWidget(
                        width: cardWidth,
                        title: 'Expense',
                        total: financialData['periodExpense'].toString(),
                        currencyMap: currencyMap,
                        data: financialData['graphDataExpense'],
                        graphLineColor: Colors.red,
                        iconData: Icons.arrow_downward,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Animated Notifications Section
              AnimatedBuilder(
                animation: _notificationCardController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, 300 * (1 - _notificationCardController.value)),
                    child: Opacity(
                      opacity: _notificationCardController.value,
                      child: child,
                    ),
                  );
                },
                child: Consumer<TempTransactionsModel>(  // Using Consumer
                  builder: (context, tempTransactionsModel, child) {
                    tempTransactionsModel.fetchTransactions();
                    if (tempTransactionsModel.transactions.isEmpty) {
                      return Container();  // If no data or empty data
                    }

                    // If data is present and not empty, show heading and notifications
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(30.0, 0.0, 0.0, 0.0),
                          child: Text(
                            'Notifications',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            children: tempTransactionsModel.transactions.map((transaction) {
                              return NotificationCard(
                                title: transaction[TempTransactionsDB.columnTitle] ?? 'No Title',
                                content: transaction[TempTransactionsDB.columnContent] ?? 'No Content',
                                icon: getIconBasedOnType(transaction[TempTransactionsDB.columnType]),
                                color: getColorBasedOnType(transaction[TempTransactionsDB.columnType]),
                                date: transaction[TempTransactionsDB.columnDate] ?? '',
                                time: transaction[TempTransactionsDB.columnTime] ?? '',
                                transactionId: transaction[TempTransactionsDB.columnId], // set this appropriately
                                onTap: (int transactionId) async {
                                  await _handleNotificationCardClick(context, transactionId);
                                },
                                onDelete: (int transactionId) {
                                  Provider.of<TempTransactionsModel>(context, listen: false).deleteTransactions(transactionId, null, context);
                                  Provider.of<TempTransactionsModel>(context, listen: false).fetchTransactions();
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(
                    bottom: 80.0), // Add 60.0 or whatever value that suits you
              ),
            ],
          ),
        ),
      );
    } else if (accountsModel.accounts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance,
              color: Colors.grey,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'No info available.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    else {
      // Show loading or empty state
      return const Center(child: CircularProgressIndicator());
    }
  }

  Future<Set<String>> fetchCurrencyList(AccountsModel accountsModel) async {
    Future<Set<String>> currencyCodes = accountsModel.getUniqueCurrencyCodes();
    return currencyCodes;
  }

  Future<Map<String, dynamic>> fetchFinancialData(
    String currencyCode,
    AccountsModel accountsModel, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final transactionsModel =
        Provider.of<TransactionsModel>(context, listen: false);

    //populate start date and end date if they are not given
    DateTime now = DateTime.now();
    startDate ??= DateTime(now.year, now.month, 1);
    DateTime firstDayNextMonth = DateTime(now.year, now.month + 1, 1);
    endDate ??= firstDayNextMonth.subtract(const Duration(days: 1));

    double totalIncome =
        await transactionsModel.getTotalIncomeForCurrency(currencyCode);
    double totalExpense =
        await transactionsModel.getTotalExpenseForCurrency(currencyCode);
    double balance = totalIncome - totalExpense;

    double periodIncome = await transactionsModel.getTotalIncomeForCurrency(
        currencyCode,
        startDate: startDate,
        endDate: endDate);
    double periodExpense = await transactionsModel.getTotalExpenseForCurrency(
        currencyCode,
        startDate: startDate,
        endDate: endDate);

    // Graph data generation
    int totalDays = endDate.difference(startDate).inDays + 1;
    int intervals = totalDays > 15 ? 15 : totalDays; // Max 15 intervals
    List<double> graphDataExpense = List.generate(intervals, (_) => 0.0);
    List<double> graphDataIncome = List.generate(intervals, (_) => 0.0);

    for (int i = 0; i < intervals; i++) {
      DateTime intervalStart =
          startDate.add(Duration(days: (totalDays / intervals * i).round()));
      DateTime intervalEnd = i == intervals - 1
          ? endDate
          : startDate.add(
              Duration(days: (totalDays / intervals * (i + 1)).round() - 1));

      double intervalExpense =
          await transactionsModel.getTotalExpenseForCurrency(currencyCode,
                  startDate: intervalStart, endDate: intervalEnd) ??
              0.0;
      graphDataExpense[i] =
          intervalExpense / (intervalEnd.difference(intervalStart).inDays + 1);

      double intervalIncome = await transactionsModel.getTotalIncomeForCurrency(
              currencyCode,
              startDate: intervalStart,
              endDate: intervalEnd) ??
          0.0;
      graphDataIncome[i] =
          intervalIncome / (intervalEnd.difference(intervalStart).inDays + 1);
    }

    return {
      'income': totalIncome,
      'expense': totalExpense,
      'balance': balance,
      'periodIncome': periodIncome,
      'periodExpense': periodExpense,
      'graphDataIncome': graphDataIncome,
      'graphDataExpense': graphDataExpense,
    };
  }

IconData getIconBasedOnType(String? type) {
  // Logic to return an icon based on the transaction type
  switch (type) {
    case 'income':
      return Icons.arrow_upward; // Replace with actual icon
    case 'expense':
      return Icons.arrow_downward;
  // Add more cases as needed
    default:
      return Icons.question_mark; // Replace with a default icon
  }
}

Color getColorBasedOnType(String? type) {
  // Logic to return a color based on the transaction type
  switch (type) {
    case 'income':
      return Colors.green;
    case 'expense':
      return Colors.red;
    default:
      return Colors.yellow; // Replace with a default color
  }
}
  Future<void> _handleNotificationCardClick(BuildContext context, int transactionId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(tempTransactionId: transactionId),
      ),
    );

    if (result == true) {
      Provider.of<TempTransactionsModel>(context,
          listen: false)
          .deleteTransactions(
          transactionId,
          null,
          context);
      Provider.of<TempTransactionsModel>(context,
          listen: false)
          .fetchTransactions();
    }
  }
}
