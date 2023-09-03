import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  CustomAppBar({required this.title});

  @override
  Widget build(BuildContext context) {
    // Set the status bar color
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // transparent status bar
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Container(
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.blueGrey[900],
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.white),
          onPressed: () {},
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
        ),
        title: Text(
          title,
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.account_circle, color: Colors.white, size: 30), // More detailed profile icon
            onPressed: () {},
            highlightColor: Colors.transparent,
            splashColor: Colors.transparent,
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
