import 'package:expnz/utils/global.dart';
import 'package:expnz/widgets/SimpleWidgets/ExpnZTextField.dart';
import 'package:flutter/material.dart';
import '../database/CategoriesDB.dart';
import '../widgets/AppWidgets/CategoryCard.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  CategoriesScreenState createState() => CategoriesScreenState();
}

class CategoriesScreenState extends State<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blueGrey[900],
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: ExpnzTextField(
              controller: _searchController,
              label: 'Search Categories',
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
              )
                  : null,
            ),
            /*child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Categories',
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),*/
          ),
          Expanded(
            child: ValueListenableBuilder<Map<String, Map<String, dynamic>>>(
                valueListenable: categoriesNotifier,
                // The ValueNotifier for local accounts data
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

                  // Create a list of category keys, sorted by category name
                  List<String> sortedCategoryKeys =
                      categoriesData.keys.toList();
                  sortedCategoryKeys.sort((a, b) =>
                      (categoriesData[a]?['name'] as String)
                          .compareTo(categoriesData[b]?['name'] as String));
                  return ListView.builder(
                    itemCount: sortedCategoryKeys.length,
                    itemBuilder: (context, index) {
                      final documentId = sortedCategoryKeys[index];
                      final categoryName = categoriesData[documentId]?['name'] as String;
                      final categoryDescription = categoriesData[documentId]?['description'] as String;

                      // Filter categories based on the search query
                      if (_searchQuery.isNotEmpty && (!categoryName.toLowerCase().contains(_searchQuery.toLowerCase()) && !categoryDescription.toLowerCase().contains(_searchQuery.toLowerCase()))) {
                        return Container();
                      }

                      return buildAnimatedCategoryCard(
                        documentId: documentId,
                        index: index,
                      );
                    },
                  );
                }),
          ),
        ],
      ),
    );
  }

  Widget buildAnimatedCategoryCard({
    Key? key,
    required String documentId,
    required int index,
  }) {

    // Extracting category data
    final categoryData = categoriesNotifier.value[documentId];
    final String categoryName = categoryData?['name'] ?? 'Unknown Category';
    final String? imagePath = categoryData?[
        'imageUrl']; // Replace 'imageUrl' with your field name if different
    final IconData iconData = _getIconData(categoryData);
    final Color? primaryColor = categoryData?['color'] != null
        ? Color(categoryData?['color'] as int)
        : null;

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
                documentId: documentId,
                categoryName: categoryName,
                imagePath: imagePath,
                iconDetails: iconData,
                primaryColor: primaryColor,
                animation: _animation,
                index: index,
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getIconData(Map<String, dynamic>? categoryData) {
    if (categoryData != null && categoryData.containsKey('iconCodePoint')) {
      return IconData(
        int.parse(categoryData['iconCodePoint'].toString()),
        fontFamily: categoryData['iconFontFamily'],
        fontPackage: categoryData['iconFontPackage'],
      );
    }
    return Icons.category; // Default icon
  }

  void _showDeleteConfirmationDialog(BuildContext context, String documentId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Category"),
          content: const Text(
              "Are you sure you want to delete this category?\n\n"
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
