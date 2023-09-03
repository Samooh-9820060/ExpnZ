import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ModernAccountCard extends StatelessWidget {
  final String accountName;
  final String totalBalance;
  final String income;
  final String expense;
  final String? cardNumber;
  final String currency;

  ModernAccountCard({
    required this.accountName,
    required this.totalBalance,
    required this.income,
    required this.expense,
    this.cardNumber,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.black, Colors.grey[850]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            offset: Offset(0, 4),
            blurRadius: 10.0,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Currency Symbol at the top-left corner
          Positioned(
            top: 10,
            child: Text(
              currency,
              style: GoogleFonts.roboto(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          // Custom design element in the top-right corner
          Positioned(
            top: 10,
            right: 10,
            child: CustomPaint(
              size: Size(40, 40),
              painter: MyPainter(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 50, 0, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Optional Card Number or Placeholder
                if (cardNumber != null)
                  Text(
                    cardNumber!,
                    style: GoogleFonts.robotoMono(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                else
                  SizedBox(height: 24), // Placeholder
                SizedBox(height: 24),
                // Account name
                Text(
                  accountName,
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                SizedBox(height: 16),
                // Balance, Income, and Expense
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    infoColumn("Balance", totalBalance, Colors.white),
                    infoColumn("Income", income, Colors.green),
                    infoColumn("Expense", expense, Colors.red),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Column infoColumn(String title, String value, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.roboto(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

class MyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 2.0;

    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, 0),
      paint,
    );

    canvas.drawLine(
      Offset(0, size.height * 0.5),
      Offset(size.width * 0.5, 0),
      paint,
    );

    canvas.drawLine(
      Offset(size.width * 0.5, size.height),
      Offset(size.width, size.height * 0.5),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
