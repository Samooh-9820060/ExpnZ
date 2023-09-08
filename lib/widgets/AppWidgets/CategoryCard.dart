import 'package:expnz/screens/AddCategory.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class CategoryCard extends StatefulWidget {
  final Key? key;
  final int categoryId;
  final String categoryName;
  final String income;
  final String expense;
  final IconData iconData;
  final Animation<double> animation;
  final Color primaryColor;

  CategoryCard({
    this.key,
    required this.categoryId,
    required this.categoryName,
    required this.income,
    required this.expense,
    required this.iconData,
    required this.animation,
    required this.primaryColor,
  }) : super(key: key);

  @override
  _CategoryCardState createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> with TickerProviderStateMixin {
  late AnimationController _numberController;
  late Animation<double> _numberAnimation;
  late AnimationController _deleteController;
  late Animation<double> _deleteAnimation;

  @override
  void initState() {
    super.initState();
    _numberController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _numberAnimation = Tween<double>(begin: 0, end: 1).animate(_numberController);
    _numberController.forward();
    _deleteController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _deleteAnimation = Tween<double>(begin: 1, end: 0).animate(_deleteController);
  }

  @override
  void dispose() {
    _numberController.dispose();
    _deleteController.dispose();
    super.dispose();
  }

  String _animatedNumberString(double animationValue, String targetValue) {
    int value = (double.parse(targetValue.replaceAll(RegExp(r'[\$,]'), '')) * animationValue).toInt();
    final formatter = NumberFormat("#,###");
    return '\$' + formatter.format(value);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _deleteController,
      builder: (context, child) {
        return Opacity(
          opacity: _deleteAnimation.value,
          child: child,
        );
      },
      child: AnimatedBuilder(
        animation: _numberController,
        builder: (context, child) {
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddCategoryScreen(categoryId: this.widget.categoryId),
                ),
              ).then((value) {
                setState(() {});
              });
              },
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.black, Colors.grey[850]!],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    offset: Offset(0, 4),
                    blurRadius: 6.0,
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: widget.primaryColor,
                    child: Icon(widget.iconData, color: Colors.white, size: 24),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.categoryName,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      infoColumn("Income", _animatedNumberString(_numberAnimation.value, widget.income), Colors.green),
                      SizedBox(width: 16),
                      infoColumn("Expense", _animatedNumberString(_numberAnimation.value, widget.expense), Colors.red),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Column infoColumn(String title, String value, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 8,
            color: Colors.white70,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
