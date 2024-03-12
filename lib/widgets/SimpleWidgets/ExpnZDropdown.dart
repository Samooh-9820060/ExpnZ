import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ExpnzDropdownButton extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final Function(String?) onChanged;
  final bool isError;
  final AnimationController? animationController;

  ExpnzDropdownButton({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.isError = false,
    this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    // If animationController is provided, use AnimatedBuilder
    if (animationController != null) {
      return AnimatedBuilder(
        animation: animationController!,
        builder: (context, child) {
          return Opacity(
            opacity: animationController!.value,
            child: Transform.scale(
              scale: animationController!.value,
              child: child,
            ),
          );
        },
        child: buildDropdown(context), // Refactored dropdown building logic
      );
    } else {
      // If no animationController, build dropdown normally
      return buildDropdown(context);
    }
  }

  Widget buildDropdown(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 0, 0, 0),
            child: Text(
              label,
              style: TextStyle(
                color: isError ? Colors.red : Colors.white,
                fontSize: 14,
              ),
            ),
          ),
          SizedBox(height: 8), // Spacing between label and dropdown
          Container(
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: DropdownButton<String>(
              value: value,
              onChanged: onChanged,
              items: items.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                );
              }).toList(),
              isExpanded: true,
              dropdownColor: Colors.blueGrey[700],
              underline: SizedBox(),
              hint: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              icon: const Icon(
                Icons.arrow_drop_down,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
