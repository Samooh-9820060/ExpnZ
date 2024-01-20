import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'DatabaseHelper.dart';

/*class AccountsDB {
  static const tableName = 'accounts';
  static const accountId = '_id';
  static const accountName = 'name';
  static const accountCurrency = 'currency';
  static const accountIconCodePoint = 'iconCodePoint';
  static const accountIconFontFamily = 'iconFontFamily';
  static const accountIconFontPackage = 'iconFontPackage';
  static const accountCardNumber = 'card_number';

  Future<int> insertAccount(Map<String, dynamic> row) async {
    final db = await DatabaseHelper.instance.database;
    return await db!.insert(tableName, row);
  }

  Future<void> deleteAllAccounts() async {
    final db = await DatabaseHelper.instance.database;
    await db?.delete(AccountsDB.tableName); // Assuming 'AccountsDB.tableName' holds your table name
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
    int updatedRows = await db!.update(
      tableName,
      row,
      where: '$accountId = ?',
      whereArgs: [id],
    );
    print("Updated $updatedRows rows.");
    return updatedRows;
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
}*/

class AccountsDB {
  static const String collectionName = 'accounts';

  static const String uid = 'uid';
  static const String accountName = 'name';
  static const String accountCurrency = 'currency';
  static const String accountIconCodePoint = 'iconCodePoint';
  static const String accountIconFontFamily = 'iconFontFamily';
  static const String accountIconFontPackage = 'iconFontPackage';
  static const String accountCardNumber = 'card_number';
  static const String totalIncome = 'totalIncome';
  static const String totalExpense = 'totalExpense';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<DocumentReference> insertAccount(Map<String, dynamic> data) async {
    String userUid = FirebaseAuth.instance.currentUser!.uid;  // Get the current user's UID
    data[AccountsDB.uid] = userUid;
    data[AccountsDB.totalIncome] = 0.0;
    data[AccountsDB.totalExpense] = 0.0;
    return await _firestore.collection(collectionName).add(data);
  }

  Future<void> deleteAccount(String documentId) async {
    await _firestore.collection(collectionName).doc(documentId).delete();
  }

  Stream<QuerySnapshot> getAllAccounts() {
    return _firestore.collection(collectionName).snapshots();
  }

  Future<void> updateAccount(String documentId, Map<String, dynamic> data) async {
    await _firestore.collection(collectionName).doc(documentId).update(data);
  }

  Future<DocumentSnapshot> getSelectedAccount(String documentId) async {
    return await _firestore.collection(collectionName).doc(documentId).get();
  }

  // Method to update totalIncome and totalExpense
  Future<void> updateTotals(String documentId, double income, double expense) async {
    await _firestore.collection(collectionName).doc(documentId).update({
      totalIncome: income,
      totalExpense: expense,
    });
  }
}
