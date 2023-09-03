import 'package:expnz/screens/AccountsScreen.dart';
import 'package:expnz/screens/CategoriesScreen.dart';
import 'package:flutter/material.dart';

import '../widgets/CustomAppBar.dart';
import '../widgets/CustomBottomNavBar.dart';
import '../widgets/FloatingActionMenu.dart';
import 'HomeScreen.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}



class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  bool isOpened = false;
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _animation;

  final List<Widget> _children = [
    HomeScreen(),
    AccountsScreen(),
    CategoriesScreen(),
    Text("Overview Screen"),
  ];

  final List<String> _tabNames = [
    "Home",
    "Accounts",
    "Categories",
    "Overview",
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void toggleMenu() {
    setState(() {
      isOpened = !isOpened;
      if (isOpened) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.blueGrey[900],
      appBar: CustomAppBar(title: _tabNames[_currentIndex]),
      body: _children[_currentIndex],
      bottomNavigationBar: SafeArea(
        child: CustomBottomNavBar(
          currentIndex: _currentIndex,
          onTabTapped: onTabTapped,
        ),
      ),
      floatingActionButton: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Positioned(
            bottom: 90,  // Adjust the position as needed.
            right: 10,
            child: AnimatedOpacity(
              opacity: isOpened ? 1 : 0,
              duration: Duration(milliseconds: 300),
              child: FloatingActionMenu(isOpened: isOpened),
            ),
          ),
          Positioned(
            bottom: 10,  // Adjust the position as needed.
            right: 10,
            child: FloatingActionButton(
              backgroundColor: Colors.black87,  // Changed background color
              elevation: 8,  // Changed elevation
              onPressed: toggleMenu,
              child: RotationTransition(
                turns: _animation,
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  child: isOpened
                      ? Icon(Icons.close, key: UniqueKey(), color: Colors.white)  // Added color
                      : Icon(Icons.add, key: UniqueKey(), color: Colors.white),  // Changed to menu icon and added color
                ),
              ),
            ),
          ),
        ],
      ),

    );
  }
}
