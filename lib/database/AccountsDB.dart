import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expnz/utils/global.dart';

class AccountsDB {
  static const String collectionName = 'accounts';
  static const String usersCollection = 'users';

  static const String uid = 'uid';
  static const String accountName = 'name';
  static const String accountCurrency = 'currency';
  static const String accountIconCodePoint = 'iconCodePoint';
  static const String accountIconFontFamily = 'iconFontFamily';
  static const String accountIconFontPackage = 'iconFontPackage';
  static const String accountCardNumber = 'card_number';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void listenToAccountChanges(String userUid) {
    _firestore.collection(collectionName)
        .where(uid, isEqualTo: userUid)
        .snapshots()
        .listen((snapshot) {
      final Map<String, Map<String, dynamic>> newAccountsData = {};

      // Add all existing accounts to the new map
      for (var doc in snapshot.docs) {
        newAccountsData[doc.id] = doc.data() as Map<String, dynamic>;
      }

      // Check and remove any deleted accounts from the local cache
      final currentAccounts = accountsNotifier.value ?? {};
      for (var docId in currentAccounts.keys) {
        if (!newAccountsData.containsKey(docId)) {
          newAccountsData.remove(docId);
        }
      }

      cacheAccountsLocally(newAccountsData);
    });
  }

  Future<void> cacheAccountsLocally(Map<String, Map<String, dynamic>> accountsData) async {
    final prefs = await SharedPreferences.getInstance();
    String encodedData = json.encode(accountsData);
    await prefs.setString('userAccounts', encodedData);
    accountsNotifier.value = accountsData;
  }

  Future<Map<String, Map<String, dynamic>>?> getLocalAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    String? encodedData = prefs.getString('userAccounts');
    return encodedData != null ? json.decode(encodedData) as Map<String, Map<String, dynamic>> : null;
  }

  Future<DocumentReference> insertAccount(Map<String, dynamic> data) async {
    String userUid = FirebaseAuth.instance.currentUser!.uid;
    data[AccountsDB.uid] = userUid;

    // Add the new account to the accounts collection
    DocumentReference accountRef = await _firestore.collection(collectionName).add(data);

    // Initialize account-specific aggregate data under the user's document
    await _firestore.collection(usersCollection).doc(userUid).set({
      'accounts': {
        accountRef.id: {
          'totalIncome': 0.0,
          'totalExpense': 0.0,
        }
      }
    }, SetOptions(merge: true));

    return accountRef;
  }

  Future<void> deleteAccount(String documentId) async {
    String userUid = FirebaseAuth.instance.currentUser!.uid;

    await _firestore.collection(collectionName).doc(documentId).delete();

    // Update the user's document to remove the account's aggregate data
    await _firestore.collection(usersCollection).doc(userUid).update({
      'accounts.$documentId': FieldValue.delete(),
    });
  }

  Future<void> updateAccount(String documentId, Map<String, dynamic> data) async {
    await _firestore.collection(collectionName).doc(documentId).update(data);
  }

  Future<DocumentSnapshot> getSelectedAccount(String documentId) async {
    return await _firestore.collection(collectionName).doc(documentId).get();
  }
}
