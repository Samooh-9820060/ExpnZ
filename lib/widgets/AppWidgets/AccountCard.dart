import 'package:expnz/screens/AddAccount.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ModernAccountCard extends StatefulWidget {
  final int accountId;
  final String accountName;
  final String totalBalance;
  final String income;
  final String expense;
  final String? cardNumber;
  final String currency;
  final IconData iconData;

  ModernAccountCard({
    required this.accountId,
    required this.accountName,
    required this.totalBalance,
    required this.income,
    required this.expense,
    this.cardNumber,
    required this.currency,
    required this.iconData,
  });

  @override
  _ModernAccountCardState createState() => _ModernAccountCardState();
}

class _ModernAccountCardState extends State<ModernAccountCard> with SingleTickerProviderStateMixin {
  late AnimationController _numberController;
  late Animation<double> _numberAnimation;

  @override
  void initState() {
    super.initState();
    _numberController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _numberAnimation = Tween<double>(begin: 0, end: 1).animate(_numberController);
    _numberController.forward();
  }

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  String _animatedNumberString(double animationValue, String targetValue) {
    int value = (double.parse(targetValue.replaceAll(RegExp(r'[\$,]'), '')) * animationValue).toInt();
    final formatter = NumberFormat("#,###");
    return '\$' + formatter.format(value);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _numberController,
      builder: (context, child) {
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddAccountScreen(accountId: this.widget.accountId),
              ),
            ).then((value) {
              setState(() {});
            });
          },
          child: Container(
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
                // Add this Positioned widget to display the icon
                Positioned(
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      widget.iconData, // replace with the icon you want to use
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                // Currency Symbol at the top-left corner
                Positioned(
                  top: 10,
                  child: Text(
                    widget.currency,
                    style: GoogleFonts.roboto(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Custom design element in the top-right corner
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 50, 0, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Optional Card Number or Placeholder
                      if (widget.cardNumber != null && widget.cardNumber!.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 15),
                          child: Text(
                            '**** **** **** '+widget.cardNumber!,
                            style: GoogleFonts.robotoMono(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        )
                      else
                        SizedBox(height: 24), // Placeholder
                      SizedBox(height: 24),
                      // Account name
                      Text(
                        widget.accountName,
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
                          infoColumn("Balance", _animatedNumberString(_numberAnimation.value, widget.totalBalance), Colors.white),
                          infoColumn("Income", _animatedNumberString(_numberAnimation.value, widget.income), Colors.green),
                          infoColumn("Expense", _animatedNumberString(_numberAnimation.value, widget.expense), Colors.red),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
