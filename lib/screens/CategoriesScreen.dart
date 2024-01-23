import 'package:expnz/utils/global.dart';
import 'package:flutter/material.dart';
import '../database/CategoriesDB.dart';
import '../widgets/AppWidgets/CategoryCard.dart';

class CategoriesScreen extends StatefulWidget {
  @override
  _CategoriesScreenState createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

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
      child: ValueListenableBuilder<Map<String, Map<String, dynamic>>>(
          valueListenable: categoriesNotifier, // The ValueNotifier for local accounts data
          builder: (context, categoriesData, child) {
            if (categoriesData.isEmpty) {
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
            }
            return ListView.builder(
              itemCount: categoriesData.length,
              itemBuilder: (context, index) {
                final documentId = categoriesData.keys.elementAt(index);

                return buildAnimatedCategoryCard(
                  documentId: documentId,
                  index: index,
                );
              },
            );
        }
      ),
    );
  }

  Widget buildAnimatedCategoryCard({
    Key? key,
    required String documentId,
    required int index,
  }) {
    return GestureDetector(
      onLongPress: () {
        _showDeleteConfirmationDialog(context, documentId);
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
                documentId: documentId,
                animation: _animation,
                index: index,
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, String documentId) {
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
}
