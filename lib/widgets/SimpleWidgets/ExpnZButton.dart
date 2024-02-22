import 'package:flutter/material.dart';

class ExpnZButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color primaryColor;
  final Color textColor;
  final double fontSize;
  final IconData? icon;

  const ExpnZButton({super.key,
    required this.label,
    required this.onPressed,
    this.primaryColor = Colors.blueAccent,
    this.textColor = Colors.white,
    this.fontSize = 18.0,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (icon != null) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: textColor,),
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(primaryColor),
          padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 50, vertical: 20)),
          textStyle: MaterialStateProperty.all(TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold)),
          elevation: MaterialStateProperty.all(5),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50.0),
            ),
          ),
        ),
        label: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else {
      return ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(primaryColor),
          padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 50, vertical: 20)),
          textStyle: MaterialStateProperty.all(TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold)),
          elevation: MaterialStateProperty.all(5),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50.0),
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }
}
