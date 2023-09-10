import 'package:expnz/models/TransactionsModel.dart';
import 'package:provider/provider.dart';

import 'DatabaseHelper.dart';

class TransactionsDB {
  static final tableName = 'transactions';
  static final columnId = '_id';
  static final columnType = 'type';
  static final columnName = 'name';
  static final columnDescription = 'description';
  static final columnAmount = 'amount';
  static final columnDate = 'date';
  static final columnTime = 'time';
  static final columnAccountId = 'account_id';
  static final columnCategories = 'categories';

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