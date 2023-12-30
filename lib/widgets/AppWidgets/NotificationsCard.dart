import 'package:expnz/database/TempTransactionsDB.dart';
import 'package:flutter/material.dart';

class NotificationCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final Color color;
  final String date;
  final String time;
  final int transactionId;
  final Function(int) onTap;
  final Function(int) onDelete;

  const NotificationCard({super.key,
    required this.title,
    required this.content,
    required this.icon,
    required this.color,
    required this.date, // Initialize date
    required this.time, // Initialize time
    required this.transactionId,
    required this.onTap,
    required this.onDelete,
  });

  void showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Transaction'),
        content: Text('Are you sure you want to delete this saved notification?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await TempTransactionsDB().deleteTransaction(transactionId);
              Navigator.pop(context);
              onDelete(transactionId); // Call the callback function after deletion
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: InkWell(
        onLongPress: () => showDeleteDialog(context),
        onTap: () => onTap(transactionId),
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            leading: Icon(
              icon,
              color: color,
              size: 30,
            ),
            title: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4), // Spacing between content and date/time
                Text(
                  "$date $time", // Displaying date and time
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            isThreeLine: true, // Set to true to accommodate the additional line
            dense: true,
          ),
        ),
      ),
    );
  }
}
