import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expnz/screens/AddAccount.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../database/AccountsDB.dart';
import '../../models/AccountsModel.dart';
import '../../models/TransactionsModel.dart';
import '../../utils/animation_utils.dart';

class ModernAccountCard extends StatefulWidget {
  final String documentId;
  final Map<String, dynamic> currencyMap;

  ModernAccountCard({
    required this.documentId,
    required this.currencyMap,
  });

  @override
  _ModernAccountCardState createState() => _ModernAccountCardState();
}

class _ModernAccountCardState extends State<ModernAccountCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _numberController;
  late Animation<double> _numberAnimation;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _numberController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _numberAnimation =
        Tween<double>(begin: 0, end: 1).animate(_numberController);
    _numberController.forward();
  }

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection(AccountsDB.collectionName).doc(widget.documentId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError || !snapshot.data!.exists) {
          return Text('Error fetching account details');
        } else {
          final account = snapshot.data!.data() as Map<String, dynamic>;
          double totalIncome = account[AccountsDB.totalIncome] ?? 0.0;
          double totalExpense = account[AccountsDB.totalExpense] ?? 0.0;
          double totalBalance = totalIncome - totalExpense;
          IconData iconData = IconData(
            account[AccountsDB.accountIconCodePoint],
            fontFamily: account[AccountsDB.accountIconFontFamily],
            fontPackage: account[AccountsDB.accountIconFontPackage],
          );

          return AnimatedBuilder(
            animation: _numberController,
            builder: (context, child) {
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AddAccountScreen(documentId: widget.documentId),
                    ),
                  ).then((value) {
                    setState(() {});
                  });
                },
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  padding: const EdgeInsets.all(16),
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
                        offset: const Offset(0, 4),
                        blurRadius: 10.0,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: account['name']+' - ('+widget.currencyMap['code']+')',
                                    style: GoogleFonts.roboto(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              iconData,
                              color: Colors.white,
                              size: 32,
                            ),
                          ]),
                      const SizedBox(height: 16),
                      // Card Number (Optional)
                      Text(
                        account['card_number'] != null && account['card_number']!.isNotEmpty
                            ? '**** **** **** ' + account['card_number']!
                            : ' ',  // Replace with a placeholder if you want
                        style: GoogleFonts.robotoMono(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Balance
                      Text(
                        "Balance: ${animatedNumberString(_numberAnimation.value, totalBalance.toString(), widget.currencyMap)}",
                        style: GoogleFonts.roboto(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Income and Expense
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          infoColumn(
                              "Income",
                              animatedNumberString(_numberAnimation.value, totalIncome.toString(), widget.currencyMap),
                              Colors.green,
                              Icons.arrow_upward),
                          infoColumn(
                              "Expense",
                              animatedNumberString(_numberAnimation.value, totalExpense.toString(), widget.currencyMap),
                              Colors.red,
                              Icons.arrow_downward),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }

  Widget infoColumn(
      String title, String value, Color textColor, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: textColor, size: 18),
        const SizedBox(width: 4),
        Column(
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
