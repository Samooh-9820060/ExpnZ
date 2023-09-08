import 'dart:convert';

import 'package:flutter/material.dart';

class TransactionCard extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final String accountName;

  TransactionCard({required this.transaction, required this.accountName});

  IconData getCategoryIcon(int iconCode) {
    return IconData(
      iconCode,
      fontFamily: 'MaterialIcons',
    );
  }

  @override
  Widget build(BuildContext context) {
    final String name = transaction['name'] ?? 'Unknown';
    final String account = accountName;
    final String date = transaction['date'] != null
        ? transaction['date'].split('T')[0]
        : 'Unknown';
    final String time = transaction['time'] ?? 'Unknown';
    final double amount = transaction['amount'] ?? 0.0;
    final String type = transaction['type'] ?? 'Unknown';
    final List<dynamic> categories = jsonDecode(transaction['categories'] ?? '[]');
    final int categoryIcon = categories.isNotEmpty ? categories[0]['icon'] : Icons.help_outline.codePoint;

    // Determine color based on transaction type
    final Color? amountColor = type == 'income' ? Colors.greenAccent[400] : (type == 'expense' ? Colors.redAccent[100] : Colors.white);


    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18.0),
          color: Colors.blueGrey[700],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.blueGrey[800],
                      child: Icon(
                        getCategoryIcon(categoryIcon),
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "$account • $date",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 10,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '\$$amount',
                      style: TextStyle(
                        color: amountColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
