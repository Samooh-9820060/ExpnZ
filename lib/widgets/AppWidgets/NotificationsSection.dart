import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../database/TempTransactionsDB.dart';
import '../../models/TempTransactionsModel.dart';
import '../../screens/AddTransaction.dart';
import 'NotificationsCard.dart';

class NotificationsSection extends StatelessWidget {
  final AnimationController notificationCardController;
  final TempTransactionsModel tempTransactionsModel;

  const NotificationsSection({
    Key? key,
    required this.notificationCardController,
    required this.tempTransactionsModel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    tempTransactionsModel.fetchTransactions();
    return AnimatedBuilder(
      animation: notificationCardController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 300 * (1 - notificationCardController.value)),
          child: Opacity(
            opacity: notificationCardController.value,
            child: child,
          ),
        );
      },
      child: tempTransactionsModel.transactions.isEmpty
          ? Container() // If no data or empty data
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(30.0, 0.0, 0.0, 0.0),
            child: Text(
              'Notifications',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          ...tempTransactionsModel.transactions.map((transaction) {
            return NotificationCard(
              title: transaction[TempTransactionsDB
                  .columnTitle] ??
                  'No Title',
              content: transaction[TempTransactionsDB
                  .columnContent] ??
                  'No Content',
              icon: getIconBasedOnType(transaction[
              TempTransactionsDB.columnType]),
              color: getColorBasedOnType(transaction[
              TempTransactionsDB.columnType]),
              date: transaction[TempTransactionsDB
                  .columnDate] ??
                  '',
              time: transaction[TempTransactionsDB
                  .columnTime] ??
                  '',
              transactionId: transaction[
              TempTransactionsDB.columnId],
              // set this appropriately
              onTap: (int transactionId) async {
                await _handleNotificationCardClick(
                    context, transactionId);
              },
              onDelete: (int transactionId) {
                Provider.of<TempTransactionsModel>(
                    context,
                    listen: false)
                    .deleteTransactions(
                    transactionId, null, context);
                Provider.of<TempTransactionsModel>(
                    context,
                    listen: false)
                    .fetchTransactions();
              },
            );
          }).toList(),
          const SizedBox(height: 80), // Space at the bottom
        ],
      ),
    );
  }
}

IconData getIconBasedOnType(String? type) {
  // Logic to return an icon based on the transaction type
  switch (type) {
    case 'income':
      return Icons.arrow_upward; // Replace with actual icon
    case 'expense':
      return Icons.arrow_downward;
  // Add more cases as needed
    default:
      return Icons.question_mark; // Replace with a default icon
  }
}

Color getColorBasedOnType(String? type) {
  // Logic to return a color based on the transaction type
  switch (type) {
    case 'income':
      return Colors.green;
    case 'expense':
      return Colors.red;
    default:
      return Colors.yellow; // Replace with a default color
  }
}

Future<void> _handleNotificationCardClick(
    BuildContext context, int transactionId) async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) =>
          AddTransactionScreen(tempTransactionId: transactionId),
    ),
  );

  if (result == true) {
      Provider.of<TempTransactionsModel>(context, listen: false)
          .deleteTransactions(transactionId, null, context);
      Provider.of<TempTransactionsModel>(context, listen: false)
          .fetchTransactions();
    }
}


