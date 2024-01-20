import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expnz/utils/global.dart';

class ProfileDB {
  static const String collectionName = 'users'; // or 'profiles'

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void listenToProfileChanges(String uid) {
    _firestore.collection(collectionName).doc(uid).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        cacheProfileLocally(snapshot.data());
      }
    });
  }

  Future<void> cacheProfileLocally(Map<String, dynamic>? profileData) async {
    if (profileData != null) {
      final prefs = await SharedPreferences.getInstance();
      String encodedData = json.encode(profileData);
      await prefs.setString('userProfile', encodedData);
      profileNotifier.value = profileData;
    }
  }

  Future<Map<String, dynamic>?> getLocalProfile() async {
    final prefs = await SharedPreferences.getInstance();
    String? encodedData = prefs.getString('userProfile');
    return encodedData != null ? json.decode(encodedData) as Map<String, dynamic> : null;
  }

  Future<void> createUserProfileWithAggregates(String uid, Map<String, dynamic> profileData) async {
    // Adding default aggregate data
    profileData.addAll({
      'accounts': {},
      'categories': {},
    });

    await _firestore.collection(collectionName).doc(uid).set(profileData);
  }

  Future<DocumentSnapshot> getProfile(String uid) async {
    return await _firestore.collection(collectionName).doc(uid).get();
  }

  // Method to fetch income and expense for each account in a specific category
  Map<String, dynamic> getIncomeExpenseForCategory(String categoryId) {
    Map<String, dynamic> categoryIncomeExpense = {};

    final profileData = profileNotifier.value;
    if (profileData != null && profileData['categories'] != null) {
      Map<String, dynamic> categories = profileData['categories'];
      if (categories.containsKey(categoryId)) {
        Map<String, dynamic> categoryData = categories[categoryId];
        // Iterate over the category data where keys are account IDs
        categoryData.forEach((accountId, incomeExpenseData) {
          // Ensure the data is a map and contains income and expense keys
          if (incomeExpenseData is Map<String, dynamic>) {
            double totalIncome = (incomeExpenseData['totalIncome'] ?? 0).toDouble();
            double totalExpense = (incomeExpenseData['totalExpense'] ?? 0).toDouble();
            categoryIncomeExpense[accountId] = {
              'totalIncome': totalIncome,
              'totalExpense': totalExpense
            };
          }
        });
      }
    }

    return categoryIncomeExpense;
  }

}
