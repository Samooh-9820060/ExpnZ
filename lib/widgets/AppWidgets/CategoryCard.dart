import 'dart:convert';
import 'dart:io';
import 'package:expnz/screens/AddCategory.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../database/AccountsDB.dart';
import '../../database/TransactionsDB.dart';
import '../../utils/animation_utils.dart';
import '../../utils/global.dart';
import '../../utils/image_utils.dart';


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
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AddCategoryScreen(documentId: widget.documentId),
                ),
              ).then((value) {
                setState(() {});
              });
            },
            child: Column(children: [
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
                          if (showMoreInfo)
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_upward,
                                size: 20.0,
                              ),
                              onPressed: () {
                                setState(() {
                                  showMoreInfo = false;
                                  _numberController.reverse();
                                });
                              },
                            ),
                          if (!showMoreInfo)
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_downward,
                                size: 20.0,
                              ),
                              onPressed: () {
                                setState(() {
                                  showMoreInfo = true;
                                  _numberController.reset();
                                  _numberController.forward();
                                });
                              },
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
                    ]),
              ),
            ]),
          );
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
                  fontSize: 12,
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
                        fontSize: 12,
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
                        fontSize: 12,
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
