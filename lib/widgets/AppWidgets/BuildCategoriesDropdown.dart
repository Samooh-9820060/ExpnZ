import 'package:flutter/material.dart';
import '../../database/CategoriesDB.dart';
import '../../models/CategoriesModel.dart';

Widget buildCategoriesDropdown(
    CategoriesModel categoriesModel,
    List<Map<String, dynamic>> selectedCategoriesList,
    String searchText,
    Function setStateCallback, // Add this
    bool showDropdown,
    )
{

  if (categoriesModel.categories.isEmpty) {
    return Center(
      child: Text('No categories available.'),
    );
  } else {
    List<Map<String, dynamic>> sortedData = List.from(categoriesModel.categories);
    sortedData = sortedData.where((category) {
      int categoryId = category[CategoriesDB.columnId];
      bool isAlreadySelected = selectedCategoriesList.any((selectedCategory) => int.parse(selectedCategory['id'].toString()) == categoryId);

      return category[CategoriesDB.columnName]
          .toLowerCase()
          .contains(searchText.toLowerCase()) && !isAlreadySelected;
    }).toList();
    sortedData.sort((a, b) => a[CategoriesDB.columnName].compareTo(b[CategoriesDB.columnName]));

    double itemHeight = 55.0; // Approximate height of one ListTile
    double maxHeight = 200.0; // Maximum height you'd like to allow for dropdown

    double calculatedHeight = sortedData.length * itemHeight;
    calculatedHeight = calculatedHeight > maxHeight ? maxHeight : calculatedHeight;

    return Container(
      height: calculatedHeight,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: sortedData.length,
        itemBuilder: (context, index) {
          return Container(
              height: calculatedHeight,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: sortedData.length,
                itemBuilder: (context, index) {
                  final category = sortedData[index];
                  IconData categoryIcon = IconData(
                    category[CategoriesDB.columnIconCodePoint],
                    fontFamily: category[CategoriesDB.columnIconFontFamily],
                    fontPackage: category[CategoriesDB.columnIconFontPackage],
                  );
                  String categoryId = category[CategoriesDB.columnId].toString();
                  String categoryName = category[CategoriesDB.columnName];

                  BorderRadius borderRadius;

                  // Top item
                  if (index == 0) {
                    borderRadius = BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    );
                  }
                  // Bottom item
                  else if (index == sortedData.length - 1) {
                    borderRadius = BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    );
                  }
                  // Middle items
                  else {
                    borderRadius = BorderRadius.zero;
                  }

                  return Material(
                    type: MaterialType.transparency, // To make it transparent
                    child: InkWell(
                      onTap: () {
                        setStateCallback(() { // Use the passed setStateCallback
                          selectedCategoriesList.add({
                            'id': categoryId,
                          });
                          showDropdown = false; // Use the passed showDropdown
                        });
                      },
                      borderRadius: borderRadius, // Use the dynamic border radius
                      splashColor: Colors.blue,
                      highlightColor: Colors.blue.withOpacity(0.5),
                      child: ListTile(
                        title: Text(categoryName),
                        leading: category['imageFile'] == null
                            ? Icon(categoryIcon)
                            : CircleAvatar(
                          backgroundImage: FileImage(category['imageFile']),
                          radius: 12,
                        ),
                      ),
                    ),
                  );
                },
              )
          );
        },
      ),
    );
  }
}