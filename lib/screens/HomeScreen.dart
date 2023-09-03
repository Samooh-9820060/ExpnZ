import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../widgets/FinanceCard.dart';
import '../widgets/FinanceInfoCard.dart';
import '../widgets/NotificationsCard.dart';
import '../widgets/SummaryMonthCardWidget.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _nameController;
  late AnimationController _cardController;
  late AnimationController _incomeCardController;
  late AnimationController _expenseCardController;
  late AnimationController _notificationCardController;


  @override
  void initState() {
    super.initState();

    _nameController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _incomeCardController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _expenseCardController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _notificationCardController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _nameController.forward();
      _cardController.forward();
      _incomeCardController.forward();
      _expenseCardController.forward();
      _notificationCardController.forward();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cardController.dispose();
    _incomeCardController.dispose();
    _expenseCardController.dispose();
    _notificationCardController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    double cardWidth = MediaQuery.of(context).size.width / 2.25;  // About half of the screen width, adjust the divisor as needed

    return Container(
      color: Colors.blueGrey[900],
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Animated "Name" and "Welcome Back!"
            AnimatedBuilder(
              animation: _nameController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(-300 * (1 - _nameController.value), 0),
                  child: Opacity(
                    opacity: _nameController.value,
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(30.0, 10.0, 16.0, 0.0),
                // Reduced top padding to 50
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Samooh Moosa',
                      style: TextStyle(
                          fontSize: 25, // Reduced font size
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Welcome Back!',
                      style: TextStyle(
                        fontSize: 15, // Reduced font size
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Animated Balance Card
            FinanceCard(
              cardController: _cardController,
              totalBalance: "\$5,000",
              income: "+\$3,000",
              expense: "-\$3,000",
              optionalIcon: Icons.credit_card,
            ),
            SizedBox(height: 10), // Add some space below the card

            AnimatedBuilder(
              animation: _nameController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(-300 * (1 - _nameController.value), 0),
                  child: Opacity(
                    opacity: _nameController.value,
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(30.0, 0.0, 0.0, 0.0),
                child: Text(
                  'This Month',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Income Card
                  AnimatedBuilder(
                    animation: _incomeCardController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(-300 * (1 - _incomeCardController.value), 0),
                        child: Opacity(
                          opacity: _incomeCardController.value,
                          child: child,
                        ),
                      );
                    },
                    child: SummaryMonthCardWidget(
                      width: cardWidth,
                      title: 'Income',
                      total: '\$10,000',
                      data: [0.0, 3.0, 1.0, 4.2, 3.2, 1.0],
                      graphLineColor: Colors.green,
                      iconData: Icons.arrow_downward,
                    ),
                  ),

                  // Expense Card
                  AnimatedBuilder(
                    animation: _expenseCardController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(300 * (1 - _expenseCardController.value), 0),
                        child: Opacity(
                          opacity: _expenseCardController.value,
                          child: child,
                        ),
                      );
                    },
                    child: SummaryMonthCardWidget(
                      width: cardWidth,
                      title: 'Expense',
                      total: '\$5,000',
                      data: [0.0, 1.1, 3.4, 5.3, 0.2, 4.0],
                      graphLineColor: Colors.red,
                      iconData: Icons.arrow_upward,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            AnimatedBuilder(
              animation: _nameController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(-300 * (1 - _nameController.value), 0),
                  child: Opacity(
                    opacity: _nameController.value,
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(30.0, 0.0, 0.0, 0.0),
                child: Text(
                  'Notifications',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(height: 10),
            // Animated Notifications Section
            AnimatedBuilder(
              animation: _notificationCardController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 300 * (1 - _notificationCardController.value)),
                  child: Opacity(
                    opacity: _notificationCardController.value,
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0), // Left and Right Padding
                child: Column(
                  children: [
                    NotificationCard(
                      title: "Large Transaction Alert",
                      content: "A transaction of \$500 was made at ABC Store.",
                      icon: Icons.warning_amber_outlined,
                      color: Colors.orange,
                    ),
                    NotificationCard(
                      title: "Bill Due Soon",
                      content: "Your electricity bill of \$120 is due in 3 days.",
                      icon: Icons.calendar_today_outlined,
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 80.0),  // Add 60.0 or whatever value that suits you
            ),
          ],
        ),
      ),
    );
  }
}
