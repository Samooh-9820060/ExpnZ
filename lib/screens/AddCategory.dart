import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AddCategoryScreen extends StatefulWidget {
  @override
  _AddCategoryScreenState createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  late TextEditingController _categoryController;
  late TextEditingController _descriptionController;
  IconData selectedIcon = Icons.star;  // Default icon
  Color selectedColor = Colors.blue; // Default color

  @override
  void initState() {
    super.initState();
    _categoryController = TextEditingController();
    _descriptionController = TextEditingController();
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
              child: const Text('Got it'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
        title: Text("Add Category", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueGrey[900],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Redesigned Text Field for Category
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: LinearGradient(
                  colors: [Colors.blueGrey[800]!, Colors.blueGrey[700]!],
                ),
              ),
              child: TextField(
                controller: _categoryController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Enter Category",
                  labelStyle: TextStyle(color: Colors.white),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(20),
                ),
              ),
            ),
            SizedBox(height: 16),
            // Redesigned Text Field for Description
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: LinearGradient(
                  colors: [Colors.blueGrey[800]!, Colors.blueGrey[700]!],
                ),
              ),
              child: TextField(
                controller: _descriptionController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Enter Description",
                  labelStyle: TextStyle(color: Colors.white),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(20),
                ),
              ),
            ),
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
                primary: Colors.blueGrey[700],
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
            // Redesigned Button for Color Picker
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
                primary: Colors.blueGrey[700],
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
            ElevatedButton(
              onPressed: () {
                // Implement your code to add the category here
                // After adding, navigate back to the Home Screen
                Navigator.pop(context);
              },
              child: Text("Add", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                primary: Colors.blueAccent,
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                textStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50.0),
                ),
                elevation: 5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}