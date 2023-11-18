import 'package:flutter/material.dart';

import '../database/CategoriesDB.dart';
import '../utils/image_utils.dart';

class CategoriesModel extends ChangeNotifier {
  final db = CategoriesDB();
  //List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> _categories = [];

  Future<void> fetchCategories() async {
    var categories = await CategoriesDB().getAllCategories();
    _categories = await preprocessCategories(categories);
    notifyListeners();
  }

  Future<Map<int, String>> fetchAllCategoriesAsMap() async {
    var allCategories = await db.getAllCategories();
    Map<int, String> categoriesMap = {};

    for (var category in allCategories) {
      int categoryId = category[CategoriesDB.columnId];
      String categoryName = category[CategoriesDB.columnName];
      categoriesMap[categoryId] = categoryName;
    }

    return categoriesMap;
  }


  Future<void> clearCategories() async {
    final db = CategoriesDB();
    await db.deleteAllCategories();
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> preprocessCategories(List<Map<String, dynamic>> categories) async {
    List<Map<String, dynamic>> processedCategories = [];

    for (var category in categories) {
      Map<String, dynamic> newCategory = Map.from(category);

      if (category[CategoriesDB.columnSelectedImageBlob] != null) {
        List<int> retrievedImageBytes = category[CategoriesDB.columnSelectedImageBlob];
        newCategory['imageFile'] = await bytesToFile(retrievedImageBytes); // Modify the copy
      }

      processedCategories.add(newCategory); // Add the modified/new category to the list
    }

    return processedCategories;
  }

  Map<String, dynamic>? getCategoryById(int id) {
    for (var category in _categories) {
      if (category[CategoriesDB.columnId] == id) {
        return category;
      }
    }
    return null;
  }

  Map<String, dynamic>? getCategoryByName(String categoryName) {
    for (var category in _categories) {
      if (category[CategoriesDB.columnName] == categoryName) {
        return category;
      }
    }
    return null;
  }

  // This function takes a list of category names and returns a list of corresponding category IDs.
  String getCategoryIdsFromNames(List<String> categoryNames) {
    List<String> categoryIds = [];

    for (var categoryName in categoryNames) {
      var category = getCategoryByName(categoryName);
      if (category != null) {
        int? categoryId = category[CategoriesDB.columnId];
        if (categoryId != null) {
          categoryIds.add(categoryId.toString());
        }
      }
    }

    return categoryIds.join(', ');
  }

  List<Map<String, dynamic>> get categories => _categories;

  Future<void> deleteCategory(int categoryId) async {
    await db.deleteCategory(categoryId);
    await fetchCategories();  // Refresh the categories
    notifyListeners();  // Notify the UI to rebuild
  }
}

