import 'package:expnz/screens/HelpSupportScreen.dart';
import 'package:expnz/screens/HomeScreen.dart';
import 'package:expnz/screens/MyProfile.dart';
import 'package:expnz/screens/SettingsScreen.dart';
import 'package:expnz/screens/SignInScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class MenuDrawer extends StatefulWidget {
  final String? profilePicUrl;  // Assuming this is your profile picture URL

  MenuDrawer({this.profilePicUrl});

  @override
  _MenuDrawerState createState() => _MenuDrawerState();
}

class _MenuDrawerState extends State<MenuDrawer> {
  bool isDarkMode = false;

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      // Navigate to the HomeScreen or any other screen after successful logout
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => SignInScreen()));
    } catch (e) {
      print("Error while logging out: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 100.0, left: 15),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.profilePicUrl != null)  // If profile picture is available
              Image.network(
                widget.profilePicUrl!,
                width: MediaQuery.of(context).size.width / 4,
                height: MediaQuery.of(context).size.width / 4,
              )
            else  // If profile picture is not available, show Lottie animation
              Lottie.asset(
                'assets/lottie/profile-pic1.json',
                width: MediaQuery.of(context).size.width / 4,
                height: MediaQuery.of(context).size.width / 4,
                fit: BoxFit.fill,
              ),
            SizedBox(height: 40),
            menuGroup([
              //menuItem(Icons.home, "Home", context, HomeScreen()),
              menuItem(Icons.person, "My Profile", context, targetPage: MyProfileScreen()),
            ]),
            menuGroup([
              menuItem(Icons.settings, "Settings", context, targetPage: SettingsScreen()),
              menuItem(Icons.help, "Help & Support", context, targetPage: HelpSupportScreen()),
              //menuItem(Icons.notifications, "Notifications", context, targetPage: HomeScreen()),
            ]),
            menuGroup([
              //menuItem(Icons.loop, "Recurring Transactions", context, targetPage: HomeScreen()),
              //menuItem(Icons.group_add, "Invite Friends", context, targetPage: HomeScreen()),
              menuItem(Icons.info, "About Us", context, targetPage: HomeScreen()),
              menuItem(Icons.exit_to_app, "Logout", context, targetPage: null, onTap: _signOut),
            ]),
          ],
        ),
      ),
    );
  }

  Widget menuGroup(List<Widget> items) {
    return Column(
      children: [
        ...items,
        SizedBox(height: 20),
        Divider(color: Colors.blueGrey[700], thickness: 2),
        SizedBox(height: 20),
      ],
    );
  }

  Widget menuItem(IconData icon, String title, BuildContext context, {Widget? targetPage, Widget? trailing, Function()? onTap}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: () {
          if (targetPage != null) {
            Navigator.push(
              context,
              PageRouteBuilder(
                transitionDuration: Duration(milliseconds: 500),
                pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
                  return targetPage;
                },
                transitionsBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  );
                },
              ),
            );
          } else {
            onTap!(); // Call the onTap function
          }
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(vertical: 8.0),
          padding: EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.blueGrey[800],
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.blueGrey[700]!.withOpacity(0.5),
                spreadRadius: 1,
                blurRadius: 2,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Container(
            height: 15,
            child: Row(
              mainAxisSize: MainAxisSize.min,  // Wrap content by setting this to min
              children: [
                Icon(icon, color: Colors.white, size: 14),
                SizedBox(width: 20),
                Text(title, style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                if (trailing != null) trailing // Add trailing widget if available
              ],
            ),
          ),
        ),
      ),
    );
  }
}
