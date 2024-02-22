import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expnz/widgets/SimpleWidgets/ExpnZButton.dart';
import 'package:expnz/widgets/SimpleWidgets/ExpnZTextField.dart';
import 'package:expnz/widgets/SimpleWidgets/ExpnzSnackBar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as Path;

import '../utils/global.dart';
import 'ChangePassword.dart';

class MyProfileScreen extends StatefulWidget {
  @override
  _MyProfileScreenState createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  final _nameController = TextEditingController();
  final _mobileNumberController = TextEditingController();
  XFile? _profileImage;
  String? _profileImageUrl;
  XFile? _pickedFile;
  bool imageHasChanged = false;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileNumberController.dispose();
    super.dispose();
  }

  ImageProvider? getImageProvider() {
    if (_profileImage != null) {
      return FileImage(File(_profileImage!.path));
    } else if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      return NetworkImage(_profileImageUrl!);
    }
    return null;
  }

  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Fetch user data from profileNotifier
      final profileData = profileNotifier.value;
      if (profileData != null) {
        setState(() {
          _nameController.text =
              profileData['name'] ?? ''; // Use the name from the profile data
          _mobileNumberController.text = profileData['phoneNumber'] ??
              ''; // Use the phone number from the profile data

          if (profileData.containsKey('profileImageUrl') &&
              profileData['profileImageUrl'] is String) {
            _profileImageUrl = profileData[
                'profileImageUrl']; // Use the profile image URL from the profile data
          }
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        //selectedImage = File(pickedFile.path);
        setState(() {
          _pickedFile = pickedFile;
          _cropImage();
        });
        //selectedIcon = Icons.search;
      } else {
        print("No image selected.");
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
        final xFile = XFile(compressedFile?.path ?? file.path);
        setState(() {
          _profileImage = xFile;
          imageHasChanged = true;
        });
      }
    }
  }

  Future<File?> _compressFile(File file) async {
    try {
      final filePath = file.absolute.path;

      // Define the target path and file name for JPEG format
      String outPath =
          "${filePath.substring(0, filePath.lastIndexOf('.'))}_compressed.jpg";

      // Compress the image and convert to JPEG
      final compressedImage = await FlutterImageCompress.compressAndGetFile(
        filePath,
        outPath,
        quality: 60,
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

  Future<String> uploadImage(XFile? imageFile) async {
    setState(() {
      isProcessing = true;
    });
    if (imageFile == null) {
      throw Exception('No image selected');
    }

    // Fetch the user's unique ID
    String userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown_user';

    // Generate a timestamp
    int timestamp = DateTime.now().millisecondsSinceEpoch;

    // Construct a unique file name
    String fileExtension = Path.extension(imageFile.path);
    String fileName = '$userId-$timestamp$fileExtension';

    // Reference to Firebase Storage with specific bucket
    firebase_storage.FirebaseStorage storage =
        firebase_storage.FirebaseStorage.instanceFor(
            bucket: 'gs://expnzapp.appspot.com');

    firebase_storage.Reference storageRef =
        storage.ref().child('profile_images/$fileName');

    // Upload the file
    firebase_storage.UploadTask uploadTask =
        storageRef.putFile(File(imageFile.path));
    await uploadTask.whenComplete(() => null);

    // Get the download URL
    String downloadUrl = await storageRef.getDownloadURL();
    return downloadUrl;
  }

  Future<void> saveUserData(
      String name, String phoneNumber, String imageUrl) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': name,
        'phoneNumber': phoneNumber,
        'profileImageUrl': imageUrl,
      });
    }

    setState(() {
      isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        title: Text('My Profile'),
        backgroundColor: Colors.blueGrey[900],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 80.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Profile Picture
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user?.uid)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                    var userData = snapshot.data!.data() as Map<String, dynamic>?;
                    String? profileImageUrl = userData?['profileImageUrl'];

                    return CircleAvatar(
                      radius: 100.0, // This radius defines the size of the CircleAvatar
                      backgroundColor: Colors.grey[300], // Fallback color
                      backgroundImage: getImageProvider(),
                      child: _profileImage == null && (_profileImageUrl == null || _profileImageUrl!.isEmpty)
                          ? Icon(Icons.camera_alt, size: 50, color: Colors.white70)
                          : null,
                    );
                  } else {
                    return CircularProgressIndicator();
                  }
                },
              ),
              IconButton(
                icon: Icon(Icons.edit),
                color: Colors.white,
                onPressed: _pickImage,
              ),
              const SizedBox(height: 20),

              // Name TextField
              ExpnzTextField(label: 'Your Name', controller: _nameController),
              SizedBox(height: 20),

              // Phone TextField
              ExpnzTextField(
                label: 'Phone Number',
                controller: _mobileNumberController,
                isNumber: true,
              ),
              SizedBox(height: 20),
              // Save Changes Button
              ExpnZButton(
                label: isProcessing ? 'Saving' : 'Save Changes',
                onPressed: () async {
                  if (isProcessing) {
                    return;
                  }
                  isProcessing = true;
                  try {
                    String imageUrl = _profileImageUrl ?? '';
                    if (_profileImage != null && imageHasChanged) {
                      // If a new image has been picked, upload it
                      imageUrl = await uploadImage(_profileImage);
                    }
                    await saveUserData(_nameController.text,
                        _mobileNumberController.text, imageUrl);

                    // Show a confirmation message
                    showModernSnackBar(context: context, message: 'Data has been updated successfully', backgroundColor: Colors.green);
                  } catch (e) {
                    // Handle any errors here
                    showModernSnackBar(context: context, message: 'Failed to update data', backgroundColor: Colors.red);
                  }
                  isProcessing = false;
                },
              ),
              SizedBox(
                height: 30,
              ),
              // Change Password Button
              ExpnZButton(
                label: 'Change Password',
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ChangePasswordScreen(),
                  ));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
