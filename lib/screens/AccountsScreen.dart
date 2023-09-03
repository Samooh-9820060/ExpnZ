import 'package:flutter/material.dart';

import '../widgets/AccountCard.dart';

class AccountsScreen extends StatefulWidget {
  @override
  _AccountsScreenState createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> with TickerProviderStateMixin {
  late AnimationController _accountCardController;

  @override
  void initState() {
    super.initState();

    _accountCardController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _accountCardController.forward();
    });
  }

  @override
  void dispose() {
    _accountCardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blueGrey[900],
      child: SingleChildScrollView(
        child: Column(
          children: [
            // ... (existing code)
            // Here we will add the modern-looking cards with animations
            AnimatedBuilder(
              animation: _accountCardController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 300 * (1 - _accountCardController.value)),
                  child: Opacity(
                    opacity: _accountCardController.value,
                    child: child,
                  ),
                );
              },
              child: Column(
                children: [
                  ModernAccountCard(
                    accountName: "Primary Account",
                    totalBalance: "\$12,345",
                    income: "+\$6,789",
                    expense: "-\$1,234",
                    cardNumber: "**** **** **** 1234",
                    currency: 'MVR',
                  ),
                  ModernAccountCard(
                    accountName: "Primary Account",
                    totalBalance: "\$12,345",
                    income: "+\$6,789",
                    expense: "-\$1,234",
                    currency: 'USD',
                  ),
                  ModernAccountCard(
                    accountName: "Primary Account",
                    totalBalance: "\$12,345",
                    income: "+\$6,789",
                    expense: "-\$1,234",
                    currency: 'USD',
                  ),
                  ModernAccountCard(
                    accountName: "Primary Account",
                    totalBalance: "\$12,345",
                    income: "+\$6,789",
                    expense: "-\$1,234",
                    currency: 'USD',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 80.0),  // Add 80.0 or whatever value that suits you
            ),
          ],
        ),
      ),
    );
  }
}
