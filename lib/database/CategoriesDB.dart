import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expnz/utils/global.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoriesDB {
  static const String collectionName = 'categories';
  static const String usersCollection = 'users';

  static const String uid = 'uid';
  static const String categoryName = 'name';
  static const String categoryDescription = 'description';
  static const String categoryColor = 'color';
  static const String categoryIconCodePoint = 'iconCodePoint';
  static const String categoryIconFontFamily = 'iconFontFamily';
  static const String categoryIconFontPackage = 'iconFontPackage';
  static const String categorySelectedImageBlob = 'selectedImageBlob';
  static const String totalIncome = 'totalIncome';
  static const String totalExpense = 'totalExpense';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void listenToCategoryChanges(String userUid) {
    _firestore.collection(collectionName)
        .where(uid, isEqualTo: userUid)
        .snapshots()
        .listen((snapshot) {
      final Map<String, Map<String, dynamic>> newCategoriesData = {};

      // Add all existing accounts to the new map
      for (var doc in snapshot.docs) {
        newCategoriesData[doc.id] = doc.data() as Map<String, dynamic>;
      }

      // Check and remove any deleted accounts from the local cache
      final currentCategories = categoriesNotifier.value ?? {};
      for (var docId in currentCategories.keys) {
        if (!newCategoriesData.containsKey(docId)) {
          newCategoriesData.remove(docId);
        }
      }

      cacheCategoriesLocally(newCategoriesData);
    });
  }

  Future<void> cacheCategoriesLocally(Map<String, Map<String, dynamic>> categoriesData) async {
    final prefs = await SharedPreferences.getInstance();
    String encodedData = json.encode(categoriesData);
    await prefs.setString('userCategories', encodedData);
    categoriesNotifier.value = categoriesData;
  }

  Future<Map<String, Map<String, dynamic>>?> getLocalAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    String? encodedData = prefs.getString('userAccounts');
    return encodedData != null ? json.decode(encodedData) as Map<String, Map<String, dynamic>> : null;
  }

  Future<DocumentReference> insertCategory(Map<String, dynamic> data) async {
    String userUid = FirebaseAuth.instance.currentUser!.uid;
    data[uid] = userUid;

    // Add the new account to the accounts collection
    DocumentReference categoryRef = await _firestore.collection(collectionName).add(data);

    return categoryRef;
  }

  Future<bool> checkIfCategoryExists(String name) async {
    String userUid = FirebaseAuth.instance.currentUser!.uid;
    final querySnapshot = await _firestore.collection(collectionName)
        .where(uid, isEqualTo: userUid)
        .where(categoryName, isEqualTo: name)
        .limit(1)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }

  Stream<QuerySnapshot> getAllCategories() {
    String userUid = FirebaseAuth.instance.currentUser!.uid;
    return _firestore.collection(collectionName)
        .where(uid, isEqualTo: userUid)
        .snapshots();
  }

  Future<void> updateCategory(String documentId, Map<String, dynamic> data) async {
    await _firestore.collection(collectionName).doc(documentId).update(data);
  }

  // Deletes all categories for the current user
  Future<void> deleteAllCategories() async {
    String userUid = FirebaseAuth.instance.currentUser!.uid;
    var snapshot = await _firestore.collection(collectionName)
        .where(uid, isEqualTo: userUid)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> deleteCategory(String documentId) async {
    String userUid = FirebaseAuth.instance.currentUser!.uid;
    await _firestore.collection(collectionName).doc(documentId).delete();

    // Update the user's document to remove the account's aggregate data
    await _firestore.collection(usersCollection).doc(userUid).update({
      'categories.$documentId': FieldValue.delete(),
    });
  }

  Future<DocumentSnapshot> getSelectedCategory(String documentId) async {
    return await _firestore.collection(collectionName).doc(documentId).get();
  }
}
