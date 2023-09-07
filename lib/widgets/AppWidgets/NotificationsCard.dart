import 'package:flutter/material.dart';

class NotificationCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final Color color;

  NotificationCard({
    required this.title,
    required this.content,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          leading: Icon(
            icon,
            color: color,
            size: 20,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          subtitle: Text(
            content,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white,
            ),
          ),
          isThreeLine: false,
          dense: true,
        ),
      ),
    );
  }
}
