import 'package:expnz/widgets/SimpleWidgets/ExpnZTextField.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/AppWidgets/CategoryChip.dart';
import '../widgets/AppWidgets/SelectAccountCard.dart';
import '../widgets/SimpleWidgets/ExpnZButton.dart';

enum TransactionType { income, expense, transfer }

class AddTransactionScreen extends StatefulWidget {
  @override
  _AddTransactionScreenState createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {

  int selectedFromAccountIndex = -1;
  int selectedToAccountIndex = -1;
  int selectedAccoutIndex = -1;

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;

  final TextEditingController _categorySearchController = TextEditingController();
  List<String> selectedCategories = ["Food", "Shopping", "Travel", "test", "Test2"];  // Sample categories
  TransactionType _selectedType = TransactionType.income; // Default to income

  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _amountController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
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
        title: Text("Add Transaction", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueGrey[900],
      ),
      body: Stack(
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
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            scrollDirection: Axis.horizontal,
                            itemCount: 3, // Change this with the number of account cards you have
                            itemBuilder: (context, index) {
                              final accounts = <Map<String, dynamic>>[
                                {'icon': Icons.account_balance_wallet, 'currency': 'USD', 'accountName': 'Savings'},
                                {'icon': Icons.money, 'currency': 'EUR', 'accountName': 'Checking'},
                                {'icon': Icons.add, 'currency': '', 'accountName': 'Create New'},
                              ];
                              final account = accounts[index];
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedAccoutIndex = index;
                                  });
                                },
                                child: AccountCard(
                                  icon: account['icon'],
                                  currency: account['currency'],
                                  accountName: account['accountName'],
                                  isSelected: index == selectedAccoutIndex,
                                ),
                              );
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
                              // Here you can implement the search logic to populate suggestions
                              onChanged: (value) {
                                // Implement search logic
                              },
                            ),
                            SizedBox(height: 20),
                            Wrap(
                              spacing: 8.0, // gap between chips
                              runSpacing: 8.0,
                              children: List<Widget>.generate(
                                selectedCategories.length,
                                    (int index) {
                                  return CategoryChip(
                                    icon: Icons.category,  // This is just a placeholder, use appropriate icon
                                    label: selectedCategories[index],
                                    onTap: () {
                                      setState(() {
                                        selectedCategories.removeAt(index);  // Remove the category when the chip is tapped
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
                      onPressed: () {
                        // Implement your logic for adding the transaction
                      },
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
                          height: 150,
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            scrollDirection: Axis.horizontal,
                            itemCount: 3,
                            itemBuilder: (context, index) {
                              final accounts = <Map<String, dynamic>>[
                                {'icon': Icons.account_balance_wallet, 'currency': 'USD', 'accountName': 'Savings'},
                                {'icon': Icons.money, 'currency': 'EUR', 'accountName': 'Checking'},
                                {'icon': Icons.add, 'currency': '', 'accountName': 'Create New'},
                              ];
                              final account = accounts[index];
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedFromAccountIndex = index;
                                  });
                                },
                                child: AccountCard(
                                  icon: account['icon'],
                                  currency: account['currency'],
                                  accountName: account['accountName'],
                                  isSelected: index == selectedFromAccountIndex,
                                ),
                              );
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
                          height: 150,
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            scrollDirection: Axis.horizontal,
                            itemCount: 3,
                            itemBuilder: (context, index) {
                              final accounts = <Map<String, dynamic>>[
                                {'icon': Icons.account_balance_wallet, 'currency': 'USD', 'accountName': 'Savings'},
                                {'icon': Icons.money, 'currency': 'EUR', 'accountName': 'Checking'},
                                {'icon': Icons.add, 'currency': '', 'accountName': 'Create New'},
                              ];
                              final account = accounts[index];
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedToAccountIndex = index;
                                  });
                                },
                                child: AccountCard(
                                  icon: account['icon'],
                                  currency: account['currency'],
                                  accountName: account['accountName'],
                                  isSelected: index == selectedToAccountIndex,
                                ),
                              );
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
                              // Here you can implement the search logic to populate suggestions
                              onChanged: (value) {
                                // Implement search logic
                              },
                            ),
                            SizedBox(height: 20),
                            Wrap(
                              spacing: 8.0, // gap between chips
                              runSpacing: 8.0,
                              children: List<Widget>.generate(
                                selectedCategories.length,
                                    (int index) {
                                  return CategoryChip(
                                    icon: Icons.category,  // This is just a placeholder, use appropriate icon
                                    label: selectedCategories[index],
                                    onTap: () {
                                      setState(() {
                                        selectedCategories.removeAt(index);  // Remove the category when the chip is tapped
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
                      onPressed: () {
                        // Implement your logic for adding the transaction
                      },
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
    );
  }
}
