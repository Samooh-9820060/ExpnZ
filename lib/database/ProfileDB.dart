import 'DatabaseHelper.dart';

class ProfileDB {
  static const tableName = 'profile';
  static const columnId = '_id';
  static const columnName = 'name';
  static const columnEmail = 'email';
  static const columnProfilePic = 'profile_pic';
  static const columnPhoneNumber = 'phone_number';

  // Method to insert a profile into the database
  Future<int> insertProfile(Map<String, dynamic> row) async {
    final db = await DatabaseHelper.instance.database;
    return await db!.insert(tableName, row);
  }

  // Method to fetch all profiles from the database
  Future<List<Map<String, dynamic>>> getAllProfiles() async {
    final db = await DatabaseHelper.instance.database;
    return await db!.query(tableName);
  }

  // Method to delete a profile by its id
  Future<int> deleteProfile(int id) async {
    final db = await DatabaseHelper.instance.database;
    return await db!.delete(
      tableName,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  // Method to delete all profiles from the database
  Future<void> deleteAllProfiles() async {
    final db = await DatabaseHelper.instance.database;
    await db?.delete(tableName);
  }

  // Method to update a profile by its id
  Future<int> updateProfile(int id, Map<String, dynamic> row) async {
    final db = await DatabaseHelper.instance.database;
    return await db!.update(
      tableName,
      row,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  // Method to get a profile by its id
  Future<Map<String, dynamic>?> getSelectedProfile(int id) async {
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
