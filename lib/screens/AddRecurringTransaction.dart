import 'dart:convert';

import 'package:android_intent_plus/android_intent.dart';
import 'package:expnz/widgets/SimpleWidgets/ExpnZTextField.dart';
import 'package:flutter/material.dart';
import 'package:expnz/utils/global.dart';
import 'package:expnz/widgets/SimpleWidgets/ExpnZButton.dart';
import 'package:expnz/widgets/SimpleWidgets/ExpnzSnackBar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'dart:io' show Platform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../database/AccountsDB.dart';
import '../database/RecurringTransactionsDB.dart';
import '../widgets/AppWidgets/BuildCategoriesDropdown.dart';
import '../widgets/AppWidgets/CategoryChip.dart';
import '../widgets/AppWidgets/SelectAccountCard.dart';
import '../widgets/SimpleWidgets/ExpnZDropdown.dart';

class AddRecurringTransactionPage extends StatefulWidget {
  String? documentId;

  AddRecurringTransactionPage({super.key, this.documentId});

  @override
  _AddRecurringTransactionPageState createState() =>
      _AddRecurringTransactionPageState();
}

class _AddRecurringTransactionPageState
    extends State<AddRecurringTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String description = '';
  double? amount;
  bool scheduleReminder = false;
  String frequency = 'Daily'; // Default value for transaction frequency
  String dayOfWeek = 'Monday'; // Default value for weekly frequency
  DateTime selectedDate =
  DateTime.now(); // Default value for monthly or yearly frequency
  TimeOfDay selectedTime = TimeOfDay.now(); // Default value for due time
  int notificationDaysBefore = 0;
  int notificationHoursBefore = 0;
  int notificationMinutesBefore = 0;
  String notificationFrequency =
      'Hourly'; // Notification frequency for monthly/yearly
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  bool _notificationsEnabled = false;
  bool updateMode = false;
  int selectedAccountIndex = -1;
  String selectedAccountId = "-1";
  final FocusNode _categorySearchFocusNode = FocusNode();
  bool _showDropdown = false;


  // TextEditingControllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _categorySearchController = TextEditingController();


  List<Map<String, dynamic>> selectedCategoriesList = [];
  final List<String> frequencies = ['Daily', 'Weekly', 'Monthly', 'Yearly'];
  final List<String> daysOfWeek = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday'
  ];
  final List<String> notificationFrequencies = [
    'Hourly',
    'Daily',
    'At Time of Event'
  ];

  @override
  void initState() {
    super.initState();
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    if (widget.documentId != null) {
      updateMode = true;
      loadTransactionData();
    }
  }

  void closeDropdown() {
    setState(() {
      _showDropdown = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void loadTransactionData() {
    final transactionsData = recurringTransactionsNotifier.value;

    // Extract the transaction data using the widget's transaction ID
    final transaction = transactionsData[widget.documentId];

    if (transaction != null) {
      _nameController.text = transaction['name'];
      _descriptionController.text = transaction['description'] ?? '';
      _amountController.text = transaction['amount']?.toString() ?? '';

      // Update other fields
      scheduleReminder = transaction['scheduleReminder'] ?? false;
      frequency = transaction['frequency'] ?? 'Daily';
      dayOfWeek = transaction['dayOfWeek'] ?? 'Monday';

      if (transaction.containsKey('dueDate')) {
        selectedDate = DateTime.parse(transaction['dueDate']);
      }

      if (transaction.containsKey('dueTime')) {
        selectedTime = TimeOfDay.fromDateTime(
            DateTime.parse('2022-01-01 ${transaction['dueTime']}'));
      }

      notificationDaysBefore = transaction['notificationDaysBefore'] ?? 0;
      notificationHoursBefore = transaction['notificationHoursBefore'] ?? 0;
      notificationMinutesBefore = transaction['notificationMinutesBefore'] ?? 0;
      notificationFrequency = transaction['notificationFrequency'] ?? 'Hourly';
    }
  }

  Future<void> _requestBatteryOptimization() async {
    if (Platform.isAndroid) {
      final AndroidIntent intent = AndroidIntent(
        action: 'android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
        data: 'package:com.techNova.ExpnZ.expnz', // Replace with your package name
      );
      await intent.launch();
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isIOS || Platform.isMacOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      final bool? grantedNotificationPermission =
      await androidImplementation?.requestNotificationsPermission();
      setState(() {
        _notificationsEnabled = grantedNotificationPermission ?? false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> notificationTimingWidgets = [];

    if (scheduleReminder) {
      notificationTimingWidgets
          .addAll(buildNotificationTimingFields(['days', 'hours', 'minutes']));
    }

    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        title: Text(
          updateMode ? 'Update Recurring Transaction' : 'Add Recurring Transaction',
          style: TextStyle(fontSize: 20), // Slightly larger font size
        ),
        backgroundColor: Colors.blueGrey[900],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ExpnzTextField(label: 'Name *', controller: _nameController),
              SizedBox(height: 10,),
              //buildTextField(_nameController, 'Name *', 'Please enter a name'),
              ExpnzTextField(label: 'Description', controller: _descriptionController),
              SizedBox(height: 10,),
              //buildTextField(_descriptionController, 'Description', null),
              ExpnzTextField(label: 'Amount (optional)', controller: _amountController, isNumber: true,),
              SizedBox(height: 10,),
              //buildTextField(_amountController, 'Amount (optional)', null, isNumeric: true),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Account (Optional)',
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
                                    if (selectedAccountIndex == index) {
                                      selectedAccountId = "-1";
                                      selectedAccountIndex = -1;
                                    } else {
                                      selectedAccountIndex = index;
                                      selectedAccountId = accountId;
                                    }
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
              SizedBox(height: 10,),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Category (Optional)',
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
              SizedBox(height: 10,),
              ExpnzDropdownButton(
                label: "Recurring Frequency",
                value: frequency,
                items: frequencies,
                onChanged: (newValue) {
                  setState(() => frequency = newValue!);
                },
              ),
              const SizedBox(height: 0),
              if (frequency == 'Weekly')
                ExpnzDropdownButton(
                  label: "Day of Week Due",
                  value: dayOfWeek,
                  items: daysOfWeek,
                  onChanged: (newValue) {
                    setState(() => dayOfWeek = newValue!);
                  },
                ),
              if (frequency == 'Monthly' || frequency == 'Yearly')
                buildDateSelector('Select Due Date', selectedDate, (DateTime? pickedDate) {
                  if (pickedDate != null && pickedDate != selectedDate) {
                    setState(() {
                      selectedDate = pickedDate;
                    });
                  }
                }),
              buildTimeSelector('Select Due Time', selectedTime, (TimeOfDay? pickedTime) {
                if (pickedTime != null && pickedTime != selectedTime) {
                  setState(() {
                    selectedTime = pickedTime;
                  });
                }
              }),
              buildSwitchListTile('Schedule Reminder Notifications', scheduleReminder, (bool value) async {
                if (value) {
                  await _requestPermissions();
                  if (Platform.isAndroid) {
                    await _requestBatteryOptimization();
                  }
                }
                setState(() => scheduleReminder = value && _notificationsEnabled);
              }),
              ...notificationTimingWidgets,
              buildSubmitButton(updateMode ? 'Update' : 'Save', _submitForm),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField(TextEditingController controller, String labelText, String? validationError, {bool isNumeric = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: labelText),
        validator: (value) => validationError != null && value!.isEmpty ? validationError : null,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      ),
    );
  }

  Widget buildDropdownButtonFormField(String labelText, String currentValue, List<String> items, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField(
        decoration: InputDecoration(labelText: labelText),
        value: currentValue,
        onChanged: onChanged,
        items: items.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
      ),
    );
  }

  Widget buildDateSelector(String title, DateTime selectedDate, Function(DateTime?) onSelectDate) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: ListTile(
        title: Text(title),
        subtitle: Text('${selectedDate.toLocal()}'.split(' ')[0]),
        onTap: () async {
          DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: selectedDate,
            firstDate: DateTime.now(),
            lastDate: DateTime(2101),
          );
          if (pickedDate != null) {
            await onSelectDate(pickedDate); // Await the onSelectDate future
          }
        },
      ),
    );
  }

  Widget buildTimeSelector(String title, TimeOfDay selectedTime, Function(TimeOfDay?) onSelectTime) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: ListTile(
        title: Text(title),
        subtitle: Text(selectedTime.format(context)),
        onTap: () async {
          TimeOfDay? pickedTime = await showTimePicker(
            context: context,
            initialTime: selectedTime,
          );
          onSelectTime(pickedTime);
        },
      ),
    );
  }

  Widget buildSwitchListTile(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget buildSubmitButton(String label, VoidCallback onPressed) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: ExpnZButton(
          label: label,
          onPressed: onPressed,
        ),
      ),
    );
  }

  List<Widget> buildNotificationTimingFields(List<String> units) {
    List<Widget> fields = [];

    // Add a header to explain the purpose of these fields
    fields.add(
      Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Text(
          'Set Notification Time Before Due',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );

    for (String unit in units) {
      fields.add(buildUnitSelector(
          'Time Before Due (${unit.capitalize()}):',
          // Capitalize the first letter
          unit,
          unit == 'days'
              ? notificationDaysBefore
              : unit == 'hours'
              ? notificationHoursBefore
              : notificationMinutesBefore));
    }
    return fields;
  }

  Widget buildUnitSelector(String label, String unit, int value) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          SizedBox(width: 10),
          DropdownButton<int>(
            value: value,
            onChanged: (int? newValue) {
              setState(() {
                if (unit == 'days')
                  notificationDaysBefore = newValue!;
                else if (unit == 'hours')
                  notificationHoursBefore = newValue!;
                else if (unit == 'minutes')
                  notificationMinutesBefore = newValue!;
              });
            },
            items: List<DropdownMenuItem<int>>.generate(
                unit == 'hours' ? 24 : 60,
                // Generate up to 22 for hours, 59 for minutes
                    (index) =>
                    DropdownMenuItem(value: index, child: Text('$index'))),
          ),
        ],
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // Prepare data for the new recurring transaction
      Map<String, dynamic> recurringTransactionData = {
        'name': name,
        'description': description,
        'amount': amount,
        'scheduleReminder': scheduleReminder,
        'frequency': frequency,
        'dayOfWeek': frequency == 'Weekly' ? dayOfWeek : null,
        'dueDate': (frequency == 'Monthly' || frequency == 'Yearly')
            ? selectedDate.toIso8601String()
            : null,
        'dueTime': selectedTime.format(context),
        'notificationDaysBefore': notificationDaysBefore,
        'notificationHoursBefore': notificationHoursBefore,
        'notificationMinutesBefore': notificationMinutesBefore,
        'notificationFrequency':
        scheduleReminder ? notificationFrequency : null,
        'createdTime': DateTime.now().toIso8601String(),
        'lastEditedTime': DateTime.now().toIso8601String(),
        'userId': FirebaseAuth.instance.currentUser?.uid,
      };

      try {
        if (updateMode) {
          // Update existing transaction
          await RecurringTransactionDB().updateRecurringTransaction(
              widget.documentId!, recurringTransactionData);
          showModernSnackBar(
              context: context,
              message: 'Recurring Transaction updated',
              backgroundColor: Colors.green);
        } else {
          // Add new transaction
          await RecurringTransactionDB()
              .addRecurringTransaction(recurringTransactionData);
          //_scheduleNotification;
          showModernSnackBar(
              context: context,
              message: 'Recurring Transaction added',
              backgroundColor: Colors.green);
        }
        Navigator.pop(context);
      } catch (e) {
        showModernSnackBar(
            context: context,
            message: 'Failed to process transaction',
            backgroundColor: Colors.red);
      }
    }
  }
}

// Helper function to capitalize the first letter of a string
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
