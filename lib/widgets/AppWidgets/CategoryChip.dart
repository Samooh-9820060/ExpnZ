import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';

class CategoryChip extends StatefulWidget {
  final bool isSelected;
  final Function onTap;
  final int categoryId;

  CategoryChip({
    this.isSelected = true,
    required this.onTap,
    required this.categoryId,
  });

  @override
  _CategoryChipState createState() => _CategoryChipState();
}

class _CategoryChipState extends State<CategoryChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _animateAndRemove() async {
    await _controller.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    //var categoriesModel = Provider.of<CategoriesModel>(context);
    //var categoryDetails = categoriesModel.getCategoryById(widget.categoryId);
    var categoryDetails = null;

    if (categoryDetails == null) {
      // Handle the case when the category is null (e.g., show a default widget)
      return SizedBox.shrink();
    }
    // Extract details from the category
    var iconData = IconData(
      categoryDetails['iconCodePoint'],
      fontFamily: categoryDetails['iconFontFamily'],
      fontPackage: categoryDetails['iconFontPackage'],
    );
    var label = categoryDetails['name'];
    File? imageFile = categoryDetails['imageFile'];

    _controller.forward();

    return GestureDetector(
      onTap: () => _animateAndRemove(),

      child: AnimatedBuilder(
        animation: _animation,
        builder: (BuildContext context, Widget? child) {
          return Transform.scale(
            scale: _animation.value,
            child: AnimatedOpacity(
              opacity: _animation.value,
              duration: Duration(milliseconds: 100),
              child: child,
            ),
          );
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Internal padding for the text and icon
          margin: EdgeInsets.all(0), // Margin for external spacing
          decoration: BoxDecoration(
            border: Border.all(
              color: widget.isSelected ? Colors.blueAccent : Colors.transparent,
              width: 1.0,
            ),
            borderRadius: BorderRadius.all(
              Radius.circular(16.0),
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isSelected ? Colors.blueAccent.withOpacity(0.2) : Colors.transparent,
                blurRadius: 4.0,
              ),
            ],
            color: widget.isSelected ? Colors.blueGrey[700] : Colors.blueGrey[800],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                backgroundColor: Colors.transparent,
                radius: 12,
                child: imageFile == null
                    ? Icon(
                  iconData,
                  color: widget.isSelected ? Colors.blueAccent : Colors.grey,
                  size: 24,
                )
                    : null,
                backgroundImage: imageFile != null
                    ? FileImage(imageFile!)
                    : null,
              ),
              SizedBox(width: 4),
              Text(label),
              SizedBox(width: 4),
              InkWell(  // Replacing IconButton with InkWell
                onTap: () => _animateAndRemove(),
                child: Icon(Icons.clear_sharp, size: 18),  // You can choose an appropriate size
              ),
            ],
          ),
        ),
      ),
    );
  }
}
