import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Padding(
          padding: EdgeInsets.only(left: 5),
          child: AutoSizeText(
            amount,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            minFontSize: 10, // Minimum font size you want to use
            overflow: TextOverflow.ellipsis, // To handle overflow if text is still too long
          ),
        ),
      ],
    );
  }
}