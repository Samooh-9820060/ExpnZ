import 'package:flutter/material.dart';

class ExpnZButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color primaryColor;
  final Color textColor;
  final double fontSize;

  ExpnZButton({
    required this.label,
    required this.onPressed,
    this.primaryColor = Colors.blueAccent,
    this.textColor = Colors.white,
    this.fontSize = 18.0,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(primaryColor),
        padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 50, vertical: 20)),
        textStyle: MaterialStateProperty.all(TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold)),
        elevation: MaterialStateProperty.all(5),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50.0),
          ),
        ),
      ),
    );
  }
}
