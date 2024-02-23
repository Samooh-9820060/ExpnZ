import 'package:expnz/widgets/SimpleWidgets/ExpnZButton.dart';
import 'package:expnz/widgets/SimpleWidgets/ExpnZTextField.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChangePasswordScreen extends StatefulWidget {
  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();

  Future<void> changePassword() async {
    final oldPassword = _oldPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmNewPassword = _confirmNewPasswordController.text;

    // Check if the new passwords match
    if (newPassword != confirmNewPassword) {
      _showErrorDialog("New passwords do not match");
      return;
    }

    try {
      User? user = FirebaseAuth.instance.currentUser;
      String email = user?.email ?? '';

      // Reauthenticate the user
      AuthCredential credential = EmailAuthProvider.credential(
          email: email,
          password: oldPassword
      );

      await user?.reauthenticateWithCredential(credential);

      // Change password
      await user?.updatePassword(newPassword);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Password changed successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        _showErrorDialog("The old password is incorrect");
      } else if (e.code == 'weak-password') {
        _showErrorDialog("The password is too weak");
      } else {
        _showErrorDialog(e.message ?? "An error occurred");
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }


  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        scrolledUnderElevation: 0.0,
        backgroundColor: Colors.blueGrey[900],
        title: const Text('Change Password'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              ExpnzTextField(label: 'Old Password', controller: _oldPasswordController, isPassword: true),
              ExpnzTextField(label: 'New Password', controller: _newPasswordController, isPassword: true),
              ExpnzTextField(label: 'Confirm New Password', controller: _confirmNewPasswordController, isPassword: true),

              // Change Password Button
              const SizedBox(height: 10,),
              ExpnZButton(label: 'Change Password', onPressed: changePassword),
            ],
          )
          ,
        ),
      ),
    );
  }
}
