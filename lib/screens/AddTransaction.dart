import 'dart:convert';
import 'package:expnz/models/AccountsModel.dart';
import 'package:expnz/widgets/SimpleWidgets/ExpnZTextField.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../database/AccountsDB.dart';
import '../database/CategoriesDB.dart';
import '../database/TransactionsDB.dart';
import '../models/CategoriesModel.dart';
import '../models/TransactionsModel.dart';
import '../widgets/AppWidgets/CategoryChip.dart';
import '../widgets/AppWidgets/SelectAccountCard.dart';
import '../widgets/SimpleWidgets/ExpnZButton.dart';
import '../widgets/SimpleWidgets/ModernSnackBar.dart';

enum TransactionType { income, expense, transfer }

class AddTransactionScreen extends StatefulWidget {

  Map<String, dynamic>? transaction;

  AddTransactionScreen({this.transaction});

  @override
  _AddTransactionScreenState createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> with WidgetsBindingObserver{

  int selectedFromAccountIndex = -1;
  int selectedToAccountIndex = -1;
  int selectedAccoutIndex = -1;
  int selectedFromAccountId = -1;
  int selectedToAccountId = -1;
  int selectedAccoutId = -1;

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  final TextEditingController _categorySearchController = TextEditingController();
  bool _showDropdown = false;
  bool isProcessing = false;
  bool updateMode = false;

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
    Provider.of<AccountsModel>(context, listen: false).fetchAccounts();
    Provider.of<CategoriesModel>(context, listen: false).fetchCategories();
    if (widget.transaction != null) { updateMode = true; loadTransactionData(); }
  }

  void loadTransactionData() {
    final String name = widget.transaction?['name'] ?? 'Unknown';
    final String description = widget.transaction?['description'] ?? 'Unknown';
    final int accountId = widget.transaction?['account_id'];
    final String date = widget.transaction?['date'];
    final String time = widget.transaction?['time'] ?? 'Unknown';
    final double amount = widget.transaction?['amount'] ?? 0.0;
    final String type = widget.transaction?['type'] ?? 'Unknown';
    final List<dynamic> categories = jsonDecode(widget.transaction?['categories'] ?? '[]');

    if (type == 'expense') {
      _selectedType = TransactionType.expense;
    } else if (type == 'income') {
      _selectedType = TransactionType.income;
    }
    _nameController.text = name;
    _descriptionController.text = description;
    _amountController.text = amount.toString();
    if (date != null && time != null) {
      // Combine the date and time into a single DateTime object
      DateTime completeDateTime = DateTime.parse("$date $time");
      selectedDate = DateTime.parse(date);
      // Extract the time from the complete DateTime object
      selectedTime = TimeOfDay.fromDateTime(completeDateTime);
    }

    final accountsModel = Provider.of<AccountsModel>(context, listen: false);
    if (accountId != null) {
      selectedAccoutIndex = accountsModel.accounts.indexWhere((account) => account[AccountsDB.accountId] == accountId);
      if (selectedAccoutIndex != -1) {
        selectedAccoutId = accountId;
      }
    }
    final String? categoriesJson = widget.transaction?['categories'];
    if (categoriesJson != null) {
      selectedCategoriesList = List<Map<String, dynamic>>.from(jsonDecode(categoriesJson));
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
    if (isProcessing) return;
    setState(() {
      isProcessing = true;
    });

    if (updateMode) {
      isUpdate = updateMode;
      existingTransaction = widget.transaction;
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

      // Prepare data for "withdrawal" from the source account
      Map<String, dynamic> rowFrom = {
        TransactionsDB.columnType: "expense",
        TransactionsDB.columnName: name,
        TransactionsDB.columnDescription: description,
        TransactionsDB.columnAmount: amount,
        TransactionsDB.columnDate: DateFormat('yyyy-MM-dd').format(selectedDate),
        TransactionsDB.columnTime: selectedTime.format(context),
        TransactionsDB.columnAccountId: selectedFromAccountId,
        TransactionsDB.columnCategories: jsonEncode(selectedCategoriesList),
      };

      // Prepare data for "deposit" into the destination account
      Map<String, dynamic> rowTo = {
        TransactionsDB.columnType: "income",
        TransactionsDB.columnName: name,
        TransactionsDB.columnDescription: description,
        TransactionsDB.columnAmount: amount,
        TransactionsDB.columnDate: DateFormat('yyyy-MM-dd').format(selectedDate),
        TransactionsDB.columnTime: selectedTime.format(context),
        TransactionsDB.columnAccountId: selectedToAccountId,
        TransactionsDB.columnCategories: jsonEncode(selectedCategoriesList),
      };

      final transactionsModel = Provider.of<TransactionsModel>(context, listen: false);
      bool successFrom = false, successTo = false;

      if (isUpdate && existingTransaction != null) {
        // Update the existing transactions (you need to manage IDs for both 'from' and 'to' transactions)
        final idFrom = await TransactionsDB().updateTransaction(existingTransaction['from_id'], rowFrom);
        final idTo = await TransactionsDB().updateTransaction(existingTransaction['to_id'], rowTo);

        successFrom = idFrom != null && idFrom > 0;
        successTo = idTo != null && idTo > 0;
      } else {
        // Insert new transactions
        final idFrom = await TransactionsDB().insertTransaction(rowFrom);
        final idTo = await TransactionsDB().insertTransaction(rowTo);

        successFrom = idFrom != null && idFrom > 0;
        successTo = idTo != null && idTo > 0;
      }

      if (successFrom && successTo) {
        // Both transactions were successful
        transactionsModel.fetchTransactions();
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

      // Prepare the transaction data
      Map<String, dynamic> row = {
        TransactionsDB.columnType: _selectedType.toString().split('.').last,  // income, expense or transfer
        TransactionsDB.columnName: name,
        TransactionsDB.columnDescription: description,
        TransactionsDB.columnAmount: amount,
        TransactionsDB.columnDate: DateFormat('yyyy-MM-dd').format(selectedDate),
        TransactionsDB.columnTime: selectedTime.format(context),  // You might want to store this differently
        TransactionsDB.columnAccountId: selectedAccoutId,
        TransactionsDB.columnCategories: jsonEncode(selectedCategoriesList),  // Storing categories as a JSON string
      };

      final transactionsModel = Provider.of<TransactionsModel>(context, listen: false);
      bool success = false;

      if (isUpdate && existingTransaction != null) {
        // Update the existing transaction
        final id = await TransactionsDB().updateTransaction(existingTransaction['_id'], row);
        success = id != null && id > 0;
      } else {
        // Insert a new transaction
        final id = await TransactionsDB().insertTransaction(row);
        success = id != null && id > 0;
      }

      if (success) {
        transactionsModel.fetchTransactions();
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
        Navigator.pop(context, true);
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.blueGrey[900],
        appBar: AppBar(
          elevation: 0,
          leading: BackButton(
            color: Colors.white,
            onPressed: () {
              Navigator.pop(context, true);
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
                        SizedBox(width: 16),
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
                              child: Consumer<AccountsModel>(
                                builder: (context, accountsModel, child) {
                                  if (accountsModel.accounts.isEmpty) {
                                    return Center(
                                      child: Text('No accounts available.'),
                                    );
                                  } else {
                                    return ListView.builder(
                                      padding: EdgeInsets.zero,
                                      scrollDirection: Axis.horizontal,
                                      itemCount: accountsModel.accounts.length,
                                      itemBuilder: (context, index) {
                                        final account = accountsModel.accounts[index];
                                        Map<String, dynamic> currencyMap = jsonDecode(account[AccountsDB.accountCurrency]);
                                        String currencyCode = currencyMap['code'] as String;

                                        return GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              selectedAccoutIndex = index;
                                              selectedAccoutId = account[AccountsDB.accountId];
                                            });
                                          },
                                          child: AccountCard(
                                            accountId: account[AccountsDB.accountId],
                                            icon: IconData(
                                              int.tryParse(account[AccountsDB.accountIcon]) ?? Icons.error.codePoint,
                                              fontFamily: 'MaterialIcons',
                                            ),
                                            currency: currencyCode,
                                            accountName: account[AccountsDB.accountName],
                                            isSelected: index == selectedAccoutIndex,
                                          ),
                                        );
                                      },
                                    );
                                  }
                                }, // This is where the missing '}' should be placed.
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
                                        child: Consumer<CategoriesModel>(
                                          builder: (context, categoriesModel, child) {
                                            if (categoriesModel.categories.isEmpty) {
                                              return Center(
                                                child: Text('No categories available.'),
                                              );
                                            } else {
                                              List<Map<String, dynamic>> sortedData = List.from(categoriesModel.categories);
                                              sortedData = sortedData.where((category) {
                                                return category[CategoriesDB.columnName]
                                                    .toLowerCase()
                                                    .contains(_categorySearchController.text.toLowerCase());
                                              }).toList();
                                              sortedData.sort((a, b) => a[CategoriesDB.columnName].compareTo(b[CategoriesDB.columnName]));

                                              double itemHeight = 55.0; // Approximate height of one ListTile
                                              double maxHeight = 200.0; // Maximum height you'd like to allow for dropdown

                                              double calculatedHeight = sortedData.length * itemHeight;
                                              calculatedHeight = calculatedHeight > maxHeight ? maxHeight : calculatedHeight;

                                              return Container(
                                                height: calculatedHeight,
                                                child: ListView.builder(
                                                  padding: EdgeInsets.zero,
                                                  itemCount: sortedData.length,
                                                  itemBuilder: (context, index) {
                                                    final category = sortedData[index];
                                                    IconData categoryIcon = IconData(
                                                      int.tryParse(category[CategoriesDB.columnIcon]) ?? Icons.error.codePoint,
                                                      fontFamily: 'MaterialIcons',
                                                    );
                                                    String categoryName = category[CategoriesDB.columnName];

                                                    BorderRadius borderRadius;

                                                    // Top item
                                                    if (index == 0) {
                                                      borderRadius = BorderRadius.only(
                                                        topLeft: Radius.circular(30),
                                                        topRight: Radius.circular(30),
                                                      );
                                                    }
                                                    // Bottom item
                                                    else if (index == sortedData.length - 1) {
                                                      borderRadius = BorderRadius.only(
                                                        bottomLeft: Radius.circular(30),
                                                        bottomRight: Radius.circular(30),
                                                      );
                                                    }
                                                    // Middle items
                                                    else {
                                                      borderRadius = BorderRadius.zero;
                                                    }

                                                    return Material(
                                                      type: MaterialType.transparency, // To make it transparent
                                                      child: InkWell(
                                                        onTap: () {
                                                          setState(() {
                                                            selectedCategoriesList.add({
                                                              'name': categoryName,
                                                              'icon': categoryIcon.codePoint,
                                                            });
                                                            _showDropdown = false;
                                                          });
                                                        },
                                                        borderRadius: borderRadius, // Use the dynamic border radius
                                                        splashColor: Colors.blue,
                                                        highlightColor: Colors.blue.withOpacity(0.5),
                                                        child: ListTile(
                                                          title: Text(categoryName),
                                                          leading: Icon(categoryIcon),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                )
                                              );
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
                                      return CategoryChip(
                                        icon: IconData(
                                          category['icon'],
                                          fontFamily: 'MaterialIcons',
                                        ),
                                        label: category['name'],
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
                              child: Consumer<AccountsModel>(
                                builder: (context, accountsModel, child) {
                                  if (accountsModel.accounts.isEmpty) {
                                    return Center(
                                      child: Text('No accounts available.'),
                                    );
                                  } else {
                                    return ListView.builder(
                                      padding: EdgeInsets.zero,
                                      scrollDirection: Axis.horizontal,
                                      itemCount: accountsModel.accounts.length,
                                      itemBuilder: (context, index) {
                                        final account = accountsModel.accounts[index];
                                        Map<String, dynamic> currencyMap = jsonDecode(account[AccountsDB.accountCurrency]);
                                        String currencyCode = currencyMap['code'] as String;

                                        return GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              selectedFromAccountIndex = index;
                                              selectedFromAccountId = account[AccountsDB.accountId];
                                            });
                                          },
                                          child: AccountCard(
                                            accountId: account[AccountsDB.accountId],
                                            icon: IconData(
                                              int.tryParse(account[AccountsDB.accountIcon]) ?? Icons.error.codePoint,
                                              fontFamily: 'MaterialIcons',
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
                              child: Consumer<AccountsModel>(
                                builder: (context, accountsModel, child) {
                                  if (accountsModel.accounts.isEmpty) {
                                    return Center(
                                      child: Text('No accounts available.'),
                                    );
                                  } else {
                                    return ListView.builder(
                                      padding: EdgeInsets.zero,
                                      scrollDirection: Axis.horizontal,
                                      itemCount: accountsModel.accounts.length,
                                      itemBuilder: (context, index) {
                                        final account = accountsModel.accounts[index];
                                        Map<String, dynamic> currencyMap = jsonDecode(account[AccountsDB.accountCurrency]);
                                        String currencyCode = currencyMap['code'] as String;

                                        return GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              selectedToAccountIndex = index;
                                              selectedToAccountId = account[AccountsDB.accountId];
                                            });
                                          },
                                          child: AccountCard(
                                            accountId: account[AccountsDB.accountId],
                                            icon: IconData(
                                              int.tryParse(account[AccountsDB.accountIcon]) ?? Icons.error.codePoint,
                                              fontFamily: 'MaterialIcons',
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
                                        child: Consumer<CategoriesModel>(
                                          builder: (context, categoriesModel, child) {
                                            if (categoriesModel.categories.isEmpty) {
                                              return Center(
                                                child: Text('No categories available.'),
                                              );
                                            } else {
                                              List<Map<String, dynamic>> sortedData = List.from(categoriesModel.categories);
                                              sortedData = sortedData.where((category) {
                                                return category[CategoriesDB.columnName]
                                                    .toLowerCase()
                                                    .contains(_categorySearchController.text.toLowerCase());
                                              }).toList();
                                              sortedData.sort((a, b) => a[CategoriesDB.columnName].compareTo(b[CategoriesDB.columnName]));

                                              double itemHeight = 55.0; // Approximate height of one ListTile
                                              double maxHeight = 200.0; // Maximum height you'd like to allow for dropdown

                                              double calculatedHeight = sortedData.length * itemHeight;
                                              calculatedHeight = calculatedHeight > maxHeight ? maxHeight : calculatedHeight;

                                              return Container(
                                                  height: calculatedHeight,
                                                  child: ListView.builder(
                                                    padding: EdgeInsets.zero,
                                                    itemCount: sortedData.length,
                                                    itemBuilder: (context, index) {
                                                      final category = sortedData[index];
                                                      IconData categoryIcon = IconData(
                                                        int.tryParse(category[CategoriesDB.columnIcon]) ?? Icons.error.codePoint,
                                                        fontFamily: 'MaterialIcons',
                                                      );
                                                      String categoryName = category[CategoriesDB.columnName];

                                                      BorderRadius borderRadius;

                                                      // Top item
                                                      if (index == 0) {
                                                        borderRadius = BorderRadius.only(
                                                          topLeft: Radius.circular(30),
                                                          topRight: Radius.circular(30),
                                                        );
                                                      }
                                                      // Bottom item
                                                      else if (index == sortedData.length - 1) {
                                                        borderRadius = BorderRadius.only(
                                                          bottomLeft: Radius.circular(30),
                                                          bottomRight: Radius.circular(30),
                                                        );
                                                      }
                                                      // Middle items
                                                      else {
                                                        borderRadius = BorderRadius.zero;
                                                      }

                                                      return Material(
                                                        type: MaterialType.transparency, // To make it transparent
                                                        child: InkWell(
                                                          onTap: () {
                                                            setState(() {
                                                              selectedCategoriesList.add({
                                                                'name': categoryName,
                                                                'icon': categoryIcon.codePoint,
                                                              });
                                                              _showDropdown = false;
                                                            });
                                                          },
                                                          borderRadius: borderRadius, // Use the dynamic border radius
                                                          splashColor: Colors.blue,
                                                          highlightColor: Colors.blue.withOpacity(0.5),
                                                          child: ListTile(
                                                            title: Text(categoryName),
                                                            leading: Icon(categoryIcon),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  )
                                              );
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
                                      return CategoryChip(
                                        icon: IconData(
                                          category['icon'],
                                          fontFamily: 'MaterialIcons',
                                        ),
                                        label: category['name'],
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
                          label: "Add",
                          onPressed: _addUpdateTransaction,
                          primaryColor: Colors.blueAccent,
                          textColor: Colors.white,
                          fontSize: 18.0,
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
