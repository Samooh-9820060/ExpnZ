import 'dart:convert';
import 'dart:io';
import 'package:expnz/screens/AddCategory.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../database/AccountsDB.dart';
import '../../database/CategoriesDB.dart';
import '../../database/ProfileDB.dart';
import '../../utils/animation_utils.dart';
import '../../utils/global.dart';
import '../../utils/image_utils.dart';

class CategoryCard extends StatefulWidget {
  final Key? key;
  final String documentId;
  final Animation<double> animation;

  CategoryCard({
    this.key,
    required this.documentId,
    required this.animation,
  }) : super(key: key);

  @override
  _CategoryCardState createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard>
    with TickerProviderStateMixin {
  late AnimationController _numberController;
  late Animation<double> _numberAnimation;
  late AnimationController _deleteController;
  late Animation<double> _deleteAnimation;
  late Map<int, double> accountIncome;
  late Map<int, double> accountExpense;

  bool showMoreInfo = false;

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
  }

  @override
  void dispose() {
    _numberController.dispose();
    _deleteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: profileNotifier,
      builder: (context, profileData, child) {
        return ValueListenableBuilder<Map<String, Map<String, dynamic>>?>(
          valueListenable: categoriesNotifier,
          builder: (context, categoriesData, child) {
            if (categoriesData != null && categoriesData.containsKey(widget.documentId)) {
              final categoryDetails = categoriesData[widget.documentId]!;
              final totalIncome = profileData != null && profileData['accounts'] != null && profileData['accounts'][widget.documentId] != null
                  ? (profileData['accounts'][widget.documentId]['totalIncome'] ?? 0).toDouble()
                  : 0.0;
              final totalExpense = profileData != null && profileData['accounts'] != null && profileData['accounts'][widget.documentId] != null
                  ? (profileData['accounts'][widget.documentId]['totalExpense'] ?? 0).toDouble()
                  : 0.0;
              final totalBalance = totalIncome - totalExpense;

              return buildCard(categoryDetails, totalIncome, totalExpense, totalBalance);
            } else {
              // If no account data is available, display a message
              return Center(child: Text('No accounts available.'));
            }
          },
        );
      },
    );
  }

  Widget buildCard(Map<String, dynamic> category, double totalIncome, double totalExpense, double totalBalance) {

    int? iconCodePoint = category[CategoriesDB.categoryIconCodePoint] as int?;
    String? iconFontFamily = category[CategoriesDB.categoryIconFontFamily] as String?;
    String? iconFontPackage = category[CategoriesDB.categoryIconFontPackage] as String?;

    IconData? iconData;
    if (iconCodePoint != null && iconFontFamily != null) {
      iconData = IconData(
        iconCodePoint,
        fontFamily: iconFontFamily,
        fontPackage: iconFontPackage,
      );
    } else {
      // Default icon in case of null values
      iconData = Icons.category_outlined;
    }

    Future<File?>? _imageFileFuture;
    if (category.containsKey(CategoriesDB.categorySelectedImageBlob) &&
        category[CategoriesDB.categorySelectedImageBlob] != null) {
      _imageFileFuture = bytesToFile(
        category[CategoriesDB.categorySelectedImageBlob] as List<int>,
      );
    }

    String? categoryName = category[CategoriesDB.categoryName];
    Color? primaryColor;
    if (category[CategoriesDB.categoryColor] != null) {
      primaryColor = Color(category[CategoriesDB.categoryColor] as int);
    }


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
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                      offset: Offset(0, 4),
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
                              if (_imageFileFuture == null) {
                                // _imageFileFuture is null, show the icon
                                return CircleAvatar(
                                  backgroundColor: primaryColor,
                                  child: Icon(
                                    iconData,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                );
                              } else if (snapshot.connectionState == ConnectionState.done) {
                                if (snapshot.hasError) {
                                  // Handle the error
                                  return CircleAvatar(
                                    backgroundColor: primaryColor,
                                    child: Icon(
                                      iconData,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  );
                                }

                                // File is ready
                                File? file = snapshot.data;
                                return CircleAvatar(
                                  backgroundColor: primaryColor,
                                  child: file == null ? Icon(iconData, color: Colors.white, size: 24) : null,
                                  backgroundImage: file != null ? FileImage(file) : null,
                                );
                              } else {
                                // File still loading
                                return CircularProgressIndicator();
                              }
                            },
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              categoryName!,
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            ValueListenableBuilder<Map<String, Map<String, dynamic>>?>(
                              valueListenable: accountsNotifier,
                              builder: (context, accountsData, child) {
                                // Ensure the accounts data is not null and not empty
                                if (accountsData == null || accountsData.isEmpty) {
                                  return const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: Colors.red,
                                          size: 50.0,
                                        ),
                                        SizedBox(height: 10),
                                        Text(
                                          "No accounts are there",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blueGrey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                return ValueListenableBuilder<Map<String, dynamic>?>(
                                  valueListenable: profileNotifier,
                                  builder: (context, profileData, child) {


                                    List<Widget> accountWidgets = [];
                                    accountsData.forEach((documentId, account) {
                                      // Fetch income and expense for each account from the category details
                                      Map<String, dynamic> incomeExpenseData = ProfileDB().getIncomeExpenseForCategory(widget.documentId)[documentId] ?? {};
                                      double income = (incomeExpenseData['totalIncome'] ?? 0).toDouble(); // Convert to double
                                      double expense = (incomeExpenseData['totalExpense'] ?? 0).toDouble(); // Convert to double
                                      Map<String, dynamic> currencyMap = jsonDecode(account[AccountsDB.accountCurrency]);

                                      accountWidgets.add(
                                        accountInfoRow(account['name'], income.toStringAsFixed(2), expense.toStringAsFixed(2), currencyMap),
                                      );
                                    });

                                    if (accountWidgets.isEmpty) {
                                      return const Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.info_outline,
                                              color: Colors.red,
                                              size: 50.0,
                                            ),
                                            SizedBox(height: 10),
                                            Text(
                                              "No more info available",
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blueGrey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }

                                    /*List<Widget> finalWidgets = [];
                              for (int i = 0; i < accountWidgets.length; i++) {
                                finalWidgets.add(accountWidgets[i]);
                                if (i < accountWidgets.length - 1) {
                                  finalWidgets.add(Divider(color: Colors.grey));
                                }
                              }*/

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: accountWidgets,
                                    );
                                  }
                                );
                            },
                          ),
                        ]),
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

        return Container(
          margin: EdgeInsets.symmetric(vertical: 4),
          padding: EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                accountName,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Icon(Icons.arrow_upward, color: Colors.green, size: 16),
                  SizedBox(width: 4),
                  Text(
                    animatedIncome,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 16),
                  Icon(Icons.arrow_downward, color: Colors.red, size: 16),
                  SizedBox(width: 4),
                  Text(
                    animatedExpense,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
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
