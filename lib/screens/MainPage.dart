import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expnz/models/TempTransactionsModel.dart';
import 'package:expnz/models/TransactionsModel.dart';
import 'package:expnz/screens/AccountsScreen.dart';
import 'package:expnz/screens/CategoriesScreen.dart';
import 'package:expnz/screens/OverviewScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:animated_drawer/views/animated_drawer.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../menus/CustomAppBar.dart';
import '../menus/CustomBottomNavBar.dart';
import '../menus/FloatingActionMenu.dart';
import '../utils/NotificationListener.dart';
import 'HomeScreen.dart';
import '../menus/MenuDrawer.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin, WidgetsBindingObserver {
  bool isOpened = false;
  bool isDrawerOpen = false;
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _animation;
  late AppNotificationListener appNotificationListener;
  String? _profileImageUrl;

  final List<Widget> _children = [
    //HomeScreen(),
    AccountsScreen(),
    AccountsScreen(),
    CategoriesScreen(),
  ];

  final List<String> _tabNames = [
    "Home",
    "Accounts",
    "Categories",
  ];

  @override
  void initState() {
    super.initState();
    appNotificationListener = AppNotificationListener();
    _fetchUserData();
    initializeApp(context);
    Future.delayed(Duration.zero, () {
      Provider.of<TransactionsModel>(context, listen: false).fetchTransactions();
      Provider.of<TempTransactionsModel>(context, listen: false).fetchTransactions();
    });
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);
  }

  Future<void> initializeApp(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final allowNotificationReading = prefs.getBool('allowNotificationReading') ?? false;

    if (allowNotificationReading) {
      if (appNotificationListener.started) {
        // If already listening, show an alert dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Notification Listener Active"),
              content: Text("The app is already listening for notifications."),
              actions: <Widget>[
                TextButton(
                  child: Text("OK"),
                  onPressed: () {
                    Navigator.of(context).pop(); // Closes the dialog
                  },
                ),
              ],
            );
          },
        );
      } else {
        // Start listening for notifications
        appNotificationListener.startListening();
      }
    } else {
      appNotificationListener.stopListening();
    }
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

  void toggleDrawer() {
    setState(() {
      isDrawerOpen = !isDrawerOpen;
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

  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        // Other user data
        if (userData['profileImageUrl'] is String) {
          _profileImageUrl = userData['profileImageUrl'];
        }
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedDrawer(
          openIcon: Icon(Icons.menu, color: Colors.white),
          // Add your custom icon here
          closeIcon: Icon(Icons.arrow_back, color: Colors.white),
          backgroundGradient: LinearGradient(
            colors: [Colors.blueGrey[900]!, Colors.blueGrey[800]!],
          ),
          shadowColor: Colors.blueGrey[700]!,
          menuPageContent: MenuDrawer(profilePicUrl: _profileImageUrl),
          homePageContent: Scaffold(
            extendBody: true,
            backgroundColor: Colors.blueGrey[900],
            appBar: CustomAppBar(
              title: _tabNames[_currentIndex],
              toggleDrawer: toggleDrawer,
              notificationListener: appNotificationListener,
            ),
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
                  bottom: 90, // Adjust the position as needed.
                  right: 10,
                  child: AnimatedOpacity(
                    opacity: isOpened ? 1 : 0,
                    duration: Duration(milliseconds: 300),
                    child: FloatingActionMenu(
                      isOpened: isOpened,
                      closeMenu: toggleMenu,  // Pass the toggleMenu function here
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10, // Adjust the position as needed.
                  right: 10,
                  child: FloatingActionButton(
                    backgroundColor: Colors.black87, // Changed background color
                    elevation: 8, // Changed elevation
                    onPressed: toggleMenu,
                    child: RotationTransition(
                      turns: _animation,
                      child: AnimatedSwitcher(
                        duration: Duration(milliseconds: 300),
                        child: isOpened
                            ? Icon(Icons.close,
                                key: UniqueKey(),
                                color: Colors.white) // Added color
                            : Icon(Icons.add,
                                key: UniqueKey(),
                                color: Colors
                                    .white), // Changed to menu icon and added color
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
