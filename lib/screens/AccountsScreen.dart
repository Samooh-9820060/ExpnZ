import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/AccountsDB.dart';
import '../models/AccountsModel.dart';
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
                Map<String, dynamic> currencyMap = jsonDecode(account[AccountsDB.accountCurrency]);
                String currencyCode = currencyMap['code'] as String;

                return buildAnimatedAccountCard(
                  accountId: account[AccountsDB.accountId],
                  accountName: account[AccountsDB.accountName],
                  accountCurrency: currencyCode,
                  cardNumber: account[AccountsDB.accountCardNumber].toString(),
                  iconData: IconData(
                    int.tryParse(account[AccountsDB.accountIcon]) ?? Icons.error.codePoint,
                    fontFamily: 'MaterialIcons',
                  ),
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
    required String accountName,
    required String accountCurrency,
    required IconData iconData,
    required String cardNumber,
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
                accountName: accountName,
                currency: accountCurrency,
                iconData: iconData,
                // fill in other properties as per your requirement
                totalBalance: "\$0",
                income: "+\$0",
                expense: "-\$0",
                cardNumber: cardNumber, // example value, replace with real card number
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
          content: Text("Are you sure you want to delete this account?"),
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
                await Provider.of<AccountsModel>(context, listen: false)
                    .deleteAccount(accountId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
