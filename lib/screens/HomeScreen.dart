import 'dart:async';
import 'dart:convert';

import 'package:expnz/screens/AddAccount.dart';
import 'package:expnz/widgets/AppWidgets/IncomeExpenseGraphs.dart';
import 'package:expnz/widgets/SimpleWidgets/ExpnZButton.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/FinancialDataNotifier.dart';
import '../models/TempTransactionsModel.dart';
import '../utils/global.dart';
import '../widgets/AppWidgets/FinanceCard.dart';
import '../widgets/AppWidgets/NotificationsSection.dart';
import '../widgets/SimpleWidgets/ExpnZDropdown.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _nameController;
  late AnimationController _cardController;
  late AnimationController _incomeCardController;
  late AnimationController _expenseCardController;
  late AnimationController _notificationCardController;
  String? selectedCurrencyCode;
  String userName = '';
  String _selectedTimeFrame = 'Last 30 Days';

  @override
  void initState() {
    super.initState();
    //AccountsDB().printFirestoreReadDetails();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final financialDataNotifier = Provider.of<FinancialDataNotifier>(context, listen: false);
      financialDataNotifier.loadFinancialData();
    });
    _initializeDataAndControllers();
    fetchUserName();
    setState(() {});
  }

  Future<void> _initializeDataAndControllers() async {
    _nameController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _incomeCardController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _expenseCardController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _notificationCardController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Start animations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameController.forward();
      _cardController.forward();
      _incomeCardController.forward();
      _expenseCardController.forward();
      _notificationCardController.forward();
    });
  }

  // Function to fetch user's name from Firestore
  void fetchUserName() async {
    final profileData = profileNotifier.value;
    final prefs = await SharedPreferences.getInstance();
    String? encodedProfileData = prefs.getString('userProfile');

    if (profileData != null) {
      final fetchedName = profileData['name'] ?? '';
      setState(() {
        userName = fetchedName;
      });
    } else if (encodedProfileData != null) {
      try {
        Map<String, dynamic> profileData = json.decode(encodedProfileData);
        String fetchedName = profileData['name'] ?? '';
        setState(() {
          userName = fetchedName;
        });
      } catch (e) {
        // Handle any errors during JSON parsing
        //print('Error parsing user profile data: $e');
      }
    }
    else {
      try {
        //final uid = FirebaseAuth.instance.currentUser?.uid;
        /*if (uid != null) {
          final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            final fetchedName = userData['name'] ?? '';
            setState(() {
              userName = fetchedName;
            });
          }
        }*/
      } catch (e) {
        // Handle any errors while fetching the name
        //print(e.toString());
      }
    }
  }


  /*Future<void> updateFinancialData(String currencyCode) async {
    setState(()  {
      selectedCurrencyCode = currencyCode;
      Currency? currencyObj = currencyService.findByCode(currencyCode);
      fetchAndUpdateFinancialData(currencyCode);

      if (currencyObj != null) {
        currencyMap = {
          'code': currencyObj.code,
          'name': currencyObj.name,
          'symbol': currencyObj.symbol,
          'flag': currencyObj.flag,
          'decimalDigits': currencyObj.decimalDigits,
          'decimalSeparator': currencyObj.decimalSeparator,
          'namePlural': currencyObj.namePlural,
          'number': currencyObj.number,
          'spaceBetweenAmountAndSymbol':
              currencyObj.spaceBetweenAmountAndSymbol,
          'symbolOnLeft': currencyObj.symbolOnLeft,
          'thousandsSeparator': currencyObj.thousandsSeparator,
        };
      } else {
        currencyMap = {}; // or some default values
      }
    });
  }
*/

  @override
  void dispose() {
    _nameController.dispose();
    _cardController.dispose();
    _incomeCardController.dispose();
    _expenseCardController.dispose();
    _notificationCardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double cardWidth = MediaQuery.of(context).size.width / 2.25;
    return Container(
      color: Colors.blueGrey[900],
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Animated "Name" and "Welcome Back!" section
            AnimatedBuilder(
              animation: _nameController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(-300 * (1 - _nameController.value), 0),
                  child: Opacity(
                    opacity: _nameController.value,
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(30.0, 10.0, 16.0, 0.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName == '' ? 'Hi' : userName,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Welcome Back!',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Consumer<FinancialDataNotifier>(
              builder: (context, financialDataNotifier, child) {
                var financialData = financialDataNotifier.financialData;
                if (financialDataNotifier.isLoading) {
                  // Show loading indicator when data is being loaded
                  return const Center(child: CircularProgressIndicator());
                } else if (financialDataNotifier.financialData.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20.0, 50.0, 20.0, 0.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.monetization_on,
                            size: 80,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "No financial data available",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Looks like there's no financial data to display right now. Start Adding Transactions below",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 30),
                          ExpnZButton(
                            label: 'Add Account',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => AddAccountScreen()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  return Column(
                    children: [
                      buildFinanceCard(cardWidth, financialData, financialDataNotifier.currencyMap, financialDataNotifier.currencyCodes),
                      // Add some space below the card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: ExpnzDropdownButton(
                          label: '',
                          items: const ['This Month', 'Last 30 Days', 'Last Week'],
                          onChanged: (String? newValue) {
                            setState(() {

                              _selectedTimeFrame = newValue!;
                              DateTime now = DateTime.now();
                              DateTime startDate;
                              DateTime endDate = DateTime(now.year, now.month, now.day);

                              switch (newValue) {
                                case 'This Month':
                                  startDate = DateTime(now.year, now.month, 1);
                                  endDate = DateTime(now.year, now.month + 1, 1).subtract(const Duration(days: 1));
                                  break;
                                case 'Last 30 Days':
                                  startDate = DateTime.now().subtract(Duration(days: 30));
                                  break;
                                case 'Last Week':
                                  startDate = DateTime.now().subtract(Duration(days: 7));
                                  break;
                                default:
                                  startDate = DateTime(now.year, now.month, 1); // Default to 'This Month'
                              }

                              financialDataNotifier.loadData(selectedCurrencyCode, startDate: startDate, endDate: endDate);
                            });
                          },
                          isError: false,
                          value: _selectedTimeFrame,
                          animationController: _nameController,
                        ),
                      ),
                      IncomeExpenseGraphs(
                          timeFrame: _selectedTimeFrame,
                          incomeCardController: _incomeCardController,
                          expenseCardController: _expenseCardController,
                          cardWidth: cardWidth,
                          financialData: financialData,
                          currencyMap: financialDataNotifier.currencyMap
                      ),
                      const SizedBox(height: 20),
                      // Add the NotificationsSection here
                      Consumer<TempTransactionsModel>(
                        builder: (context, tempTransactionsModel, child) {
                          return NotificationsSection(
                            notificationCardController: _notificationCardController,
                            tempTransactionsModel: tempTransactionsModel,
                          );
                        },
                      ),
                      const SizedBox(height: 100,),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
  Widget buildFinanceCard(double cardWidth, Map<String, dynamic> financialData, Map<String, dynamic> currencyMap, List<String> currencyCodes) {
    if (financialData.isNotEmpty &&
        currencyMap.isNotEmpty &&
        currencyCodes.isNotEmpty) {
      return Container(
        color: Colors.blueGrey[900],
        child: FinanceCard(
          cardController: _cardController,
          totalBalance: financialData['balance'].toString(),
          income: financialData['income'].toString(),
          expense: financialData['expense'].toString(),
          optionalIcon: Icons.credit_card,
          currencyMap: currencyMap,
          currencyCodes: currencyCodes,
          onCurrencyChange: (selectedCurrency) {
            final financialDataNotifier = Provider.of<FinancialDataNotifier>(context, listen: false);
            financialDataNotifier.loadFinancialData(selectedCurrency);
            selectedCurrencyCode = selectedCurrency;
          },
        ),
      );
    } else {
      // Handle the case when data is not available
      return const Center(
        child: Text("No financial data available or there was an issue loading the data."),
      );
    }
  }
}
