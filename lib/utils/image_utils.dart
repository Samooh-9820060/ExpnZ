import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../database/CategoriesDB.dart';

Future<File> bytesToFile(List<int> bytes) async {
  final directory = await getTemporaryDirectory();
  final path = '${directory.path}/temp_image_${DateTime.now().millisecondsSinceEpoch}.jpg'; // Added a unique identifier
  ImageCache imageCache = PaintingBinding.instance!.imageCache!;
  imageCache!.evict(FileImage(File(path)));
  final file = File(path);
  return await file.writeAsBytes(bytes);
}

Widget getCategoryWidget(Map<String, dynamic>? category, {double? radius = 12.0}) {
  if (category != null) {
    if (category[CategoriesDB.columnSelectedImageBlob] != null) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: MemoryImage(category[CategoriesDB.columnSelectedImageBlob]),
      );
    } else {
      return Icon(
        IconData(
          category[CategoriesDB.columnIconCodePoint],
          fontFamily: category[CategoriesDB.columnIconFontFamily],
          fontPackage: category[CategoriesDB.columnIconFontPackage],
        ),
        size: radius,
      );
    }
  }
  return Icon(Icons.help_outline, size: 24); // Default icon if category is null
}
