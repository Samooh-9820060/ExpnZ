import 'dart:convert';

import 'package:expnz/screens/AddCategory.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/AccountsModel.dart';
import '../../models/TransactionsModel.dart';

class CategoryCard extends StatefulWidget {
  final Key? key;
  final int categoryId;
  final String categoryName;
  final IconData iconData;
  final Animation<double> animation;
  final Color primaryColor;

  CategoryCard({
    this.key,
    required this.categoryId,
    required this.categoryName,
    required this.iconData,
    required this.animation,
    required this.primaryColor,
  }) : super(key: key);

  @override
  _CategoryCardState createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard>
    with TickerProviderStateMixin {
  late AnimationController _numberController;
  late Animation<double> _numberAnimation;
  late AnimationController _deleteController;
  late Animation<double> _deleteAnimation;

  late Map<int, double> accountIncome;
  late Map<int, double> accountExpense;

  bool showMoreInfo = false;

  @override
  void initState() {
    super.initState();
    _numberController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _numberAnimation =
        Tween<double>(begin: 0, end: 1).animate(_numberController);
    _numberController.forward();
    _deleteController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _deleteAnimation =
        Tween<double>(begin: 1, end: 0).animate(_deleteController);
    _calculateCategoryAmounts();
  }

  void _calculateCategoryAmounts() {
    final transactionsModel = Provider.of<TransactionsModel>(context, listen: false);

    // Initialize Maps to store income and expense for each account
    accountIncome = {};
    accountExpense = {};

    // Filter transactions related to this category
    List<Map<String, dynamic>> categoryTransactions = transactionsModel.transactions.where((transaction) {
      if (transaction.containsKey('categories')) {
        // Decode the JSON string into a List<dynamic>
        List<dynamic> categories = jsonDecode(transaction['categories']);
        return categories.any((category) => category['name'] == widget.categoryName);
      }
      return false;
    }).toList();

    // Loop through filtered transactions and sum the income and expense for each account
    for (var transaction in categoryTransactions) {
      int accountId = transaction['account_id'];
      double amount = transaction['amount'];

      if (transaction['type'] == 'income') {
        accountIncome[accountId] = (accountIncome[accountId] ?? 0) + amount;
      } else if (transaction['type'] == 'expense') {
        accountExpense[accountId] = (accountExpense[accountId] ?? 0) + amount;
      }
    }
  }

  @override
  void dispose() {
    _numberController.dispose();
    _deleteController.dispose();
    super.dispose();
  }

  String _animatedNumberString(double animationValue, String targetValue) {
    int value = (double.parse(targetValue.replaceAll(RegExp(r'[\$,]'), '')) *
            animationValue)
        .toInt();
    final formatter = NumberFormat("#,###");
    return '\$' + formatter.format(value);
  }

  @override
  Widget build(BuildContext context) {
    final accountsModel = Provider.of<AccountsModel>(context, listen: false);

    // Fetch account names for display
    Future<void> fetchAccountNames() async {
      for (int accountId in accountIncome.keys) {
        String accountName = await accountsModel.getAccountNameById(accountId);
        // Use accountName along with accountIncome[accountId] and accountExpense[accountId] for display
      }
    }
    fetchAccountNames();

    return AnimatedBuilder(
      animation: _deleteController,
      builder: (context, child) {
        return Opacity(
          opacity: _deleteAnimation.value,
          child: child,
        );
      },
      child: AnimatedBuilder(
        animation: _numberController,
        builder: (context, child) {
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AddCategoryScreen(categoryId: this.widget.categoryId),
                ),
              ).then((value) {
                setState(() {});
              });
            },
            child: Column(children: [
              Container(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.black, Colors.grey[850]!],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      offset: Offset(0, 4),
                      blurRadius: 6.0,
                    ),
                  ],
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: widget.primaryColor,
                            child: Icon(widget.iconData,
                                color: Colors.white, size: 24),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              widget.categoryName,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (showMoreInfo)
                            IconButton(
                              icon: Icon(
                                Icons.arrow_upward,
                                size: 20.0,
                              ),
                              onPressed: () {
                                setState(() {
                                  showMoreInfo = false;
                                });
                              },
                            ),
                          if (!showMoreInfo)
                            IconButton(
                              icon: Icon(
                                Icons.arrow_downward,
                                size: 20.0,
                              ),
                              onPressed: () {
                                setState(() {
                                  showMoreInfo = true;
                                });
                              },
                            ),
                        ],
                      ),
                      if (showMoreInfo)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 20),
                            Consumer<AccountsModel>(
                            builder: (context, accountsModel, child) {
                              // Ensure the accounts list is not empty
                              if (accountsModel.accounts.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Colors.red,
                                        size: 50.0,
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        "No accounts are there",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blueGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }


                              List<Widget> accountWidgets = [];
                              for (var account in accountsModel.accounts) {
                                int? accountId = account['_id'];
                                if (accountId == null) {
                                  // Handle the null case
                                  continue;
                                }
                                String accountName = account['name'];
                                double income = accountIncome[accountId] ?? 0.0;
                                double expense = accountExpense[accountId] ?? 0.0;

                                // If both income and expense are zero, don't show this account
                                if (income == 0.0 && expense == 0.0) {
                                  continue;
                                }

                                accountWidgets.add(
                                  accountInfoRow(accountName, "\$${income.toStringAsFixed(2)}", "\$${expense.toStringAsFixed(2)}"),
                                );
                              }

                              if (accountWidgets.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Colors.red,
                                        size: 50.0,
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        "No more info available",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blueGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              List<Widget> finalWidgets = [];
                              for (int i = 0; i < accountWidgets.length; i++) {
                                finalWidgets.add(accountWidgets[i]);
                                if (i < accountWidgets.length - 1) {
                                  finalWidgets.add(Divider(color: Colors.grey));
                                }
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: finalWidgets,
                              );
                            },
                          ),
                        ]),
                    ]),
              ),
            ]),
          );
        },
      ),
    );
  }

  Widget accountInfoRow(String accountName, String expense, String income) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      padding: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            accountName,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              Icon(Icons.arrow_upward, color: Colors.green, size: 16),
              SizedBox(width: 4),
              Text(
                income,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 16),
              Icon(Icons.arrow_downward, color: Colors.red, size: 16),
              SizedBox(width: 4),
              Text(
                expense,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
