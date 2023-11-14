import 'dart:convert';

import 'package:expnz/database/AccountsDB.dart';
import 'package:expnz/models/AccountsModel.dart';
import 'package:expnz/widgets/AppWidgets/SelectAccountCard.dart';
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
              onPressed: () {
                // Implement file picker and validation logic
              },
            ),
          ],
        );
      },
    );
  }
}
