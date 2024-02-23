import 'dart:convert';
import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:excel/excel.dart';
import 'package:expnz/database/AccountsDB.dart';
import 'package:expnz/database/CategoriesDB.dart';
import 'package:expnz/database/RecurringTransactionsDB.dart';
import 'package:expnz/database/TransactionsDB.dart';
import 'package:expnz/utils/NotificationListener.dart';
import 'package:expnz/widgets/AppWidgets/SelectAccountCard.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/global.dart';
import 'MainPage.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  bool _showImportOptions = false;
  bool _showExportOptions = false;
  bool _showDeleteOptions = false;
  int selectedImportAccountIndex = -1;
  int selectedExportAccountIndex = -1;
  String selectedImportAccountId = "";
  String selectedExportAccountId = "";
  bool _allowNotificationReading = false;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final AppNotificationListener _notificationListener = AppNotificationListener();

  String _lastAccountSyncTime = '';
  String _lastCategorySyncTime = '';
  String _lastTransactionSyncTime = '';
  String _lastRecurringTransactionSyncTime = '';

  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
    _loadLastSyncTimes();
  }

  Future<void> _loadLastSyncTimes() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lastAccountSyncTime = _formatDateTime(prefs.getString('lastAccountSyncTime'));
      _lastCategorySyncTime = _formatDateTime(prefs.getString('lastCategorySyncTime'));
      _lastTransactionSyncTime = _formatDateTime(prefs.getString('lastTransactionSyncTime'));
      _lastRecurringTransactionSyncTime = _formatDateTime(prefs.getString('lastRecurringTransactionSyncTime'));
    });
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return 'Not synced yet';
    DateTime dateTime = DateTime.parse(dateTimeStr);
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }

  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSetting = prefs.getBool('allowNotificationReading') ?? false;
    setState(() {
      _allowNotificationReading = savedSetting;
    });
  }

  Future<void> _resync(String type) async {
    String? userUid = FirebaseAuth.instance.currentUser?.uid;
    // Implement the resync logic here
    switch (type) {
      case 'Last Account Sync Time':
        if (userUid != null) {
          AccountsDB().fetchAccountsSince(DateTime.fromMillisecondsSinceEpoch(0), userUid);
        }
        break;
      case 'Last Category Sync Time':
        if (userUid != null) {
          CategoriesDB().fetchCategoriesSince(DateTime.fromMillisecondsSinceEpoch(0), userUid);
        }
        break;
      case 'Last Transaction Sync Time':
        if (userUid != null) {
          TransactionsDB().fetchTransactionsSince(DateTime.fromMillisecondsSinceEpoch(0), userUid);
        }
        break;
      case 'Last Recurring Transaction Sync Time':
        if (userUid != null) {
          RecurringTransactionDB().fetchRecurringTransactionsSince(DateTime.fromMillisecondsSinceEpoch(0), userUid);
        }
        break;
      default:
      // Handle unknown type
        break;
    }

    // After resync, update the last sync times
    _loadLastSyncTimes();
  }

  Future<bool> _checkNotificationPermission() async {
    /*print('starting');
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    print(packageInfo);
    final String packageName = packageInfo.packageName;
    print(packageName);
    final String? enabledNotificationListeners = await SystemChannels.platform.invokeMethod<String>('SystemSettings.getEnabledNotificationListeners');
    print(enabledNotificationListeners);
    return enabledNotificationListeners?.contains(packageName) ?? false;*/
    return true;
  }

  Future<void> _requestBatteryOptimization() async {
    if (Platform.isAndroid) {
      const AndroidIntent intent = AndroidIntent(
        action: 'android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
        data: 'package:com.techNova.ExpnZ.expnz',
      );
      await intent.launch();
    }
  }

  void _handleNotificationPermission(bool value) async {
    if (value) {
      bool isPermissionGranted = await _checkNotificationPermission();

      if (isPermissionGranted) {
        await _requestBatteryOptimization();

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
    // Add a section for Sync Information
    Column syncInfoSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sync Information',
          style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        _buildSyncInfoTile('Last Account Sync Time', _lastAccountSyncTime),
        _buildSyncInfoTile('Last Category Sync Time', _lastCategorySyncTime),
        _buildSyncInfoTile('Last Transaction Sync Time', _lastTransactionSyncTime),
        _buildSyncInfoTile('Last Recurring Transaction Sync Time', _lastRecurringTransactionSyncTime),
      ],
    );
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: Colors.blueGrey[900],
        appBar: AppBar(
          scrolledUnderElevation: 0.0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => HomePage()),
                    (Route<dynamic> route) => false,
              ); // Pops the current route off the navigation stack
            },
          ),
          automaticallyImplyLeading: false,
          title: const Text('Settings'),
          backgroundColor: Colors.blueGrey[900],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Data Management',
                  style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ListTile(
                  title: const Text('Import Data', style: TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.import_export, color: Colors.white),
                  onTap: () => setState(() {
                    _showImportOptions = !_showImportOptions;
                  }),
                ),
                if (_showImportOptions) _buildImportOptions(),
                ListTile(
                  title: const Text('Export Data', style: TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.import_export, color: Colors.white),
                  onTap: () => setState(() {
                    _showExportOptions = !_showExportOptions;
                  }),
                ),
                if (_showExportOptions) _buildExportOptions(),
                ListTile(
                  title: const Text('Clear Data', style: TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.delete, color: Colors.white),
                  onTap: () => setState(() {
                    _showDeleteOptions = !_showDeleteOptions;
                  }),
                ),
                if (_showDeleteOptions) _buildDeleteOptions(),
                const SizedBox(height: 20),
                syncInfoSection,
                const SizedBox(height: 20),
                const Text(
                  'Notification Management',
                  style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                // Toggle for reading notifications
                SwitchListTile(
                  title: const Text('Allow Reading of Notifications',
                      style: TextStyle(color: Colors.white)),
                  value: _allowNotificationReading, // Boolean variable to track the toggle state
                  onChanged: (bool value) {
                    setState(() {
                      _handleNotificationPermission(value);
                    });
                  },
                  secondary: const Icon(Icons.notifications_active, color: Colors.white),
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
          title: const Text('Import Transactions (Select an account)', style: TextStyle(color: Colors.white70)),
          leading: const Icon(Icons.arrow_right, color: Colors.white70),
          onTap: () {
            // Add your onTap logic here
          },
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 150, // set the height
              child: ValueListenableBuilder<Map<String, Map<String, dynamic>>>(
                valueListenable: accountsNotifier,
                builder: (context, accountsData, child) {
                  if (accountsData.isEmpty) {
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
                        final accountId = accountIds[index];
                        final account = accountsData[accountId]!;
                        Map<String, dynamic> currencyMap = jsonDecode(account[AccountsDB.accountCurrency]);
                        String currencyCode = currencyMap['code'] as String;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedImportAccountIndex = index;
                              selectedImportAccountId = accountId; // Using the document ID as account ID
                              _showImportTemplateDialog(account[AccountsDB.accountName], selectedImportAccountId, account[AccountsDB.accountType]);
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
                            isSelected: index == selectedImportAccountIndex,
                          ),
                        );
                      },
                    );
                  }
                },
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
          title: const Text('Export Transactions (Select Account)', style: TextStyle(color: Colors.white70)),
          leading: const Icon(Icons.arrow_right, color: Colors.white70),
          onTap: () {

          },
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 150, // set the height
              child: ValueListenableBuilder<Map<String, Map<String, dynamic>>>(
                valueListenable: accountsNotifier,
                builder: (context, accountsData, child) {
                  if (accountsData.isEmpty) {
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
                        final accountId = accountIds[index];
                        final account = accountsData[accountId]!;
                        Map<String, dynamic> currencyMap = jsonDecode(account[AccountsDB.accountCurrency]);
                        String currencyCode = currencyMap['code'] as String;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedExportAccountIndex = index;
                              selectedExportAccountId = accountId; // Using the document ID as account ID
                              _exportToExcel();
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
                            isSelected: index == selectedExportAccountIndex,
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        )
      ],
    );
  }
  Future<void> _exportToExcel() async {
    try {
      // Prompt the user to select a location to save the file
      String? outputFile = await _pickSaveLocation();
      if (outputFile != null) {
        // Generate the Excel file
        var excel = Excel.createExcel();
        Sheet sheetObject = excel['Sheet1'];

        // TODO: Add your data to the sheet
        // For example, sheetObject.appendRow(["Date", "Description", "Amount"]);

        // Save the file
        var fileBytes = excel.save();
        File(outputFile)
          ..createSync(recursive: true)
          ..writeAsBytesSync(fileBytes!);

        // Inform the user of success
        print('Excel file saved successfully!');
      }
    } catch (e) {
      print('Error exporting to Excel: $e');
    }
  }

  Future<String?> _pickSaveLocation() async {
    //save the file in temp location instead and share it
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Please select an output file:',
      fileName: 'Transactions.xlsx',
    );

    return outputFile;
  }


  Widget _buildSyncInfoTile(String title, String syncTime) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(syncTime, style: const TextStyle(color: Colors.white70)),
      trailing: IconButton(
        icon: const Icon(Icons.sync, color: Colors.white),
        onPressed: () {
          _resync(title);
          showSyncingDialog(context);
        },
      ),
    );
  }

  Widget _buildDeleteOptions() {
    return Column(
      children: [
        ListTile(
          title: const Text('Clear All Transactions, Accounts, and Categories', style: TextStyle(color: Colors.white70)),
          leading: const Icon(Icons.arrow_right, color: Colors.white70),
          onTap: () => _clearData(context, clearAll: true),
        ),
        ListTile(
          title: const Text('Clear All Transactions and Categories', style: TextStyle(color: Colors.white70)),
          leading: const Icon(Icons.arrow_right, color: Colors.white70),
          onTap: () => _clearData(context, clearTransactions: true, clearCategories: true),
        ),
        ListTile(
          title: const Text('Clear All Transactions and Accounts', style: TextStyle(color: Colors.white70)),
          leading: const Icon(Icons.arrow_right, color: Colors.white70),
          onTap: () => _clearData(context, clearTransactions: true, clearAccounts: true),
        ),
        ListTile(
          title: const Text('Clear Only All Transactions', style: TextStyle(color: Colors.white70)),
          leading: const Icon(Icons.arrow_right, color: Colors.white70),
          onTap: () => _clearData(context, clearTransactions: true),
        ),
      ],
    );
  }

  void _clearData(BuildContext context, {bool clearAll = false, bool clearTransactions = false, bool clearAccounts = false, bool clearCategories = false}) async {
    // Show confirmation dialog before clearing data
    /*bool confirm = await _showConfirmationDialog(context);
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
    );*/
  }

  void _showImportTemplateDialog(String selectedAccountName, String selectedAccountId, String accountType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Import Template for transactions"),
          content: SingleChildScrollView(
              child: accountType == 'Cash/Wallet' ? const ListBody(
                children: <Widget>[
                  Text('Expected Excel format:'),
                  Text('Column 1: Type (Income/Expense)'),
                  Text('Column 2: Name'),
                  Text('Column 3: Description'),
                  Text('Column 4: Expense Amount'),
                  Text('Column 5: Actual Amount'),
                  Text('Column 6: DateTime (YYYY-MM-DD HH:MM)'),
                  Text('Column 7: Categories (comma-separated)'),
                ],
              ) : const ListBody(
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
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Choose File'),
              onPressed: () async {
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['xlsx'],
                );

                if (result != null) {
                  File file = File(result.files.single.path!);
                  _validateExcelFile(file, context, accountType);
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
  void _validateExcelFile(File file, BuildContext context, String accountType) async {
    var bytes = File(file.path).readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);

    if (excel.tables.isNotEmpty) {
      var table = excel.tables.keys.first;
      List<List<dynamic>> rows = excel.tables[table]?.rows ?? [];
      if (rows.isNotEmpty) {
        var headerRow = rows.first.map((cell) => (cell as Data?)?.value?.toString()).toList();
        // Checking if the header row contains the expected columns
        // Determine the expected header based on account type
        List<String> expectedHeader = accountType == 'Cash/Wallet'
            ? ['Type', 'Name', 'Description', 'Expense Amount', 'Actual Amount', 'DateTime', 'Categories']
            : ['Type', 'Name', 'Description', 'Amount', 'DateTime', 'Categories'];

        // Checking if the header row contains the expected columns
        bool isValidHeader = headerRow.length >= expectedHeader.length &&
            List.generate(expectedHeader.length, (index) => headerRow[index] == expectedHeader[index]).every((element) => element);

        if (isValidHeader) {
          _validateDataRows(rows, context, accountType);
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
  Future<void> _validateDataRows(List<List<dynamic>> rows, BuildContext context, String accountType) async {
    List<String> errorMessages = [];
    List<String> categoriesToCreate = [];
    List<Map<String, dynamic>> transactionsToCreate = [];

    var categoriesData = categoriesNotifier.value;

    for (int i = 1; i < rows.length; i++) { // Start from 1 to skip the header row
      var row = rows[i];

      bool errorsInRow = false;

      // Initialize cell values
      var typeCell = _getCellData(row, 0);
      var nameCell = _getCellData(row, 1);
      var descriptionCell = _getCellData(row, 2);
      var dateTimeCell = _getCellData(row, accountType == 'Cash/Wallet' ? 5 : 4);
      var categoriesCell = _getCellData(row, accountType == 'Cash/Wallet' ? 6 : 5);

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
      /*if (!_isValidAmount(amountCell)) {
        errorsInRow = true;
        errorMessages.add('Row ${i + 1}, Column 4: Invalid amount "$amountCell"');
      }*/
      if (!_isValidDateTime(dateTimeCell)) {
        errorsInRow = true;
        errorMessages.add('Row ${i + 1}, Column 5: Invalid date time "$dateTimeCell"');
      }
      if (categoriesCell.isEmpty) {
        errorMessages.add('Row ${i + 1}, Column 6: Categories are empty');
        errorsInRow = true;
      }

      String expenseAmountCell = '';
      String actualAmountCell = '';

      if (accountType == 'Cash/Wallet') {
        expenseAmountCell = _getCellData(row, 3);
        actualAmountCell = _getCellData(row, 4);

        if (!_isValidAmount(expenseAmountCell)) {
          errorsInRow = true;
          errorMessages.add('Row ${i + 1}, Column 4: Invalid expense amount "$expenseAmountCell"');
        }

        if (!_isValidAmount(actualAmountCell)) {
          errorsInRow = true;
          errorMessages.add('Row ${i + 1}, Column 5: Invalid actual amount "$actualAmountCell"');
        }

        if (_isValidAmount(expenseAmountCell) && _isValidAmount(actualAmountCell)) {
          double? expenseAmountValue = double.tryParse(expenseAmountCell) ?? 0.0;
          double? actualAmountValue = double.tryParse(actualAmountCell) ?? 0.0;

          if (expenseAmountValue < actualAmountValue) {
            errorsInRow = true;
            errorMessages.add('Row ${i + 1}, Column 4, 5: Expense amount should be greater than or equal to the actual amount');
          }
        }

      } else {
        var amountCell = _getCellData(row, 3);

        if (!_isValidAmount(amountCell)) {
          errorsInRow = true;
          errorMessages.add('Row ${i + 1}, Column 4: Invalid amount "$amountCell"');
        }
      }


      // Check if existing categories
      var categoryList = categoriesCell.split(',');
      for (var categoryName in categoryList) {
        var categoryExists = categoriesData.values.any((category) => category['name'].toString().trim().toLowerCase() == categoryName.trim().toLowerCase());

        if (!categoryExists && !categoriesToCreate.contains(categoryName.trim())) {
          categoriesToCreate.add(categoryName.trim());
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
          TransactionsDB.transactionType: typeCell.toLowerCase(),  // income, expense or transfer
          TransactionsDB.transactionName: nameCell,
          TransactionsDB.transactionDescription: descriptionCell,
          TransactionsDB.transactionAmount: double.tryParse(expenseAmountCell) ?? 0.0, // Convert to double
          TransactionsDB.transactionActualPrice: double.tryParse(actualAmountCell) ?? 0.0, // Convert to double
          TransactionsDB.transactionBalance: (double.tryParse(expenseAmountCell) ?? 0.0) - (double.tryParse(actualAmountCell) ?? 0.0),
          TransactionsDB.transactionDate: DateFormat('yyyy-MM-dd').format(parsedDate),
          TransactionsDB.transactionTime: parsedTime.format(context),
          TransactionsDB.transactionAccountId: selectedImportAccountId,
          TransactionsDB.transactionCategoryIDs: categoriesCell,
        };
        transactionsToCreate.add(row);
      }
    }

    if (errorMessages.isNotEmpty) {
      _showDetailedErrorDialog(context, errorMessages);
    } else {
      //if there are uncreated categories
      _showCreateCategoriesDialog(context, categoriesToCreate, () async {
        _updateCategoryIdsInTransactions(transactionsToCreate);
        // Create transactions
        _createTransactions(transactionsToCreate, context);
        Navigator.of(context).pop();
      });
    }
  }
  bool _isValidAmount(String amount) {
    return double.tryParse(amount) != null;
  }
  bool _isValidDateTime(String date) {
    return DateTime.tryParse(date) != null;
  }

  void _updateCategoryIdsInTransactions(List<Map<String, dynamic>> transactions) {
    final categoriesData = categoriesNotifier.value;

    for (var transaction in transactions) {
      var categoryNames = (transaction[TransactionsDB.transactionCategoryIDs] as String).split(',');
      var updatedCategoryIds = _getCategoryIdsFromNames(categoryNames, categoriesData);
      transaction[TransactionsDB.transactionCategoryIDs] = updatedCategoryIds.join(',');
    }
  }

  List<String> _getCategoryIdsFromNames(List<String> categoryNames, Map<String, Map<String, dynamic>> categoriesData) {
    List<String> categoryIds = [];

    for (var name in categoryNames) {
      var foundEntry = categoriesData.entries.firstWhere(
              (entry) => entry.value['name'].toString().toLowerCase() == name.toLowerCase(),
          orElse: () => const MapEntry<String, Map<String, dynamic>>("_noKeyFound", {}) // Return a placeholder MapEntry if not found
      );

      if (foundEntry.key != "_noKeyFound") {
        categoryIds.add(foundEntry.key);
      }
    }

    return categoryIds;
  }


  Future<void> _createTransactions(List<Map<String, dynamic>> transactionsData, BuildContext context) async {
    int processedCount = 0;
    int total = transactionsData.length;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Processing transactions..."),
              const SizedBox(height: 15),
              LinearProgressIndicator(value: processedCount / total),
              Text("$processedCount of $total processed"),
            ],
          ),
        );
      },
    );

    bool result = await TransactionsDB().insertTransactions(transactionsData);
    if (result) {
      _showSuccessPrompt(transactionsData.length);
    } else {
      _showErrorDialog(context, "Could not insert transactions");
    }

    Navigator.of(context).pop();
  }

  void showSyncingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // User must not close the dialog
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              Icon(Icons.sync, color: Colors.blue),
              SizedBox(width: 20),
              Text("Syncing in background"),
            ],
          ),
        );
      },
    );

    // Close the dialog after a short delay
    Future.delayed(Duration(seconds: 2), () {
      Navigator.of(context).pop();
    });
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
          title: const Text("Error"),
          content: Text(errorMessage),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
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
          title: const Text("Errors in Imported Data"),
          content: SingleChildScrollView(
            child: ListBody(
              children: errorMessages.map((message) => Text(message)).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
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
          title: const Text("Create Categories"),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text('The following categories do not exist and need to be created:'),
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
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Create'),
              onPressed: () {
                CategoriesDB().createCategories(categoriesToCreate, context).then((_) {
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
}
