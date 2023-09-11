import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/AccountsDB.dart';
import '../models/AccountsModel.dart';
import '../models/TransactionsModel.dart';
import '../widgets/AppWidgets/SearchTransactionCard.dart';
import '../widgets/AppWidgets/SelectAccountCard.dart';
import 'AddTransaction.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> filteredTransactions = [];

  void _showFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.6,  // covers 60% of screen height
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.0),
                topRight: Radius.circular(20.0),
              ),
            ),
            padding: EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Filter Options", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 20),

                  // Account selection
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Accounts',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        height: 150, // set the height
                        child: Consumer<AccountsModel>(
                          builder: (context, accountsModel, child) {
                            if (accountsModel.accounts.isEmpty) {
                              return Center(
                                child: Text('No accounts available.'),
                              );
                            } else {
                              return ListView.builder(
                                padding: EdgeInsets.zero,
                                scrollDirection: Axis.horizontal,
                                itemCount: accountsModel.accounts.length,
                                itemBuilder: (context, index) {
                                  final account = accountsModel.accounts[index];
                                  Map<String, dynamic> currencyMap = jsonDecode(account[AccountsDB.accountCurrency]);
                                  String currencyCode = currencyMap['code'] as String;

                                  return GestureDetector(
                                    onTap: () {
                                      // Handle onTap here
                                      // ...
                                    },
                                    child: Transform.scale(
                                      scale: 0.8, // Adjust this scale factor to your need
                                      child: AccountCard(
                                        accountId: account[AccountsDB.accountId],
                                        icon: IconData(
                                          account[AccountsDB.accountIconCodePoint],
                                          fontFamily: account[AccountsDB.accountIconFontFamily],
                                          fontPackage: account[AccountsDB.accountIconFontPackage],
                                        ),
                                        currency: currencyCode,
                                        accountName: account[AccountsDB.accountName],
                                        //isSelected: index == selectedToAccountIndex,  // I assume 'selectedToAccountIndex' is declared and maintained in your code
                                      ),
                                    ),
                                  );
                                },
                              );
                            }
                          },
                        ),
                      )
                    ],
                  ),
                  Text("Select Categories:"),
                  // Your ListView.builder code for selecting categories will go here
                  SizedBox(height: 20),
                  Text("Select From Date:"),
                  // Your DatePicker code will go here
                  SizedBox(height: 20),
                  Text("Select To Date:"),
                  // Your DatePicker code will go here
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterTransactions);
    Provider.of<TransactionsModel>(context, listen: false).fetchTransactions();
  }

  void _filterTransactions() {
    String searchText = _searchController.text.toLowerCase();
    Provider.of<TransactionsModel>(context, listen: false)
        .filterTransactions(context, searchText);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blueGrey[900],
        leading: BackButton(
          color: Colors.white,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 2), // Reduced padding
                decoration: BoxDecoration(
                  color: Colors.blueGrey[700],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          // Reduced padding
                          border: InputBorder.none,
                        ),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon:
                          Icon(Icons.filter_alt, color: Colors.white, size: 20),
                      // Reduced icon size
                      onPressed: () {
                        _showFilterDialog(
                            context); // <-- Call the filter dialog here
                      },
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: Consumer<TransactionsModel>(
        builder: (context, transactionsModel, child) {
          var transactionsToShow =
              transactionsModel.filteredTransactions.isNotEmpty ||
                      _searchController.text.isNotEmpty
                  ? transactionsModel.filteredTransactions
                  : transactionsModel.transactions;
          return Container(
            color: Colors.blueGrey[900],
            child: _searchController
                    .text.isNotEmpty // <-- Check if text is entered
                ? (transactionsToShow.isNotEmpty
                    ? SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                'Result',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.white),
                              ),
                            ),
                            for (var transaction in transactionsToShow)
                              TransactionCard(
                                transaction: transaction,
                                onDelete: () {
                                  Provider.of<TransactionsModel>(context,
                                          listen: false)
                                      .deleteTransactions(
                                          transaction['_id'],
                                          _searchController.text.toLowerCase(),
                                          context);
                                  Provider.of<TransactionsModel>(context,
                                          listen: false)
                                      .fetchTransactions();
                                },
                                onUpdate: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          AddTransactionScreen(
                                        transaction: transaction,
                                      ),
                                    ),
                                  );

                                  if (result != null && result == true) {
                                    await Provider.of<TransactionsModel>(
                                            context,
                                            listen: false)
                                        .fetchTransactions();
                                    Provider.of<TransactionsModel>(context,
                                            listen: false)
                                        .filterTransactions(
                                            context,
                                            _searchController.text
                                                .toLowerCase());
                                  }
                                },
                              )
                          ],
                        ),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.sentiment_dissatisfied,
                              size: 50,
                              color: Colors.white,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Sorry, nothing found',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ))
                : Center(
                    // <-- This will be displayed when the search box is empty
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.sentiment_very_satisfied,
                          size: 50,
                          color: Colors.white,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Please enter something to search',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: SearchScreen(),
    theme: ThemeData.dark(),
  ));
}
