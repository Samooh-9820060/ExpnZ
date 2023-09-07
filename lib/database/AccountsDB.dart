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
}
