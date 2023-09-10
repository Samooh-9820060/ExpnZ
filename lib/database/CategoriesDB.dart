import 'DatabaseHelper.dart';

class CategoriesDB {
  static final tableName = 'categories';
  static final columnId = '_id';
  static final columnName = 'name';
  static final columnDescription = 'description';
  static final columnColor = 'color';
  static final columnIconCodePoint = 'iconCodePoint';
  static final columnIconFontFamily = 'iconFontFamily';
  static final columnSelectedImageBlob = 'selectedImageBlob';

  Future<int> insertCategory(Map<String, dynamic> row) async {
    final db = await DatabaseHelper.instance.database;
    return await db!.insert(tableName, row);
  }

  // method to fetch all categories from the database
  Future<List<Map<String, dynamic>>> getAllCategories() async {
    final db = await DatabaseHelper.instance.database;
    return await db!.query(tableName);
  }


  Future<bool> checkIfCategoryExists(String name, [int? excludeId]) async {
    final db = await DatabaseHelper.instance.database;
    final List<dynamic> whereArgs = [name];
    String whereString = '$columnName = ?';

    if (excludeId != null) {
      whereString += ' AND $columnId != ?';
      whereArgs.add(excludeId);
    }

    final result = await db!.query(
      tableName,
      where: whereString,
      whereArgs: whereArgs,
    );

    return result.isNotEmpty;
  }


  // method to delete a category by its id
  Future<int> deleteCategory(int id) async {
    final db = await DatabaseHelper.instance.database;
    return await db!.delete(
      tableName,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  //method to update category by its id
  Future<int> updateCategory(int id, Map<String, dynamic> row) async {
    final db = await DatabaseHelper.instance.database;
    return await db!.update(
      tableName,
      row,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }


  // method to get a category by its id
  Future<Map<String, dynamic>?> getSelectedCategory(int id) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db!.query(
      tableName,
      where: '$columnId = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return result.first;
    } else {
      return null;
    }
  }
}
