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
  static const String lastEditedTime = 'lastEditedTime';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void listenToAccountChanges(String userUid) async {
    final prefs = await SharedPreferences.getInstance();
    // Get the last sync time for accounts
    String? lastSyncTimeStr = prefs.getString('lastAccountSyncTime');
    DateTime lastSyncTime = lastSyncTimeStr != null
        ? DateTime.parse(lastSyncTimeStr)
        : DateTime.fromMillisecondsSinceEpoch(0);

    _firestore.collection(collectionName)
        .where(uid, isEqualTo: userUid)
        .where('lastEditedTime', isGreaterThan: lastSyncTime.toIso8601String())
        .snapshots()
        .listen((snapshot) async {
      final Map<String, Map<String, dynamic>> newAccountsData = {};

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        newAccountsData[doc.id] = data;
      }

      if (newAccountsData.isNotEmpty) {
        await cacheAccountsLocally(newAccountsData);
      } else {
        await loadAccountsFromLocal();
      }

      // Update the last sync time
      await prefs.setString('lastAccountSyncTime', DateTime.now().toIso8601String());
    }, onError: (error) {
      print('Error fetching accounts: $error');
    });
  }
  Future<void> fetchAccountsSince(DateTime sinceTime, String userUid) async {
    final prefs = await SharedPreferences.getInstance();
    final String formattedSinceTime = sinceTime.toIso8601String();

    try {
      // Fetch accounts updated after the provided sinceTime
      QuerySnapshot snapshot = await _firestore.collection(collectionName)
          .where(uid, isEqualTo: userUid)
          .where('lastEditedTime', isGreaterThan: formattedSinceTime)
          .get();

      final Map<String, Map<String, dynamic>> newAccountsData = {};

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        newAccountsData[doc.id] = data;
      }

      if (newAccountsData.isNotEmpty) {
        await cacheAccountsLocally(newAccountsData);
      } else {
        await loadAccountsFromLocal();
      }

      // Update the last sync time in SharedPreferences
      await prefs.setString('lastAccountSyncTime', DateTime.now().toIso8601String());
    } catch (error) {
      print('Error fetching accounts: $error');
    }
  }

  Future<void> loadAccountsFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    String? encodedData = prefs.getString('userAccounts');
    if (encodedData != null) {
      Map<String, Map<String, dynamic>> accountsData = Map<String, Map<String, dynamic>>.from(
        json.decode(encodedData) as Map<String, dynamic>,
      );
      accountsNotifier.value = accountsData;
    }
  }

  Future<void> cacheAccountsLocally(Map<String, Map<String, dynamic>> newAccountsData) async {
    final prefs = await SharedPreferences.getInstance();
    String? existingData = prefs.getString('userAccounts');
    Map<String, Map<String, dynamic>> existingAccounts = existingData != null
        ? Map<String, Map<String, dynamic>>.from(json.decode(existingData))
        : {};

    // Update existing accounts with new data
    existingAccounts.addAll(newAccountsData);

    // Remove soft-deleted accounts
    newAccountsData.forEach((key, value) {
      if (value['isDeleted'] == true) {
        existingAccounts.remove(key);
      }
    });

    // Encode the updated accounts and save them
    String encodedData = json.encode(existingAccounts);
    await prefs.setString('userAccounts', encodedData);
    accountsNotifier.value = existingAccounts;
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
    await _firestore.collection(collectionName).doc(documentId).update({
      'isDeleted': true,
      'lastEditedTime': DateTime.now().toIso8601String(),
    });
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
