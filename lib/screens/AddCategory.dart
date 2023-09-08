import 'package:expnz/widgets/SimpleWidgets/ExpnZButton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import '../database/CategoriesDB.dart';
import '../widgets/SimpleWidgets/ExpnZTextField.dart';
import '../widgets/SimpleWidgets/ModernSnackBar.dart';
import '../models/CategoriesModel.dart';
import 'package:provider/provider.dart';



class AddCategoryScreen extends StatefulWidget {
  final int? categoryId;

  AddCategoryScreen({
    this.categoryId,
  });

  @override
  _AddCategoryScreenState createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  late TextEditingController _categoryController;
  late TextEditingController _descriptionController;
  late IconData selectedIcon = Icons.star;  // Default icon
  late Color selectedColor = Colors.blue; // Default color
  bool isDuplicateCategory = false;
  bool isProcessing = false;
  bool isModifyMode = false;

  @override
  void initState() {
    super.initState();
    _categoryController = TextEditingController();
    _descriptionController = TextEditingController();

    _categoryController.addListener(() async {
      bool duplicate = await CategoriesDB().checkIfCategoryExists(_categoryController.text);
      setState(() {
        isDuplicateCategory = duplicate;
        //isModifyMode = duplicate;
      });
    });

    if (widget.categoryId != null){
      _loadExistingCategory(widget.categoryId!);
    } else {
      selectedIcon = Icons.star;
      selectedColor = Colors.blue;
    }
  }

  void _loadExistingCategory(int id) async {
    final category = await CategoriesDB().getSelectedCategory(id);
    print("Loaded category: $category");  // Debug line

    if (category != null) {
      setState(() {
        isModifyMode = true;
        _categoryController.text = category[CategoriesDB.columnName] as String;
        _descriptionController.text = category[CategoriesDB.columnDescription] as String;
        selectedIcon = IconData(
            category[CategoriesDB.columnIcon] is String ?
            int.parse(category[CategoriesDB.columnIcon] as String) :
            category[CategoriesDB.columnIcon] as int,
            fontFamily: 'MaterialIcons'
        );

        selectedColor = Color(
            category[CategoriesDB.columnColor] is String ?
            int.parse(category[CategoriesDB.columnColor] as String) :
            category[CategoriesDB.columnColor] as int
        );
      });
    } else {
      setState(() {
        selectedIcon = Icons.star;
        selectedColor = Colors.blue;
      });
    }
  }


  @override
  void dispose() {
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _pickIcon() async {
    IconData? icon = await FlutterIconPicker.showIconPicker(context,
        iconPackModes: [
          IconPack.material,
          IconPack.cupertino,
          IconPack.fontAwesomeIcons
        ]);
    if (icon != null) {
      setState(() {
        selectedIcon = icon;
      });
    }
  }

  void _pickColor() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a color!'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: selectedColor,
              onColorChanged: (Color color) {
                setState(() => selectedColor = color);
              },
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text('Got it', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  //database functions
  void _addModifyCategory() async {
    if (isProcessing) return;
    setState(() {
      isProcessing = true;
    });


    if (_categoryController.text.trim().isEmpty || _descriptionController.text.trim().isEmpty) {
      await showModernSnackBar(
        context: context,
        message: "Category name or description cannot be empty!",
        backgroundColor: Colors.red,
      );
      setState(() {
        isProcessing = false;
      });
      return;
    }

    // Check if category name is duplicated
    isDuplicateCategory = await CategoriesDB().checkIfCategoryExists(
        _categoryController.text.trim(),
        isModifyMode ? widget.categoryId : null
    );

    if (isDuplicateCategory) {
      await showModernSnackBar(
        context: context,
        message: "Category name cannot be duplicated",
        backgroundColor: Colors.red,
      );
      setState(() {
        isProcessing = false;
      });
      return;
    }

    if (isDuplicateCategory && !isModifyMode) {
      await showModernSnackBar(
        context: context,
        message: "Category name cannot be duplicated",
        backgroundColor: Colors.red,
      );
      setState(() {
        isProcessing = false;
      });
      return;
    }


    // Prepare data to insert or update
    Map<String, dynamic> row = {
      'name': _categoryController.text,
      'description': _descriptionController.text,
      'icon': selectedIcon.codePoint.toString(),
      'color': selectedColor.value,
    };

    final int? id;

    if (isModifyMode) {
      // Update existing category
      id = await CategoriesDB().updateCategory(widget.categoryId!, row);
    } else {
      // Add new category
      id = await CategoriesDB().insertCategory(row);
    }

    final categoriesModel = Provider.of<CategoriesModel>(context, listen: false);
    if (id != null && id > 0) {
      await showModernSnackBar(
        context: context,
        message: isModifyMode ? "Category updated successfully!" : "Category added successfully!",
        backgroundColor: Colors.green,
      );
      categoriesModel.fetchCategories();
      setState(() {
        isProcessing = false;
      });
      Navigator.pop(context, true);
    } else {
      await showModernSnackBar(
        context: context,
        message: isModifyMode ? "Category was not updated" : "Category was not added",
        backgroundColor: Colors.redAccent,
      );
      setState(() {
        isProcessing = false;
      });    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        elevation: 0,
        leading: BackButton(
          color: Colors.white,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(isModifyMode ? "Modify Category" : "Add Category", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueGrey[900],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Redesigned Text Field for Category
            CustomTextField(label: "Enter Category", controller: _categoryController, isError: isDuplicateCategory),
            SizedBox(height: 16),
            // Redesigned Text Field for Description
            CustomTextField(label: "Enter Description", controller: _descriptionController),
            SizedBox(height: 16),
            // Redesigned Button for Icon Picker
            ElevatedButton(
              onPressed: _pickIcon,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(
                    selectedIcon,
                    color: Colors.white,
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Select Icon"),
                      Text(
                        "Tap to choose icon",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey[700],
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                textStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50.0),
                ),
              ),
            ),
            SizedBox(height: 16),
            // Redesigned Button for Color Picker
            ElevatedButton(
              onPressed: _pickColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.color_lens, // You can change this to any icon you like
                        color: Colors.white,
                      ),
                      SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Pick a Color"),
                          Text(
                            "Tap to choose color",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Display the selected color
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: selectedColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey[700],
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                textStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50.0),
                ),
              ),
            ),

            SizedBox(height: 32),
            // Redesigned Add Button
            ExpnZButton(
              label: isProcessing ? "Processing..." : (isModifyMode ? "Modify" : "Add"),
              onPressed: isProcessing ? null : (_addModifyCategory),
            ),

          ],
        ),
      ),
    );
  }
}
