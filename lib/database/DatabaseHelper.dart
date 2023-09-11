import 'dart:io';
import 'package:expnz/database/AccountsDB.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'CategoriesDB.dart';
import 'TransactionsDB.dart';

class DatabaseHelper {
  static final _databaseName = "ExpnzDatabase.db";
  static final _databaseVersion = 1;

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
    await _createCategoriesTable(db); // creating the Categories table
    await _createAccountsTable(db); // creating the Accounts table
    await _createTransactionsTable(db); // creating the transactions table
  }

  Future _createAccountsTable(Database db) async {
    await db.execute('''
          CREATE TABLE ${AccountsDB.tableName} (
            ${AccountsDB.accountId} INTEGER PRIMARY KEY,
            ${AccountsDB.accountName} TEXT NOT NULL,
            ${AccountsDB.accountCurrency} TEXT NOT NULL,
            ${AccountsDB.accountIconCodePoint} INTEGER,
            ${AccountsDB.accountIconFontFamily} TEXT,
            ${AccountsDB.accountIconFontPackage} TEXT,
            ${AccountsDB.accountCardNumber} TEXT NULL
          )
    ''');
  }

  Future _createCategoriesTable(Database db) async {
    await db.execute('''
          CREATE TABLE ${CategoriesDB.tableName} (
            ${CategoriesDB.columnId} INTEGER PRIMARY KEY,
            ${CategoriesDB.columnName} TEXT NOT NULL,
            ${CategoriesDB.columnDescription} TEXT NOT NULL,
            ${CategoriesDB.columnColor} INTEGER NOT NULL,
            ${CategoriesDB.columnIconCodePoint} INTEGER,
            ${CategoriesDB.columnIconFontFamily} TEXT,
            ${CategoriesDB.columnIconFontPackage} TEXT,
            ${CategoriesDB.columnSelectedImageBlob} BLOB
          )
    ''');
  }

  Future _createTransactionsTable(Database db) async {
    await db.execute('''
        CREATE TABLE ${TransactionsDB.tableName} (
          ${TransactionsDB.columnId} INTEGER PRIMARY KEY,
          ${TransactionsDB.columnType} TEXT NOT NULL,
          ${TransactionsDB.columnName} TEXT NOT NULL,
          ${TransactionsDB.columnDescription} TEXT NOT NULL,
          ${TransactionsDB.columnAmount} REAL NOT NULL,
          ${TransactionsDB.columnDate} TEXT NOT NULL,
          ${TransactionsDB.columnTime} TEXT NOT NULL,
          ${TransactionsDB.columnAccountId} INTEGER NOT NULL,
          ${TransactionsDB.columnCategories} TEXT NOT NULL,
          FOREIGN KEY (${TransactionsDB.columnAccountId}) REFERENCES ${AccountsDB.tableName}(${AccountsDB.accountId})
        )
  ''');
  }
}
