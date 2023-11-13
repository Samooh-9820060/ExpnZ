import 'dart:convert';

import 'package:currency_picker/currency_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/AccountsDB.dart';
import '../models/AccountsModel.dart';
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
  Map<String, dynamic>? financialData;
  late Map<String, dynamic> currencyMap;

  @override
  void initState() {
    super.initState();

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
          'spaceBetweenAmountAndSymbol': currencyObj.spaceBetweenAmountAndSymbol,
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
                      'Samooh Moosa',
                      style: TextStyle(
                          fontSize: 25, // Reduced font size
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    SizedBox(height: 10),
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
            FutureBuilder(
              future: accountsModel.fetchAccounts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (accountsModel.accounts.isNotEmpty) {
                    final account = accountsModel.accounts.first;
                    if (financialData == null) {
                      currencyMap =
                      jsonDecode(account[AccountsDB.accountCurrency]);
                    }

                    return FutureBuilder<Map<String, dynamic>>(
                        future: fetchFinancialData(currencyMap['code'], accountsModel),
                        builder: (context, financialSnapshot) {
                          if (financialSnapshot.connectionState == ConnectionState.done) {
                            if (financialSnapshot.hasData) {
                              if (financialData == null) {
                                financialData = financialSnapshot.data!;
                              }
                            } else {
                              return Center(child: CircularProgressIndicator());
                            }
                          }
                          return FutureBuilder<Set<String>>(
                            future: accountsModel.getUniqueCurrencyCodes(),
                            builder: (context, currencySnapshot) {
                              if (currencySnapshot.connectionState == ConnectionState.done) {
                                if (currencySnapshot.hasData) {
                                  var currencyCodes = currencySnapshot.data!;

                                  // Ensure financialData is not null before using it
                                  if (financialData != null) {
                                    return FinanceCard(
                                      cardController: _cardController,
                                      totalBalance: financialData!['balance'].toString(),
                                      income: financialData!['income'].toString(),
                                      expense: financialData!['expense'].toString(),
                                      optionalIcon: Icons.credit_card,
                                      currencyMap: currencyMap,
                                      currencyCodes: currencyCodes,
                                      onCurrencyChange: (selectedCurrency) {
                                        updateFinancialData(selectedCurrency, accountsModel);
                                      },
                                    );
                                  } else {
                                    return CircularProgressIndicator();
                                  }
                                } else {
                                  return CircularProgressIndicator();
                                }
                              } else {
                                return CircularProgressIndicator();
                              }
                            });
                      }
                    );
                  } else {
                    return SizedBox(
                      height: 20,
                    );
                  }
                } else {
                  return Container();
                }
              },
            ),

            SizedBox(height: 10), // Add some space below the card

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
                padding: const EdgeInsets.fromLTRB(30.0, 0.0, 0.0, 0.0),
                child: Text(
                  'This Month',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            FutureBuilder(
                future: accountsModel.fetchAccounts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (accountsModel.accounts.isNotEmpty) {
                      final account = accountsModel.accounts.first;
                      if (financialData == null) {
                        currencyMap =
                            jsonDecode(account[AccountsDB.accountCurrency]);
                      }

                      return FutureBuilder<Map<String, dynamic>>(
                        future: fetchFinancialData(currencyMap['code'], accountsModel),
                        builder: (context, financialSnapshot) {
                          if (financialSnapshot.connectionState == ConnectionState.done) {
                            if (financialSnapshot.hasData) {
                              if (financialData == null) {
                                financialData = financialSnapshot.data!;
                              }
                            } else {
                              return Center(child: CircularProgressIndicator());
                            }
                            print(financialData);
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment
                                    .spaceEvenly,
                                children: [
                                  // Income Card
                                  AnimatedBuilder(
                                    animation: _incomeCardController,
                                    builder: (context, child) {
                                      return Transform.translate(
                                        offset:
                                        Offset(
                                            -300 * (1 -
                                                _incomeCardController.value),
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
                                      total: financialData!['periodIncome']
                                          .toString(),
                                      currencyMap: currencyMap,
                                      data: financialData!['graphDataIncome'],
                                      graphLineColor: Colors.green,
                                      iconData: Icons.arrow_upward,
                                    ),
                                  ),

                                  // Expense Card
                                  AnimatedBuilder(
                                    animation: _expenseCardController,
                                    builder: (context, child) {
                                      return Transform.translate(
                                        offset:
                                        Offset(
                                            300 * (1 -
                                                _expenseCardController.value),
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
                                      total: financialData!['periodExpense']
                                          .toString(),
                                      currencyMap: currencyMap,
                                      data: financialData!['graphDataExpense'],
                                      graphLineColor: Colors.red,
                                      iconData: Icons.arrow_downward,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            return Container();
                          }
                        }
                      );
                    }
                    else {
                      return Container();
                    }
                  }
                  else {
                    return Container();
                  }
              }
            ),
            SizedBox(height: 10),
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
                padding: const EdgeInsets.fromLTRB(30.0, 0.0, 0.0, 0.0),
                child: Text(
                  'Notifications',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(height: 10),
            // Animated Notifications Section
            AnimatedBuilder(
              animation: _notificationCardController,
              builder: (context, child) {
                return Transform.translate(
                  offset:
                      Offset(0, 300 * (1 - _notificationCardController.value)),
                  child: Opacity(
                    opacity: _notificationCardController.value,
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                // Left and Right Padding
                child: Column(
                  children: [
                    NotificationCard(
                      title: "Large Transaction Alert",
                      content: "A transaction of \$500 was made at ABC Store.",
                      icon: Icons.warning_amber_outlined,
                      color: Colors.orange,
                    ),
                    NotificationCard(
                      title: "Bill Due Soon",
                      content:
                          "Your electricity bill of \$120 is due in 3 days.",
                      icon: Icons.calendar_today_outlined,
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  bottom: 80.0), // Add 60.0 or whatever value that suits you
            ),
          ],
        ),
      ),
    );
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
    final transactionsModel = Provider.of<TransactionsModel>(context, listen: false);

    //populate start date and end date if they are not given
    DateTime now = DateTime.now();
    startDate ??= DateTime(now.year, now.month, 1);
    DateTime firstDayNextMonth = DateTime(now.year, now.month + 1, 1);
    endDate ??= firstDayNextMonth.subtract(Duration(days: 1));

    double totalIncome = await transactionsModel.getTotalIncomeForCurrency(currencyCode);
    double totalExpense = await transactionsModel.getTotalExpenseForCurrency(currencyCode);
    double balance = totalIncome - totalExpense;

    double periodIncome = await transactionsModel.getTotalIncomeForCurrency(currencyCode, startDate: startDate, endDate: endDate);
    double periodExpense = await transactionsModel.getTotalExpenseForCurrency(currencyCode, startDate: startDate, endDate: endDate);

    // Graph data generation
    int totalDays = endDate.difference(startDate).inDays + 1;
    int intervals = totalDays > 15 ? 15 : totalDays; // Max 15 intervals
    List<double> graphDataExpense = List.generate(intervals, (_) => 0.0);
    List<double> graphDataIncome = List.generate(intervals, (_) => 0.0);

    for (int i = 0; i < intervals; i++) {
      DateTime intervalStart = startDate.add(Duration(days: (totalDays / intervals * i).round()));
      DateTime intervalEnd = i == intervals - 1 ? endDate : startDate.add(Duration(days: (totalDays / intervals * (i + 1)).round() - 1));

      double intervalExpense = await transactionsModel.getTotalExpenseForCurrency(currencyCode, startDate: intervalStart, endDate: intervalEnd) ?? 0.0;
      graphDataExpense[i] = intervalExpense / (intervalEnd.difference(intervalStart).inDays + 1);

      double intervalIncome = await transactionsModel.getTotalIncomeForCurrency(currencyCode, startDate: intervalStart, endDate: intervalEnd) ?? 0.0;
      graphDataIncome[i] = intervalIncome / (intervalEnd.difference(intervalStart).inDays + 1);
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
}
