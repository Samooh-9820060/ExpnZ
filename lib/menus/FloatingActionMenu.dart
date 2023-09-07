import 'package:expnz/screens/AddCategory.dart';
import 'package:flutter/material.dart';

class FloatingActionMenu extends StatelessWidget {
  final bool isOpened;

  FloatingActionMenu({required this.isOpened});

  Widget buildMenuItem(
      IconData icon, String label, VoidCallback onPressed) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),  // Reduced vertical margin
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            offset: Offset(0, 4),
            blurRadius: 10.0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(50),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),  // Reduced padding
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 20),  // Reduced icon size
                SizedBox(width: 16),  // Reduced width
                Text(
                  label,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,  // Reduced font size
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: Duration(milliseconds: 300),
      opacity: isOpened ? 1.0 : 0.0,
      child: ClipRect(
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          height: isOpened ? null : 0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              buildMenuItem(Icons.add_chart, "Add Transaction", () {}),
              buildMenuItem(Icons.payment, "Add Account", () {}),
              buildMenuItem(Icons.payment, "Add Category", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddCategoryScreen()),
                );
              }),            ],
          ),
        ),
      ),
    );
  }
}
