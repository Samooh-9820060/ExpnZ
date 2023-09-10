import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/TransactionsModel.dart';
import '../widgets/AppWidgets/SearchTransactionCard.dart';
import 'AddTransaction.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> filteredTransactions = [];

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
                        // Add filter logic here
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
          print(transactionsToShow);
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
                                      .deleteTransactions(transaction['_id'],
                                          _searchController.text.toLowerCase(), context);
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
                                        .filterTransactions(context, _searchController
                                            .text
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
