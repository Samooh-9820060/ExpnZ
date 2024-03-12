import 'package:flutter/material.dart';

import 'SummaryMonthCardWidget.dart';

class IncomeExpenseGraphs extends StatelessWidget {
  final AnimationController incomeCardController;
  final AnimationController expenseCardController;
  final double cardWidth;
  final Map<String, dynamic> financialData;
  final Map<String, dynamic> currencyMap;
  final String timeFrame;

  const IncomeExpenseGraphs({
    Key? key,
    required this.timeFrame,
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
        // Add some space below the card
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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