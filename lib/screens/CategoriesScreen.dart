import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/AppWidgets/CategoryCard.dart';

class CategoriesScreen extends StatefulWidget {
  @override
  _CategoriesScreenState createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blueGrey[900],
      child: ListView(
        children: [
          buildAnimatedCategoryCard("Groceries", "\$200", "\$50", Icons.ac_unit),
          buildAnimatedCategoryCard("Entertainment", "\$100", "\$75", Icons.add_chart),
        ],
      ),
    );
  }

  Widget buildAnimatedCategoryCard(String categoryName, String income, String expense, IconData iconData) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.scale(
            scale: _animation.value,
            child: CategoryCard(
              categoryName: categoryName,
              income: income,
              expense: expense,
              iconData: iconData,
              animation: _animation,
            ),
          ),
        );
      },
    );
  }
}
