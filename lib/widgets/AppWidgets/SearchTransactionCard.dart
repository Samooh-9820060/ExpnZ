import 'dart:convert';
import 'package:flutter/material.dart';
import '../../utils/currency_utils.dart';
import '../../utils/global.dart';

class TransactionCard extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final Function onDelete;
  final Function onUpdate;

  const TransactionCard({super.key, required this.transaction,
    required this.onDelete,
    required this.onUpdate,
  });

  void showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              onDelete(); // Call the delete function
              Navigator.pop(context);
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.white, // Set the text color to white
              ),
            ),

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
    final dynamic rawAmount = transaction['amount'] ?? 0.0;
    final double amount = rawAmount is int ? rawAmount.toDouble() : (rawAmount as double);
    final String type = transaction['type'] ?? 'Unknown';
    final String categoriesString = transaction['categories'] ?? '';
    final List<String> categoryIds = categoriesString.split(',');

    // Determine color based on transaction type
    final Color? amountColor = type == 'income'
        ? Colors.greenAccent[400]
        : (type == 'expense' ? Colors.redAccent[100] : Colors.white);

    return FutureBuilder<Object>(
      future: _fetchAccountDetails(transaction['account_id']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          final Map<String, dynamic> account = snapshot.data as Map<String, dynamic>;
          final String accountName = account['name'] ?? 'Unknown';
          final Map<String, dynamic> currencyMap = jsonDecode(account['currency'] ?? '{}');

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

          // Build category widgets
          List<Widget> categoryWidgets = categoryIds.map((categoryId) {
            return _buildCategoryWidget(categoryId);
          }).toList();

          return GestureDetector(
            onLongPress: () => showDeleteDialog(context),
            onTap: () => onUpdate(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 5),
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
                        ...categoryWidgets,
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              const SizedBox(height: 2),
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
                            const SizedBox(height: 6),
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

  Future<Map<String, dynamic>> _fetchAccountDetails(String accountId) async {
    // Implementation to fetch account details either from the notifier or database
    final accountsData = accountsNotifier.value;
    return accountsData[accountId] ?? {};
  }

  Widget _buildCategoryWidget(String categoryId) {
    // Retrieve the category's details
    final categoryDetails = categoriesNotifier.value[categoryId] ?? {};

    // Check if the categoryDetails is not empty
    if (categoryDetails.isNotEmpty) {
      IconData? iconData;

      if (categoryDetails.containsKey('iconCodePoint') && categoryDetails['iconCodePoint'] != null) {
        int? iconCodePoint = int.tryParse(categoryDetails['iconCodePoint'].toString());
        String? iconFontFamily = categoryDetails['iconFontFamily'] as String?;
        String? iconFontPackage = categoryDetails['iconFontPackage'] as String?;

        if (iconCodePoint != null && iconFontFamily != null) {
          iconData = IconData(iconCodePoint, fontFamily: iconFontFamily, fontPackage: iconFontPackage);
        }
      }

      iconData ??= Icons.category;

      return Container(
        alignment: Alignment.center, // Center the icon vertically and horizontally
        child: Icon(iconData, size: 20),
      );
    } else {
      // Return an empty container or a placeholder if categoryDetails is empty
      return Container();
    }
  }
}