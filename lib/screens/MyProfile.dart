import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as Path;

class MyProfileScreen extends StatefulWidget {
  @override
  _MyProfileScreenState createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  final _nameController = TextEditingController();
  final _mobileNumberController = TextEditingController();
  XFile? _profileImage;
  String? _profileImageUrl; // Add this line

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
      DocumentSnapshot userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        _nameController.text = userData['name'] ?? ''; // Add null check
        _mobileNumberController.text = userData['phoneNumber'] ?? ''; // Add null check
        if (userData['profileImageUrl'] is String) {
          _profileImageUrl = userData['profileImageUrl']; // Ensure it's a String
        }
      });
    }
  }



  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = image;
      });
    }
  }

  Future<String> uploadImage(XFile? imageFile) async {
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
    firebase_storage.FirebaseStorage.instanceFor(bucket: 'gs://expnzapp.appspot.com');

    firebase_storage.Reference storageRef =
    storage.ref().child('profile_images/$fileName');

    // Upload the file
    firebase_storage.UploadTask uploadTask = storageRef.putFile(File(imageFile.path));
    await uploadTask.whenComplete(() => null);

    // Get the download URL
    String downloadUrl = await storageRef.getDownloadURL();
    return downloadUrl;
  }

  Future<void> saveUserData(String name, String phoneNumber, String imageUrl) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': name,
        'phoneNumber': phoneNumber,
        'profileImageUrl': imageUrl,
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        title: Text('My Profile'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 80.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Profile Picture
              CircleAvatar(
                radius: 50,
                backgroundImage: getImageProvider(),
                child: _profileImage == null && (_profileImageUrl == null || _profileImageUrl!.isEmpty)
                    ? Icon(Icons.camera_alt, size: 50, color: Colors.white70)
                    : null,
              ),
              IconButton(
                icon: Icon(Icons.edit),
                color: Colors.white,
                onPressed: _pickImage,
              ),
              const SizedBox(height: 20),

              // Name TextField
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Your Name',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green),
                  ),
                ),
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 20),

              // Phone TextField
              TextField(
                controller: _mobileNumberController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green),
                  ),
                ),
                style: TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 20),
              // Save Changes Button
              ElevatedButton(
                onPressed: () async {
                  try {
                    String imageUrl = _profileImageUrl ?? '';
                    if (_profileImage != null) {
                      // If a new image has been picked, upload it
                      imageUrl = await uploadImage(_profileImage);
                    }
                    await saveUserData(_nameController.text, _mobileNumberController.text, imageUrl);

                    // Show a confirmation message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Data has been updated successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    // Handle any errors here
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update data'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: Text('Save Changes'),
                style: ElevatedButton.styleFrom(
                  primary: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              SizedBox(height: 30,),
              // Change Password Button
              ElevatedButton(
                onPressed: () {
                  // Logic to navigate to Change Password Screen
                },
                child: Text('Change Password'),
                style: ElevatedButton.styleFrom(
                  primary: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
