import 'package:expnz/models/TransactionsModel.dart';
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
    final categoriesModel = Provider.of<CategoriesModel>(context, listen: false);
    categoriesModel.fetchCategories();
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
            return const Center(
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
            List<Map<String, dynamic>> sortedData = List.from(categoriesModel.categories);
            sortedData.sort((a, b) => a[CategoriesDB.columnName].compareTo(b[CategoriesDB.columnName]));

            return ListView.builder(
              itemCount: sortedData.length,
              itemBuilder: (context, index) {
                final category = sortedData[index];

                return buildAnimatedCategoryCard(
                  key: ValueKey(category[CategoriesDB.columnId]),
                  categoryId: category[CategoriesDB.columnId],
                  income: "\$200",
                  expense: "\$50",
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
    required String income,
    required String expense,
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
                key: key,
                categoryId: categoryId,
                animation: _animation,
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
          title: const Text("Delete Category"),
          content: const Text("Are you sure you want to delete this category?\n\n"
              "This will remove this category from all transactions with more than 1 category and Uncategorize any transactions with this category only."),
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
                await Provider.of<TransactionsModel>(context, listen: false).deleteTransactionsByCategoryId(categoryId, null, context);
                await Provider.of<CategoriesModel>(context, listen: false).deleteCategory(categoryId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
