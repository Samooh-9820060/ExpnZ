import 'dart:async';
import 'package:flutter/material.dart';
import '../database/CategoriesDB.dart';
import '../utils/utility_functions.dart';
import '../widgets/AppWidgets/CategoryCard.dart';

class CategoriesScreen extends StatefulWidget {
  @override
  _CategoriesScreenState createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  final db = CategoriesDB();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blueGrey[900],
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: db.getAllCategories(),  // Fetching the categories from database
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Text('No categories available.');
          } else {
            // Sort the list of categories by name in ascending order
            List<Map<String, dynamic>> sortedData = List.from(snapshot.data!);
            sortedData.sort((a, b) => a[CategoriesDB.columnName].compareTo(b[CategoriesDB.columnName]));

            return ListView.builder(
              itemCount: sortedData.length,
              itemBuilder: (context, index) {
                final category = sortedData[index];
                return buildAnimatedCategoryCard(
                  category[CategoriesDB.columnName],
                  "\$200",
                  "\$50",
                  IconData(
                    int.tryParse(category[CategoriesDB.columnIcon]) ?? Icons.error.codePoint,
                    fontFamily: 'MaterialIcons',
                  ),
                  hexToColor(category[CategoriesDB.columnColor]),
                );
              },
            );
          }
        },
      ),
    );
  }

  Widget buildAnimatedCategoryCard(String categoryName, String income, String expense, IconData iconData, Color primaryColor) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.scale(
            scale: _animation.value,
            child: CategoryCard(
              categoryName: categoryName,
              income: income,
              expense: expense,
              iconData: iconData,
              animation: _animation,
              primaryColor: primaryColor,
              onDelete: () async {  // Pass the callback here
                await CategoriesDB().deleteCategory(categoryName);  // Replace with your actual delete function
                setState(() {});  // Refresh the state to reflect the change
              },
            ),
          ),
        );
      },
    );
  }
}
