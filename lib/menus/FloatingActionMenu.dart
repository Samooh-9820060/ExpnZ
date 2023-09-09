import 'package:expnz/models/AccountsModel.dart';
import 'package:expnz/models/CategoriesModel.dart';
import 'package:expnz/screens/AddAccount.dart';
import 'package:expnz/screens/AddCategory.dart';
import 'package:expnz/screens/AddTransaction.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/TransactionsModel.dart';

class FloatingActionMenu extends StatelessWidget {
  final bool isOpened;
  final VoidCallback closeMenu;

  FloatingActionMenu({required this.isOpened, required this.closeMenu});

  Widget buildMenuItem(BuildContext context, IconData icon, String label,
      Future<bool> Function() onPressed) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4), // Reduced vertical margin
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            offset: Offset(0, 4),
            blurRadius: 10.0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final result = await onPressed();
            if (result) {
              Provider.of<TransactionsModel>(context, listen: false).fetchTransactions();
              Provider.of<CategoriesModel>(context, listen: false).fetchCategories();
              Provider.of<AccountsModel>(context, listen: false).fetchAccounts();
            }
            closeMenu(); // Close the menu
          },
          borderRadius: BorderRadius.circular(50),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            // Reduced padding
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 20), // Reduced icon size
                SizedBox(width: 16), // Reduced width
                Text(
                  label,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16, // Reduced font size
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: Duration(milliseconds: 300),
      opacity: isOpened ? 1.0 : 0.0,
      child: ClipRect(
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          height: isOpened ? null : 0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              buildMenuItem(
                context,
                Icons.add_chart,
                "Add Transaction",
                () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AddTransactionScreen()),
                  );
                  return result != null && result == true;
                },
              ),
              buildMenuItem(context, Icons.payment, "Add Account", () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddAccountScreen()),
                );
                return result != null && result == true;
              }),
              buildMenuItem(context, Icons.payment, "Add Category", () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddCategoryScreen()),
                );
                return result != null && result == true;
              }),
            ],
          ),
        ),
      ),
    );
  }
}
