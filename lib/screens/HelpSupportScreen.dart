import 'package:expnz/widgets/SimpleWidgets/ExpnZButton.dart';
import 'package:expnz/widgets/SimpleWidgets/ExpnZDropdown.dart';
import 'package:expnz/widgets/SimpleWidgets/ExpnZTextField.dart';
import 'package:expnz/widgets/SimpleWidgets/ExpnzSnackBar.dart';
import 'package:flutter/material.dart';
import 'package:feedback/feedback.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HelpSupportScreen extends StatefulWidget {
  @override
  _HelpSupportScreenState createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  late String selectedIdentifier;
  late TextEditingController feedbackController;

  @override
  void initState() {
    super.initState();
    feedbackController = TextEditingController();
    User? currentUser = auth.currentUser;
    selectedIdentifier = 'Anonymous';
    if (currentUser != null) {
      String displayIdentifier = currentUser.displayName ?? currentUser.email ?? currentUser.uid;
      selectedIdentifier = displayIdentifier;
    }
  }

  @override
  void dispose() {
    feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    List<String> identifierOptions = ['Anonymous'];
    User? currentUser = auth.currentUser;
    if (currentUser != null) {
      String displayIdentifier = currentUser.displayName ?? currentUser.email ?? currentUser.uid;
      identifierOptions.add(displayIdentifier);
    }

    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        title: Text('Help & Support'),
        backgroundColor: Colors.blueGrey[900],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ExpnzDropdownButton(
                label: 'Select Identifier',
                value: selectedIdentifier,
                items: identifierOptions,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedIdentifier = newValue!;
                  });
                },
            ),
            SizedBox(height: 20),
            ExpnzTextField(
              label: 'Your Feedback',
              controller: feedbackController,
              maxLines: 5,
              alwaysFloatingLabel: true,
            ),
            SizedBox(height: 20),
            ExpnZButton(
                label: 'Submit Feedback',
                onPressed: () => _submitFeedback(),
            ),
          ],
        ),
      ),
    );
  }

  void _submitFeedback() async {
    String feedbackText = feedbackController.text;
    if (feedbackText.isEmpty) {
      showModernSnackBar(context: context, message: 'Please enter some feedback before submitting', backgroundColor: Colors.red);
      return;
    }

    try {
      String uid = 'Anonymous';
      if (selectedIdentifier != 'Anonymous') {
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          uid = user.uid;
        }
      }
      await firestore.collection('feedbacks').add({
        'identifier': uid,
        'feedback': feedbackText,
        'timestamp': FieldValue.serverTimestamp(),
      });

      showModernSnackBar(context: context, message: 'Feedback submitted successfully', backgroundColor: Colors.green);
      Navigator.of(context).pop();

      feedbackController.clear();
    } catch (e) {
      showModernSnackBar(context: context, message: 'Error submitting feedback: $e', backgroundColor: Colors.red);
    }
  }
}
