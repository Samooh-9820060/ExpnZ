import 'package:expnz/models/TempTransactionsModel.dart';
import 'package:expnz/models/TransactionsModel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './screens/MainPage.dart';
import 'models/AccountsModel.dart';
import 'models/CategoriesModel.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CategoriesModel()),
        ChangeNotifierProvider(create: (context) => AccountsModel()),
        ChangeNotifierProvider(create: (context) => TransactionsModel()),
        ChangeNotifierProvider(create: (context) => TempTransactionsModel()),
      ],
        child: const MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: Colors.blueAccent,
        hintColor: Colors.amber,
        brightness: Brightness.dark, // Set brightness as per your design
        visualDensity: VisualDensity.adaptivePlatformDensity,

        buttonTheme: ButtonThemeData(
          buttonColor: Colors.blueAccent,
          textTheme: ButtonTextTheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            primary: Colors.blueAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),

        dialogTheme: DialogTheme(
          backgroundColor: Colors.grey[900],
          titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
          contentTextStyle: const TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
            borderRadius: BorderRadius.circular(20),
          ),
          labelStyle: const TextStyle(color: Colors.white),
          hintStyle: const TextStyle(color: Colors.grey),
        ),
      ),

      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}
