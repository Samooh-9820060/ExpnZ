import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expnz/utils/global.dart';
import 'package:http/http.dart' as http;

class ProfileDB {
  static const String collectionName = 'users'; // or 'profiles'

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void listenToProfileChanges(String uid) {
    _firestore.collection(collectionName).doc(uid).snapshots().listen((snapshot) async {
      if (snapshot.exists) {
        final Map<String, dynamic> profileData = snapshot.data() as Map<String, dynamic>;

        // Check if profileImageUrl has changed
        if (profileData.containsKey('profileImageUrl')) {
          String imageUrl = profileData['profileImageUrl'];
          await downloadAndSaveImage(imageUrl, uid);
        }

        // Cache the updated profile data locally
        cacheProfileLocally(profileData);
      } else {
        clearLocalProfileCache();
      }
    });
  }

  Future<void> downloadAndSaveImage(String imageUrl, String uid) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$uid-profile-image.jpg';
      final file = File(filePath);
      file.writeAsBytesSync(response.bodyBytes);
      // Optionally, save the local path in shared preferences or some local database
    } catch (e) {
      print('Error downloading or saving image: $e');
    }
  }

  Future<File?> getLocalProfileImage(String uid) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$uid-profile-image.jpg';
    final file = File(filePath);
    return file.existsSync() ? file : null;
  }

  Future<void> clearLocalProfileCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userProfile');
    profileNotifier.value = null;
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

  Future<void> createUserProfile(String uid, Map<String, dynamic> profileData) async {
    await _firestore.collection(collectionName).doc(uid).set(profileData);
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
