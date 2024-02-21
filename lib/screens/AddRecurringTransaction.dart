import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:expnz/utils/global.dart';
import 'package:expnz/widgets/SimpleWidgets/ExpnZButton.dart';
import 'package:expnz/widgets/SimpleWidgets/ModernSnackBar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'dart:io' show Platform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../database/RecurringTransactionsDB.dart';

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

  int _notificationId = 0;

  // TextEditingControllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

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
      appBar: AppBar(
        title: Text(
          updateMode
              ? 'Update Recurring Transaction'
              : 'Add Recurring Transaction',
          style: TextStyle(fontSize: 18), // Adjust font size as needed
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
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name *'),
                validator: (value) =>
                value!.isEmpty ? 'Please enter a name' : null,
                onSaved: (value) => name = value!,
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                onSaved: (value) => description = value ?? '',
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(labelText: 'Amount (optional)'),
                keyboardType: TextInputType.number,
                onSaved: (value) =>
                amount = value!.isEmpty ? null : double.parse(value),
              ),
              SizedBox(height: 20),
              DropdownButtonFormField(
                decoration: InputDecoration(labelText: 'Recurring Frequency'),
                value: frequency,
                onChanged: (String? newValue) =>
                    setState(() => frequency = newValue!),
                items:
                frequencies.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              SizedBox(height: 20),
              if (frequency == 'Weekly') ...[
                DropdownButtonFormField(
                  decoration: InputDecoration(labelText: 'Day of Week Due'),
                  value: dayOfWeek,
                  onChanged: (String? newValue) =>
                      setState(() => dayOfWeek = newValue!),
                  items:
                  daysOfWeek.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
              if (frequency == 'Monthly' || frequency == 'Yearly') ...[
                ListTile(
                  title: Text('Select Due Date'),
                  subtitle: Text('${selectedDate.toLocal()}'.split(' ')[0]),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null && pickedDate != selectedDate) {
                      setState(() {
                        selectedDate = pickedDate;
                      });
                    }
                  },
                ),
              ],
              ListTile(
                title: Text('Select Due Time'),
                subtitle: Text(selectedTime.format(context)),
                onTap: () async {
                  TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (pickedTime != null && pickedTime != selectedTime) {
                    setState(() {
                      selectedTime = pickedTime;
                    });
                  }
                },
              ),
              SizedBox(height: 10),
              SwitchListTile(
                title: Text('Schedule Reminder Notifications'),
                value: scheduleReminder,
                onChanged: (bool value) async {
                  if (value) {
                    await _requestPermissions();
                    if (Platform.isAndroid) {
                      await _requestBatteryOptimization();
                    }
                  }
                  setState(() => scheduleReminder = value && _notificationsEnabled);
                },
              ),
              ...notificationTimingWidgets,
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: ExpnZButton(
                    label: updateMode ? 'Update' : 'Save',
                    onPressed: _submitForm,
                  ),
                ),
              ),
            ],
          ),
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
