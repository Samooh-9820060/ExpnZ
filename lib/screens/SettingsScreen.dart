import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:expnz/database/AccountsDB.dart';
import 'package:expnz/database/CategoriesDB.dart';
import 'package:expnz/database/TransactionsDB.dart';
import 'package:expnz/models/AccountsModel.dart';
import 'package:expnz/models/CategoriesModel.dart';
import 'package:expnz/models/TransactionsModel.dart';
import 'package:expnz/utils/NotificationListener.dart';
import 'package:expnz/widgets/AppWidgets/SelectAccountCard.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:notifications/notifications.dart';

import 'MainPage.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _showImportOptions = false;
  bool _showExportOptions = false;
  bool _showDeleteOptions = false;
  int selectedAccoutIndex = -1;
  int selectedAccoutId = -1;
  bool _allowNotificationReading = false;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final AppNotificationListener _notificationListener = AppNotificationListener();

  
  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
  }

  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSetting = prefs.getBool('allowNotificationReading') ?? false;
    setState(() {
      _allowNotificationReading = savedSetting;
    });
  }

  Future<bool> _checkNotificationPermission() async {
    /*print('srartg');
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    print(packageInfo);
    final String packageName = packageInfo.packageName;
    print(packageName);
    final String? enabledNotificationListeners = await SystemChannels.platform.invokeMethod<String>('SystemSettings.getEnabledNotificationListeners');
    print(enabledNotificationListeners);
    return enabledNotificationListeners?.contains(packageName) ?? false;*/
    return true;
  }

  void _handleNotificationPermission(bool value) async {
    print('started');
    if (value) {
      bool isPermissionGranted = await _checkNotificationPermission();
      print('went here');

      if (isPermissionGranted) {
        print('turning on permission');
        _notificationListener.stopListening();
        _notificationListener.startListening();
      }
    } else {
      _notificationListener.stopListening();
    }
    // Update the shared preferences and UI state
    _updateNotificationReadingPreference(value);
  }

  Future<void> _updateNotificationReadingPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('allowNotificationReading', value);
    setState(() {
      _allowNotificationReading = value;
    });
  }


  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: Colors.blueGrey[900],
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => HomePage()),
                    (Route<dynamic> route) => false,
              ); // Pops the current route off the navigation stack
            },
          ),
          automaticallyImplyLeading: false,
          title: Text('Settings'),
          backgroundColor: Colors.blueGrey[700],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                Text(
                  'Data Management',
                  style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                ListTile(
                  title: Text('Import Data', style: TextStyle(color: Colors.white)),
                  trailing: Icon(Icons.import_export, color: Colors.white),
                  onTap: () => setState(() {
                    _showImportOptions = !_showImportOptions;
                  }),
                ),
                if (_showImportOptions) _buildImportOptions(),
                ListTile(
                  title: Text('Export Data', style: TextStyle(color: Colors.white)),
                  trailing: Icon(Icons.import_export, color: Colors.white),
                  onTap: () => setState(() {
                    _showExportOptions = !_showExportOptions;
                  }),
                ),
                if (_showExportOptions) _buildExportOptions(),
                ListTile(
                  title: Text('Clear Data', style: TextStyle(color: Colors.white)),
                  trailing: Icon(Icons.delete, color: Colors.white),
                  onTap: () => setState(() {
                    _showDeleteOptions = !_showDeleteOptions;
                  }),
                ),
                if (_showDeleteOptions) _buildDeleteOptions(),
                SizedBox(height: 20),
                Text(
                  'Notification Management',
                  style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                // Toggle for reading notifications
                SwitchListTile(
                  title: Text('Allow Reading of Notifications',
                      style: TextStyle(color: Colors.white)),
                  value: _allowNotificationReading, // Boolean variable to track the toggle state
                  onChanged: _handleNotificationPermission,
                  secondary: Icon(Icons.notifications_active, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImportOptions() {
    return Column(
      children: [
        ListTile(
          title: Text('Import Transactions (Select an account)', style: TextStyle(color: Colors.white70)),
          leading: Icon(Icons.arrow_right, color: Colors.white70),
          onTap: () {

          },
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                              _showImportTemplateDialog(account[AccountsDB.accountName], selectedAccoutId);
                            });
                          },
                          child: AccountCard(
                            accountId: account[AccountsDB.accountId],
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
                }, // This is where the missing '}' should be placed.
              ),
            ),
          ],
        )
      ],
    );
  }
  Widget _buildExportOptions() {
    return Column(
      children: [
        ListTile(
          title: Text('Export Transactions', style: TextStyle(color: Colors.white70)),
          leading: Icon(Icons.arrow_right, color: Colors.white70),
          onTap: () {

          },
        )
      ],
    );
  }
  Widget _buildDeleteOptions() {
    return Column(
      children: [
        ListTile(
          title: Text('Clear All Transactions, Accounts, and Categories', style: TextStyle(color: Colors.white70)),
          leading: Icon(Icons.arrow_right, color: Colors.white70),
          onTap: () => _clearData(context, clearAll: true),
        ),
        ListTile(
          title: Text('Clear All Transactions and Categories', style: TextStyle(color: Colors.white70)),
          leading: Icon(Icons.arrow_right, color: Colors.white70),
          onTap: () => _clearData(context, clearTransactions: true, clearCategories: true),
        ),
        ListTile(
          title: Text('Clear All Transactions and Accounts', style: TextStyle(color: Colors.white70)),
          leading: Icon(Icons.arrow_right, color: Colors.white70),
          onTap: () => _clearData(context, clearTransactions: true, clearAccounts: true),
        ),
        ListTile(
          title: Text('Clear Only All Transactions', style: TextStyle(color: Colors.white70)),
          leading: Icon(Icons.arrow_right, color: Colors.white70),
          onTap: () => _clearData(context, clearTransactions: true),
        ),
      ],
    );
  }

  void _clearData(BuildContext context, {bool clearAll = false, bool clearTransactions = false, bool clearAccounts = false, bool clearCategories = false}) async {
    // Show confirmation dialog before clearing data
    bool confirm = await _showConfirmationDialog(context);
    if (!confirm) return;

    if (clearAll || clearTransactions) {
      // Clear transactions logic
      final transactionsModel = Provider.of<TransactionsModel>(context, listen: false);
      await transactionsModel.clearTransactions();
    }
    if (clearAll || clearAccounts) {
      // Clear accounts logic
      final accountsModel = Provider.of<AccountsModel>(context, listen: false);
      await accountsModel.clearAccounts();
    }
    if (clearAll || clearCategories) {
      // Clear categories logic
      final categoriesModel = Provider.of<CategoriesModel>(context, listen: false);
      await categoriesModel.clearCategories();
    }

    Navigator.of(context).pop(); // Close the dialog
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Data cleared successfully')),
    );
  }

  void _showImportTemplateDialog(String selectedAccountName, int selectedAccountId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Import Template for transactions"),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Expected Excel format:'),
                Text('Column 1: Type (Income/Expense)'),
                Text('Column 2: Name'),
                Text('Column 3: Description'),
                Text('Column 4: Amount'),
                Text('Column 5: DateTime (YYYY-MM-DD HH:MM)'),
                Text('Column 6: Categories (comma-separated)'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Choose File'),
              onPressed: () async {
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['xlsx'],
                );

                if (result != null) {
                  File file = File(result.files.single.path!);
                  _validateExcelFile(file, context);
                } else {
                  // User canceled the picker
                }
              },
            ),
          ],
        );
      },
    );
  }
  void _validateExcelFile(File file, BuildContext context) async {
    var bytes = File(file.path).readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);

    if (excel.tables.isNotEmpty) {
      var table = excel.tables.keys.first;
      List<List<dynamic>> rows = excel.tables[table]?.rows ?? [];
      print('rows $rows');
      if (rows.isNotEmpty) {
        var headerRow = rows.first.map((cell) => (cell as Data?)?.value?.toString()).toList();
        // Checking if the header row contains the expected columns
        if (headerRow.length >= 6 &&
            headerRow[0] == 'Type' &&
            headerRow[1] == 'Name' &&
            headerRow[2] == 'Description' &&
            headerRow[3] == 'Amount' &&
            headerRow[4] == 'DateTime' &&
            headerRow[5] == 'Categories') {
          _validateDataRows(rows, context);
        } else {
          _showErrorDialog(context, 'Invalid file format. Please ensure the file matches the template.');
        }
      } else {
        _showErrorDialog(context, 'The file is empty.');
      }
    } else {
      _showErrorDialog(context, 'No tables found in the file.');
    }
  }

  String _getCellData(List<dynamic> row, int index) {
    return row.length > index ? (row[index] as Data?)?.value?.toString() ?? '' : '';
  }
  Future<void> _validateDataRows(List<List<dynamic>> rows, BuildContext context) async {
    List<String> errorMessages = [];
    List<String> categoriesToCreate = [];
    List<Map<String, dynamic>> transactionsToCreate = [];

    var categoriesModel = Provider.of<CategoriesModel>(context, listen: false);

    for (int i = 1; i < rows.length; i++) { // Start from 1 to skip the header row
      var row = rows[i];

      bool errorsInRow = false;

      // Initialize cell values
      var typeCell = _getCellData(row, 0);
      var nameCell = _getCellData(row, 1);
      var descriptionCell = _getCellData(row, 2);
      var amountCell = _getCellData(row, 3);
      var dateTimeCell = _getCellData(row, 4);
      var categoriesCell = _getCellData(row, 5);

      // Validate each cell
      if (typeCell.toLowerCase() != 'income' && typeCell.toLowerCase() != 'expense') {
        errorsInRow = true;
        errorMessages.add('Row ${i + 1}, Column 1: Invalid type "$typeCell"');
      }
      if (nameCell.isEmpty) {
        errorsInRow = true;
        errorMessages.add('Row ${i + 1}, Column 2: Name is empty');
      }
      if (descriptionCell.isEmpty) {
        errorsInRow = true;
        errorMessages.add('Row ${i + 1}, Column 3: Description is empty');
      }
      if (!_isValidAmount(amountCell)) {
        errorsInRow = true;
        errorMessages.add('Row ${i + 1}, Column 4: Invalid amount "$amountCell"');
      }
      if (!_isValidDateTime(dateTimeCell)) {
        errorsInRow = true;
        errorMessages.add('Row ${i + 1}, Column 5: Invalid date time "$dateTimeCell"');
      }
      if (categoriesCell.isEmpty) {
        errorMessages.add('Row ${i + 1}, Column 6: Categories are empty');
        errorsInRow = true;
      }

      //check if existing categories
      var categoryList = categoriesCell.split(',');
      for (var category in categoryList) {
        if (categoriesModel.getCategoryByName(category) == null && !categoriesToCreate.contains(category)) {
          categoriesToCreate.add(category.trim());
        }
      }

      if (errorsInRow == false) {
        var dateTimeParts = dateTimeCell.split('T');
        var datePart = dateTimeParts[0];
        var timePart = dateTimeParts.length > 1 ? dateTimeParts[1] : '00:00';
        var parsedDate = DateFormat('yyyy-MM-dd').parse(datePart);
        var timeParts = timePart.split(':');
        var parsedTime = TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));

        Map<String, dynamic> row = {
          TransactionsDB.columnType: typeCell.toLowerCase(),  // income, expense or transfer
          TransactionsDB.columnName: nameCell,
          TransactionsDB.columnDescription: descriptionCell,
          TransactionsDB.columnAmount: amountCell,
          TransactionsDB.columnDate: DateFormat('yyyy-MM-dd').format(parsedDate),
          TransactionsDB.columnTime: parsedTime.format(context),
          TransactionsDB.columnAccountId: selectedAccoutId,
          TransactionsDB.columnCategories: categoriesCell,
        };
        transactionsToCreate.add(row);
      }
    }

    if (errorMessages.isNotEmpty) {
      _showDetailedErrorDialog(context, errorMessages);
    } else {
      //if there are uncreated categories
      _showCreateCategoriesDialog(context, categoriesToCreate, () async {
        // Refresh categories model to include newly created categories
        await categoriesModel.fetchCategories();
        // Update category IDs in transactions
        _updateCategoryIdsInTransactions(transactionsToCreate, categoriesModel);
        // Create transactions
        _createTransactions(transactionsToCreate, context);
        Navigator.of(context).pop();
      });
    }
  }
  bool _isValidAmount(String amount) {
    // Implement your logic to validate amount
    // For example, checking if it's a valid number
    return double.tryParse(amount) != null;
  }
  bool _isValidDateTime(String date) {
    return DateTime.tryParse(date) != null;
  }
  Future<void> _createCategories(List<String> categoriesToCreate, BuildContext context) async {
    final categoriesModel = Provider.of<CategoriesModel>(context, listen: false);
    for (var categoryName in categoriesToCreate) {
      // Default values for icon, color, and description
      final defaultIcon = Icons.category;
      final defaultColor = Colors.blue;
      final description = categoryName;

      // Prepare data to insert
      Map<String, dynamic> row = {
        'name': categoryName,
        'description': description,
        'color': defaultColor.value,
        'iconCodePoint': defaultIcon.codePoint,
        'iconFontFamily': defaultIcon.fontFamily,
        'iconFontPackage': defaultIcon.fontPackage,
        'selectedImageBlob': null, // No image
      };

      // Insert new category
      final int? id = await CategoriesDB().insertCategory(row);
      if (id != null && id > 0) {
        // Category added successfully
        print("Category '$categoryName' added successfully.");
      } else {
        // Error handling if needed
        print("Failed to add category '$categoryName'.");
      }
    }

    // Refresh the categories list
    return categoriesModel.fetchCategories();
  }
  void _updateCategoryIdsInTransactions(List<Map<String, dynamic>> transactions, CategoriesModel categoriesModel) {
    for (var transaction in transactions) {
      var categoryNames = (transaction[TransactionsDB.columnCategories] as String).split(',');
      var updatedCategoryIds = categoriesModel.getCategoryIdsFromNames(categoryNames);
      transaction[TransactionsDB.columnCategories] = updatedCategoryIds;
    }
  }
  Future<void> _createTransactions(List<Map<String, dynamic>> transactionsData, BuildContext context) async {
    await _showLoadingDialog(context, "Processing transactions...");
    final transactionsModel = Provider.of<TransactionsModel>(context, listen: false);
    for (var transactionData in transactionsData) {
      // You can modify this to suit your transaction creation logic
      final id = await TransactionsDB().insertTransaction(transactionData);
      if (id != null && id > 0) {
        print("Transaction added successfully.");
      } else {
        print("Failed to add transaction.");
      }
    }
    Navigator.of(context).pop(); // Dismiss the loading dialog
    transactionsModel.fetchTransactions();
    _showSuccessPrompt(transactionsData.length);
  }

  Future<void> _showLoadingDialog(BuildContext context, String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must not close the dialog.
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Expanded(child: Text(message)),
            ],
          ),
        );
      },
    );
  }
  void _showSuccessPrompt(int transactionsCount) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text('$transactionsCount transactions added successfully')),
    );
  }

  void _showErrorDialog(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Error"),
          content: Text(errorMessage),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  void _showDetailedErrorDialog(BuildContext context, List<String> errorMessages) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Errors in Imported Data"),
          content: SingleChildScrollView(
            child: ListBody(
              children: errorMessages.map((message) => Text(message)).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
  void _showCreateCategoriesDialog(BuildContext context, List<String> categoriesToCreate, Function onCategoriesCreated) {
    if (categoriesToCreate.isEmpty) {
      onCategoriesCreated();
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Create Categories"),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('The following categories do not exist and need to be created:'),
                for (var category in categoriesToCreate)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(category),
                  ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Create'),
              onPressed: () {
                _createCategories(categoriesToCreate, context).then((_) {
                  Navigator.of(context).pop();
                  onCategoriesCreated();
                });
              },
            ),
          ],
        );
      },
    );
  }
  Future<bool> _showConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to clear this data? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Confirm'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    ) ?? false;
  }
}
