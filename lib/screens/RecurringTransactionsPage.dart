import 'package:expnz/utils/notification_manager.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/RecurringTransactionsDB.dart';
import '../widgets/SimpleWidgets/ExpnzSnackBar.dart';
import 'AddRecurringTransaction.dart';
import 'package:expnz/utils/global.dart';

import 'AddTransaction.dart'; // Import global utilities

class RecurringTransactionsPage extends StatefulWidget {
  const RecurringTransactionsPage({super.key});

  @override
  RecurringTransactionsPageState createState() => RecurringTransactionsPageState();
}

class RecurringTransactionsPageState extends State<RecurringTransactionsPage> {


  @override
  void initState() {
    super.initState();
    RecurringTransactionDB().updateScheduledNotifications();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        title: const Text('Recurring Transactions'),
        scrolledUnderElevation: 0.0,
        backgroundColor: Colors.blueGrey[900],
      ),
      body: ValueListenableBuilder<Map<String, Map<String, dynamic>>>(
        valueListenable: recurringTransactionsNotifier, // Use the notifier
        builder: (context, transactionsData, _) {
          var transactionsList = transactionsData.values.toList();

          if (transactionsList.isEmpty) {
            return const Center(
              child: Text('No recurring transactions found.'),
            );
          }

          // Sort the list based on due date
          transactionsList.sort((a, b) {
            var dateA = DateTime.tryParse(a['dueDate'] ?? '');
            var dateB = DateTime.tryParse(b['dueDate'] ?? '');
            return dateA?.compareTo(dateB ?? DateTime.now()) ?? -1;
          });

          // Create a list of transaction keys based on the sorted list
          List transactionKeys = transactionsList.map((e) => e['docKey']).toList();

          return ListView.builder(
            itemCount: transactionKeys.length,
            itemBuilder: (context, index) {
              String documentId = transactionKeys[index];
              var transaction = transactionsData[documentId];

              return FutureBuilder<Map<String, dynamic>?>(
                future: NotificationManager().getNotificationPayload(documentId),
                builder: (context, snapshot) {
                  String subtitle;
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.hasData && snapshot.data != null) {
                      // Format the date string if it's not null
                      DateTime? notificationTime;
                      try {
                        notificationTime = DateTime.parse(snapshot.data!['notificationTime']);
                      } catch (e) {
                        // Handle error or invalid format
                      }
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

                  // Inside ListView.builder itemBuilder:
                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    child: ListTile(
                      title: Text(transaction?['name'] ?? 'Unknown'),
                      subtitle: Text(subtitle),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min, // This is needed to keep the row size to a minimum
                        children: <Widget>[
                          Text(
                            transaction?['amount'] != null
                                ? double.tryParse(transaction?['amount'])?.toStringAsFixed(2) ?? ''
                                : 'Undefined',
                          ),
                          PopupMenuButton<String>(
                            onSelected: (String result) async {
                              switch (result) {
                                case 'Edit':
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
                                  break;
                                case 'Delete':
                                // Call your delete function
                                  showDeleteConfirmationDialog(
                                    context: context,
                                    title: "Delete Transaction",
                                    content: "Are you sure you want to delete this transaction? This action cannot be undone.",
                                    onConfirmDelete: () async {
                                      await RecurringTransactionDB().softDeleteRecurringTransaction(documentId);
                                      setState(() {}); // Update the UI if necessary
                                    },
                                  );
                                  break;
                                case 'Pay':
                                // Handle payment logic
                                  await _handlePayNowClick(
                                  context, documentId);
                                  setState(() {

                                  });
                                  break;
                                case 'MarkPaid':
                                  setState(() {
                                    RecurringTransactionDB().payRecurringTransaction(documentId);
                                  });
                                  showModernSnackBar(context: context, message: 'Due Date has been updated', backgroundColor: Colors.green);
                                  break;
                              }
                            },
                            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                              const PopupMenuItem<String>(
                                value: 'Edit',
                                child: Text('Edit Recurring Transaction'),
                              ),
                              const PopupMenuItem<String>(
                                value: 'Delete',
                                child: Text('Delete Recurring Transaction'),
                              ),
                              const PopupMenuItem<String>(
                                value: 'Pay',
                                child: Text('Pay Now'),
                              ),
                              const PopupMenuItem<String>(
                                value: 'MarkPaid',
                                child: Text('Mark as Paid'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      onTap: () {

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
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }
}

Future<void> _handlePayNowClick(
    BuildContext context, String transactionId) async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) =>
          AddTransactionScreen(recurringTransactionId: transactionId),
    ),
  );

  if (result == true) {
    RecurringTransactionDB().payRecurringTransaction(transactionId);
  }
}
