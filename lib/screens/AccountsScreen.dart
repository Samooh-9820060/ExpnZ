import 'package:flutter/material.dart';

import '../widgets/AccountCard.dart';

class AccountsScreen extends StatefulWidget {
  @override
  _AccountsScreenState createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blueGrey[900],
      child: SingleChildScrollView(
        child: Column(
          children: [
            // ... (existing code)
            // Here we will add the modern-looking cards
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
    );
  }
}
