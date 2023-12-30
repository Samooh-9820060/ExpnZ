import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../screens/SearchScreen.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback toggleDrawer;

  CustomAppBar({required this.title, required this.toggleDrawer});

  @override
  Widget build(BuildContext context) {
    // Set the status bar color
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // transparent status bar
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.blueGrey[900],
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 50,
        title: Transform.translate(
          offset: const Offset(0, -5),  // Move title upwards by 5 units
          child: Text(
            title,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        actions: [
          // In CustomAppBar
          Transform.translate(
            offset: const Offset(0, -5),  // Move icon upwards by 5 units
            child: IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    transitionDuration: const Duration(milliseconds: 500),
                    pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
                      return SearchScreen();
                    },
                    transitionsBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(1.0, 0.0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
