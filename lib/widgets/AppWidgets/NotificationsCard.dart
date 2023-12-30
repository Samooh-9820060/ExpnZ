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

  const NotificationCard({super.key,
    required this.title,
    required this.content,
    required this.icon,
    required this.color,
    required this.date, // Initialize date
    required this.time, // Initialize time
    required this.transactionId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: InkWell(
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
