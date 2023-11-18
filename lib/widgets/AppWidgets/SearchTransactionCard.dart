import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../database/AccountsDB.dart';
import '../../models/AccountsModel.dart';
import '../../models/CategoriesModel.dart';
import '../../utils/currency_utils.dart';
import '../../utils/image_utils.dart';

class TransactionCard extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final Function onDelete;
  final Function onUpdate;

  TransactionCard({required this.transaction,
    required this.onDelete,
    required this.onUpdate,
  });

  void showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Transaction'),
        content: Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              onDelete(); // Call the delete function
              Navigator.pop(context);
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final String name = transaction['name'] ?? 'Unknown';
    final String date = transaction['date'] != null
        ? transaction['date'].split('T')[0]
        : 'Unknown';
    final String time = transaction['time'] ?? 'Unknown';
    final double amount = transaction['amount'] ?? 0.0;
    final String type = transaction['type'] ?? 'Unknown';
    final String categoriesString = transaction['categories'] ?? '';
    final List<int> categoryIds = categoriesString
        .split(',')
        .map((e) => int.tryParse(e.trim()) ?? 0)
        .toList();

    final categoriesModel = Provider.of<CategoriesModel>(context);
    final int firstCategoryId = categoryIds.isNotEmpty ? categoryIds.first : 0;
    final Map<String, dynamic>? firstCategory = categoriesModel.getCategoryById(firstCategoryId);
    final Widget categoryWidget = getCategoryWidget(firstCategory);


    // Determine color based on transaction type
    final Color? amountColor = type == 'income'
        ? Colors.greenAccent[400]
        : (type == 'expense' ? Colors.redAccent[100] : Colors.white);

    return FutureBuilder<Object>(
      future: Provider.of<AccountsModel>(context, listen: false)
          .getAccountDetailsById(transaction['account_id']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          final account = snapshot.data;
          String accountName;
          String currencySymbol;
          Map<String, dynamic> currencyMap = new Map<String, dynamic>();

          if (account is Map<String, dynamic>) {
            accountName = account[AccountsDB.accountName] ?? 'Unknown';
            currencyMap =
                jsonDecode(account[AccountsDB.accountCurrency]);
            currencySymbol = currencyMap['symbol'] ?? 'Unknown';
            if (currencyMap['spaceBetweenAmountAndSymbol'] == true) {
              currencySymbol = currencySymbol+" ";
            }
          } else {
            accountName = 'Unknown';
            currencySymbol = 'Unknown';
          }

          // Use the utility functions to get the formatted symbol and amount
          String formattedSymbol = formatCurrencySymbol(
              currencyMap['symbol'] ?? 'Unknown',
              currencyMap['spaceBetweenAmountAndSymbol'] ?? false,
              currencyMap['symbolOnLeft'] ?? true
          );

          String formattedAmount = formatAmountWithSeparator(
              amount,
              currencyMap['thousandsSeparator'] ?? ',',
              currencyMap['decimalDigits'] ?? 2
          );


          return GestureDetector(
            onLongPress: () => showDeleteDialog(context),
            onTap: () => onUpdate(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18.0),
                  color: Colors.blueGrey[700],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              categoryWidget,
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      "$accountName • $date",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              time,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 10,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              currencyMap['symbolOnLeft']
                                  ? '$formattedSymbol$formattedAmount'
                                  : '$formattedAmount$formattedSymbol',
                              style: TextStyle(
                                color: amountColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }
}