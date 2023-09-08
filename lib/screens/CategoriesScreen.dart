import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/CategoriesDB.dart';
import '../models/CategoriesModel.dart';
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
    Provider.of<CategoriesModel>(context, listen: false).fetchCategories();
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
      child: Consumer<CategoriesModel>(
        builder: (context, categoriesModel, child) {
          if (categoriesModel.categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.category_outlined,
                    color: Colors.grey,
                    size: 64,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No categories available.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          } else {
            // Sort the list of categories by name in ascending order
            List<Map<String, dynamic>> sortedData = List.from(categoriesModel.categories!);
            sortedData.sort((a, b) => a[CategoriesDB.columnName].compareTo(b[CategoriesDB.columnName]));

            return ListView.builder(
              itemCount: sortedData.length,
              itemBuilder: (context, index) {
                final category = sortedData[index];
                return buildAnimatedCategoryCard(
                  key: ValueKey(category[CategoriesDB.columnId]),
                  categoryId: category[CategoriesDB.columnId],
                  categoryName: category[CategoriesDB.columnName],
                  income: "\$200",
                  expense: "\$50",
                  iconData: IconData(
                    int.tryParse(category[CategoriesDB.columnIcon]) ?? Icons.error.codePoint,
                    fontFamily: 'MaterialIcons',
                  ),
                  primaryColor: Color(category[CategoriesDB.columnColor]),
                );
              },
            );
          }
        },
      ),
    );
  }

  Widget buildAnimatedCategoryCard({
    Key? key,
    required int categoryId,
    required String categoryName,
    required String income,
    required String expense,
    required IconData iconData,
    required Color primaryColor
  }) {
    return GestureDetector(
      onLongPress: () {
        _showDeleteConfirmationDialog(context, categoryId);
      },
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Opacity(
            opacity: _animation.value,
            child: Transform.scale(
              scale: _animation.value,
              child: CategoryCard(
                key: key,  // Pass the key here
                categoryId: categoryId,
                categoryName: categoryName,
                income: income,
                expense: expense,
                iconData: iconData,
                animation: _animation,
                primaryColor: primaryColor,
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, int categoryId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete Category"),
          content: Text("Are you sure you want to delete this category?"),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Delete"),
              onPressed: () async {
                await Provider.of<CategoriesModel>(context, listen: false)
                    .deleteCategory(categoryId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
