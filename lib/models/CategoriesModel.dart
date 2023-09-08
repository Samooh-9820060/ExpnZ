import 'package:flutter/material.dart';

import '../database/CategoriesDB.dart';

class CategoriesModel extends ChangeNotifier {
  final db = CategoriesDB();
  List<Map<String, dynamic>> categories = [];

  Future<void> fetchCategories() async {
    categories = await db.getAllCategories();
    notifyListeners();
  }

  Future<void> deleteCategory(int categoryId) async {
    await db.deleteCategory(categoryId);
    await fetchCategories();  // Refresh the categories
    notifyListeners();  // Notify the UI to rebuild
  }
}

