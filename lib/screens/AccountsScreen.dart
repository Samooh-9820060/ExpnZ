import 'dart:convert';
import 'package:expnz/database/TransactionsDB.dart';
import 'package:flutter/material.dart';
import '../database/AccountsDB.dart';
import '../widgets/AppWidgets/AccountCard.dart';
import 'package:expnz/utils/global.dart';

class AccountsScreen extends StatefulWidget {
  @override
  _AccountsScreenState createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blueGrey[900],
      child: ValueListenableBuilder<Map<String, Map<String, dynamic>>>(
          valueListenable: accountsNotifier, // The ValueNotifier for local accounts data
          builder: (context, accountsData, child) {
            if (accountsData.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.credit_card,
                      color: Colors.grey,
                      size: 64,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No accounts available.',
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

            List<String> accountIds = accountsData.keys.toList();
            return FutureBuilder<Map<String, Map<String, double>>>(
              future: TransactionsDB().getTotalIncomeAndExpenseForAccounts(accountIds),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No data available.'));
                }

                Map<String, Map<String, double>> incomeExpenseData = snapshot.data!;

                return ListView.builder(
                  itemCount: accountsData.length,
                  itemBuilder: (context, index) {
                    final documentId = accountsData.keys.elementAt(index);
                    final accountData = accountsData[documentId]!;
                    final currencyMap = jsonDecode(accountData[AccountsDB.accountCurrency]);

                    // Retrieve income and expense for the current account
                    final accountTotals = incomeExpenseData[documentId] ?? {'totalIncome': 0.0, 'totalExpense': 0.0};

                    // Use the null coalescing operator to ensure a non-null value is passed
                    double totalIncome = accountTotals['totalIncome'] ?? 0.0;
                    double totalExpense = accountTotals['totalExpense'] ?? 0.0;

                    return buildAnimatedAccountCard(
                      documentId: documentId,
                      currencyMap: currencyMap,
                      totalIncome: totalIncome,
                      totalExpense: totalExpense,
                      index: index,
                    );
                  },
                );
              },
            );
          }),
    );
  }

  Widget buildAnimatedAccountCard({
    required String documentId,
    required Map<String, dynamic> currencyMap,
    required int index,
    required double totalIncome,
    required double totalExpense,
  }) {
    return GestureDetector(
      onLongPress: () {
        _showDeleteConfirmationDialog(context, documentId);
      },
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Opacity(
            opacity: _animation.value,
            child: Transform.scale(
              scale: _animation.value,
              child: ModernAccountCard(
                documentId: documentId,
                currencyMap: currencyMap,
                index: index,
                totalExpense: totalExpense,
                totalIncome: totalIncome,
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, String documentId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete Account"),
          content: Text(
              "Are you sure you want to delete this account? \n\nThis will delete all transactions associated with this account"),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Delete"),
              onPressed: () async {
                AccountsDB().deleteAccount(documentId);

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
