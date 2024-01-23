import 'dart:io';
import 'package:expnz/database/TempTransactionsDB.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const  _databaseName = "ExpnzDatabase.db";
  static const _databaseVersion = 1;

  // make this a singleton class
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database?> get database async {
    if (_database != null) return _database;
    _database = await _initDatabase();
    return _database;
  }

  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
  }


  Future _createTempTransactionsTable(Database db) async {
    await db.execute('''
    CREATE TABLE ${TempTransactionsDB.tableName} (
      ${TempTransactionsDB.columnId} INTEGER PRIMARY KEY,
      ${TempTransactionsDB.columnTitle} TEXT NOT NULL,
      ${TempTransactionsDB.columnContent} TEXT NOT NULL,
      ${TempTransactionsDB.columnType} TEXT,
      ${TempTransactionsDB.columnName} TEXT, 
      ${TempTransactionsDB.columnDescription} TEXT, 
      ${TempTransactionsDB.columnAmount} REAL,
      ${TempTransactionsDB.columnDate} TEXT,
      ${TempTransactionsDB.columnTime} TEXT,
      ${TempTransactionsDB.columnCategories} TEXT,
      ${TempTransactionsDB.columnCardDigits} TEXT,
    )
  ''');
  }
}
