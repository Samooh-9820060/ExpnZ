import 'dart:convert';

import 'package:expnz/widgets/SimpleWidgets/ExpnZButton.dart';
import 'package:expnz/widgets/SimpleWidgets/ModernSnackBar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../database/AccountsDB.dart';
import '../database/TransactionsDB.dart';
import '../widgets/AppWidgets/BuildCategoriesDropdown.dart';
import '../widgets/AppWidgets/CategoryChip.dart';
import '../widgets/AppWidgets/SearchTransactionCard.dart';
import '../widgets/AppWidgets/SelectAccountCard.dart';
import 'AddTransaction.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<List<String>> selectedAccountsNotifier = ValueNotifier<List<String>>([]);
  List<String> selectedAccounts = [];
  List<Map<String, dynamic>> filteredConditionalTransactions = [];

  final TextEditingController _categoryIncludeSearchController = TextEditingController();
  final TextEditingController _categoryExcludeSearchController = TextEditingController();

  bool _showIncludeDropdown = false;
  List<Map<String, dynamic>> selectedIncludeCategoriesList = [];
  bool _showExcludeDropdown = false;
  List<Map<String, dynamic>> selectedExcludeCategoriesList = [];

  DateTime selectedFromDate = DateTime(DateTime.now().year, 1, 1);
  DateTime selectedToDate = DateTime(DateTime.now().year, 12, 31);

  bool _cancelOngoingFiltering = false;
  ScrollController _scrollController = ScrollController();
  int _currentMax = 10;

  /*Future<void> _loadMore() async {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      // Load more data here
      setState(() {
        _currentMax += 10; // Increase the max items to display
      });

      String searchText = _searchController.text.toLowerCase();
      if (filteredConditionalTransactions == null || filteredConditionalTransactions.isEmpty) {
        await Provider.of<TransactionsModel>(context, listen: false)
            .filterTransactions(context, searchText, null, null, null, null, null, null, 100, false);
      } else {
        await Provider.of<TransactionsModel>(context, listen: false)
            .filterTransactions(context, searchText, filteredConditionalTransactions);
      }
    }
  }*/


    @override
    void initState() {
      super.initState();
      //_scrollController.addListener(_loadMore);
      _searchController.addListener(_filterTransactions);
      // Fetch accounts and populate selectedAccounts
      _fetchAccountsData();
      selectedAccountsNotifier.addListener(() {
        setState(() {
          selectedAccounts = selectedAccountsNotifier.value;
        });
      });

      selectedAccountsNotifier.addListener(() {
        setState(() {
          selectedAccounts = selectedAccountsNotifier.value;
        });
      });
    }

    Future<void> _fetchAccountsData() async {
      final localAccountsData = await AccountsDB().getLocalAccounts();
      if (localAccountsData != null && localAccountsData.isNotEmpty) {
        List<String> accountIds = localAccountsData.keys.toList();
        selectedAccountsNotifier.value = accountIds;
      }
    }

  void _filterTransactions() {
    String searchText = _searchController.text.toLowerCase();

    if (searchText.length > 3) {
      // Signal to cancel any ongoing filtering operation
      _cancelOngoingFiltering = true;

      // Delay to ensure any ongoing operation has time to stop
      Future.delayed(const Duration(milliseconds: 100), () async {
        // Reset the flag and start new filtering
        _cancelOngoingFiltering = false;
        filteredConditionalTransactions = await TransactionsDB().filterTransactions(searchText, selectedAccounts);


        // Check if the operation should be canceled at significant steps
        if (_cancelOngoingFiltering) return;

        setState(() {}); // Trigger a rebuild to update the UI with filtered data
      });
    } else {
      filteredConditionalTransactions.clear();
      setState(() {

      });
    }
  }

  @override
  void dispose() {
    _categoryIncludeSearchController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void updateFromDate(DateTime newDate) {
    setState(() {
      selectedFromDate = newDate;
    });
  }
  void updateToDate(DateTime newDate) {
    setState(() {
      selectedToDate = newDate;
    });
  }

  /*Future<void> clearFilter() async {
    selectedFromDate = DateTime(DateTime.now().year, 1, 1);
    selectedToDate = DateTime(DateTime.now().year, 12, 31);
    selectedIncludeCategoriesList = [];
    selectedExcludeCategoriesList = [];
    _categoryIncludeSearchController.text = '';
    _categoryExcludeSearchController.text = '';
    _showExcludeDropdown = false;
    _showIncludeDropdown = false;
    filteredConditionalTransactions = [];

    // Fetch all accounts and populate selectedAccounts with their IDs
    AccountsModel accountsModel = Provider.of<AccountsModel>(context, listen: false);
    if (accountsModel.accounts.isNotEmpty) {
      selectedAccounts = accountsModel.accounts.map<int>((account) {
        return account[AccountsDB.accountId] as int;
      }).toList();

      // Update the ValueNotifier
      selectedAccountsNotifier.value = selectedAccounts;
    } else {
      selectedAccounts = [];
    }

    Navigator.pop(context, true);
    showModernSnackBar(context: context, message: 'Filters cleared', backgroundColor: Colors.green);
  }*/

  /*void _showFilterDialog(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      barrierColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (BuildContext context) {

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: MediaQuery.of(context).viewInsets.top,
              ),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.7,
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blueGrey,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        const Center(child: Text("Filter Conditions", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                        const SizedBox(height: 40),
                        const Text("Select Date Range", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // From Date Button
                              InkWell(
                                onTap: () async {
                                  DateTime? newDate = await showDatePicker(
                                    context: context,
                                    initialDate: selectedFromDate,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2101),
                                  );
                                  if (newDate != null && newDate != selectedFromDate) {
                                    modalSetState(() { // <-- Use the local modalSetState
                                      selectedFromDate = newDate;
                                    });
                                  }
                                },
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
                                      const SizedBox(width: 5),
                                      Text(
                                        DateFormat('yyyy-MM-dd').format(selectedFromDate),  // Replace 'selectedFromDate' with your variable
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // To Date Button
                              InkWell(
                                onTap: () async {
                                  DateTime? newDate = await showDatePicker(
                                    context: context,
                                    initialDate: selectedToDate,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2101),
                                  );
                                  if (newDate != null && newDate != selectedToDate) {
                                    modalSetState(() { // <-- Use the local modalSetState
                                      selectedToDate = newDate;
                                    });
                                  }
                                },
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
                                        DateFormat('yyyy-MM-dd').format(selectedToDate),  // Replace 'selectedToDate' with your variable
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
                        ),
                        // Account selection
                        const SizedBox(height: 20),
                        Builder(
                          builder: (context) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Select Accounts To Include In Search',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  height: 150, // set the height
                                  child: Consumer<AccountsModel>(
                                    builder: (context, accountsModel, child) {
                                      if (accountsModel.accounts.isEmpty) {
                                        return const Center(
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
                                                int currentAccountId = account[AccountsDB.accountId];
                                                modalSetState(() {
                                                  if (selectedAccounts.contains(currentAccountId)) {
                                                    selectedAccounts.remove(currentAccountId);
                                                  } else {
                                                    selectedAccounts.add(currentAccountId);
                                                  }
                                                });
                                              },
                                              child: Transform.scale(
                                                scale: 0.8, // Adjust this scale factor to your need
                                                child: AccountCard(
                                                  accountId: account[AccountsDB.accountId],
                                                  icon: IconData(
                                                    account[AccountsDB.accountIconCodePoint],
                                                    fontFamily: account[AccountsDB.accountIconFontFamily],
                                                    fontPackage: account[AccountsDB.accountIconFontPackage],
                                                  ),
                                                  currency: currencyCode,
                                                  accountName: account[AccountsDB.accountName],
                                                  horizontalMargin: 0,
                                                  verticalMargin: 0,
                                                  isSelected: selectedAccounts.contains(account[AccountsDB.accountId]),
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      }
                                    },
                                  ),
                                )
                              ],
                            );
                          },
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Your existing code for date selectors goes here

                            SizedBox(height: 20),

                            // Text headers for category selection
                            Text(
                              'Select Categories To Include In Search',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            SizedBox(height: 20),
                            TextField(
                              controller: _categoryIncludeSearchController,
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
                              onChanged: (value) {
                                modalSetState(() {
                                  _showIncludeDropdown = value.isNotEmpty;
                                });
                              },
                            ),
                            SizedBox(height: 10),
                            if (_showIncludeDropdown)
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
                                  child: Container(
                                    width: MediaQuery.of(context).size.width, // Adjust as needed
                                    child: Consumer<CategoriesModel>(
                                      builder: (context, categoriesModel, child) {
                                        return buildCategoriesDropdown(
                                          categoriesModel,
                                          selectedIncludeCategoriesList,
                                          _categoryIncludeSearchController.text,
                                          modalSetState, // Assuming this is within a StatefulWidget and you have access to setState
                                          _showIncludeDropdown,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            SizedBox(height: 10),
                            Wrap(
                              spacing: 8.0,
                              runSpacing: 8.0,
                              children: List<Widget>.generate(
                                selectedIncludeCategoriesList.length,
                                    (int index) {
                                  final category = selectedIncludeCategoriesList[index];
                                  dynamic categoryIdRaw = category['id'];
                                  int categoryId = 0;

                                  if (categoryIdRaw is String) {
                                    categoryId = int.parse(categoryIdRaw);
                                  } else if (categoryIdRaw is int) {
                                    categoryId = categoryIdRaw;
                                  } else {
                                    // Handle error: unknown type
                                    print('Unknown type for category ID');
                                  }

                                  return CategoryChip(
                                    categoryId: categoryId,
                                    onTap: () {
                                      modalSetState(() {
                                        selectedIncludeCategoriesList.removeAt(index);
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Your existing code for date selectors goes here

                            SizedBox(height: 20),

                            // Text headers for category selection
                            Text(
                              'Select Categories To Exclude From Search',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            SizedBox(height: 20),
                            TextField(
                              controller: _categoryExcludeSearchController,
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
                              onChanged: (value) {
                                modalSetState(() {
                                  _showExcludeDropdown = value.isNotEmpty;
                                });
                              },
                            ),
                            SizedBox(height: 10),
                            if (_showExcludeDropdown)
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
                                  child: Container(
                                    width: MediaQuery.of(context).size.width, // Adjust as needed
                                    child: Consumer<CategoriesModel>(
                                      builder: (context, categoriesModel, child) {
                                        return buildCategoriesDropdown(
                                          categoriesModel,
                                          selectedExcludeCategoriesList,
                                          _categoryExcludeSearchController.text,
                                          modalSetState, // Assuming this is within a StatefulWidget and you have access to setState
                                          _showExcludeDropdown,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            SizedBox(height: 10),
                            Wrap(
                              spacing: 8.0,
                              runSpacing: 8.0,
                              children: List<Widget>.generate(
                                selectedExcludeCategoriesList.length,
                                    (int index) {
                                  final category = selectedExcludeCategoriesList[index];
                                  dynamic categoryIdRaw = category['id'];
                                  int categoryId = 0;

                                  if (categoryIdRaw is String) {
                                    categoryId = int.parse(categoryIdRaw);
                                  } else if (categoryIdRaw is int) {
                                    categoryId = categoryIdRaw;
                                  } else {
                                    // Handle error: unknown type
                                    print('Unknown type for category ID');
                                  }

                                  return CategoryChip(
                                    categoryId: categoryId,
                                    onTap: () {
                                      modalSetState(() {
                                        selectedExcludeCategoriesList.removeAt(index);
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                                child: ExpnZButton(label: 'Clear', onPressed: clearFilter, primaryColor: Colors.grey,)
                            ),
                            SizedBox(width: 10),
                            Expanded(
                                child: ExpnZButton(label: 'Filter', onPressed: FilterTransactions)
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        );
      },
    );
  }*/


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blueGrey[900],
        leading: BackButton(
          color: Colors.white,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 2), // Reduced padding
                decoration: BoxDecoration(
                  color: Colors.blueGrey[700],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          // Reduced padding
                          border: InputBorder.none,
                        ),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        //_showFilterDialog(context); // <-- Call the filter dialog here
                      },
                      borderRadius: BorderRadius.circular(30), // Tune this for your case
                      splashColor: Colors.blue.withOpacity(0.5),
                      radius: 20.0, // Adjust the radius to control the splash size
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.filter_alt,
                          color: filteredConditionalTransactions.isNotEmpty ? Colors.blue : Colors.white,
                          size: 20,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: _buildTransactionList(),
    );
  }

  Widget _buildTransactionList() {
    List<Map<String, dynamic>> transactionsToShow = _searchController.text.isNotEmpty
        ? filteredConditionalTransactions
        : filteredConditionalTransactions; // Or any other logic to determine the transactions to show

    if (transactionsToShow.isNotEmpty) {
      return ListView.builder(
        itemCount: transactionsToShow.length,
        controller: _scrollController,
        itemBuilder: (context, index) {
          // Retrieve each transaction by index
          Map<String, dynamic> transaction = transactionsToShow[index];

          return TransactionCard(
            transaction: transaction,
            onDelete: () {
              TransactionsDB().deleteTransaction(transaction['id']);
              _filterTransactions();
            },
            onUpdate: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddTransactionScreen(
                    transaction: transaction,
                  ),
                ),
              );
              //refresh the transactions
              _filterTransactions();
            },
          );
        },
      );
    } else {
      return _buildNoTransactionsPlaceholder();
    }
  }

  Widget _buildNoTransactionsPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchController.text.isNotEmpty
                ? Icons.sentiment_dissatisfied
                : Icons.sentiment_very_satisfied,
            size: 50,
            color: Colors.white,
          ),
          SizedBox(height: 10),
          Text(
            _searchController.text.length > 3
                ? 'No transactions available'
                : 'Enter more than 3 letters to search or use the filter button',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  /*void FilterTransactions(){
    Provider.of<TransactionsModel>(context, listen: false)
        .filterTransactions(
        context,
        null,  // Search text
        null,  // Transactions to filter
        selectedFromDate,
        selectedToDate,
        selectedIncludeCategoriesList.map((category) => int.parse(category['id'])).toList(),
        selectedExcludeCategoriesList.map((category) => int.parse(category['id'])).toList(),
        selectedAccounts,
    );
    showModernSnackBar(context: context, message: 'Filters Applied', backgroundColor: Colors.green);
    setState(() {
      filteredConditionalTransactions = Provider.of<TransactionsModel>(context, listen: false).filteredTransactions;
    });
    Navigator.pop(context, true);
  }*/
}

void main() {
  runApp(MaterialApp(
    home: SearchScreen(),
    theme: ThemeData.dark(),
  ));
}