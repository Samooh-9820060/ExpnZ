import 'package:expnz/screens/AddAccount.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../database/AccountsDB.dart';
import '../../database/TransactionsDB.dart';
import '../../utils/animation_utils.dart';
import 'package:expnz/utils/global.dart';

class ModernAccountCard extends StatefulWidget {
  final String documentId;
  final Map<String, dynamic> currencyMap;
  final int index;

  ModernAccountCard({
    required this.documentId,
    required this.currencyMap,
    required this.index,
  });

  @override
  _ModernAccountCardState createState() => _ModernAccountCardState();
}

class _ModernAccountCardState extends State<ModernAccountCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _numberController;
  late Animation<double> _numberAnimation;

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
    return FutureBuilder<Map<String, double>>(
      future: TransactionsDB().getTotalIncomeAndExpenseForAccount(widget.documentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.index == 0 ? const Center(child: CircularProgressIndicator()) : Container();
        } else if (snapshot.hasError) {
          print(snapshot.error);
          // Handle any errors here
          return Center(child: Text('Error fetching data.'));
        } else if (snapshot.hasData) {
          final totalIncome = snapshot.data!['totalIncome'] ?? 0.0;
          final totalExpense = snapshot.data!['totalExpense'] ?? 0.0;
          final totalBalance = totalIncome - totalExpense;

          return ValueListenableBuilder<Map<String, Map<String, dynamic>>?>(
            valueListenable: accountsNotifier,
            builder: (context, accountsData, child) {
              if (accountsData != null && accountsData.containsKey(widget.documentId)) {
                final accountDetails = accountsData[widget.documentId]!;
                return buildCard(accountDetails, totalIncome, totalExpense, totalBalance);
              } else {
                // If no account data is available, display a message
                return Center(child: Text('No accounts available.'));
              }
            },
          );
        } else {
          // Handle the case where there is no data
          return Center(child: Text('No data available.'));
        }
      },
    );
  }


  Widget buildCard(Map<String, dynamic> account, double totalIncome, double totalExpense, double totalBalance) {
    int? iconCodePoint = account[AccountsDB.accountIconCodePoint] as int?;
    String? iconFontFamily = account[AccountsDB.accountIconFontFamily] as String?;
    String? iconFontPackage = account[AccountsDB.accountIconFontPackage] as String?;

    IconData? iconData;
    if (iconCodePoint != null && iconFontFamily != null) {
      iconData = IconData(
        iconCodePoint,
        fontFamily: iconFontFamily,
        fontPackage: iconFontPackage,
      );
    } else {
      // Default icon in case of null values
      iconData = Icons.account_balance_wallet;
    }

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
