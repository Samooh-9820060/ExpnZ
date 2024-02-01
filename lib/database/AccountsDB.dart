import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expnz/utils/global.dart';

class AccountsDB {
  static const String collectionName = 'accounts';

  static const String uid = 'uid';
  static const String accountName = 'name';
  static const String accountType = 'type';
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
        .listen((snapshot) async {
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

      await updateFirestoreReadCount(snapshot.docs.length);
    });
  }

  Future<void> updateFirestoreReadCount(int documentCount) async {
    final prefs = await SharedPreferences.getInstance();
    int totalReads = prefs.getInt('totalFirestoreReads') ?? 0;
    totalReads += documentCount;
    await prefs.setString('type', 'AccountsRead');
    await prefs.setInt('totalFirestoreReads', totalReads);
    await prefs.setString('lastFirestoreReadTime', DateTime.now().toIso8601String());
  }

  Future<void> printFirestoreReadDetails() async {
    final prefs = await SharedPreferences.getInstance();

    String type = prefs.getString('type') ?? "Not specified";
    int totalReads = prefs.getInt('totalFirestoreReads') ?? 0;
    String lastFirestoreReadTime = prefs.getString('lastFirestoreReadTime') ?? "Not available";

    print('Type: $type');
    print('Total Firestore Reads: $totalReads');
    print('Last Firestore Read Time: $lastFirestoreReadTime');
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
    if (encodedData != null) {
      final decodedData = json.decode(encodedData);
      if (decodedData is Map) {
        return decodedData.map((key, value) {
          if (value is Map) {
            return MapEntry(key, value.cast<String, dynamic>());
          } else {
            // In case the value is not a Map, handle it appropriately
            // You can return an empty map or throw an error based on your app's needs
            return MapEntry(key, <String, dynamic>{});
          }
        });
      } else {
        // Handle the case where decodedData is not a Map
        // You can return null or throw an error based on your app's needs
        return null;
      }
    } else {
      return null;
    }
  }

  Future<bool> insertAccount(Map<String, dynamic> data) async {
    try {
      String userUid = FirebaseAuth.instance.currentUser!.uid;
      data[AccountsDB.uid] = userUid;

      // Add the new account to the accounts collection
      DocumentReference accountRef = await _firestore.collection(collectionName).add(data);

      return true;
    } catch(ex) {
      return false;
    }

  }

  // function to get unique currency codes
  Future<Set<String>> getUniqueCurrencyCodes() async {
    final accountsData = accountsNotifier.value ?? {};
    Set<String> uniqueCurrencyCodes = {};

    accountsData.forEach((accountId, accountInfo) {
      if (accountInfo.containsKey(AccountsDB.accountCurrency)) {
        var currencyData = jsonDecode(accountInfo[AccountsDB.accountCurrency]);
        if (currencyData['code'] != null) {
          uniqueCurrencyCodes.add(currencyData['code']);
        }
      }
    });

    return uniqueCurrencyCodes;
  }

  Future<void> deleteAccount(String documentId) async {
    await _firestore.collection(collectionName).doc(documentId).delete();

    // Update the local cache by removing the deleted transaction
    final currentAccounts = accountsNotifier.value ?? {};
    if (currentAccounts.containsKey(documentId)) {
      currentAccounts.remove(documentId);
      accountsNotifier.value = currentAccounts;
    }
  }

  Future<void> updateAccount(String documentId, Map<String, dynamic> data) async {
    await _firestore.collection(collectionName).doc(documentId).update(data);
  }

  Future<Map<String, dynamic>?> getSelectedAccount(String documentId) async {
    final accountsData = accountsNotifier.value;

    // Check if the account data is available in the notifier
    if (accountsData.containsKey(documentId)) {
      return accountsData[documentId];
    }

    return null;
  }
}
