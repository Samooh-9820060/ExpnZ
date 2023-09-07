import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class CategoryCard extends StatefulWidget {
  final String categoryName;
  final String income;
  final String expense;
  final IconData iconData;
  final Animation<double> animation;
  final Color primaryColor;
  final Function onDelete;

  CategoryCard({
    required this.categoryName,
    required this.income,
    required this.expense,
    required this.iconData,
    required this.animation,
    required this.primaryColor,
    required this.onDelete,
  });

  @override
  _CategoryCardState createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> with SingleTickerProviderStateMixin {
  late AnimationController _numberController;
  late Animation<double> _numberAnimation;

  @override
  void initState() {
    super.initState();
    _numberController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _numberAnimation = Tween<double>(begin: 0, end: 1).animate(_numberController);
    _numberController.forward();
  }

  @override
  void dispose() {
    _numberController.dispose();
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
      animation: _numberController,
      builder: (context, child) {
        return Container(
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
              IconButton(
                onPressed: () => widget.onDelete(), // Call the callback function here
                icon: Icon(Icons.delete, color: Colors.white),
              ),
            ],
          ),
        );
      },
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
