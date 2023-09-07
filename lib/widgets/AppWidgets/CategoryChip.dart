import 'package:flutter/material.dart';

class CategoryChip extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Function onTap;

  CategoryChip({
    required this.icon,
    required this.label,
    this.isSelected = true,
    required this.onTap,
  });

  @override
  _CategoryChipState createState() => _CategoryChipState();
}

class _CategoryChipState extends State<CategoryChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

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

  Future<void> _animateAndRemove() async {
    await _controller.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {

    _controller.forward();


    return GestureDetector(
      onTap: () => _animateAndRemove(),

      child: AnimatedBuilder(
        animation: _animation,
        builder: (BuildContext context, Widget? child) {
          return Transform.scale(
            scale: _animation.value,
            child: AnimatedOpacity(
              opacity: _animation.value,
              duration: Duration(milliseconds: 100),
              child: child,
            ),
          );
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Internal padding for the text and icon
          margin: EdgeInsets.all(0), // Margin for external spacing
          decoration: BoxDecoration(
            border: Border.all(
              color: widget.isSelected ? Colors.blueAccent : Colors.transparent,
              width: 1.0,
            ),
            borderRadius: BorderRadius.all(
              Radius.circular(16.0),
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isSelected ? Colors.blueAccent.withOpacity(0.2) : Colors.transparent,
                blurRadius: 4.0,
              ),
            ],
            color: widget.isSelected ? Colors.blueGrey[700] : Colors.blueGrey[800],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: widget.isSelected ? Colors.blueAccent : Colors.grey),
              SizedBox(width: 4),
              Text(widget.label),
              SizedBox(width: 4),
              InkWell(  // Replacing IconButton with InkWell
                onTap: () => _animateAndRemove(),
                child: Icon(Icons.clear_sharp, size: 18),  // You can choose an appropriate size
              ),
            ],
          ),
        ),
      ),
    );
  }
}
