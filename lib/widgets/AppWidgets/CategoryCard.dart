import 'dart:convert';
import 'dart:io';
import 'package:expnz/screens/AddCategory.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../database/AccountsDB.dart';
import '../../database/CategoriesDB.dart';
import '../../database/TransactionsDB.dart';
import '../../utils/animation_utils.dart';
import '../../utils/global.dart';
import '../../utils/image_utils.dart';

class CurrencyTotal {
  final String currency;
  final double totalAmount;

  CurrencyTotal({required this.currency, required this.totalAmount});
}

class CategoryCard extends StatefulWidget {
  final String documentId;
  final String categoryName;
  final String? imagePath;
  final IconData iconDetails;
  final Color? primaryColor;
  final Animation<double> animation;
  final int index;



  const CategoryCard({super.key,
    required this.documentId,
    required this.categoryName,
    this.imagePath,
    required this.iconDetails,
    this.primaryColor,
    required this.animation,
    required this.index,
  });

  @override
  CategoryCardState createState() => CategoryCardState();
}

class CategoryCardState extends State<CategoryCard>
    with TickerProviderStateMixin {
  late AnimationController _numberController;
  late Animation<double> _numberAnimation;
  late AnimationController _deleteController;
  late Animation<double> _deleteAnimation;
  late Map<int, double> accountIncome;
  late Map<int, double> accountExpense;

  bool showMoreInfo = false;
  Future<File?>? _imageFileFuture;

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
    _deleteController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _deleteAnimation =
        Tween<double>(begin: 1, end: 0).animate(_deleteController);
    if (widget.imagePath != null) {
      String fileName = widget.imagePath != null ? generateFileNameFromUrl(widget.imagePath!) : 'default.jpg';
      _imageFileFuture = getImageFile(widget.imagePath!, fileName);
    }
  }

  @override
  void dispose() {
    _numberController.dispose();
    _deleteController.dispose();
    super.dispose();
  }

  Future<List<Widget>> _fetchAccountWidgets(String categoryId) async {
    final accountsData = accountsNotifier.value;
    Map<String, Map<String, double>> accountIncomeExpenses = await TransactionsDB().getIncomeExpenseForAccountsInCategory(categoryId);

    List<Widget> accountWidgets = [];
    for (var entry in accountsData.entries) {
      String documentId = entry.key;
      Map<String, dynamic> account = entry.value;
      Map<String, dynamic> currencyMap = jsonDecode(account[AccountsDB.accountCurrency]);

      // Fetching income and expense for the account
      double totalIncome = accountIncomeExpenses[documentId]?['totalIncome'] ?? 0.0;
      double totalExpense = accountIncomeExpenses[documentId]?['totalExpense'] ?? 0.0;

      // Extracting currency symbol or code from currencyMap
      String currencyCode = currencyMap['code'];

      String accountNameWithCurrency = '${account['name']} ($currencyCode)';

      if (totalIncome != 0.0 || totalExpense != 0.0) {
        accountWidgets.add(
          accountInfoRow(accountNameWithCurrency, totalIncome.toStringAsFixed(2), totalExpense.toStringAsFixed(2), currencyMap),
        );
      }
    }
    return accountWidgets;
  }
  Future<List<CurrencyTotal>> _fetchCurrencyTotals(String categoryId) async {
    final accountsData = accountsNotifier.value;
    Map<String, Map<String, double>> accountIncomeExpenses = await TransactionsDB().getIncomeExpenseForAccountsInCategory(categoryId);

    // Map to hold totals for each currency
    Map<String, double> currencyTotals = {};
    // Set to track which currencies have been used
    Set<String> usedCurrencies = Set<String>();

    for (var entry in accountsData.entries) {
      String documentId = entry.key;
      Map<String, dynamic> account = entry.value;
      Map<String, dynamic> currencyMap = jsonDecode(account[AccountsDB.accountCurrency]);
      String currencyCode = currencyMap['code'];

      double totalIncome = accountIncomeExpenses[documentId]?['totalIncome'] ?? 0.0;
      double totalExpense = accountIncomeExpenses[documentId]?['totalExpense'] ?? 0.0;

      if(totalIncome != 0.0 || totalExpense != 0.0) {
        usedCurrencies.add(currencyCode);
      }

      // Calculate net amount (income - expense)
      double netAmount = totalIncome - totalExpense;

      // Aggregate this net amount into the corresponding currency total
      if (!currencyTotals.containsKey(currencyCode)) {
        currencyTotals[currencyCode] = 0.0;
      }
      currencyTotals[currencyCode] = currencyTotals[currencyCode]! + netAmount;
    }

    // Convert the map into a list of CurrencyTotal objects, including only those currencies that have been used
    List<CurrencyTotal> currencyTotalList = currencyTotals.entries
        .where((entry) => usedCurrencies.contains(entry.key))
        .map((entry) => CurrencyTotal(currency: entry.key, totalAmount: entry.value))
        .toList();

    return currencyTotalList;
  }


  @override
  Widget build(BuildContext context) {
    return buildCard(widget.documentId, widget.imagePath);
  }


  Widget buildCard(String documentId, String? imageUrl) {
    return AnimatedBuilder(
      animation: _deleteController,
      builder: (context, child) {
        return Opacity(
          opacity: _deleteAnimation.value,
          child: child,
        );
      },
      child: AnimatedBuilder(
        animation: _numberController,
        builder: (context, child) {
          return Column(children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.black, Colors.grey[850]!],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    offset: const Offset(0, 4),
                    blurRadius: 6.0,
                  ),
                ],
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        FutureBuilder<File?>(
                          future: _imageFileFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const CircularProgressIndicator(); // Show loading indicator
                            } else if (snapshot.hasError || snapshot.data == null) {
                              return CircleAvatar(
                                backgroundColor: widget.primaryColor,
                                child: Icon(
                                  widget.iconDetails,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              );
                            } else {
                              return CircleAvatar(
                                backgroundColor: widget.primaryColor,
                                backgroundImage: snapshot.data != null ? FileImage(snapshot.data!) : null,
                              );
                            }
                          },
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            widget.categoryName,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (String result) {
                            if (result == 'edit') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AddCategoryScreen(documentId: widget.documentId),
                                ),
                              ).then((value) {
                                setState(() {});
                              });
                            } else if (result == 'delete') {
                              _showDeleteConfirmationDialog(context, documentId);
                            } else if (result == 'showInfo') {
                              setState(() {
                                if (showMoreInfo == false) {
                                  showMoreInfo = true;
                                  _numberController.reset();
                                  _numberController.forward();
                                } else {
                                  showMoreInfo = false;
                                  _numberController.reverse();
                                }
                              });
                            }
                          },
                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete'),
                                ],
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'showInfo',
                              child: Row(
                                children: [
                                  showMoreInfo ? const Icon(Icons.arrow_upward, color: Colors.green) : const Icon(Icons.arrow_downward, color: Colors.green),
                                  const SizedBox(width: 8),
                                  showMoreInfo ? const Text('Hide Info') : const Text('Show More Info'),
                                ],
                              ),
                            ),
                          ],
                          icon: const Icon(Icons.more_vert, color: Colors.white),
                        ),
                      ],
                    ),
                    if (showMoreInfo)
                      const SizedBox(height: 10),
                    if (showMoreInfo)
                      FutureBuilder<List<Widget>>(
                        future: _fetchAccountWidgets(widget.documentId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                "Error loading data: ${snapshot.error}",
                                style: const TextStyle(color: Colors.red, fontSize: 18),
                              ),
                            );
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.info_outline, color: Colors.red, size: 50.0),
                                  SizedBox(height: 10),
                                  Text(
                                    "No more info available",
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                                  ),
                                ],
                              ),
                            );
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: snapshot.data!,
                          );
                        },
                      ),
                    if (showMoreInfo)
                      const SizedBox(height: 20),
                    if (showMoreInfo)
                      FutureBuilder<List<CurrencyTotal>>(
                        future: _fetchCurrencyTotals(widget.documentId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Container();
                          }
                          if (snapshot.hasError) {
                            return Container();
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Container();
                          }
                          return Column(
                            children: snapshot.data!.map((currencyTotal) =>
                                Container(
                                  margin: const EdgeInsets.fromLTRB(0,4,12,4),
                                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [Colors.black, Colors.grey[850]!],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        offset: const Offset(0, 4),
                                        blurRadius: 6.0,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        currencyTotal.currency,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        currencyTotal.totalAmount.toStringAsFixed(2),
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ).toList(),
                          );
                        },
                      ),

                  ]),
            ),
          ]);
        },
      ),
    );
  }

  Widget accountInfoRow(String accountName, String income, String expense, Map<String, dynamic> currencyMap) {
    return AnimatedBuilder(
      animation: _numberController,
      builder: (context, child) {
        String animatedIncome = animatedNumberString(_numberAnimation.value, income, currencyMap);
        String animatedExpense = animatedNumberString(_numberAnimation.value, expense, currencyMap);

        // Define a fixed width for the amount containers
        const double amountWidth = 70.0; // You can adjust this value as needed

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                accountName,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.arrow_upward, color: Colors.green, size: 16),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: amountWidth,
                    child: Text(
                      animatedIncome,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.arrow_downward, color: Colors.red, size: 16),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: amountWidth,
                    child: Text(
                      animatedExpense,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

void _showDeleteConfirmationDialog(BuildContext context, String documentId) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Delete Category"),
        content: const Text(
            "Are you sure you want to delete this category?\n\n"
                "This will remove this category from all transactions with more than 1 category and remove categories from any transactions with this category only."),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text("Delete"),
            onPressed: () async {
              //await Provider.of<TransactionsModel>(context, listen: false).deleteTransactionsByCategoryId(categoryId, null, context);
              CategoriesDB().deleteCategory(documentId);
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}