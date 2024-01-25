import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expnz/widgets/AppWidgets/MonthlySummaryCards.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/FinancialDataNotifier.dart';
import '../models/TempTransactionsModel.dart';
import '../utils/global.dart';
import '../widgets/AppWidgets/FinanceCard.dart';
import '../widgets/AppWidgets/NotificationsSection.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _nameController;
  late AnimationController _cardController;
  late AnimationController _incomeCardController;
  late AnimationController _expenseCardController;
  late AnimationController _notificationCardController;
  late String selectedCurrencyCode;
  String userName = '';

  @override
  void initState() {
    super.initState();
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
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            final fetchedName = userData['name'] ?? '';
            setState(() {
              userName = fetchedName;
            });
          }
        }
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
                      userName,
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
                if (financialData.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                } else {
                  return Column(
                    children: [
                      buildFinanceCard(cardWidth, financialData, financialDataNotifier.currencyMap, financialDataNotifier.currencyCodes),
                      const SizedBox(height: 10),
                      // Add some space below the card
                      MonthlySummaryCards(
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
