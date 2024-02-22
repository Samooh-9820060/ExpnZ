import 'dart:async';
import 'package:flutter/material.dart';

class ExpnzSnackBar extends StatelessWidget {
  final String message;
  final Color backgroundColor;
  final VoidCallback? onClose;

  ExpnzSnackBar({
    required this.message,
    this.onClose,
    this.backgroundColor = Colors.green,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 50,
      left: 20,
      right: 20,
      child: Material(
        borderRadius: BorderRadius.circular(30), // Changed to affect all corners
        elevation: 12,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width, // Full screen width
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                backgroundColor,
                backgroundColor.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(30), // Changed to affect all corners
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Center(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
    builder: (context) => ExpnzSnackBar(
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
  Overlay.of(context).insert(overlayEntry);
  await Future.delayed(Duration(seconds: durationSeconds));
  if (!completer.isCompleted) {
    overlayEntry.remove();
    completer.complete();
  }
}

void showDeleteConfirmationDialog({
  required BuildContext context,
  required String title,
  required String content,
  required VoidCallback onConfirmDelete,
}) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          TextButton(
            child: const Text("Delete"),
            onPressed: () {
              onConfirmDelete();
              Navigator.of(dialogContext).pop();
            },
          ),
        ],
      );
    },
  );
}

