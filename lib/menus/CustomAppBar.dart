import 'dart:async';

import 'package:expnz/utils/NotificationListener.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../screens/SearchScreen.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback toggleDrawer;
  final AppNotificationListener notificationListener;

  CustomAppBar({required this.title, required this.toggleDrawer, required this.notificationListener});

  @override
  _CustomAppBarState createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarState extends State<CustomAppBar> {
  bool isListenerActive = false;

  late StreamSubscription<bool> _listenerSubscription;

  @override
  void initState() {
    super.initState();
    _listenerSubscription = widget.notificationListener.statusStream.listen(
          (isActive) {
        setState(() {
          print('changing to $isActive');
          isListenerActive = isActive;
        });
      },
    );
  }

  @override
  void dispose() {
    _listenerSubscription.cancel();
    super.dispose();
  }

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
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 50,
        title: Transform.translate(
          offset: const Offset(0, -5),  // Move title upwards by 5 units
          child: Text(
            widget.title,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        actions: [
          if (isListenerActive)
            Transform.translate(
              offset: const Offset(0, -5),  // Move icon upwards by 5 units
              child: Icon(Icons.circle, color: Colors.green, size: 5.0),
            ),
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
}
