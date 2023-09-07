import 'DatabaseHelper.dart';

class CategoriesDB {
  static final tableName = 'categories';
  static final columnId = '_id';
  static final columnName = 'name';
  static final columnDescription = 'description';
  static final columnIcon = 'icon';
  static final columnColor = 'color';

  Future<int> insertCategory(Map<String, dynamic> row) async {
    final db = await DatabaseHelper.instance.database;
    return await db!.insert(tableName, row);
  }

  // method to fetch all categories from the database
  Future<List<Map<String, dynamic>>> getAllCategories() async {
    final db = await DatabaseHelper.instance.database;
    return await db!.query(tableName);
  }

  Future<bool> checkIfCategoryExists(String name) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db!.query(
      tableName,
      where: '$columnName = ?',
      whereArgs: [name],
    );
    return result.isNotEmpty;
  }

  // method to delete a category by its name
  Future<int> deleteCategory(String name) async {
    final db = await DatabaseHelper.instance.database;
    return await db!.delete(
      tableName,
      where: '$columnName = ?',
      whereArgs: [name],
    );
  }
}
