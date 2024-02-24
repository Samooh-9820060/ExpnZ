import 'dart:io';

import 'package:flutter/material.dart';
import 'package:expnz/utils/global.dart';

import '../../database/CategoriesDB.dart';
import '../../utils/image_utils.dart';

Future<File?> _fetchImageFile(String imageUrl) async {
  String fileName = generateFileNameFromUrl(imageUrl);
  return await getImageFile(imageUrl, fileName);
}

Widget buildCategoriesDropdown(
    List<Map<String, dynamic>> selectedCategoriesList,
    TextEditingController categorySearchController,
    Function setStateCallback,
    Function closeDropdownCallback,
    ) {

  return ValueListenableBuilder<Map<String, Map<String, dynamic>>?>(
    valueListenable: categoriesNotifier,
    builder: (context, categoriesData, child) {
      if (categoriesData == null || categoriesData.isEmpty) {
        return const Center(
          child: Text('No categories available.'),
        );
      } else {
        List<Map<String, dynamic>> sortedData = categoriesData.entries.map((entry) {
          return {
            'id': entry.key,
            ...entry.value
          };
        }).toList();

        sortedData = sortedData.where((category) {
          bool isAlreadySelected = selectedCategoriesList.any((selectedCategory) => selectedCategory['id'] == category['id']);
          return category['name']
              .toLowerCase()
              .contains(categorySearchController.text.toLowerCase()) && !isAlreadySelected;
        }).toList();

        sortedData.sort((a, b) => a['name'].compareTo(b['name']));

        double itemHeight = 55.0;
        double maxHeight = 200.0;

        double calculatedHeight = sortedData.length * itemHeight;
        calculatedHeight = calculatedHeight > maxHeight ? maxHeight : calculatedHeight;

        return SizedBox(
          height: calculatedHeight,
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: sortedData.length,
            itemBuilder: (context, index) {
              final category = sortedData[index];
              String? imageUrl = category['imageUrl']; // Get the imageUrl from the category data

              Widget leadingWidget;
              const double iconSize = 32.0; // Define a standard size for icons and images

              if (imageUrl != null && imageUrl.isNotEmpty) {
                leadingWidget = FutureBuilder<File?>(
                  future: _fetchImageFile(imageUrl), // Use a separate function to fetch the image file
                  builder: (context, imageSnapshot) {
                    if (imageSnapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        width: iconSize,
                        height: iconSize,
                        child: CircularProgressIndicator(),
                      );
                    } else if (imageSnapshot.hasError || imageSnapshot.data == null) {
                      return const Icon(Icons.error, size: iconSize); // Display an error icon
                    } else {
                      return SizedBox(
                        width: iconSize,
                        height: iconSize,
                        child: CircleAvatar(
                          backgroundColor: Colors.transparent,
                          backgroundImage: FileImage(imageSnapshot.data!),
                        ),
                      );
                    }
                  },
                );
              } else {
                IconData categoryIcon = IconData(
                  category['iconCodePoint'],
                  fontFamily: category['iconFontFamily'],
                  fontPackage: category['iconFontPackage'],
                );
                leadingWidget = SizedBox(
                  width: iconSize,
                  height: iconSize,
                  child: Icon(categoryIcon, size: iconSize),
                );
              }


              return Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: () {
                    setStateCallback(() {
                      selectedCategoriesList.add({'id': category['id']});
                      categorySearchController.text = '';
                      //close dropdown
                      //showDropdown = false;
                    });
                    closeDropdownCallback();
                  },
                  child: ListTile(
                    title: Text(category['name']),
                    leading: leadingWidget,
                  ),
                ),
              );
            },
          ),
        );
      }
    },
  );
}