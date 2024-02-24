import 'dart:io';

import 'package:expnz/database/CategoriesDB.dart';
import 'package:flutter/material.dart';

import '../../utils/image_utils.dart';

class CategoryChip extends StatefulWidget {
  final bool isSelected;
  final Function onTap;
  final String categoryId;

  const CategoryChip({super.key,
    this.isSelected = true,
    required this.onTap,
    required this.categoryId,
  });

  @override
  CategoryChipState createState() => CategoryChipState();
}

class CategoryChipState extends State<CategoryChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  Future<Map<String, dynamic>?>? _categoryDetailsFuture;
  Future<File?>? _imageFileFuture;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _fetchCategoryDetails();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchCategoryDetails() async {
    var categoryDetails = await CategoriesDB().getSelectedCategory(widget.categoryId);
    _categoryDetailsFuture = CategoriesDB().getSelectedCategory(widget.categoryId);
    if (mounted) { // Check if the widget is still in the tree
      setState(() {
        _categoryDetailsFuture = Future.value(categoryDetails); // Update the future with the fetched data
        if (categoryDetails != null && categoryDetails['imageUrl'] != null) {
          String imageUrl = categoryDetails['imageUrl'];
          String fileName = generateFileNameFromUrl(imageUrl);
          _imageFileFuture = getImageFile(imageUrl, fileName);
        }
      });
    }
  }


  @override
  void didUpdateWidget(CategoryChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.categoryId != oldWidget.categoryId) {
      _fetchCategoryDetails();
    }
  }

  Future<void> _animateAndRemove() async {
    await _controller.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
        future: _categoryDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show a loading indicator while waiting for data
            return const CircularProgressIndicator();
          }

          if (snapshot.hasError || snapshot.data == null) {
            // Handle error or null data
            return const SizedBox.shrink();
          }

          // Extract details from the category
          var categoryDetails = snapshot.data!;
          var label = categoryDetails['name'];
          String? imageUrl = categoryDetails['imageUrl'];

          _controller.forward();

          // Check if imageUrl is not null and load the image
          Widget leadingWidget;
          if (imageUrl != null && imageUrl.isNotEmpty) {
            leadingWidget = FutureBuilder<File?>(
              future: _imageFileFuture,
              builder: (context, imageSnapshot) {
                if (imageSnapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator(); // Show loading indicator
                } else if (imageSnapshot.hasError || imageSnapshot.data == null) {
                  IconData iconData = CategoriesDB().getIconData(categoryDetails);
                  Color? backgroundColor;
                  if (categoryDetails['color'] != null) {
                    backgroundColor = Color(categoryDetails['color']);
                  }
                  return CircleAvatar(
                    backgroundColor: backgroundColor ?? Colors.transparent,
                    child: Icon(
                      iconData,
                      color: Colors.white,
                      size: 24,
                    ),
                  );
                } else {
                  Color? backgroundColor;
                  if (categoryDetails['color'] != null) {
                    backgroundColor = Color(categoryDetails['color']);
                  }
                  return CircleAvatar(
                    backgroundColor: backgroundColor ?? Colors.transparent,
                    backgroundImage: FileImage(imageSnapshot.data!),
                    maxRadius: 12,
                  );
                }
              },
            );
          } else {
            // Load the icon if imageUrl is null
            IconData iconData = IconData(
              categoryDetails['iconCodePoint'],
              fontFamily: categoryDetails['iconFontFamily'],
              fontPackage: categoryDetails['iconFontPackage'],
            );
            leadingWidget = Icon(iconData, color: widget.isSelected ? Colors.blueAccent : Colors.grey, size: 24);
          }


          return GestureDetector(
            onTap: () => _animateAndRemove(),

            child: AnimatedBuilder(
              animation: _animation,
              builder: (BuildContext context, Widget? child) {
                return Transform.scale(
                  scale: _animation.value,
                  child: AnimatedOpacity(
                    opacity: _animation.value,
                    duration: const Duration(milliseconds: 100),
                    child: child,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                // Internal padding for the text and icon
                margin: const EdgeInsets.all(0),
                // Margin for external spacing
                decoration: BoxDecoration(
                  border: Border.all(
                    color: widget.isSelected ? Colors.blueAccent : Colors
                        .transparent,
                    width: 1.0,
                  ),
                  borderRadius: const BorderRadius.all(
                    Radius.circular(16.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.isSelected ? Colors.blueAccent.withOpacity(
                          0.2) : Colors.transparent,
                      blurRadius: 4.0,
                    ),
                  ],
                  color: widget.isSelected ? Colors.blueGrey[700] : Colors
                      .blueGrey[800],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    leadingWidget,
                    const SizedBox(width: 4),
                    Text(label),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => _animateAndRemove(),
                      child: const Icon(Icons.clear_sharp, size: 18),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
    );
  }
}
