import 'package:expnz/screens/AddAccount.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../database/AccountsDB.dart';
import '../../utils/animation_utils.dart';
import 'package:expnz/utils/global.dart';

class ModernAccountCard extends StatefulWidget {
  final String documentId;
  final Map<String, dynamic> currencyMap;
  final int index;
  final double totalIncome;
  final double totalExpense;

  const ModernAccountCard({
    super.key,
    required this.documentId,
    required this.currencyMap,
    required this.index,
    required this.totalIncome,
    required this.totalExpense,
  });

  @override
  ModernAccountCardState createState() => ModernAccountCardState();
}

class ModernAccountCardState extends State<ModernAccountCard>
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
    final totalBalance = widget.totalIncome - widget.totalExpense;

    return ValueListenableBuilder<Map<String, Map<String, dynamic>>?>(
      valueListenable: accountsNotifier,
      builder: (context, accountsData, child) {
        if (accountsData != null &&
            accountsData.containsKey(widget.documentId)) {
          final accountDetails = accountsData[widget.documentId]!;
          return buildCard(accountDetails, widget.totalIncome,
              widget.totalExpense, totalBalance);
        } else {
          // If no account data is available, display a message
          return const Center(child: Text('No accounts available.'));
        }
      },
    );
  }

  Widget buildCard(Map<String, dynamic> account, double totalIncome,
      double totalExpense, double totalBalance) {
    int? iconCodePoint = account[AccountsDB.accountIconCodePoint] as int?;
    String? iconFontFamily =
        account[AccountsDB.accountIconFontFamily] as String?;
    String? iconFontPackage =
        account[AccountsDB.accountIconFontPackage] as String?;

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
        return Container(
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
                            text: account['name'] +
                                ' - (' +
                                widget.currencyMap['code'] +
                                ')',
                            style: GoogleFonts.roboto(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          iconData,
                          color: Colors.white,
                          size: 32,
                        ),
                        PopupMenuButton<String>(
                          onSelected: (String result) {
                            if (result == 'edit') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AddAccountScreen(documentId: widget.documentId),
                                ),
                              ).then((value) {
                                setState(() {});
                              });
                            } else if (result == 'delete') {
                              _showDeleteConfirmationDialog(context, widget.documentId);
                            }
                          },
                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete'),
                                ],
                              ),
                            ),
                          ],
                          icon: const Icon(Icons.more_vert, color: Colors.white),
                        ),
                      ],
                    ),
                  ]),
              const SizedBox(height: 16),
              // Card Number (Optional)
              Text(
                account['card_number'] != null &&
                        account['card_number']!.isNotEmpty
                    ? '**** **** **** ' + account['card_number']!
                    : ' ', // Replace with a placeholder if you want
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
                      animatedNumberString(_numberAnimation.value,
                          totalIncome.toString(), widget.currencyMap),
                      Colors.green,
                      Icons.arrow_upward),
                  infoColumn(
                      "Expense",
                      animatedNumberString(_numberAnimation.value,
                          totalExpense.toString(), widget.currencyMap),
                      Colors.red,
                      Icons.arrow_downward),
                ],
              ),
            ],
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
void _showDeleteConfirmationDialog(BuildContext context, String documentId) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Delete Account"),
        content: const Text(
            "Are you sure you want to delete this account? \n\nThis will delete all transactions associated with this account"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text("Delete"),
            onPressed: () async {
              AccountsDB().deleteAccount(documentId);

              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
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
