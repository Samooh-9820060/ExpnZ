import 'DatabaseHelper.dart';

class TempTransactionsDB {
  static const tableName = 'temp_transactions';
  static const columnId = '_id';
  static const columnTitle = 'title';
  static const columnContent = 'content';
  static const columnType = 'type';
  static const columnName = 'name';
  static const columnDescription = 'description';
  static const columnAmount = 'amount';
  static const columnDate = 'date';
  static const columnTime = 'time';
  static const columnAccountId = 'account_id';
  static const columnCategories = 'categories';
  static const columnCardDigits = 'card_digts';

  Future<int> insertTransaction(Map<String, dynamic> row) async {
    final db = await DatabaseHelper.instance.database;
    return await db!.insert(tableName, row);
  }

  // method to fetch all transactions from the database
  Future<List<Map<String, dynamic>>> getAllTransaction() async {
    final db = await DatabaseHelper.instance.database;
    return await db!.query(tableName);
  }

  // method to delete a transaction by its id
  Future<int> deleteTransaction(int id) async {
    final db = await DatabaseHelper.instance.database;
    return await db!.delete(
      tableName,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAllTransactions() async {
    final db = await DatabaseHelper.instance.database;
    await db?.delete(TempTransactionsDB.tableName); // Assuming 'TransactionsDB.tableName' holds your table name
  }

  //method to update transaction by its id
  Future<int> updateTransaction(int id, Map<String, dynamic> row) async {
    final db = await DatabaseHelper.instance.database;
    return await db!.update(
      tableName,
      row,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }


  // method to get a transaction by its id
  Future<Map<String, dynamic>?> getSelectedTransaction(int id) async {
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