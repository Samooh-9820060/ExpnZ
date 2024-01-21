import 'package:flutter/material.dart';
import 'package:expnz/utils/global.dart';

Widget buildCategoriesDropdown(
    List<Map<String, dynamic>> selectedCategoriesList,
    String searchText,
    Function setStateCallback,
    bool showDropdown,
    ) {
  return ValueListenableBuilder<Map<String, Map<String, dynamic>>?>(
    valueListenable: categoriesNotifier,
    builder: (context, categoriesData, child) {
      if (categoriesData == null || categoriesData.isEmpty) {
        return Center(
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
              .contains(searchText.toLowerCase()) && !isAlreadySelected;
        }).toList();

        sortedData.sort((a, b) => a['name'].compareTo(b['name']));

        double itemHeight = 55.0;
        double maxHeight = 200.0;

        double calculatedHeight = sortedData.length * itemHeight;
        calculatedHeight = calculatedHeight > maxHeight ? maxHeight : calculatedHeight;

        return Container(
          height: calculatedHeight,
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: sortedData.length,
            itemBuilder: (context, index) {
              final category = sortedData[index];
              IconData categoryIcon = IconData(
                category['iconCodePoint'],
                fontFamily: category['iconFontFamily'],
                fontPackage: category['iconFontPackage'],
              );

              return Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: () {
                    setStateCallback(() {
                      selectedCategoriesList.add({'id': category['id']});
                      showDropdown = false;
                    });
                  },
                  child: ListTile(
                    title: Text(category['name']),
                    leading: Icon(categoryIcon),
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