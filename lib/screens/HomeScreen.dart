import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:expnz/database/TempTransactionsDB.dart';
import 'package:expnz/screens/AddTransaction.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/AccountsDB.dart';
import '../models/TempTransactionsModel.dart';
import '../utils/global.dart';
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
  bool financialDataFetched = false;
  Map<String, dynamic> currencyMap = {};
  Set<String> currencyCodes = {};
  String userName = '';

  @override
  void initState() {
    super.initState();
    financialDataFetched = false; // Explicitly set loading state to false initially
    _initializeDataAndControllers();
    fetchUserName();
    fetchAndUpdateFinancialData().then((_) {
      setState(() {
        financialDataFetched = true; // Set to true once data is fetched
      });
    }).catchError((error) {
      // Handle any errors here
      print("Error fetching financial data: $error");
      setState(() {
        financialDataFetched = false; // In case of error, reset loading state
      });
    });
    setState(() {});
  }

  Future<void> _initializeDataAndControllers() async {
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

    // Fetch data
    //fetchAndUpdateFinancialData();

    // Start animations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameController.forward();
      _cardController.forward();
      _incomeCardController.forward();
      _expenseCardController.forward();
      _notificationCardController.forward();
    });
  }

  // Function to fetch user's name from Firestore
  void fetchUserName() async {
    final profileData = profileNotifier.value;
    final prefs = await SharedPreferences.getInstance();
    String? encodedProfileData = prefs.getString('userProfile');

    if (profileData != null) {
      final fetchedName = profileData['name'] ?? '';
      setState(() {
        userName = fetchedName;
      });
    } else if (encodedProfileData != null) {
      try {
        Map<String, dynamic> profileData = json.decode(encodedProfileData);
        String fetchedName = profileData['name'] ?? '';
        setState(() {
          userName = fetchedName;
        });
      } catch (e) {
        // Handle any errors during JSON parsing
        print('Error parsing user profile data: $e');
      }
    }
    else {
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
  }

  Future<void> fetchAndUpdateFinancialData([String? currencyCode]) async {
    var accountsData = accountsNotifier.value;

    try {
      await Future.delayed(Duration(milliseconds: 500)).timeout(
        Duration(milliseconds: 500),
        onTimeout: () {},
      );

      while (accountsData.isEmpty) {
        accountsData = accountsNotifier.value;
      }
    } catch (e) {
      print('Error: $e'); // Handle any exceptions that occur during the operation.
    }

    //final localAccountsData = await AccountsDB().getLocalAccounts();
    //Map<String, Map<String, dynamic>> accountsData = localAccountsData ?? {};

    if (accountsData.isNotEmpty) {
      final account = accountsData.entries.first.value;
      currencyMap = jsonDecode(account[AccountsDB.accountCurrency]);
      String usedCurrencyCode = currencyCode ?? currencyMap['code'];

      AccountsDB().getUniqueCurrencyCodes().then((codes) async {
        currencyCodes = codes;

        DateTime now = DateTime.now();
        DateTime startDate = DateTime(now.year, now.month, 1);
        DateTime firstDayNextMonth = DateTime(now.year, now.month + 1, 1);
        DateTime endDate = firstDayNextMonth.subtract(const Duration(days: 1));

        List<dynamic> finalResults = await Future.wait([
          getTotalForCurrency(usedCurrencyCode, 'income'),
          getTotalForCurrency(usedCurrencyCode, 'expense'),
          getTotalForCurrency(usedCurrencyCode, 'income', startDate: startDate, endDate: endDate),
          getTotalForCurrency(usedCurrencyCode, 'expense', startDate: startDate, endDate: endDate),
          generateGraphData(usedCurrencyCode, 'income', startDate, endDate),
          generateGraphData(usedCurrencyCode, 'expense', startDate, endDate)
        ]);

        setState(() {
          financialData = {
            'income': finalResults[0] as double,
            'expense': finalResults[1] as double,
            'balance': (finalResults[0] as double) - (finalResults[1] as double),
            'periodIncome': finalResults[2] as double,
            'periodExpense': finalResults[3] as double,
            'graphDataIncome': finalResults[4] as List<double>,
            'graphDataExpense': finalResults[5] as List<double>,
          };
          financialDataFetched = true;
        });
      }).catchError((error) {
        // Handle any errors here
        print("Error fetching financial data: $error");
      });
    } else {
      setState(() {
        financialDataFetched = false;
      });
    }
  }


  Future<void> updateFinancialData(String currencyCode) async {
    setState(()  {
      selectedCurrencyCode = currencyCode;
      Currency? currencyObj = currencyService.findByCode(currencyCode);
      fetchAndUpdateFinancialData(currencyCode);

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
    if (!financialDataFetched) {
      return Center(child: CircularProgressIndicator());
    }

    double cardWidth = MediaQuery.of(context).size.width / 2.25;
    return buildFinancialUI(cardWidth);
  }

  Widget buildFinancialUI(double cardWidth) {
    // Your existing UI building code goes here
    return ValueListenableBuilder<Map<String, Map<String, dynamic>>?>(
        valueListenable: accountsNotifier,
        builder: (context, accountsData, child) {
          if (accountsData != null && accountsData.isNotEmpty) {
            if (financialData.isNotEmpty &&
                currencyMap.isNotEmpty &&
                currencyCodes.isNotEmpty) {
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
                            offset:
                            Offset(-300 * (1 - _nameController.value), 0),
                            child: Opacity(
                              opacity: _nameController.value,
                              child: child,
                            ),
                          );
                        },
                        child: Padding(
                          padding:
                          const EdgeInsets.fromLTRB(30.0, 10.0, 16.0, 0.0),
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
                          updateFinancialData(selectedCurrency);
                        },
                      ),

                      const SizedBox(height: 10),
                      // Add some space below the card
                      AnimatedBuilder(
                        animation: _nameController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset:
                            Offset(-300 * (1 - _nameController.value), 0),
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
                                      -300 * (1 - _incomeCardController.value),
                                      0),
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
                                      300 * (1 - _expenseCardController.value),
                                      0),
                                  child: Opacity(
                                    opacity: _expenseCardController.value,
                                    child: child,
                                  ),
                                );
                              },
                              child: SummaryMonthCardWidget(
                                width: cardWidth,
                                title: 'Expense',
                                total:
                                financialData['periodExpense'].toString(),
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
                            offset: Offset(0,
                                300 * (1 - _notificationCardController.value)),
                            child: Opacity(
                              opacity: _notificationCardController.value,
                              child: child,
                            ),
                          );
                        },
                        child: Consumer<TempTransactionsModel>(
                          // Using Consumer
                          builder: (context, tempTransactionsModel, child) {
                            tempTransactionsModel.fetchTransactions();
                            if (tempTransactionsModel.transactions.isEmpty) {
                              return Container(); // If no data or empty data
                            }

                            // If data is present and not empty, show heading and notifications
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding:
                                  EdgeInsets.fromLTRB(30.0, 0.0, 0.0, 0.0),
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  child: Column(
                                    children: tempTransactionsModel.transactions
                                        .map((transaction) {
                                      return NotificationCard(
                                        title: transaction[TempTransactionsDB
                                            .columnTitle] ??
                                            'No Title',
                                        content: transaction[TempTransactionsDB
                                            .columnContent] ??
                                            'No Content',
                                        icon: getIconBasedOnType(transaction[
                                        TempTransactionsDB.columnType]),
                                        color: getColorBasedOnType(transaction[
                                        TempTransactionsDB.columnType]),
                                        date: transaction[TempTransactionsDB
                                            .columnDate] ??
                                            '',
                                        time: transaction[TempTransactionsDB
                                            .columnTime] ??
                                            '',
                                        transactionId: transaction[
                                        TempTransactionsDB.columnId],
                                        // set this appropriately
                                        onTap: (int transactionId) async {
                                          await _handleNotificationCardClick(
                                              context, transactionId);
                                        },
                                        onDelete: (int transactionId) {
                                          Provider.of<TempTransactionsModel>(
                                              context,
                                              listen: false)
                                              .deleteTransactions(
                                              transactionId, null, context);
                                          Provider.of<TempTransactionsModel>(
                                              context,
                                              listen: false)
                                              .fetchTransactions();
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
                            bottom:
                            80.0), // Add 60.0 or whatever value that suits you
                      ),
                    ],
                  ),
                ),
              );
            }
          } else {
            // No financial data available, show appropriate message or widget
            return Center(
              child: Text("No financial data available or there was an issue loading the data."),
            );
          }
          return Center(
            child: Text("No financial data available."),
          );
        });
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
              total += transaction['amount'];
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
      DateTime intervalStart =
          startDate.add(Duration(days: (totalDays / intervals * i).round()));
      DateTime intervalEnd = i == intervals - 1
          ? endDate
          : startDate.add(
              Duration(days: (totalDays / intervals * (i + 1)).round() - 1));

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
              if (transactionDate.isAfter(intervalStart) &&
                  transactionDate.isBefore(intervalEnd)) {
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

  /*Future<Map<String, dynamic>> fetchFinancialData(
    String currencyCode,
      Map<String, Map<String, dynamic>> accountsData, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final transactionsModel =
        Provider.of<TransactionsModel>(context, listen: false);



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
  }*/

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

  Future<void> _handleNotificationCardClick(
      BuildContext context, int transactionId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddTransactionScreen(tempTransactionId: transactionId),
      ),
    );

    /*if (result == true) {
      Provider.of<TempTransactionsModel>(context, listen: false)
          .deleteTransactions(transactionId, null, context);
      Provider.of<TempTransactionsModel>(context, listen: false)
          .fetchTransactions();
    }*/
  }
}
