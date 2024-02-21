import 'package:expnz/utils/notification_manager.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/RecurringTransactionsDB.dart';
import '../widgets/SimpleWidgets/ModernSnackBar.dart';
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

              return FutureBuilder<String?>(
                future: NotificationManager().getNotificationTime(documentId),
                builder: (context, snapshot) {
                  String subtitle;
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.hasData && snapshot.data != null) {
                      // Format the date string if it's not null
                      DateTime? notificationTime = DateTime.tryParse(snapshot.data!);
                      if (notificationTime != null) {
                        subtitle = "${transaction?['frequency']} \n(Next reminder at ${DateFormat('yyyy-MM-dd HH:mm').format(notificationTime)})";
                      } else {
                        subtitle = "${transaction?['frequency']} (No reminder set)";
                      }
                    } else {
                      subtitle = "${transaction?['frequency']} (No reminder set)";
                    }
                  } else {
                    subtitle = "${transaction?['frequency']} (Loading reminder...)";
                  }

                  return Card(
                    margin: EdgeInsets.all(8.0),
                    child: ListTile(
                      title: Text(transaction?['name'] ?? 'Unknown'),
                      subtitle: Text(subtitle),
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
                      onLongPress: () {
                        showDeleteConfirmationDialog(
                          context: context,
                          title: "Delete Transaction",
                          content: "Are you sure you want to delete this transaction? This action cannot be undone.",
                          onConfirmDelete: () async {
                            await RecurringTransactionDB().softDeleteRecurringTransaction(documentId);
                            setState(() {}); // Update the UI if necessary
                          },
                        );
                      },
                    ),
                  );
                },
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
