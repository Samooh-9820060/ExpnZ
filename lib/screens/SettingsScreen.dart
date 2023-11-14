import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _showImportOptions = false;
  bool _showExportOptions = false;

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
        _buildButton('Import Accounts'),
        _buildButton('Import Categories'),
        _buildButton('Import Transactions'),
      ],
    );
  }

  Widget _buildExportOptions() {
    return Column(
      children: [
        _buildButton('Export Accounts'),
        _buildButton('Export Categories'),
        _buildButton('Export Transactions'),
      ],
    );
  }

  Widget _buildButton(String title) {
    return ListTile(
      title: Text(title, style: TextStyle(color: Colors.white70)),
      leading: Icon(Icons.arrow_right, color: Colors.white70),
      onTap: () {
        // Implement your logic for each button
      },
    );
  }
}
