// global.dart
import 'package:flutter/material.dart';

ValueNotifier<Map<String, dynamic>?> profileNotifier = ValueNotifier(null);
ValueNotifier<Map<String, Map<String, dynamic>>> accountsNotifier = ValueNotifier({});
ValueNotifier<Map<String, Map<String, dynamic>>> categoriesNotifier = ValueNotifier({});
ValueNotifier<Map<String, Map<String, dynamic>>> transactionsNotifier = ValueNotifier({});
ValueNotifier<Map<String, Map<String, dynamic>>> recurringTransactionsNotifier = ValueNotifier({});