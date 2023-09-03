import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'FinanceInfoCard.dart';

class FinanceCard extends StatelessWidget {
  final AnimationController cardController;
  final String totalBalance;
  final String income;
  final String expense;
  final IconData? optionalIcon;

  FinanceCard({
    required this.cardController,
    required this.totalBalance,
    required this.income,
    required this.expense,
    this.optionalIcon,
  });

  Future<Uint8List?> _loadImage(BuildContext context, String assetPath) async {
    try {
      ByteData data = await rootBundle.load(assetPath);
      return data.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: 1,
      child: AnimatedBuilder(
        animation: cardController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 100 * (1 - cardController.value)),
            child: Opacity(
              opacity: cardController.value,
              child: child,
            ),
          );
        },
        child: FutureBuilder<Uint8List?>(
          future: _loadImage(context, 'assets/images/card.jpg'),
          builder: (context, snapshot) {
            return LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
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
                            //color: Colors.blue,
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
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total Balance',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    optionalIcon == null
                                        ? Container()
                                        : Icon(optionalIcon, color: Colors.white),
                                  ],
                                ),
                                SizedBox(height: 10),
                                // Total Balance
                                Text(
                                  totalBalance,
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
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    FinanceInfoCard(
                                        title: 'Income',
                                        amount: income,
                                        color: Colors.green[400]!,
                                        icon: Icons.arrow_upward),
                                    FinanceInfoCard(
                                        title: 'Expense',
                                        amount: expense,
                                        color: Colors.red[400]!,
                                        icon: Icons.arrow_downward),
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
        ),
      ),
    );
  }
}
