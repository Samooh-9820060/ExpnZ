import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expnz/screens/AboutUsScreen.dart';
import 'package:expnz/screens/HelpSupportScreen.dart';
import 'package:expnz/screens/HomeScreen.dart';
import 'package:expnz/screens/MyProfile.dart';
import 'package:expnz/screens/RecurringTransactionsPage.dart';
import 'package:expnz/screens/SettingsScreen.dart';
import 'package:expnz/screens/SignInScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lottie/lottie.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MenuDrawer extends StatefulWidget {
  final String? profilePicUrl;  // Assuming this is your profile picture URL

  MenuDrawer({this.profilePicUrl});

  @override
  _MenuDrawerState createState() => _MenuDrawerState();
}

class _MenuDrawerState extends State<MenuDrawer> {
  bool isDarkMode = false;
  String appVersion = 'v1.0.0';

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    setState(() {
      appVersion = 'v${info.version}';  // Sets the version number
    });
  }

  Future<void> _signOut() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('lastAccountSyncTime');
      await prefs.remove('lastCategorySyncTime');
      await prefs.remove('lastTransactionSyncTime');
      await prefs.remove('lastRecurringTransactionSyncTime');

      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
      // Navigate to the HomeScreen or any other screen after successful logout
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => SignInScreen()));
    } catch (e) {
      print("Error while logging out: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            child: Padding(
              padding: EdgeInsets.all(6),
              child: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(user?.uid).get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                    var userData = snapshot.data!.data() as Map<String, dynamic>?;
                    String? profileImageUrl = userData?['profileImageUrl'];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        Flexible(
                          child: CircleAvatar(
                            backgroundImage: profileImageUrl != null ? NetworkImage(profileImageUrl) : null,
                            child: profileImageUrl == null ? Icon(Icons.person, size: 40) : null,
                            radius: 50.0,
                          ),
                        ),
                      ],
                    );
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                menuItem(Icons.person, "My Profile", MyProfileScreen()),
                menuItem(Icons.settings, "Settings", SettingsScreen()),
                menuItem(Icons.help, "Help & Support", HelpSupportScreen()),
                menuItem(Icons.loop, "Recurring", RecurringTransactionsPage()),
                menuItem(Icons.info, "About Us", AboutUsScreen()),
                ListTile(
                  leading: Icon(Icons.exit_to_app, color: Colors.blueGrey[700]),
                  title: Text("Logout"),
                  onTap: _signOut,
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
            child: Text(
              'App Version: $appVersion',  // Display the version number here
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  Widget menuItem(IconData icon, String title, Widget targetPage) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueGrey[700]),
      title: Text(title),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => targetPage),
      ),
    );
  }
}
