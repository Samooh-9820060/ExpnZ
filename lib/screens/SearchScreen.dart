import 'package:flutter/material.dart';

import '../widgets/AppWidgets/SearchTransactionCard.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> transactions = [
    {
      'categories': ['Groceries', 'Entertainment', 'Others'],
      'name': 'test10',
      'account': 'Savings',
      'date': '03 Sun, 06:31 PM',
      'amount': '200.00',
    },
    {
      'categories': ['Groceries', 'Entertainment', 'Others'],
      'name': 'test9',
      'account': 'Savings',
      'date': '03 Sun, 06:31 PM',
      'amount': '200.00',
    },
    {
      'categories': ['Groceries', 'Entertainment', 'Others'],
      'name': 'test8',
      'account': 'Savings',
      'date': '03 Sun, 06:31 PM',
      'amount': '200.00',
    },
    {
      'categories': ['Groceries', 'Entertainment', 'Others'],
      'name': 'test6',
      'account': 'Savings',
      'date': '03 Sun, 06:31 PM',
      'amount': '200.00',
    },
    {
      'categories': ['Groceries', 'Entertainment', 'Others'],
      'name': 'test5',
      'account': 'Savings',
      'date': '03 Sun, 06:31 PM',
      'amount': '200.00',
    },
    {
      'categories': ['Groceries', 'Entertainment', 'Others'],
      'name': 'test4',
      'account': 'Savings',
      'date': '03 Sun, 06:31 PM',
      'amount': '200.00',
    },
    {
      'categories': ['Groceries', 'Entertainment', 'Others'],
      'name': 'test3',
      'account': 'Savings',
      'date': '03 Sun, 06:31 PM',
      'amount': '200.00',
    },
    {
      'categories': ['Groceries', 'Entertainment', 'Others'],
      'name': 'test2',
      'account': 'Savings',
      'date': '03 Sun, 06:31 PM',
      'amount': '200.00',
    },
    {
      'categories': ['Groceries', 'Entertainment', 'Others'],
      'name': 'test1',
      'account': 'Savings',
      'date': '03 Sun, 06:31 PM',
      'amount': '200.00',
    },
    // Add more transactions here
  ];

  List<Map<String, dynamic>> filteredTransactions = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterTransactions);
  }

  void _filterTransactions() {
    String searchText = _searchController.text.toLowerCase();
    if (searchText.isNotEmpty) {
      List<Map<String, dynamic>> tempTransactions = [];
      for (var transaction in transactions) {
        if (transaction.values.any((element) => element.toString().toLowerCase().contains(searchText))) {
          tempTransactions.add(transaction);
        }
      }
      setState(() {
        filteredTransactions = tempTransactions;
      });
    } else {
      setState(() {
        filteredTransactions = [];
      });
    }
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
                padding: EdgeInsets.symmetric(vertical: 2),  // Reduced padding
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
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),  // Reduced padding
                          border: InputBorder.none,
                        ),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.filter_alt, color: Colors.white, size: 20),  // Reduced icon size
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
      body: Container(
        color: Colors.blueGrey[900],
        child: filteredTransactions.isNotEmpty
            ? SingleChildScrollView(
              child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Result',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
              for (var transaction in filteredTransactions)
                TransactionCard(
                  transaction: transaction,
                ),
          ],
        ),
            )
            : _searchController.text.isNotEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sentiment_dissatisfied,
                size: 50,
                color: Colors.white,
              ),
              Text(
                'Sorry, nothing found',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        )
            : Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sentiment_very_satisfied,
                size: 50,
                color: Colors.white,
              ),
              Text(
                'Please enter something to search',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: SearchScreen(),
    theme: ThemeData.dark(),
  ));
}
