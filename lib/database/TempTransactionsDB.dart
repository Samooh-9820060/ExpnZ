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

  Future<void> addTempData() async {
    List<Map<String, dynamic>> tempData = [
      {
        columnTitle: 'Funds Transferred',
        columnContent: 'You have sent MVR 180.0 from  7730*1879 to 7730*24433',
        columnType: 'expense',
        columnName: '7730*1879',
        columnAmount: 180.00,
        columnDate: '2024-01-10',
        columnTime: '10:12',
      },
      {
        columnTitle: 'Funds Received',
        columnContent: 'You have received MVR 80.0 from AHMED SHIMAAH',
        columnType: 'income',
        columnName: 'Ahmed Shimaah',
        columnAmount: 80.00,
        columnDate: '2024-01-09',
        columnTime: '08:53',
      },
    ];

    for (var row in tempData) {
      await insertTransaction(row);
    }
  }

  Future<int> insertTransaction(Map<String, dynamic> row) async {
    final db = await DatabaseHelper.instance.database;
    return await db!.insert(tableName, row);
  }

  Future<List<Map<String, dynamic>>> getAllTransaction() async {
    final db = await DatabaseHelper.instance.database;
    List<Map<String, dynamic>> transactions = await db!.query(tableName);

    // Check if the table is empty and insert temporary data if it is
    if (transactions.isEmpty) {
      //await addTempData();
      // Re-query the database after inserting temporary data
      transactions = await db.query(tableName);
    }

    return transactions;
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