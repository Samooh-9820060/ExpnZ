import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabTapped;

  CustomBottomNavBar({required this.currentIndex, required this.onTabTapped});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blueGrey[900]?.withOpacity(0.9),
          borderRadius: BorderRadius.circular(30), // rounded corners
          boxShadow: [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 10,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Home', 0),
              _buildNavItem(Icons.account_balance_wallet, 'Accounts', 1),
              _buildNavItem(Icons.category, 'Categories', 2),
              _buildNavItem(Icons.pie_chart, 'Overview', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData iconData, String text, int index) {
    bool isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTabTapped(index),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: Colors.white?.withOpacity(0.2),
              )
            : null,
        child: Row(
          children: [
            Icon(iconData,
                color: isSelected ? Colors.white : Colors.grey[600]),
            SizedBox(width: 8),
            AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    child: child,
                    scale: animation,
                  ),
                );
              },
              child: isSelected
                  ? Text(
                      text,
                      style: TextStyle(
                          color:
                              isSelected ? Colors.white : Colors.grey[600]),
                      key: ValueKey<int>(index),
                    )
                  : SizedBox.shrink(key: ValueKey<int>(index)),
            ),
          ],
        ),
      ),
    );
  }
}
