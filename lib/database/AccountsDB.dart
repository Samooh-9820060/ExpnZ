import 'DatabaseHelper.dart';

class AccountsDB {
  static final tableName = 'accounts';
  static final accountId = '_id';
  static final accountName = 'name';
  static final accountCurrency = 'currency';
  static final accountIcon = 'icon';
  static final accountCardNumber = 'card_number';

  Future<int> insertAccount(Map<String, dynamic> row) async {
    final db = await DatabaseHelper.instance.database;
    return await db!.insert(tableName, row);
  }

  // method to fetch all accounts from the database
  Future<List<Map<String, dynamic>>> getAllAccounts() async {
    final db = await DatabaseHelper.instance.database;
    return await db!.query(tableName);
  }

  // method to delete an account by its id
  Future<int> deleteAccount(int id) async {
    final db = await DatabaseHelper.instance.database;
    return await db!.delete(
      tableName,
      where: '$accountId = ?',
      whereArgs: [id],
    );
  }

  //method to update account by its id
  Future<int> updateAccount(int id, Map<String, dynamic> row) async {
    final db = await DatabaseHelper.instance.database;
    return await db!.update(
      tableName,
      row,
      where: '$accountId = ?',
      whereArgs: [id],
    );
  }

  // method to get an account by its id
  Future<Map<String, dynamic>?> getSelectedAccount(int id) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db!.query(
      tableName,
      where: '$accountId = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return result.first;
    } else {
      return null;
    }
  }
}
