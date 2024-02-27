import 'package:flutter/material.dart';

class ExpnZButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color primaryColor;
  final Color textColor;
  final double fontSize;
  final IconData? icon;
  final bool isLoading;

  const ExpnZButton({super.key,
    required this.label,
    required this.onPressed,
    this.primaryColor = Colors.blueAccent,
    this.textColor = Colors.white,
    this.fontSize = 18.0,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (icon != null) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: isLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: Center(
            child: CircularProgressIndicator( // Loading indicator
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        )
            : Icon(icon, color: Colors.white),
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
        label: isLoading ? Text(
          'Loading',
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ) : Text(
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
