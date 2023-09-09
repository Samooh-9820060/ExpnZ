import 'dart:async';

import 'package:flutter/material.dart';

class ModernSnackBar extends StatelessWidget {
  final String message;
  final Color backgroundColor;
  final VoidCallback? onClose;

  ModernSnackBar({
    required this.message,
    this.onClose,
    this.backgroundColor = Colors.green,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 30,
      left: 16,
      right: 16,
      child: Material(
        borderRadius: BorderRadius.circular(30),  // Ultra-rounded corners
        elevation: 12,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient( // Smooth gradient
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                backgroundColor,
                backgroundColor.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(30),  // Ultra-rounded corners
            boxShadow: [ // Subtle boxShadow
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            title: Text(
              message,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,  // Reduced font size
                fontWeight: FontWeight.w600,  // Semi-bold
              ),
            ),
            trailing: ElevatedButton(
              onPressed: onClose,
              style: ElevatedButton.styleFrom(
                primary: Colors.white.withOpacity(0.5),
                shape: RoundedRectangleBorder(  // Rounded button
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              child: Icon(Icons.close, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showModernSnackBar({
  required BuildContext context,
  required String message,
  required Color backgroundColor,
  int durationSeconds = 2,
}) async {
  final Completer<void> completer = Completer<void>();
  late OverlayEntry overlayEntry;
  overlayEntry = OverlayEntry(
    builder: (context) => ModernSnackBar(
      message: message,
      backgroundColor: backgroundColor,
      onClose: () {
        overlayEntry.remove();
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
    ),
  );
  Overlay.of(context)!.insert(overlayEntry);
  await Future.delayed(Duration(seconds: durationSeconds));
  if (!completer.isCompleted) {
    overlayEntry.remove();
    completer.complete();
  }
}
