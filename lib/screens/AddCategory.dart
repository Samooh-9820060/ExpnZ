import 'package:expnz/widgets/SimpleWidgets/ExpnZButton.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_cropper/image_cropper.dart';
import '../database/CategoriesDB.dart';
import '../utils/image_utils.dart';
import '../widgets/SimpleWidgets/ExpnZTextField.dart';
import '../widgets/SimpleWidgets/ExpnzSnackBar.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';



class AddCategoryScreen extends StatefulWidget {
  final String? documentId;

  const AddCategoryScreen({super.key,
    this.documentId,
  });

  @override
  AddCategoryScreenState createState() => AddCategoryScreenState();
}

class AddCategoryScreenState extends State<AddCategoryScreen> {
  late TextEditingController _categoryController;
  late TextEditingController _descriptionController;
  late IconData selectedIcon = Icons.search;  // Default icon
  late Color selectedColor = Colors.blue; // Default color
  bool isProcessing = false;
  bool isModifyMode = false;
  File? selectedImage;
  String? originalImageUrl;
  bool imageHasChanged = false;
  XFile? _pickedFile;

  @override
  void initState() {
    super.initState();
    _categoryController = TextEditingController();
    _descriptionController = TextEditingController();


    if (widget.documentId != null){
      _loadExistingCategory(widget.documentId!);
    } else {
      selectedIcon = Icons.search;
      selectedColor = Colors.blue;
    }
  }

  void _loadExistingCategory(String documentId) async {
    var categoryData = await CategoriesDB().getSelectedCategory(documentId);

    IconData? newSelectedIcon;
    File? newSelectedImage;
    Color? newSelectedColor;

    if (categoryData != null) {
      isModifyMode = true;

      String? imageUrl = categoryData[CategoriesDB.categorySelectedImageBlob];
      String fileName = imageUrl != null ? generateFileNameFromUrl(imageUrl) : 'default.jpg';

      if (imageUrl == null) {
        String? iconFontPackage = categoryData[CategoriesDB.categoryIconFontPackage];
        newSelectedIcon = IconData(
          categoryData[CategoriesDB.categoryIconCodePoint],
          fontFamily: categoryData[CategoriesDB.categoryIconFontFamily],
          fontPackage: iconFontPackage,
        );
      } else {
        newSelectedIcon = Icons.search;
        newSelectedImage = await getImageFile(imageUrl, fileName);
      }

      int colorInt = categoryData[CategoriesDB.categoryColor] is String
          ? int.parse(categoryData[CategoriesDB.categoryColor])
          : categoryData[CategoriesDB.categoryColor];
      newSelectedColor = Color(colorInt);

      setState(() {
        _categoryController.text = categoryData[CategoriesDB.categoryName];
        _descriptionController.text = categoryData[CategoriesDB.categoryDescription];
        selectedIcon = newSelectedIcon ?? Icons.search;
        selectedImage = newSelectedImage;
        selectedColor = newSelectedColor ?? Colors.blue;
        originalImageUrl = categoryData[CategoriesDB.categorySelectedImageBlob];
      });
    } else {
      setState(() {
        selectedIcon = Icons.search;
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



  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        //selectedImage = File(pickedFile.path);
        setState(() {
          _pickedFile = pickedFile;
          _cropImage();
        });
        selectedIcon = Icons.search;
      } else {
      }
    });
  }
  Future<void> _cropImage() async {
    if (_pickedFile != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: _pickedFile!.path,
        compressFormat: ImageCompressFormat.png,
        compressQuality: 50,
        cropStyle: CropStyle.circle,
        uiSettings: [
          AndroidUiSettings(
              toolbarTitle: 'Cropper',
              toolbarColor: Colors.blueGrey[900],
              toolbarWidgetColor: Colors.white,
              backgroundColor: Colors.blueGrey[900],
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false),
          IOSUiSettings(
            title: 'Cropper',
          ),
          WebUiSettings(
            context: context,
            presentStyle: CropperPresentStyle.dialog,
            boundary: const CroppieBoundary(
              width: 520,
              height: 520,
            ),
            viewPort:
            const CroppieViewPort(width: 480, height: 480, type: 'circle'),
            enableExif: true,
            enableZoom: true,
            showZoomer: true,
          ),
        ],
      );
      if (croppedFile != null) {
        final file = File(croppedFile.path);
        final compressedFile = await _compressFile(file);
        setState(() {
          selectedImage = compressedFile ?? file;
          imageHasChanged = true;
        });
      }
    }
  }
  Future<File?> _compressFile(File file) async {
    try {
      final filePath = file.absolute.path;

      // Define the target path and file name for JPEG format
      String outPath = "${filePath.substring(0, filePath.lastIndexOf('.'))}_compressed.jpg";

      // Compress the image and convert to JPEG
      final compressedImage = await FlutterImageCompress.compressAndGetFile(
        filePath,
        outPath,
        quality: 20,
        minWidth: 1000,
        minHeight: 1000,
        format: CompressFormat.jpeg, // Specify JPEG format
      );

      if (compressedImage != null) {
        return File(compressedImage.path); // Convert to File type
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
    return null; // Return null if compression fails or any exception occurs
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
        selectedImage = null;
      });
    }
  }
  void _pickColor() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
              'Pick a color!',
          ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Got it', style: TextStyle(color: Colors.white)),
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
    bool isDuplicate = false;
    if (isModifyMode) {
      isDuplicate = await CategoriesDB().checkIfCategoryExists(_categoryController.text.trim());
    }

    if (isDuplicate && !isModifyMode) {
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

    String imageUrl = '';
    if (imageHasChanged && selectedImage != null) {
      imageUrl = await CategoriesDB().uploadImageToStorage(selectedImage!);
    }

    String formattedTime = DateTime.now().toIso8601String();

    // Prepare data to insert or update
    Map<String, dynamic> row = {
      CategoriesDB.categoryName: _categoryController.text.trim(),
      CategoriesDB.categoryDescription: _descriptionController.text.trim(),
      CategoriesDB.categoryColor: selectedColor.value,
      CategoriesDB.categoryIconCodePoint: selectedIcon.codePoint,
      CategoriesDB.categoryIconFontFamily: selectedIcon.fontFamily,
      CategoriesDB.categoryIconFontPackage: selectedIcon.fontPackage,
      CategoriesDB.categorySelectedImageBlob: imageUrl.isEmpty ? originalImageUrl : imageUrl,
      CategoriesDB.lastEditedTime: formattedTime,
    };


    try {
      if (isModifyMode) {
        // Update existing category
        await CategoriesDB().updateCategory(widget.documentId!, row);
      } else {
        // Add new category
        await CategoriesDB().insertCategory(row);
      }

      // Update UI and pop the screen
      // Show success prompt
      await showModernSnackBar(
        context: context,
        message: isModifyMode ? "Category updated successfully!" : "Category added successfully!",
        backgroundColor: Colors.green,
      );
      setState(() {
        isProcessing = false;
      });
      Navigator.pop(context, true);
    } catch (e) {
      // Handle errors, show error prompt
      await showModernSnackBar(
        context: context,
        message: isModifyMode ? "Category was not updated" : "Category was not added",
        backgroundColor: Colors.redAccent,
      );
      setState(() {
        isProcessing = false;
      });
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
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
        title: Text(isModifyMode ? "Modify Category" : "Add Category", style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueGrey[900],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Redesigned Text Field for Category
            ExpnzTextField(label: "Enter Category", controller: _categoryController),
            const SizedBox(height: 16),
            // Redesigned Text Field for Description
            ExpnzTextField(label: "Enter Description", controller: _descriptionController),
            const SizedBox(height: 16),
            // Redesigned Button for Icon Picker
            // Container for the entire row
            // Container for the entire row
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.blueGrey[700],
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 7,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Choose Icon or Image',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _pickIcon,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: Icon(
                            selectedIcon,
                            color: Colors.blueGrey[700],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: ClipOval(
                            child: (selectedImage != null)
                                ? Image.file(
                              selectedImage!,
                              fit: BoxFit.cover,
                            )
                                : Icon(
                              Icons.image,
                              color: Colors.blueGrey[700],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickColor,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey[700],
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50.0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.color_lens, // You can change this to any icon you like
                        color: Colors.white,
                      ),
                      SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Pick a Color",
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            "Tap to choose color",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w300,
                              color: Colors.white,
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
            ),

            const SizedBox(height: 32),
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
