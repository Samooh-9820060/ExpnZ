import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expnz/database/TransactionsDB.dart';
import 'package:expnz/utils/global.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoriesDB {
  static const String collectionName = 'categories';

  static const String uid = 'uid';
  static const String categoryName = 'name';
  static const String categoryDescription = 'description';
  static const String categoryColor = 'color';
  static const String categoryIconCodePoint = 'iconCodePoint';
  static const String categoryIconFontFamily = 'iconFontFamily';
  static const String categoryIconFontPackage = 'iconFontPackage';
  static const String categorySelectedImageBlob = 'imageUrl';
  static const String totalIncome = 'totalIncome';
  static const String totalExpense = 'totalExpense';
  static const String lastEditedTime = 'lastEditedTime';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void listenToCategoryChanges(String userUid) async {
    final prefs = await SharedPreferences.getInstance();
    // Get the last sync time
    String? lastSyncTimeStr = prefs.getString('lastCategorySyncTime');
    DateTime lastSyncTime = lastSyncTimeStr != null
        ? DateTime.parse(lastSyncTimeStr)
        : DateTime.fromMillisecondsSinceEpoch(0);

    _firestore.collection(collectionName)
        .where(uid, isEqualTo: userUid)
        .where('lastEditedTime', isGreaterThan: lastSyncTime.toIso8601String())
        .snapshots()
        .listen((snapshot) async {
      bool hasSoftDeletes = false;
      final Map<String, Map<String, dynamic>> newCategoriesData = {};

      print('categories fetched ${snapshot.docs.length}');
      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        newCategoriesData[doc.id] = data;
      }

      if (newCategoriesData.isNotEmpty) {
        await cacheCategoriesLocally(newCategoriesData);
      } else {
        await loadCategoriesFromLocal();
      }

      await prefs.setString('lastCategorySyncTime', DateTime.now().toIso8601String());
    }, onError: (error) {
      print('Error fetching categories: $error');
    });
  }

  Future<void> loadCategoriesFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    String? encodedData = prefs.getString('userCategories');
    if (encodedData != null) {
      Map<String, Map<String, dynamic>> categoriesData = Map<String, Map<String, dynamic>>.from(
        json.decode(encodedData) as Map<String, dynamic>,
      );
      categoriesNotifier.value = categoriesData;
    }
  }

  Future<void> cacheCategoriesLocally(Map<String, Map<String, dynamic>> newCategoriesData) async {
    final prefs = await SharedPreferences.getInstance();
    String? existingData = prefs.getString('userCategories');
    Map<String, Map<String, dynamic>> existingCategories = existingData != null
        ? Map<String, Map<String, dynamic>>.from(json.decode(existingData))
        : {};

    // Update existing categories with new data
    existingCategories.addAll(newCategoriesData);

    // Remove soft-deleted categories
    newCategoriesData.forEach((key, value) {
      if (value['isDeleted'] == true) {
        existingCategories.remove(key);
      }
    });

    // Encode the updated categories and save them
    String encodedData = json.encode(existingCategories);
    await prefs.setString('userCategories', encodedData);
    categoriesNotifier.value = existingCategories;
  }



  Future<Map<String, Map<String, dynamic>>?> getLocalCategories() async {
    final prefs = await SharedPreferences.getInstance();
    String? encodedData = prefs.getString('userCategories');
    if (encodedData != null) {
      final decodedData = json.decode(encodedData);
      if (decodedData is Map) {
        // Safely cast each value to Map<String, dynamic>
        return decodedData.map<String, Map<String, dynamic>>((key, value) {
          if (value is Map) {
            return MapEntry(key, value.cast<String, dynamic>());
          } else {
            // Handle the case where the value is not a Map
            // Return an empty Map or handle this case as needed
            return MapEntry(key, <String, dynamic>{});
          }
        });
      } else {
        // Handle the case where decodedData is not a Map
        return null;
      }
    }
    return null;
  }

  Future<DocumentReference> insertCategory(Map<String, dynamic> data) async {
    String userUid = FirebaseAuth.instance.currentUser!.uid;
    data[uid] = userUid;

    // Add the new account to the accounts collection
    DocumentReference categoryRef = await _firestore.collection(collectionName).add(data);

    return categoryRef;
  }

  Future<bool> checkIfCategoryExists(String name) async {
    final categoriesData = categoriesNotifier.value;

    for (var category in categoriesData.values) {
      if (category['name'].toString().toLowerCase() == name.toLowerCase()) {
        return true;
      }
    }

    return false;
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
    await _firestore.collection(collectionName)
        .doc(documentId)
        .update({
      'isDeleted': true,
      'lastEditedTime': DateTime.now().toIso8601String(),
    });
    TransactionsDB().deleteCategoryFromTransactions(documentId);
  }

  Future<Map<String, dynamic>?> getSelectedCategory(String documentId) async {
    final prefs = await SharedPreferences.getInstance();
    String? encodedData = prefs.getString('userCategories');

    if (encodedData != null) {
      Map<String, dynamic> categoriesData = json.decode(encodedData) as Map<String, dynamic>;

      // Check if the category with the given documentId exists in the local data
      if (categoriesData.containsKey(documentId)) {
        return categoriesData[documentId] as Map<String, dynamic>;
      }
    }
    // Return null if no matching category is found
    return null;
  }

  Future<String> uploadImageToStorage(File imageFile) async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    String fileName = 'categories/${userId}/${DateTime.now().millisecondsSinceEpoch}'; // Unique file name
    Reference storageRef = FirebaseStorage.instance.ref().child(fileName);

    UploadTask uploadTask = storageRef.putFile(imageFile);
    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();

    return downloadUrl; // URL to the uploaded image
  }

  Future<void> saveImageUrlToFirestore(String imageUrl, String documentId) async {
    var categoriesCollection = FirebaseFirestore.instance.collection('categories');
    await categoriesCollection.doc(documentId).update({'imageUrl': imageUrl});
  }

  Future<String> saveImageLocally(File imageFile) async {
    final directory = await getApplicationDocumentsDirectory();
    final imagePath = '${directory.path}/images';
    final imageDirectory = Directory(imagePath);

    if (!imageDirectory.existsSync()) {
      imageDirectory.createSync();
    }

    final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File('${imageDirectory.path}/$fileName');

    await file.writeAsBytes(await imageFile.readAsBytes());
    return file.path;
  }

  Future<void> saveImagePathToSharedPreferences(String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('localImagePath', filePath);
  }

  Future<String?> getLocalImagePathFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('localImagePath');
  }

  Future<List<Map<String, dynamic>>> getCategoryDetailsWithImage() async {
    final categoriesData = categoriesNotifier.value ?? {};
    List<Map<String, dynamic>> categoriesWithImage = [];

    for (var entry in categoriesData.entries) {
      String documentId = entry.key;
      Map<String, dynamic> category = entry.value;

      String? localImagePath;
      String? iconDetails;

      if (category.containsKey(categorySelectedImageBlob) && category[categorySelectedImageBlob] != null) {
        // If imageUrl is available, try to get the local image path
        localImagePath = await getLocalImagePathFromSharedPreferences();
      }

      if (localImagePath == null) {
        // If no image, use icon details
        iconDetails = jsonEncode({
          'iconCodePoint': category[categoryIconCodePoint],
          'iconFontFamily': category[categoryIconFontFamily],
          'iconFontPackage': category[categoryIconFontPackage],
        });
      }

      categoriesWithImage.add({
        'documentId': documentId,
        'name': category[categoryName],
        'imagePath': localImagePath,
        'iconDetails': iconDetails,
      });
    }

    return categoriesWithImage;
  }

  Future<void> createCategories(List<String> categoriesToCreate, BuildContext context) async {
    String userUid = FirebaseAuth.instance.currentUser!.uid;
    var batch = FirebaseFirestore.instance.batch();

    for (var categoryName in categoriesToCreate) {
      // Default values for icon, color, and description
      final defaultIcon = Icons.category;
      final defaultColor = Colors.blue;
      final description = categoryName;

      // Prepare data to insert
      Map<String, dynamic> data = {
        'uid': userUid,
        'name': categoryName,
        'description': description,
        'color': defaultColor.value,
        'iconCodePoint': defaultIcon.codePoint,
        'iconFontFamily': defaultIcon.fontFamily,
        'iconFontPackage': defaultIcon.fontPackage,
        'selectedImageBlob': null, // No image
      };

      // Generate a new document reference
      var categoryRef = FirebaseFirestore.instance.collection('categories').doc();
      batch.set(categoryRef, data);
    }

    try {
      await batch.commit();
      //print("All categories added successfully.");
    } catch (e) {
      //print("Failed to add categories: $e");
    }

    // Refresh the categories list in the UI
    categoriesNotifier.value = (await CategoriesDB().getLocalCategories())!;
  }
}
