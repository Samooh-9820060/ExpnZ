import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expnz/widgets/SimpleWidgets/ExpnZTextField.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../database/AccountsDB.dart';
import '../database/TempTransactionsDB.dart';
import '../database/TransactionsDB.dart';
import '../utils/global.dart';
import '../widgets/AppWidgets/BuildCategoriesDropdown.dart';
import '../widgets/AppWidgets/CategoryChip.dart';
import '../widgets/AppWidgets/SelectAccountCard.dart';
import '../widgets/SimpleWidgets/ExpnZButton.dart';
import '../widgets/SimpleWidgets/ModernSnackBar.dart';

enum TransactionType { income, expense, transfer }

class AddTransactionScreen extends StatefulWidget {
  final Map<String, dynamic>? transaction; // Nullable named parameter
  final int? tempTransactionId; // New nullable named parameter

  // Constructor with named parameters
  AddTransactionScreen({this.transaction, this.tempTransactionId});

  @override
  _AddTransactionScreenState createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> with WidgetsBindingObserver{

  int selectedFromAccountIndex = -1;
  int selectedToAccountIndex = -1;
  int selectedAccoutIndex = -1;
  String selectedFromAccountId = "-1";
  String selectedToAccountId = "-1";
  String selectedAccoutId = "-1";

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  final TextEditingController _categorySearchController = TextEditingController();
  bool _showDropdown = false;
  bool isProcessing = false;
  bool updateMode = false;
  bool tempAdding = false;

  List<Map<String, dynamic>> filteredCategories = [];
  List<Map<String, dynamic>> selectedCategoriesList = [];
  OverlayEntry? overlayEntry;

  TransactionType _selectedType = TransactionType.income; // Default to income

  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  FocusNode _categorySearchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _amountController = TextEditingController();
    if (widget.transaction != null) { updateMode = true; loadTransactionData(); }
    if (widget.tempTransactionId != null) { tempAdding = true; loadTempTransactionData(); }
  }

  Future<void> loadTempTransactionData() async {
    final tempTransactionData = await TempTransactionsDB().getSelectedTransaction(widget.tempTransactionId!);
    if (tempTransactionData != null) {
      setState(() {
        if (tempTransactionData[TempTransactionsDB.columnType] == 'expense') {
          _selectedType = TransactionType.expense;
        } else if (tempTransactionData[TempTransactionsDB.columnType] == 'income') {
          _selectedType = TransactionType.income;
        }
        _nameController.text = tempTransactionData[TempTransactionsDB.columnName] ?? '';
        _descriptionController.text = tempTransactionData[TempTransactionsDB.columnDescription] ?? '';
        _amountController.text = tempTransactionData[TempTransactionsDB.columnAmount].toString() ?? '';
        if (tempTransactionData[TempTransactionsDB.columnDate] != null && tempTransactionData[TempTransactionsDB.columnTime] != null) {
          final String date = tempTransactionData[TempTransactionsDB.columnDate];
          final String time = tempTransactionData[TempTransactionsDB.columnTime];
          DateTime completeDateTime = DateTime.parse("$date $time");
          selectedDate = DateTime.parse(tempTransactionData[TempTransactionsDB.columnDate]);
          selectedTime = TimeOfDay.fromDateTime(completeDateTime);
        }
      });
    }
  }

  void loadTransactionData() {
    final transactionsData = transactionsNotifier.value;

    // Extract the transaction data using the widget's transaction ID
    final String transactionId = widget.transaction?['documentName'];
    final transaction = transactionsData?[transactionId];

    if (transaction != null) {
      final String name = transaction[TransactionsDB.transactionName] ?? 'Unknown';
      final String description = transaction[TransactionsDB.transactionDescription] ?? 'Unknown';
      final String accountId = transaction[TransactionsDB.transactionAccountId];
      final String date = transaction[TransactionsDB.transactionDate];
      final String time = transaction[TransactionsDB.transactionTime] ?? 'Unknown';
      final double amount = transaction[TransactionsDB.transactionAmount] ?? 0.0;
      final String type = transaction[TransactionsDB.transactionType] ?? 'Unknown';

      if (type == 'expense') {
        _selectedType = TransactionType.expense;
      } else if (type == 'income') {
        _selectedType = TransactionType.income;
      }

      _nameController.text = name;
      _descriptionController.text = description;
      _amountController.text = amount.toString();

      // Combine date and time...
      if (date != null && time != null) {
        DateTime completeDateTime = DateTime.parse("$date $time");
        selectedDate = DateTime.parse(date);
        selectedTime = TimeOfDay.fromDateTime(completeDateTime);
      }

      // Fetch account index using accountData
      final accountData = accountsNotifier.value;
      if (accountId != null && accountData != null) {
        selectedAccoutIndex = accountData.entries
            .toList()
            .indexWhere((entry) => entry.key == accountId.toString());
        if (selectedAccoutIndex != -1) {
          selectedAccoutId = accountId;
        }
      }
      // Processing categories...
      final String? categoriesString = transaction[TransactionsDB.transactionCategoryIDs] ?? '';
      if (categoriesString != null) {
        final List<int> categoryIds = categoriesString
            .split(',')
            .map((e) => int.tryParse(e.trim()) ?? 0)
            .toList();

        selectedCategoriesList.clear();
        for (int categoryId in categoryIds) {
          selectedCategoriesList.add({
            'id': categoryId,
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  //modify or insert transactions
  void _addUpdateTransaction({bool isUpdate = false, Map<String, dynamic>? existingTransaction}) async {
    if (isProcessing) {
      await showModernSnackBar(
        context: context,
        message: "Please wait. Another transaction is processing",
        backgroundColor: Colors.redAccent,
      );
      return;
    }
    setState(() {
      isProcessing = true;
    });

    if (updateMode) {
      isUpdate = updateMode;
      existingTransaction = widget.transaction;
    }

    // Check if the selected categories list contains "Unassigned"
    bool hasUnassignedCategory = selectedCategoriesList.any((category) => category['id'] == '0');

    if (hasUnassignedCategory) {
      await showModernSnackBar(
        context: context,
        message: "Please remove the 'Unassigned' category",
        backgroundColor: Colors.redAccent,
      );
      setState(() {
        isProcessing = false;
      });
      return;
    }

    // Validate input fields
    String name = _nameController.text.trim();
    String description = _descriptionController.text.trim();
    String amountStr = _amountController.text.trim();
    double? amount = double.tryParse(amountStr);

    if (name.isEmpty || description.isEmpty || amount == null || amount <= 0) {
      await showModernSnackBar(
        context: context,
        message: "All fields must be filled and valid!",
        backgroundColor: Colors.red,
      );
      setState(() {
        isProcessing = false;
      });
      return;
    }

    //validate category selection
    if (selectedCategoriesList.isEmpty) {
      await showModernSnackBar(
        context: context,
        message: "Please select at least one category",
        backgroundColor: Colors.red,
      );
      setState(() {
        isProcessing = false;
      });
      return;
    }

    // Prepare Firestore reference
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference transactions = firestore.collection('transactions');

    if (_selectedType == TransactionType.transfer) {
      // Validate account selection
      if (selectedFromAccountIndex < 0 || selectedToAccountIndex < 0) {
        await showModernSnackBar(
          context: context,
          message: "Please select the from and to accounts",
          backgroundColor: Colors.red,
        );
        setState(() {
          isProcessing = false;
        });
        return;
      }

      if (selectedFromAccountIndex == selectedToAccountIndex) {
        await showModernSnackBar(
          context: context,
          message: "Please select different cards to transfer between.",
          backgroundColor: Colors.red,
        );
        setState(() {
          isProcessing = false;
        });
        return;
      }

      String categoryIds = selectedCategoriesList.map((category) {
        return category['id'].toString();
      }).join(', ');

      // Prepare data for "withdrawal" from the source account
      Map<String, dynamic> rowFrom = {
        TransactionsDB.transactionType: "expense",
        TransactionsDB.transactionName: name,
        TransactionsDB.transactionDescription: description,
        TransactionsDB.transactionAmount: amount,
        TransactionsDB.transactionDate: DateFormat('yyyy-MM-dd').format(selectedDate),
        TransactionsDB.transactionTime: selectedTime.format(context),
        TransactionsDB.transactionAccountId: selectedFromAccountId,
        TransactionsDB.transactionCategoryIDs: categoryIds,
      };

      // Prepare data for "deposit" into the destination account
      Map<String, dynamic> rowTo = {
        TransactionsDB.transactionType: "income",
        TransactionsDB.transactionName: name,
        TransactionsDB.transactionDescription: description,
        TransactionsDB.transactionAmount: amount,
        TransactionsDB.transactionDate: DateFormat('yyyy-MM-dd').format(selectedDate),
        TransactionsDB.transactionTime: selectedTime.format(context),
        TransactionsDB.transactionAccountId: selectedToAccountId,
        TransactionsDB.transactionCategoryIDs: categoryIds,
      };

      bool successFrom = false, successTo = false;

      if (isUpdate && existingTransaction != null) {
        // Update the existing transactions (you need to manage IDs for both 'from' and 'to' transactions)
        final idFrom = await TransactionsDB().updateTransaction(existingTransaction['from_id'], rowFrom);
        final idTo = await TransactionsDB().updateTransaction(existingTransaction['to_id'], rowTo);

        successFrom = idFrom;
        successTo = idTo;
      } else {
        // Insert new transactions
        final idFrom = await TransactionsDB().insertTransaction(rowFrom);
        final idTo = await TransactionsDB().insertTransaction(rowTo);

        successFrom = idFrom;
        successTo = idTo;
      }

      if (successFrom && successTo) {
        // Both transactions were successful
        await showModernSnackBar(
          context: context,
          message: isUpdate ? "Transfer transaction updated successfully!" : "Transfer transaction added successfully!",
          backgroundColor: Colors.green,
        );
        setState(() {
          isProcessing = false;
        });
        Navigator.pop(context, true);
      } else {
        // Handle failure
        await showModernSnackBar(
          context: context,
          message: isUpdate ? "Transfer transaction was not updated" : "Transfer transaction was not added",
          backgroundColor: Colors.redAccent,
        );
        setState(() {
          isProcessing = false;
        });
      }

      setState(() {
        isProcessing = false;
      });
      return;
    }
    else {
      // Validate account selection
      if (selectedAccoutIndex < 0) {
        await showModernSnackBar(
          context: context,
          message: "Please select the related account",
          backgroundColor: Colors.redAccent,
        );
        setState(() {
          isProcessing = false;
        });
        return;
      }

      String categoryIds = selectedCategoriesList.map((category) {
        return category['id'].toString();
      }).join(', ');

      // Prepare the transaction data
      Map<String, dynamic> row = {
        TransactionsDB.transactionType: _selectedType.toString().split('.').last,  // income, expense or transfer
        TransactionsDB.transactionName: name,
        TransactionsDB.transactionDescription: description,
        TransactionsDB.transactionAmount: amount,
        TransactionsDB.transactionDate: DateFormat('yyyy-MM-dd').format(selectedDate),
        TransactionsDB.transactionTime: selectedTime.format(context),  // You might want to store this differently
        TransactionsDB.transactionAccountId: selectedAccoutId,
        TransactionsDB.transactionCategoryIDs: categoryIds,
      };

      bool success = false;

      if (isUpdate && existingTransaction != null) {
        // Update the existing transaction
        final id = await TransactionsDB().updateTransaction(existingTransaction['_id'], row);
        success = id;
      } else {
        // Insert a new transaction
        final id = await TransactionsDB().insertTransaction(row);
        success = id;
      }

      if (success) {
        await showModernSnackBar(
          context: context,
          message: isUpdate ? "Transaction updated successfully!" : "Transaction added successfully!",
          backgroundColor: Colors.green,
        );
        setState(() {
          isProcessing = false;
        });
        Navigator.pop(context, true);
      } else {
        await showModernSnackBar(
          context: context,
          message: isUpdate ? "Transaction was not updated" : "Transaction was not added",
          backgroundColor: Colors.redAccent,
        );
        setState(() {
          isProcessing = false;
        });
      }
    }
  }


  Widget buildTypeButton(TransactionType type, String label) {
    bool isSelected = _selectedType == type;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),  // Add this line
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          onTap: () {
            setState(() {
              _selectedType = type;
            });
          },
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: isSelected ? Colors.blueAccent : Colors.transparent,
              ),
              gradient: LinearGradient(
                colors: [
                  isSelected ? Colors.blueGrey[800]! : Colors.blueGrey[700]!,
                  isSelected ? Colors.blueGrey[700]! : Colors.blueGrey[800]!,
                ],
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.blueAccent : Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  // Method to select Date
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != selectedDate)
      setState(() {
        selectedDate = pickedDate;
      });
  }
// Method to select Time
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (pickedTime != null && pickedTime != selectedTime)
      setState(() {
        selectedTime = pickedTime;
      });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, false);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.blueGrey[900],
        appBar: AppBar(
          elevation: 0,
          leading: BackButton(
            color: Colors.white,
            onPressed: () {
              Navigator.pop(context, false);
            },
          ),
          title: Text(
              updateMode ? "Update Transaction" : "Add Transaction",
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.blueGrey[900],
        ),
        body: GestureDetector(
          onTap: () {
            setState(() {
              _showDropdown = false;
            });
          },
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Transaction Type selector
                    Row(
                      children: [
                        buildTypeButton(TransactionType.income, 'Income'),
                        SizedBox(width: 16),
                        buildTypeButton(TransactionType.expense, 'Expense'),
                        if (!updateMode)
                          SizedBox(width: 16),
                        if (!updateMode)
                          buildTypeButton(TransactionType.transfer, 'Transfer'),
                      ],
                    ),

                    // Fields for Income and Expense
                    if (_selectedType == TransactionType.income || _selectedType == TransactionType.expense)
                      ...[
                        SizedBox(height: 16),
                        // Name
                        CustomTextField(label: "Name", controller: _nameController),
                        SizedBox(height: 16),
                        // Description
                        CustomTextField(label: "Description", controller: _descriptionController),
                        SizedBox(height: 16),
                        // Amount
                        CustomTextField(label: "Amount", controller: _amountController, isNumber: true,),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Date Button
                            InkWell(
                              onTap: () => _selectDate(context),
                              borderRadius: BorderRadius.circular(50),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.blueGrey[700],
                                  borderRadius: BorderRadius.circular(50),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 10,
                                      offset: Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text(
                                      DateFormat('yyyy-MM-dd').format(selectedDate),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Time Button
                            InkWell(
                              onTap: () => _selectTime(context),
                              borderRadius: BorderRadius.circular(50),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.blueGrey[700],
                                  borderRadius: BorderRadius.circular(50),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 10,
                                      offset: Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.access_time, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text(
                                      "${selectedTime.format(context)}",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Account',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10),
                            Container(
                              height: 150, // set the height
                              child: ValueListenableBuilder<Map<String, Map<String, dynamic>>?>(
                                valueListenable: accountsNotifier,
                                builder: (context, accountsData, child) {
                                  if (accountsData == null || accountsData.isEmpty) {
                                    return Center(
                                      child: Text('No accounts available.'),
                                    );
                                  } else {
                                    List<String> accountIds = accountsData.keys.toList();

                                    return ListView.builder(
                                      padding: EdgeInsets.zero,
                                      scrollDirection: Axis.horizontal,
                                      itemCount: accountIds.length,
                                      itemBuilder: (context, index) {
                                        final String accountId = accountIds[index];
                                        final account = accountsData[accountId]!;
                                        Map<String, dynamic> currencyMap = jsonDecode(account[AccountsDB.accountCurrency]);
                                        String currencyCode = currencyMap['code'] as String;

                                        return GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              selectedAccoutIndex = index;
                                              selectedAccoutId = accountId;
                                            });
                                          },
                                          child: AccountCard(
                                            accountId: accountId,
                                            icon: IconData(
                                              account[AccountsDB.accountIconCodePoint],
                                              fontFamily: account[AccountsDB.accountIconFontFamily],
                                              fontPackage: account[AccountsDB.accountIconFontPackage],
                                            ),
                                            currency: currencyCode,
                                            accountName: account[AccountsDB.accountName],
                                            isSelected: index == selectedAccoutIndex,
                                          ),
                                        );
                                      },
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        // Category Selector
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Select Category',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 10),
                                TextField(
                                  focusNode: _categorySearchFocusNode,
                                  controller: _categorySearchController,
                                  decoration: InputDecoration(
                                    hintText: 'Search Category',
                                    fillColor: Colors.blueGrey[700],
                                    filled: true,
                                    prefixIcon: Icon(Icons.search),
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide.none,  // Removes the underline border
                                      borderRadius: BorderRadius.circular(50.0),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.blue, width: 1),
                                      borderRadius: BorderRadius.circular(50.0),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _showDropdown = value.isNotEmpty;
                                    });
                                  },
                                ),
                                SizedBox(height: 10),
                                if (_showDropdown)
                                  GestureDetector(
                                    onTap: () {
                                      // Do nothing to stop event propagation
                                      return;
                                    },
                                    child: Material(
                                      elevation: 4.0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      color: Colors.blueGrey[700],
                                      child: Container(
                                        width: MediaQuery.of(context).size.width, // Adjust as needed
                                        child: ValueListenableBuilder<Map<String, Map<String, dynamic>>?>(
                                          valueListenable: categoriesNotifier,
                                          builder: (context, categoriesData, child) {
                                            if (categoriesData != null && categoriesData.isNotEmpty) {
                                              List<Map<String, dynamic>> categoriesList = categoriesData.entries.map((entry) {
                                                return {
                                                  'id': entry.key,
                                                  ...entry.value as Map<String, dynamic>,
                                                };
                                              }).toList();

                                              return buildCategoriesDropdown(
                                                  selectedCategoriesList,
                                                  _categorySearchController,
                                                  setState, // Pass setState directly without invoking it
                                                _showDropdown,
                                              );
                                            } else {
                                              return const Center(child: Text('No categories available.'));
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                SizedBox(height: 10),
                                Wrap(
                                  spacing: 8.0,
                                  runSpacing: 8.0,
                                  children: List<Widget>.generate(
                                    selectedCategoriesList.length,
                                        (int index) {
                                      final category = selectedCategoriesList[index];
                                      dynamic categoryIdRaw = category['id'];
                                      String categoryId = "";

                                      if (categoryIdRaw is String) {
                                        categoryId = categoryIdRaw;
                                      } else {
                                        // Handle error: unknown type
                                        print('Unknown type for category ID');
                                      }

                                      return CategoryChip(
                                        categoryId: categoryId,
                                        onTap: () {
                                          setState(() {
                                            selectedCategoriesList.removeAt(index);
                                          });
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        ExpnZButton(
                          label: updateMode ? "Update" : "Add",
                          onPressed: _addUpdateTransaction,
                          primaryColor: Colors.blueAccent,  // Optional
                          textColor: Colors.white,  // Optional
                          fontSize: 18.0,  // Optional
                        ),
                      ],
                    // Fields for Transfer
                    if (_selectedType == TransactionType.transfer)
                      ...[
                        SizedBox(height: 16),
                        // Name
                        CustomTextField(label: "Name", controller: _nameController),
                        SizedBox(height: 16),
                        // Description
                        CustomTextField(label: "Description", controller: _descriptionController),
                        SizedBox(height: 16),
                        // Amount
                        CustomTextField(label: "Amount", controller: _amountController, isNumber: true,),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Date Button
                            InkWell(
                              onTap: () => _selectDate(context),
                              borderRadius: BorderRadius.circular(50),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.blueGrey[700],
                                  borderRadius: BorderRadius.circular(50),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 10,
                                      offset: Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text(
                                      DateFormat('yyyy-MM-dd').format(selectedDate),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Time Button
                            InkWell(
                              onTap: () => _selectTime(context),
                              borderRadius: BorderRadius.circular(50),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.blueGrey[700],
                                  borderRadius: BorderRadius.circular(50),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 10,
                                      offset: Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.access_time, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text(
                                      "${selectedTime.format(context)}",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          ],
                        ),
                        SizedBox(height: 20),
                        // From Account
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'From Account',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10),
                            Container(
                              height: 150, // set the height
                              child: ValueListenableBuilder<Map<String, Map<String, dynamic>>?>(
                                valueListenable: accountsNotifier,
                                builder: (context, accountsData, child) {
                                  if (accountsData == null || accountsData.isEmpty) {
                                    return Center(
                                      child: Text('No accounts available.'),
                                    );
                                  } else {
                                    List<String> accountIds = accountsData.keys.toList();

                                    return ListView.builder(
                                      padding: EdgeInsets.zero,
                                      scrollDirection: Axis.horizontal,
                                      itemCount: accountIds.length,
                                      itemBuilder: (context, index) {
                                        final String accountId = accountIds[index];
                                        final account = accountsData[accountId]!;
                                        Map<String, dynamic> currencyMap = jsonDecode(account[AccountsDB.accountCurrency]);
                                        String currencyCode = currencyMap['code'] as String;

                                        return GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              selectedFromAccountIndex = index;
                                              selectedFromAccountId = accountId;
                                            });
                                          },
                                          child: AccountCard(
                                            accountId: accountId,
                                            icon: IconData(
                                              account[AccountsDB.accountIconCodePoint],
                                              fontFamily: account[AccountsDB.accountIconFontFamily],
                                              fontPackage: account[AccountsDB.accountIconFontPackage],
                                            ),
                                            currency: currencyCode,
                                            accountName: account[AccountsDB.accountName],
                                            isSelected: index == selectedFromAccountIndex,
                                          ),
                                        );
                                      },
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        // To Account
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'To Account',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10),
                            Container(
                              height: 150, // set the height
                              child: ValueListenableBuilder<Map<String, Map<String, dynamic>>?>(
                                valueListenable: accountsNotifier,
                                builder: (context, accountsData, child) {
                                  if (accountsData == null || accountsData.isEmpty) {
                                    return Center(
                                      child: Text('No accounts available.'),
                                    );
                                  } else {
                                    List<String> accountIds = accountsData.keys.toList();

                                    return ListView.builder(
                                      padding: EdgeInsets.zero,
                                      scrollDirection: Axis.horizontal,
                                      itemCount: accountIds.length,
                                      itemBuilder: (context, index) {
                                        final String accountId = accountIds[index];
                                        final account = accountsData[accountId]!;
                                        Map<String, dynamic> currencyMap = jsonDecode(account[AccountsDB.accountCurrency]);
                                        String currencyCode = currencyMap['code'] as String;

                                        return GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              selectedToAccountIndex = index;
                                              selectedToAccountId = accountId;
                                            });
                                          },
                                          child: AccountCard(
                                            accountId: accountId,
                                            icon: IconData(
                                              account[AccountsDB.accountIconCodePoint],
                                              fontFamily: account[AccountsDB.accountIconFontFamily],
                                              fontPackage: account[AccountsDB.accountIconFontPackage],
                                            ),
                                            currency: currencyCode,
                                            accountName: account[AccountsDB.accountName],
                                            isSelected: index == selectedToAccountIndex,
                                          ),
                                        );
                                      },
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        // Category Selector
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Select Category',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 10),
                                TextField(
                                  focusNode: _categorySearchFocusNode,
                                  controller: _categorySearchController,
                                  decoration: InputDecoration(
                                    hintText: 'Search Category',
                                    fillColor: Colors.blueGrey[700],
                                    filled: true,
                                    prefixIcon: Icon(Icons.search),
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide.none,  // Removes the underline border
                                      borderRadius: BorderRadius.circular(50.0),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.blue, width: 1),
                                      borderRadius: BorderRadius.circular(50.0),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _showDropdown = value.isNotEmpty;
                                    });
                                  },
                                ),
                                SizedBox(height: 10),
                                if (_showDropdown)
                                  GestureDetector(
                                    onTap: () {
                                      // Do nothing to stop event propagation
                                      return;
                                    },
                                    child: Material(
                                      elevation: 4.0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      color: Colors.blueGrey[700],
                                      child: Container(
                                        width: MediaQuery.of(context).size.width, // Adjust as needed
                                        child: ValueListenableBuilder<Map<String, dynamic>?>(
                                          valueListenable: categoriesNotifier,
                                          builder: (context, categoriesData, child) {
                                            if (categoriesData != null && categoriesData.isNotEmpty) {
                                              List<Map<String, dynamic>> categoriesList = categoriesData.entries.map((entry) {
                                                // Cast the entry key to String and the value to Map<String, dynamic>
                                                return {
                                                  'id': entry.key, // Cast the key to a String
                                                  ...entry.value as Map<String, dynamic>, // Cast the value to Map<String, dynamic>
                                                };
                                              }).toList();

                                              return buildCategoriesDropdown(
                                                  selectedCategoriesList,
                                                  _categorySearchController,
                                                setState,// Pass setState directly without invoking it
                                                _showDropdown
                                              );
                                            } else {
                                              return const Center(child: Text('No categories available.'));
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                SizedBox(height: 10),
                                Wrap(
                                  spacing: 8.0,
                                  runSpacing: 8.0,
                                  children: List<Widget>.generate(
                                    selectedCategoriesList.length,
                                        (int index) {
                                      final category = selectedCategoriesList[index];
                                      dynamic categoryIdRaw = category['id']; // assuming category['id'] could be int or String
                                      String categoryId = "";

                                      if (categoryIdRaw is String) {
                                        categoryId = categoryIdRaw;
                                      } else {
                                        // Handle error: unknown type
                                        print('Unknown type for category ID');
                                      }

                                      return CategoryChip(
                                        categoryId: categoryId,
                                        onTap: () {
                                          setState(() {
                                            selectedCategoriesList.removeAt(index);
                                          });
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        ExpnZButton(
                          label: updateMode ? "Update" : "Add",
                          onPressed: _addUpdateTransaction,
                          primaryColor: Colors.blueAccent,  // Optional
                          textColor: Colors.white,  // Optional
                          fontSize: 18.0,  // Optional
                        ),
                      ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

