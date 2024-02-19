import 'package:flutter/material.dart';

import 'AddRecurringTransaction.dart';

class RecurringTransactionsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // This is a placeholder for your local data fetching logic
    final List<Map<String, dynamic>> recurringTransactions = [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Recurring Transactions'),
        backgroundColor: Colors.blueGrey[900],
      ),
      body: ListView.builder(
        itemCount: recurringTransactions.length,
        itemBuilder: (context, index) {
          var transaction = recurringTransactions[index];
          return ListTile(
            title: Text(transaction['name']),
            subtitle: Text(transaction['description']),
            trailing: Text('\$${transaction['amount']}'),
            // Add more details as needed
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddRecurringTransactionPage()),
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
