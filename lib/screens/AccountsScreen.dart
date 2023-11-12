import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/AccountsDB.dart';
import '../models/AccountsModel.dart';
import '../models/TransactionsModel.dart';
import '../widgets/AppWidgets/AccountCard.dart';

class AccountsScreen extends StatefulWidget {
  @override
  _AccountsScreenState createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    Provider.of<AccountsModel>(context, listen: false).fetchAccounts();

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
    final transactionsModel = Provider.of<TransactionsModel>(context, listen: false);

    return Container(
      color: Colors.blueGrey[900],
      child: Consumer<AccountsModel>(
        builder: (context, accountsModel, child) {
          if (accountsModel.accounts.isEmpty) {
            return Center(
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
          } else {
            return ListView.builder(
              itemCount: accountsModel.accounts.length,
              itemBuilder: (context, index) {
                final account = accountsModel.accounts[index];
                transactionsModel.fetchTransactions();

                Map<String, dynamic> currencyMap = jsonDecode(account[AccountsDB.accountCurrency]);

                return buildAnimatedAccountCard(
                  accountId: account[AccountsDB.accountId],
                  currencyMap: currencyMap,
                );
              },
            );
          }
        },
      ),
    );
  }

  Widget buildAnimatedAccountCard({
    required int accountId,
    required Map<String, dynamic> currencyMap,
  }) {
    return GestureDetector(
      onLongPress: () {
        _showDeleteConfirmationDialog(context, accountId);
      },
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Opacity(
            opacity: _animation.value,
            child: Transform.scale(
              scale: _animation.value,
              child: ModernAccountCard(
                accountId: accountId,
                currencyMap: currencyMap,
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, int accountId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete Account"),
          content: Text("Are you sure you want to delete this account? \n\nThis will delete all transactions associated with this account"),
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
                await Provider.of<TransactionsModel>(context, listen: false).deleteTransactionsByAccountId(accountId, null, context);
                await Provider.of<AccountsModel>(context, listen: false).deleteAccount(accountId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
