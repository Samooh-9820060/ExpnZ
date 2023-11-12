import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/TransactionsModel.dart';
import '../../utils/animation_utils.dart';
import 'FinanceInfoCard.dart';

class FinanceCard extends StatefulWidget {
  final AnimationController cardController;
  final String totalBalance;
  final String income;
  final String expense;
  final IconData? optionalIcon;
  final Map<String, dynamic> currencyMap;

  FinanceCard({
    required this.cardController,
    required this.totalBalance,
    required this.income,
    required this.expense,
    required this.currencyMap,
    this.optionalIcon,
  });

  @override
  _FinanceCardState createState() => _FinanceCardState();
}

class _FinanceCardState extends State<FinanceCard> with SingleTickerProviderStateMixin {
  late AnimationController _numberController;
  late Animation<double> _numberAnimation;

  Future<Uint8List?> _loadImage(BuildContext context, String assetPath) async {
    try {
      ByteData data = await rootBundle.load(assetPath);
      return data.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

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
    return FractionallySizedBox(
      widthFactor: 1,
      child: AnimatedBuilder(
        animation: widget.cardController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 100 * (1 - widget.cardController.value)),
            child: Opacity(
              opacity: widget.cardController.value,
              child: child,
            ),
          );
        },
        child: FutureBuilder<Uint8List?>(
          future: _loadImage(context, 'assets/images/card.jpg'),
          builder: (context, snapshot) {
            return LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return AnimatedBuilder(
                  animation: _numberController,
                  builder: (context, child) {
                    return SizedBox(
                      height: 270,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Background Image Container
                            Container(
                              height: constraints.maxHeight,
                              width: constraints.maxWidth,
                              decoration: BoxDecoration(
                                image: snapshot.data != null
                                    ? DecorationImage(
                                        image: MemoryImage(snapshot.data!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            // Main Content Layer
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Title and Optional Icon
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Total Balance',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        widget.optionalIcon == null
                                            ? Container()
                                            : Icon(widget.optionalIcon,
                                                color: Colors.white),
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    // Total Balance
                                    Text(
                                      animatedNumberString(_numberAnimation.value,
                                           widget.totalBalance, widget.currencyMap),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 20),
                                    // Divider
                                    Divider(
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                    SizedBox(height: 20),
                                    // Income and Expense Cards
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        FinanceInfoCard(
                                          title: 'Income',
                                          amount: animatedNumberString(_numberAnimation.value,
                                              widget.income, widget.currencyMap),
                                          color: Colors.green[400]!,
                                          icon: Icons.arrow_upward,
                                        ),
                                        FinanceInfoCard(
                                          title: 'Expense',
                                          amount: animatedNumberString(_numberAnimation.value,
                                              widget.expense, widget.currencyMap),
                                          color: Colors.red[400]!,
                                          icon: Icons.arrow_downward,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
