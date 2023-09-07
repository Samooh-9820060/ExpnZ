import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isNumber;
  final int? maxLength;
  final bool isError;

  CustomTextField({
    required this.label,
    required this.controller,
    this.isNumber = false,
    this.maxLength,
    this.isError = false,
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
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          maxLength: maxLength,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
          ),
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            counterText: "",
            labelText: label,
            labelStyle: TextStyle(
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
              borderSide: BorderSide(
                color: Colors.transparent,
              ),
            ),
            contentPadding: EdgeInsets.all(20),
          ),
        ),
      ),
    );
  }
}
