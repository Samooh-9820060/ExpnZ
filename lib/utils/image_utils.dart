import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../database/CategoriesDB.dart';

Future<File> bytesToFile(List<int> bytes) async {
  final directory = await getTemporaryDirectory();
  final path = '${directory.path}/temp_image_${DateTime.now().millisecondsSinceEpoch}.jpg'; // Added a unique identifier
  ImageCache imageCache = PaintingBinding.instance.imageCache;
  imageCache.evict(FileImage(File(path)));
  final file = File(path);
  return await file.writeAsBytes(bytes);
}

Future<ImageProvider> _loadImageFromStorage(String imageRef) async {
  final ref = FirebaseStorage.instance.ref().child(imageRef);
  final url = await ref.getDownloadURL();
  return NetworkImage(url);
}

Widget getCategoryWidget(Map<String, dynamic>? category, {double? radius = 12.0}) {
  if (category != null) {
    if (category[CategoriesDB.categorySelectedImageBlob] != null) {
      // If the category contains a direct binary blob
      return CircleAvatar(
        radius: radius,
        backgroundImage: MemoryImage(category[CategoriesDB.categorySelectedImageBlob]),
      );
    } else if (category['imageRef'] != null) {
      // If the category contains a reference to an image in Firebase Storage
      String imageRef = category['imageRef'];
      return FutureBuilder(
        future: _loadImageFromStorage(imageRef),
        builder: (BuildContext context, AsyncSnapshot<ImageProvider> snapshot) {
          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
            return CircleAvatar(
              radius: radius,
              backgroundImage: snapshot.data,
            );
          } else {
            return const CircularProgressIndicator(); // Or some placeholder widget
          }
        },
      );
    } else {
      return Icon(
        IconData(
          category[CategoriesDB.categoryIconCodePoint],
          fontFamily: category[CategoriesDB.categoryIconFontFamily],
          fontPackage: category[CategoriesDB.categoryIconFontPackage],
        ),
        size: radius,
      );
    }
  }
  return const Icon(Icons.help_outline, size: 24); // Default icon if category is null
}
