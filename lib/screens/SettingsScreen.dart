import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:expnz/database/AccountsDB.dart';
import 'package:expnz/models/AccountsModel.dart';
import 'package:expnz/widgets/AppWidgets/SelectAccountCard.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _showImportOptions = false;
  bool _showExportOptions = false;
  int selectedAccoutIndex = -1;
  int selectedAccoutId = -1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Colors.blueGrey[700],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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

                }),
              ),
            ],
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
                Text('Column 5: Date (YYYY-MM-DD)'),
                Text('Column 6: Time (HH:MM)'),
                Text('Column 7: Categories (comma-separated)'),
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
        if (headerRow.length >= 7 &&
            headerRow[0] == 'Type' &&
            headerRow[1] == 'Name' &&
            headerRow[2] == 'Description' &&
            headerRow[3] == 'Amount' &&
            headerRow[4] == 'Date' &&
            headerRow[5] == 'Time' &&
            headerRow[6] == 'Categories') {
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
  void _validateDataRows(List<List<dynamic>> rows, BuildContext context) {
    List<int> invalidRows = [];
    for (int i = 1; i < rows.length; i++) { // Start from 1 to skip the header row
      var row = rows[i];
      var typeCell = row.length > 0 ? (row[0] as Data?)?.value?.toString() : '';
      if (typeCell != 'Income' && typeCell != 'Expense') {
        invalidRows.add(i + 1); // Adding 1 because row index starts from 0
      }
    }

    if (invalidRows.isNotEmpty) {
      String errorMessage = 'Invalid type found in rows: ${invalidRows.join(', ')}.';
      _showErrorDialog(context, errorMessage);
    } else {
      // Data is valid, proceed with further processing
    }
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
}
