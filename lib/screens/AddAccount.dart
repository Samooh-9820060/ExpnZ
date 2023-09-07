import 'package:currency_picker/currency_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';

import '../widgets/SimpleWidgets/ExpnZButton.dart';
import '../widgets/SimpleWidgets/ExpnZTextField.dart';

class AddAccountScreen extends StatefulWidget {
  @override
  _AddAccountScreenState createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  late TextEditingController _accountNameController;
  late TextEditingController _cardNumberController;
  Currency? selectedCurrency;  // Default currency
  IconData selectedIcon = Icons.star;  // Default icon

  @override
  void initState() {
    super.initState();
    _accountNameController = TextEditingController();
    _cardNumberController = TextEditingController();
    //selectedCurrency = Currency(code: 'USD', name: 'United States Dollar', symbol: '\$');

  }

  void _pickCurrency() {
    showCurrencyPicker(
      context: context,
      showFlag: true,
      showSearchField: true,
      showCurrencyName: true,
      showCurrencyCode: true,
      //favorite: ['USD', 'EUR', 'GBP'],
      onSelect: (Currency currency) {
        setState(() {
          selectedCurrency = currency;
        });
      },
    );
  }


  @override
  void dispose() {
    _accountNameController.dispose();
    _cardNumberController.dispose();
    super.dispose();
  }


  void _pickIcon() async {
    IconData? icon = await FlutterIconPicker.showIconPicker(context,
        iconPackModes: [
          IconPack.material,
          IconPack.cupertino,
          IconPack.fontAwesomeIcons
        ]);
    if (icon != null) {
      setState(() {
        selectedIcon = icon;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        elevation: 0,
        leading: BackButton(
          color: Colors.white,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text("Add Account", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueGrey[900],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Redesigned Button for Color Picker
            // Add your new ElevatedButton
            ElevatedButton(
              onPressed: _pickIcon,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(
                    selectedIcon,
                    color: Colors.white,
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Select Icon"),
                      Text(
                        "Tap to choose icon",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey[700],
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                textStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50.0),
                ),
              ),
            ),
            SizedBox(height: 16),
            // Redesigned Text Field for Account Name
            CustomTextField(label: "Enter Account Name", controller: _accountNameController),
            SizedBox(height: 16),
            // Button for Currency Selection
            ElevatedButton(
              onPressed: _pickCurrency,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedCurrency == null ? "Select Currency" : "${selectedCurrency!.name} (${selectedCurrency!.code})",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  Icon(Icons.arrow_drop_down, color: Colors.white),
                ],
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey[700],
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                textStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50.0),
                ),
              ),
            ),
            SizedBox(height: 16),
            CustomTextField(label: "Enter Card Number (Last 4 Digits, Optional)", controller: _cardNumberController, isNumber: true, maxLength: 4),
            SizedBox(height: 32),
            // Redesigned Add Button
            ExpnZButton(label: "Add", onPressed: (){

            })
          ],
        ),
      ),
    );
  }
}
