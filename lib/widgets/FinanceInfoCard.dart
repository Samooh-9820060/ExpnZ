import 'package:flutter/material.dart';

class FinanceInfoCard extends StatelessWidget {
  final String title;
  final String amount;
  final Color color;
  final IconData icon;

  FinanceInfoCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start, // Added this
          children: [
            Icon(icon, color: color, size: 20), // Added icon
            SizedBox(width: 4), // Added space between icon and text
            Text(
              title,
              style: TextStyle(
                  color: color, fontSize: 14, fontWeight: FontWeight.w500), // Adjusted font size
            ),
          ],
        ),
        Padding(
          padding: EdgeInsets.only(left: 5),  // Added padding to align with above text
          child: Text(
            amount,
            style: TextStyle(
                color: color, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
