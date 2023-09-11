import 'package:flutter/material.dart';

class AccountCard extends StatelessWidget {
  final IconData icon;
  final String currency;
  final String accountName;
  final bool isSelected;
  final int accountId;
  double? verticalMargin;
  double? horizontalMargin;

  AccountCard({
    required this.icon,
    required this.currency,
    required this.accountName,
    this.isSelected = false,
    required this.accountId,
    this.horizontalMargin = 8,
    this.verticalMargin = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      margin: EdgeInsets.symmetric(vertical: verticalMargin!, horizontal: horizontalMargin!),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueGrey[700]!, Colors.blueGrey[800]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
        border: isSelected
            ? Border.all(color: Colors.blueAccent, width: 3)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 36),
          SizedBox(height: 8),
          Text(
            accountName,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 4),
          Text(
            currency,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w300, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
