import 'dart:convert';

import 'package:currency_picker/currency_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import '../database/AccountsDB.dart';
import '../widgets/SimpleWidgets/ExpnZButton.dart';
import '../widgets/SimpleWidgets/ExpnZTextField.dart';
import '../widgets/SimpleWidgets/ModernSnackBar.dart';

class AddAccountScreen extends StatefulWidget {
  final String? documentId;

  AddAccountScreen({
    this.documentId,
  });

  @override
  _AddAccountScreenState createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  late TextEditingController _accountNameController;
  late TextEditingController _cardNumberController;
  Currency? selectedCurrency;  // Default currency
  IconData selectedIcon = Icons.star;  // Default icon
  bool isModifyMode = false;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    _accountNameController = TextEditingController();
    _cardNumberController = TextEditingController();
    //selectedCurrency = Currency(code: 'USD', name: 'United States Dollar', symbol: '\$');

    if (widget.documentId != null){
      _loadExistingAccount(widget.documentId!);
      isModifyMode = true;
    } else {
      selectedIcon = Icons.star;
    }
  }

  void _loadExistingAccount(String id) async {
    final account = await AccountsDB().getSelectedAccount(id);

    if (account != null) {
      setState(() {
        isModifyMode = true;
        _accountNameController.text = account[AccountsDB.accountName] as String;
        _cardNumberController.text = account[AccountsDB.accountCardNumber] as String;
        String currencyJson = account[AccountsDB.accountCurrency] as String;
        Map<String, dynamic> currencyMap = jsonDecode(currencyJson);
        selectedCurrency = Currency(
          code: currencyMap['code'] as String,
          name: currencyMap['name'] as String,
          symbol: currencyMap['symbol'] as String,
          flag: currencyMap['flag'] as String,
          decimalDigits: currencyMap['decimalDigits'] as int,
          decimalSeparator: currencyMap['decimalSeparator'] as String,
          namePlural: currencyMap['namePlural'] as String,
          number: currencyMap['number'] as int,
          spaceBetweenAmountAndSymbol: currencyMap['spaceBetweenAmountAndSymbol'] as bool,
          symbolOnLeft: currencyMap['symbolOnLeft'] as bool,
          thousandsSeparator: currencyMap['thousandsSeparator'] as String,
        );
        selectedIcon = IconData(
            account[AccountsDB.accountIconCodePoint],
            fontFamily: account[AccountsDB.accountIconFontFamily],
            fontPackage: account[AccountsDB.accountIconFontPackage],
        );
      });
    } else {
      setState(() {
        selectedIcon = Icons.star;
      });
    }
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

  void _addOrUpdateAccount() async {
    if (isProcessing) return;
    setState(() {
      isProcessing = true;
    });

    if (_accountNameController.text.trim().isEmpty ||
        (selectedCurrency == null)) {
      await showModernSnackBar(
        context: context,
        message: "Account name and currency needs to be selected!",
        backgroundColor: Colors.red,
      );
      setState(() {
        isProcessing = false;
      });
      return;
    }

    Map<String, dynamic> row = {
      AccountsDB.accountName: _accountNameController.text.trim(),
      AccountsDB.accountCurrency: jsonEncode({
        'code': selectedCurrency!.code,
        'name': selectedCurrency!.name,
        'symbol': selectedCurrency!.symbol,
        'flag': selectedCurrency!.flag,
        'decimalDigits': selectedCurrency!.decimalDigits,
        'decimalSeparator': selectedCurrency!.decimalSeparator,
        'namePlural': selectedCurrency!.namePlural,
        'number': selectedCurrency!.number,
        'spaceBetweenAmountAndSymbol': selectedCurrency!.spaceBetweenAmountAndSymbol,
        'symbolOnLeft': selectedCurrency!.symbolOnLeft,
        'thousandsSeparator': selectedCurrency!.thousandsSeparator,
      }),
      AccountsDB.accountIconCodePoint: selectedIcon.codePoint,
      AccountsDB.accountIconFontFamily: selectedIcon.fontFamily,
      AccountsDB.accountIconFontPackage: selectedIcon.fontPackage,
      AccountsDB.accountCardNumber: _cardNumberController.text.trim(),
    };

    bool? insertedAccount;

    // Check if modifying an existing account
    if (isModifyMode) {
      // Update the account in Firestore
      try {
        await AccountsDB().updateAccount(widget.documentId!, row);
        insertedAccount = true;
      } catch(ex) {
        insertedAccount = false;
      }

    } else {
      // Insert a new account into Firestore
      insertedAccount = await AccountsDB().insertAccount(row);

    }

    // Check if operation was successful
    if (insertedAccount) {
      // Success handling
      await showModernSnackBar(
        context: context,
        message: isModifyMode ? "Account updated successfully!" : "Account added successfully!",
        backgroundColor: Colors.green,
      );
      setState(() {
        isProcessing = false;
      });
      Navigator.pop(context, true);
    } else {
      // Failure handling
      await showModernSnackBar(
        context: context,
        message: isModifyMode ? "Account was not updated" : "Account was not added",
        backgroundColor: Colors.redAccent,
      );
      setState(() {
        isProcessing = false;
      });
    }
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
          IconPack.fontAwesomeIcons,
        ],
    );
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
        title:
        Text(
            isModifyMode ? "Modify Account" : "Add Account",
            style: TextStyle(color: Colors.white)
        ),
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
            ExpnZButton(
              label: isProcessing ? "Processing..." : (isModifyMode ? "Modify" : "Add"),
              onPressed: isProcessing ? null : (_addOrUpdateAccount),
            ),
          ],
        ),
      ),
    );
  }
}
