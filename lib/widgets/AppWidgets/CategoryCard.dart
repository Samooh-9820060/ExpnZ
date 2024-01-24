import 'dart:convert';
import 'dart:io';
import 'package:expnz/screens/AddCategory.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../database/AccountsDB.dart';
import '../../database/CategoriesDB.dart';
import '../../database/ProfileDB.dart';
import '../../database/TransactionsDB.dart';
import '../../utils/animation_utils.dart';
import '../../utils/global.dart';
import '../../utils/image_utils.dart';


class CategoryCard extends StatefulWidget {
  final Key? key;
  final String documentId;
  final Animation<double> animation;
  final int index;

  CategoryCard({
    this.key,
    required this.documentId,
    required this.animation,
    required this.index,
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

  Future<List<Widget>> _fetchAccountWidgets(String categoryId) async {
    final accountsData = accountsNotifier.value ?? {};
    Map<String, Map<String, double>> accountIncomeExpenses = await TransactionsDB().getIncomeExpenseForAccountsInCategory(categoryId);

    List<Widget> accountWidgets = [];
    for (var entry in accountsData.entries) {
      String documentId = entry.key;
      Map<String, dynamic> account = entry.value;
      Map<String, dynamic> currencyMap = jsonDecode(account[AccountsDB.accountCurrency]);

      // Fetching income and expense for the account
      double totalIncome = accountIncomeExpenses[documentId]?['totalIncome'] ?? 0.0;
      double totalExpense = accountIncomeExpenses[documentId]?['totalExpense'] ?? 0.0;

      accountWidgets.add(
        accountInfoRow(account['name'], totalIncome.toStringAsFixed(2), totalExpense.toStringAsFixed(2), currencyMap),
      );
    }
    return accountWidgets;
  }


  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, Map<String, dynamic>>?>(
      valueListenable: categoriesNotifier,
      builder: (context, categoriesData, child) {
        if (categoriesData != null && categoriesData.containsKey(widget.documentId)) {
          final categoryDetails = categoriesData[widget.documentId]!;

          return ValueListenableBuilder<Map<String, Map<String, dynamic>>?>(
            valueListenable: accountsNotifier,
            builder: (context, accountsData, child) {
              return FutureBuilder<Map<String, Map<String, double>>>(
                future: TransactionsDB().getIncomeAndExpenseByAccountForCategory(widget.documentId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return widget.index == 0 ? const Center(child: CircularProgressIndicator()) : Container();
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error fetching data.'));
                  } else if (snapshot.hasData) {
                    double totalIncome = 0.0;
                    double totalExpense = 0.0;

                    snapshot.data!.forEach((accountId, totals) {
                      totalIncome += totals['totalIncome'] ?? 0.0;
                      totalExpense += totals['totalExpense'] ?? 0.0;
                    });

                    double totalBalance = totalIncome - totalExpense;
                    return buildCard(categoryDetails, totalIncome, totalExpense, totalBalance);
                  } else {
                    return Center(child: Text('No data available.'));
                  }
                },
              );
            },
          );
        } else {
          return Center(child: Text('Category details not available.'));
        }
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

    String? imageUrl = category[CategoriesDB.categorySelectedImageBlob];
    String fileName = imageUrl != null ? generateFileNameFromUrl(imageUrl) : 'default.jpg';

    String? categoryName = category[CategoriesDB.categoryName];
    Color? primaryColor = category[CategoriesDB.categoryColor] != null
        ? Color(category[CategoriesDB.categoryColor] as int) : null;

    /*Future<File?> downloadImage(String imageUrl) async {
      try {
        final response = await http.get(Uri.parse(imageUrl));
        final documentDirectory = await getApplicationDocumentsDirectory();
        final file = File('${documentDirectory.path}/tempImage');
        file.writeAsBytesSync(response.bodyBytes);

        return file;
      } catch (e) {
        // Handle exceptions
        return null;
      }
    }

    Future<File?>? _imageFileFuture;

    if (category.containsKey(CategoriesDB.categorySelectedImageBlob) &&
        category[CategoriesDB.categorySelectedImageBlob] != null) {
      String imageUrl = category[CategoriesDB.categorySelectedImageBlob];
      _imageFileFuture = downloadImage(imageUrl);
    }

    String? categoryName = category[CategoriesDB.categoryName];
    Color? primaryColor;
    if (category[CategoriesDB.categoryColor] != null) {
      primaryColor = Color(category[CategoriesDB.categoryColor] as int);
    }
*/

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
                            future: imageUrl != null ? getImageFile(imageUrl, fileName) : null,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const CircularProgressIndicator(); // Show loading indicator
                              } else if (snapshot.hasError || snapshot.data == null) {
                                return CircleAvatar(
                                  backgroundColor: primaryColor,
                                  child: Icon(
                                    iconData,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                );
                              } else {
                                return CircleAvatar(
                                  backgroundColor: primaryColor,
                                  backgroundImage: snapshot.data != null ? FileImage(snapshot.data!) : null,
                                );
                              }
                              /*if (_imageFileFuture == null) {
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
                              }*/
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
                                  style: TextStyle(color: Colors.red, fontSize: 18),
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
