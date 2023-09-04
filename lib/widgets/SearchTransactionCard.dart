import 'package:flutter/material.dart';

class TransactionCard extends StatelessWidget {
  final Map<String, dynamic> transaction;

  TransactionCard({required this.transaction});

  IconData getCategoryIcon(String category) {
    switch (category) {
      case 'Groceries':
        return Icons.shopping_cart;
      case 'Entertainment':
        return Icons.movie;
      case 'Others':
        return Icons.more_horiz;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.blueGrey[800],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blueGrey[700],
                  child: Icon(
                    getCategoryIcon(transaction['categories'][0]),
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(bottom: 5),
                      child: Text(
                        transaction['name'],
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Row(  // Added this Row to contain both account and date
                      children: [
                        Text(
                          transaction['account'],
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                        ),
                        Text(
                          ' • ',  // This is the bold dot
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          transaction['date'],
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            Text(
              '\$${transaction['amount']}',
              style: TextStyle(color: Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
