import 'package:flutter/material.dart';

import 'SummaryMonthCardWidget.dart';

class MonthlySummaryCards extends StatelessWidget {
  final AnimationController incomeCardController;
  final AnimationController expenseCardController;
  final double cardWidth;
  final Map<String, dynamic> financialData;
  final Map<String, dynamic> currencyMap;

  const MonthlySummaryCards({
    Key? key,
    required this.incomeCardController,
    required this.expenseCardController,
    required this.cardWidth,
    required this.financialData,
    required this.currencyMap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        // Add some space below the card
        AnimatedBuilder(
          animation: incomeCardController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(-300 * (1 - incomeCardController.value), 0),
              child: Opacity(
                opacity: incomeCardController.value,
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(30.0, 0.0, 0.0, 5.0),
                  child: Text(
                    'This Month',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Income Card
              AnimatedBuilder(
                animation: incomeCardController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                        -300 * (1 - incomeCardController.value),
                        0),
                    child: Opacity(
                      opacity: incomeCardController.value,
                      child: child,
                    ),
                  );
                },
                child: SummaryMonthCardWidget(
                  width: cardWidth,
                  title: 'Income',
                  total: financialData['periodIncome'].toString(),
                  currencyMap: currencyMap,
                  data: financialData['graphDataIncome'],
                  graphLineColor: Colors.green,
                  iconData: Icons.arrow_upward,
                ),
              ),
              // Expense Card
              AnimatedBuilder(
                animation: expenseCardController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                        300 * (1 - expenseCardController.value),
                        0),
                    child: Opacity(
                      opacity: expenseCardController.value,
                      child: child,
                    ),
                  );
                },
                child: SummaryMonthCardWidget(
                  width: cardWidth,
                  title: 'Expense',
                  total:
                  financialData['periodExpense'].toString(),
                  currencyMap: currencyMap,
                  data: financialData['graphDataExpense'],
                  graphLineColor: Colors.red,
                  iconData: Icons.arrow_downward,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}