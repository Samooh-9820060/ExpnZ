import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expnz/utils/global.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
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
  static const String categorySelectedImageBlob = 'imageUrl';
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
    String userUid = FirebaseAuth.instance.currentUser!.uid;
    await _firestore.collection(collectionName).doc(documentId).delete();

    // Update the user's document to remove the account's aggregate data
    await _firestore.collection(usersCollection).doc(userUid).update({
      'categories.$documentId': FieldValue.delete(),
    });
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
}
