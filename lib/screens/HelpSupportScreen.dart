import 'package:expnz/widgets/SimpleWidgets/ModernSnackBar.dart';
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
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Select Identifier',
              ),
              value: selectedIdentifier,
              onChanged: (String? newValue) {
                setState(() {
                  selectedIdentifier = newValue!;
                });
              },
              items: identifierOptions
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            Text(
              'Your Feedback',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            TextField(
              controller: feedbackController,
              decoration: InputDecoration(
                hintText: 'Enter your feedback here',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _submitFeedback(),
              child: Text('Submit Feedback'),
              style: ElevatedButton.styleFrom(
                primary: Colors.blue,
                onPrimary: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
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
