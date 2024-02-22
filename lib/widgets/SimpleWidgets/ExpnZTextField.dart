import 'package:flutter/material.dart';

class ExpnzTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isNumber;
  final int? maxLength;
  final int? maxLines;
  final bool isError;
  final bool? enabled;
  final bool alwaysFloatingLabel;

  ExpnzTextField({
    required this.label,
    required this.controller,
    this.isNumber = false,
    this.maxLength,
    this.maxLines,
    this.isError = false,
    this.enabled,
    this.alwaysFloatingLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: isError ? Colors.red[300] : Colors.blueGrey[700],
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          maxLength: maxLength,
          maxLines: maxLines,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
          ),
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            counterText: "",
            labelText: label,
            labelStyle: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            border: InputBorder.none,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: BorderSide(
                color: isError ? Colors.red : Colors.blueAccent,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: const BorderSide(
                color: Colors.transparent,
              ),
            ),
            contentPadding: const EdgeInsets.all(20),
            floatingLabelBehavior: alwaysFloatingLabel
                ? FloatingLabelBehavior.always
                : FloatingLabelBehavior.auto,
          ),
          enabled: enabled,
        ),
      ),
    );
  }
}
