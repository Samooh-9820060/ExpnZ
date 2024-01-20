import 'dart:io';
import 'package:expnz/database/AccountsDB.dart';
import 'package:expnz/database/TempTransactionsDB.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'CategoriesDB.dart';
import 'ProfileDB.dart';
import 'TransactionsDB.dart';

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
    await _createProfileTable(db);
    await _createCategoriesTable(db); // creating the Categories table
    //await _createAccountsTable(db); // creating the Accounts table
    //await _createTransactionsTable(db); // creating the transactions table
    await _createTempTransactionsTable(db);
  }

  /*Future _createAccountsTable(Database db) async {
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
  }*/

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

  /*Future _createTransactionsTable(Database db) async {
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
  }*/

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

  Future _createProfileTable(Database db) async {
    await db.execute('''
          CREATE TABLE ${ProfileDB.tableName} (
            ${ProfileDB.columnId} INTEGER PRIMARY KEY,
            ${ProfileDB.columnName} TEXT NOT NULL,
            ${ProfileDB.columnEmail} TEXT NOT NULL,
            ${ProfileDB.columnProfilePic} BLOB, 
            ${ProfileDB.columnPhoneNumber} TEXT
          )
    ''');
  }
}
