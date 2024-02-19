import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AddRecurringTransactionPage extends StatefulWidget {
  @override
  _AddRecurringTransactionPageState createState() => _AddRecurringTransactionPageState();
}

class _AddRecurringTransactionPageState extends State<AddRecurringTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String description = '';
  double? amount;
  bool scheduleReminder = false;
  String frequency = 'Daily'; // Default value for transaction frequency
  String dayOfWeek = 'Monday'; // Default value for weekly frequency
  DateTime selectedDate = DateTime.now(); // Default value for monthly or yearly frequency
  TimeOfDay selectedTime = TimeOfDay.now(); // Default value for due time
  int notificationDaysBefore = 0;
  int notificationHoursBefore = 0;
  int notificationMinutesBefore = 0;
  String notificationFrequency = 'Hourly'; // Notification frequency for monthly/yearly
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  bool _notificationsEnabled = false;

  final List<String> frequencies = ['Daily', 'Weekly', 'Monthly', 'Yearly'];
  final List<String> daysOfWeek = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  final List<String> notificationFrequencies = ['Hourly', 'Daily', 'At Time of Event'];

  @override
  void initState() {
    super.initState();
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    // Initialize other variables or state
  }

  Future<void> _requestPermissions() async {
    if (Platform.isIOS || Platform.isMacOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
      flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

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
      notificationTimingWidgets.addAll(buildNotificationTimingFields(['days', 'hours', 'minutes']));
    }


    return Scaffold(
      appBar: AppBar(
        title: Text('Add Recurring Transaction'),
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
                decoration: InputDecoration(labelText: 'Name *'),
                validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
                onSaved: (value) => name = value!,
              ),
              SizedBox(height: 20),
              TextFormField(
                decoration: InputDecoration(labelText: 'Description'),
                onSaved: (value) => description = value ?? '',
              ),
              SizedBox(height: 20),
              TextFormField(
                decoration: InputDecoration(labelText: 'Amount (optional)'),
                keyboardType: TextInputType.number,
                onSaved: (value) => amount = value!.isEmpty ? null : double.parse(value),
              ),
              SizedBox(height: 20),
              DropdownButtonFormField(
                decoration: InputDecoration(labelText: 'Recurring Frequency'),
                value: frequency,
                onChanged: (String? newValue) => setState(() => frequency = newValue!),
                items: frequencies.map<DropdownMenuItem<String>>((String value) {
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
                  onChanged: (String? newValue) => setState(() => dayOfWeek = newValue!),
                  items: daysOfWeek.map<DropdownMenuItem<String>>((String value) {
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
                  }
                  setState(() => scheduleReminder = value && _notificationsEnabled);
                },
              ),
              ...notificationTimingWidgets,
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    child: Text('Submit'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    ),
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
          'Time Before Due (${unit.capitalize()}):', // Capitalize the first letter
          unit,
          unit == 'days' ? notificationDaysBefore
              : unit == 'hours' ? notificationHoursBefore
              : notificationMinutesBefore
      ));
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
                if (unit == 'days') notificationDaysBefore = newValue!;
                else if (unit == 'hours') notificationHoursBefore = newValue!;
                else if (unit == 'minutes') notificationMinutesBefore = newValue!;
              });
            },
            items: List<DropdownMenuItem<int>>.generate(
                unit == 'hours' ? 24 : 60, // Generate up to 22 for hours, 59 for minutes
                    (index) => DropdownMenuItem(value: index, child: Text('$index'))
            ),
          ),
        ],
      ),
    );
  }



  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // Save the data locally and set up notifications if needed
      // Navigate back or show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recurring Transaction added')),
      );
    }
  }
}

// Helper function to capitalize the first letter of a string
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
