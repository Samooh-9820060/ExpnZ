import 'dart:convert';
import 'package:expnz/utils/currency_utils.dart';
import 'package:expnz/widgets/SimpleWidgets/ExpnZTextField.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  final Map<String, dynamic>? transaction;
  final int? tempTransactionId;
  final String? recurringTransactionId;

  // Constructor with named parameters
  const AddTransactionScreen({super.key, this.transaction, this.tempTransactionId, this.recurringTransactionId});

  @override
  _AddTransactionScreenState createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> with WidgetsBindingObserver{

  int selectedFromAccountIndex = -1;
  int selectedToAccountIndex = -1;
  int selectedAccountIndex = -1;
  String selectedAccountType = '';
  String selectedFromAccountId = "-1";
  String selectedToAccountId = "-1";
  String selectedAccountId = "-1";

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  late TextEditingController _actualPriceController;
  late TextEditingController _balanceGivenController;
  final TextEditingController _categorySearchController = TextEditingController();
  bool _showDropdown = false;
  bool isProcessing = false;
  bool updateMode = false;
  bool tempAdding = false;
  bool recurringAdding = false;

  List<Map<String, dynamic>> filteredCategories = [];
  List<Map<String, dynamic>> selectedCategoriesList = [];
  OverlayEntry? overlayEntry;

  TransactionType _selectedType = TransactionType.income; // Default to income

  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  final FocusNode _categorySearchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _amountController = TextEditingController();
    _actualPriceController = TextEditingController();
    _balanceGivenController = TextEditingController();

    _amountController.addListener(_updateBalance);
    _actualPriceController.addListener(_updateBalance);

    if (widget.transaction != null) { updateMode = true; loadTransactionData(); }
    if (widget.tempTransactionId != null) { tempAdding = true; loadTempTransactionData(); }
    if (widget.recurringTransactionId != null) { recurringAdding = true; loadRecurringTransactionData(); }
  }

  void _updateBalance() {
    if (selectedAccountType == 'Cash/Wallet') {
      try {
        double amount = double.tryParse(_amountController.text) ?? 0.0;
        double actualPrice = double.tryParse(_actualPriceController.text) ?? 0.0;

        // Calculate the balance
        double balance = amount - actualPrice;

        // Update the balance controller
        _balanceGivenController.text = balance.toStringAsFixed(2); // Format to 2 decimal places
      } catch (ex) {}
    }
  }

  Future<void> loadRecurringTransactionData() async {
    Map<String, Map<String, dynamic>> transactionsData = recurringTransactionsNotifier.value;

    // Retrieve the specific transaction data
    Map<String, dynamic>? transactionData = transactionsData[widget.recurringTransactionId];

    if (transactionData != null) {
      _selectedType = TransactionType.expense;
      _nameController.text = transactionData['name'] ?? '';
      _descriptionController.text = transactionData['description'] ?? '';
      _amountController.text = transactionData['amount'].toString();
    }
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
        _amountController.text = tempTransactionData[TempTransactionsDB.columnAmount].toString();
        if (tempTransactionData[TempTransactionsDB.columnDate] != null && tempTransactionData[TempTransactionsDB.columnTime] != null) {
          final String date = tempTransactionData[TempTransactionsDB.columnDate];
          final String time = tempTransactionData[TempTransactionsDB.columnTime];

          DateFormat format = DateFormat("dd/MM/yy HH:mm:ss");
          DateFormat dateFormat = DateFormat("dd/MM/yy"); // Format for just the date

          DateTime completeDateTime = format.parse("$date $time");
          selectedDate = dateFormat.parse(date); // Parse just the date part
          selectedTime = TimeOfDay.fromDateTime(completeDateTime);
        }
      });
    }
  }

  void loadTransactionData() {
    final transactionsData = transactionsNotifier.value;

    // Extract the transaction data using the widget's transaction ID
    final String transactionId = widget.transaction?['documentId'];
    final transaction = transactionsData[transactionId];

    if (transaction != null) {
      final String name = transaction[TransactionsDB.transactionName] ?? 'Unknown';
      final String description = transaction[TransactionsDB.transactionDescription] ?? 'Unknown';
      final String accountId = transaction[TransactionsDB.transactionAccountId];
      final String date = transaction[TransactionsDB.transactionDate];
      final String time = transaction[TransactionsDB.transactionTime] ?? 'Unknown';
      final double amount = (transaction[TransactionsDB.transactionAmount] ?? 0).toDouble();
      final double actualPrice = (transaction[TransactionsDB.transactionActualPrice] ?? 0).toDouble();
      final double balanceAmount = (transaction[TransactionsDB.transactionBalance] ?? 0).toDouble();
      final String type = transaction[TransactionsDB.transactionType] ?? 'Unknown';

      if (type == 'expense') {
        _selectedType = TransactionType.expense;
      } else if (type == 'income') {
        _selectedType = TransactionType.income;
      }

      _nameController.text = name;
      _descriptionController.text = description;
      _amountController.text = amount.toString();
      _actualPriceController.text = actualPrice.toString();
      _balanceGivenController.text = balanceAmount.toString();

      // Combine date and time...
      DateTime completeDateTime = DateTime.parse("$date $time");
      selectedDate = DateTime.parse(date);
      selectedTime = TimeOfDay.fromDateTime(completeDateTime);

      // Fetch account index using accountData
      final accountData = accountsNotifier.value;
      selectedAccountIndex = accountData.entries
          .toList()
          .indexWhere((entry) => entry.key == accountId.toString());

      if (selectedAccountIndex != -1) {
        selectedAccountId = accountId;

        // Retrieve the account details map for the selected account
        Map<String, dynamic>? selectedAccountData = accountData[accountId];

        // Now retrieve the account type from the selected account details
        if (selectedAccountData != null && selectedAccountData.containsKey(AccountsDB.accountType)) {
          selectedAccountType = selectedAccountData[AccountsDB.accountType] as String;
        }
      }

      // Processing categories...
      final String? categoriesString = transaction[TransactionsDB.transactionCategoryIDs] ?? '';
      if (categoriesString != null && categoriesString.isNotEmpty) {
        final List<String> categoryIds = categoriesString
            .split(',')
            .map((e) => e.trim())
            .where((id) => id.isNotEmpty) // Filter out any empty strings
            .toList();

        selectedCategoriesList.clear();
        for (String categoryId in categoryIds) {
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
    _balanceGivenController.dispose();
    _actualPriceController.dispose();
    super.dispose();
  }

  void closeDropdown() {
    setState(() {
      _showDropdown = false;
    });
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
    bool hasUnassignedCategory = selectedCategoriesList.isEmpty;

    if (hasUnassignedCategory) {
      await showModernSnackBar(
        context: context,
        message: "Please assign a category to the transaction before saving",
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
    double? actualAmount = double.tryParse(_actualPriceController.text.trim());
    double? balanceAmount = double.tryParse(_balanceGivenController.text.trim());

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

    if (selectedAccountType == 'Cash/Wallet') {
      if (amount == actualAmount || balanceAmount == null) {
        balanceAmount = 0.0;
      }
      if (actualAmount == null || actualAmount <= 0) {
        await showModernSnackBar(
          context: context,
          message: "Actual amount field cannot be null and should be greater than 0",
          backgroundColor: Colors.red,
        );
        setState(() {
          isProcessing = false;
        });
        return;
      }
      else if (roundToTwoDecimalPlaces(roundToTwoDecimalPlaces(amount) - roundToTwoDecimalPlaces(actualAmount)) != roundToTwoDecimalPlaces(balanceAmount)) {
        await showModernSnackBar(
          context: context,
          message: "Amount - Actual must be equal to balance",
          backgroundColor: Colors.red,
        );
        setState(() {
          isProcessing = false;
        });
        return;
      }
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

    String formattedTime = DateTime.now().toIso8601String();

    // Prepare Firestore reference
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
        TransactionsDB.lastEditedTime: formattedTime,
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
        TransactionsDB.lastEditedTime: formattedTime,
      };

      try {
        bool dataInserted = false;

        if (isUpdate && existingTransaction != null) {
          // Update existing transactions
          TransactionsDB().updateTransaction(existingTransaction['from_id'], rowFrom);
          TransactionsDB().updateTransaction(existingTransaction['to_id'], rowTo);
          dataInserted = true;
        } else {
          // Insert new transactions
          TransactionsDB().insertTransaction(rowFrom);
          TransactionsDB().insertTransaction(rowTo);
          dataInserted = true;
        }

        // Check if both transactions were successful
        if ((isUpdate && existingTransaction != null) || (dataInserted)) {
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
      } catch (e) {
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
      if (selectedAccountIndex < 0) {
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
        TransactionsDB.transactionActualPrice: actualAmount,
        TransactionsDB.transactionBalance: balanceAmount,
        TransactionsDB.transactionDate: DateFormat('yyyy-MM-dd').format(selectedDate),
        TransactionsDB.transactionTime: selectedTime.format(context),  // You might want to store this differently
        TransactionsDB.transactionAccountId: selectedAccountId,
        TransactionsDB.transactionCategoryIDs: categoryIds,
        TransactionsDB.lastEditedTime: formattedTime,
      };

      try {
        bool dataInserted = false;

        if (isUpdate && existingTransaction != null) {
          // Update existing transaction
          TransactionsDB().updateTransaction(existingTransaction['documentId'], row);
          dataInserted = true;
        } else {
          // Insert a new transaction
          TransactionsDB().insertTransaction(row);
          dataInserted = true;
        }


        // Check if the transaction was successful
        if ((isUpdate && existingTransaction != null) || dataInserted == true) {
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
      } catch (e) {
        await showModernSnackBar(
          context: context,
          message: isUpdate ? "Error Updating Transaction" : "Error adding transaction",
          backgroundColor: Colors.redAccent,
        );
        setState(() {
          isProcessing = false;
        });
      }
    }

    setState(() {
      isProcessing = false;
    });
    return;
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
            padding: const EdgeInsets.all(16),
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
    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }
// Method to select Time
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (pickedTime != null && pickedTime != selectedTime) {
      setState(() {
        selectedTime = pickedTime;
      });
    }
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
            color: isProcessing ? Colors.grey : Colors.white,
            onPressed: () {
              isProcessing ? null : Navigator.pop(context, false);
            },
          ),
          title: Text(
              updateMode ? "Update Transaction" : "Add Transaction",
              style: const TextStyle(color: Colors.white)),
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
                        const SizedBox(width: 16),
                        buildTypeButton(TransactionType.expense, 'Expense'),
                        if (!updateMode)
                          const SizedBox(width: 16),
                        if (!updateMode)
                          buildTypeButton(TransactionType.transfer, 'Transfer'),
                      ],
                    ),

                    // Fields for Income and Expense
                    if (_selectedType == TransactionType.income || _selectedType == TransactionType.expense)
                      ...[
                        const SizedBox(height: 16),
                        // Name
                        CustomTextField(label: "Name", controller: _nameController),
                        const SizedBox(height: 16),
                        // Description
                        CustomTextField(label: "Description", controller: _descriptionController),
                        const SizedBox(height: 16),
                        // Amount
                        if (selectedAccountType == 'Cash/Wallet')
                          Row(
                            children: [
                              Expanded(
                                flex: 5, // Giving more space to Amount
                                child: CustomTextField(label: "Amount Spent", controller: _amountController, isNumber: true, alwaysFloatingLabel: true,),
                              ),
                              const SizedBox(width: 8), // Space between fields
                              Expanded(
                                flex: 5, // Giving more space to Actual Price
                                child: CustomTextField(label: "Actual Price", controller: _actualPriceController, isNumber: true, alwaysFloatingLabel: true,),
                              ),
                              const SizedBox(width: 8), // Space between fields
                              Expanded(
                                flex: 4, // Less space for Balance Given as it's automatic
                                child: CustomTextField(label: "Balance", controller: _balanceGivenController, isNumber: true, alwaysFloatingLabel: true,),
                              ),
                            ],
                          )
                        else
                          CustomTextField(label: "Amount", controller: _amountController, isNumber: true),
                        const SizedBox(height: 16),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Date Button
                            InkWell(
                              onTap: () => _selectDate(context),
                              borderRadius: BorderRadius.circular(50),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.blueGrey[700],
                                  borderRadius: BorderRadius.circular(50),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 10,
                                      offset: Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, color: Colors.white),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat('yyyy-MM-dd').format(selectedDate),
                                      style: const TextStyle(
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
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.blueGrey[700],
                                  borderRadius: BorderRadius.circular(50),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 10,
                                      offset: Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.access_time, color: Colors.white),
                                    const SizedBox(width: 8),
                                    Text(
                                      selectedTime.format(context),
                                      style: const TextStyle(
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
                        const SizedBox(height: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Select Account',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 150, // set the height
                              child: ValueListenableBuilder<Map<String, Map<String, dynamic>>?>(
                                valueListenable: accountsNotifier,
                                builder: (context, accountsData, child) {
                                  if (accountsData == null || accountsData.isEmpty) {
                                    return const Center(
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
                                        final String accountType = account[AccountsDB.accountType] as String; // Retrieving the account type
                                        Map<String, dynamic> currencyMap = jsonDecode(account[AccountsDB.accountCurrency]);
                                        String currencyCode = currencyMap['code'] as String;

                                        return GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              selectedAccountIndex = index;
                                              selectedAccountId = accountId;
                                              selectedAccountType = accountType;
                                              _balanceGivenController.text = '0';
                                              _actualPriceController.text = '0';
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
                                            isSelected: index == selectedAccountIndex,
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
                        const SizedBox(height: 16),
                        // Category Selector
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
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
                                const SizedBox(height: 10),
                                TextField(
                                  focusNode: _categorySearchFocusNode,
                                  controller: _categorySearchController,
                                  decoration: InputDecoration(
                                    hintText: 'Search Category',
                                    fillColor: Colors.blueGrey[700],
                                    filled: true,
                                    prefixIcon: const Icon(Icons.search),
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide.none,  // Removes the underline border
                                      borderRadius: BorderRadius.circular(50.0),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(color: Colors.blue, width: 1),
                                      borderRadius: BorderRadius.circular(50.0),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _showDropdown = value.isNotEmpty;
                                    });
                                  },
                                ),
                                const SizedBox(height: 10),
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
                                      child: SizedBox(
                                        width: MediaQuery.of(context).size.width, // Adjust as needed
                                        child: ValueListenableBuilder<Map<String, Map<String, dynamic>>?>(
                                          valueListenable: categoriesNotifier,
                                          builder: (context, categoriesData, child) {
                                            if (categoriesData != null && categoriesData.isNotEmpty) {
                                              List<Map<String, dynamic>> categoriesList = categoriesData.entries.map((entry) {
                                                return {
                                                  'id': entry.key,
                                                  ...entry.value,
                                                };
                                              }).toList();

                                              return buildCategoriesDropdown(
                                                  selectedCategoriesList,
                                                  _categorySearchController,
                                                  setState, // Pass setState directly without invoking it
                                                closeDropdown,
                                              );
                                            } else {
                                              return const Center(child: Text('No categories available.'));
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 10),
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
                                        //print('Unknown type for category ID');
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
                        const SizedBox(height: 20),
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
                        const SizedBox(height: 16),
                        // Name
                        CustomTextField(label: "Name", controller: _nameController),
                        const SizedBox(height: 16),
                        // Description
                        CustomTextField(label: "Description", controller: _descriptionController),
                        const SizedBox(height: 16),
                        // Amount
                        CustomTextField(label: "Amount", controller: _amountController, isNumber: true,),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Date Button
                            InkWell(
                              onTap: () => _selectDate(context),
                              borderRadius: BorderRadius.circular(50),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.blueGrey[700],
                                  borderRadius: BorderRadius.circular(50),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 10,
                                      offset: Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, color: Colors.white),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat('yyyy-MM-dd').format(selectedDate),
                                      style: const TextStyle(
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
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.blueGrey[700],
                                  borderRadius: BorderRadius.circular(50),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 10,
                                      offset: Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.access_time, color: Colors.white),
                                    const SizedBox(width: 8),
                                    Text(
                                      selectedTime.format(context),
                                      style: const TextStyle(
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
                        const SizedBox(height: 20),
                        // From Account
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'From Account',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 150, // set the height
                              child: ValueListenableBuilder<Map<String, Map<String, dynamic>>?>(
                                valueListenable: accountsNotifier,
                                builder: (context, accountsData, child) {
                                  if (accountsData == null || accountsData.isEmpty) {
                                    return const Center(
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
                        const SizedBox(height: 16),
                        // To Account
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'To Account',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 150, // set the height
                              child: ValueListenableBuilder<Map<String, Map<String, dynamic>>?>(
                                valueListenable: accountsNotifier,
                                builder: (context, accountsData, child) {
                                  if (accountsData == null || accountsData.isEmpty) {
                                    return const Center(
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
                        const SizedBox(height: 16),
                        // Category Selector
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
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
                                const SizedBox(height: 10),
                                TextField(
                                  focusNode: _categorySearchFocusNode,
                                  controller: _categorySearchController,
                                  decoration: InputDecoration(
                                    hintText: 'Search Category',
                                    fillColor: Colors.blueGrey[700],
                                    filled: true,
                                    prefixIcon: const Icon(Icons.search),
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide.none,  // Removes the underline border
                                      borderRadius: BorderRadius.circular(50.0),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(color: Colors.blue, width: 1),
                                      borderRadius: BorderRadius.circular(50.0),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _showDropdown = value.isNotEmpty;
                                    });
                                  },
                                ),
                                const SizedBox(height: 10),
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
                                      child: SizedBox(
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
                                                closeDropdown,
                                              );
                                            } else {
                                              return const Center(child: Text('No categories available.'));
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 10),
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
                                        //print('Unknown type for category ID');
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
                        const SizedBox(height: 20),
                        ExpnZButton(
                          label: isProcessing ? "Processing" : updateMode ? "Update" : "Add",
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

