import 'package:flutter/material.dart';
import 'AddRecurringTransaction.dart';
import 'package:expnz/utils/global.dart'; // Import global utilities

class RecurringTransactionsPage extends StatefulWidget {
  @override
  _RecurringTransactionsPageState createState() => _RecurringTransactionsPageState();
}

class _RecurringTransactionsPageState extends State<RecurringTransactionsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recurring Transactions'),
        backgroundColor: Colors.blueGrey[900],
      ),
      body: ValueListenableBuilder<Map<String, Map<String, dynamic>>>(
        valueListenable: recurringTransactionsNotifier, // Use the notifier
        builder: (context, transactionsData, _) {
          var transactionsList = transactionsData.values.toList();

          if (transactionsList.isEmpty) {
            return Center(
              child: Text('No recurring transactions found.'),
            );
          }

          // Create a list of transaction keys
          List<String> transactionKeys = transactionsData.keys.toList();

          return ListView.builder(
            itemCount: transactionKeys.length,
            itemBuilder: (context, index) {
              String documentId = transactionKeys[index];
              var transaction = transactionsData[documentId];
              return Card(
                margin: EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(transaction?['name'] ?? 'Unknown'),
                  subtitle: Text(transaction?['description'] ?? 'No description'),
                  trailing: Text('${transaction?['amount']?.toStringAsFixed(2) ?? 'Undefined'}'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddRecurringTransactionPage(
                          documentId: documentId,
                        ),
                      ),
                    ).then((value) {
                      setState(() {});
                    });
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddRecurringTransactionPage()),
          ).then((_) {
            // Optionally refresh the state when returning from the add transaction page
            setState(() {});
          });
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
