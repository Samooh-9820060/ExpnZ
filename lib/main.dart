import 'package:expnz/database/AccountsDB.dart';
import 'package:expnz/database/CategoriesDB.dart';
import 'package:expnz/database/TransactionsDB.dart';
import 'package:expnz/models/FinancialDataNotifier.dart';
import 'package:expnz/models/TempTransactionsModel.dart';
import 'package:expnz/screens/SignInScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './screens/MainPage.dart';
import 'database/ProfileDB.dart';
import 'firebase_options.dart';

void testRegexes() {
  final RegExp transactionRegex = RegExp(
      r"Transaction from (\d{4}) on (\d{2}/\d{2}/\d{2}) at (\d{2}:\d{2}:\d{2}) for ([A-Z]{3}\d+(\.\d{1,2})?) at (.+?) was processed\. Reference No:(\d+), Approval Code:(\d+)"
  );
  final RegExp bMLFundsReceivedRegex = RegExp(
      r"You have received ([A-Z]{3})\s(\d+\.\d{1,2}) from ([A-Z .]+) to (\d+\*\d+)"
  );

  final RegExp bMLFundsTransferredRegex = RegExp(
      r"You have sent ([A-Z]{3})\s(\d+\.\d{1,2}) from (\d+\*\d+) to ([A-Z0-9\\.* ]+)"
  );

  // Test cases
  List<String> testStrings = [
    "You have sent MVR 200.0 from 7730*1879 to 7730*7443",
    "You have sent MVR 100.0 from 7730*1879 to SHAAMIKH MOHAMED",
    "You have sent USD 77.0 from 7730*1879 to SHAAMIKH MOHAMED",
    "You have received MVR 167.12 from AISHATH L.MOHAMED to 7730*7443",
    "You have received MVR 23.5 from AISHATH L.MOHAMED to 7730*7443",
    "You have sent MVR 4.9 from 7730*7443 to 7730*1879",
    "You have received MVR 231.9 from MOHD.S.SHUJAU to 7730*7443",
    "Transaction from 3368 on 25/01/24 at 17:39:04 for MVR200.00 at VILIMALE' BRANCH          was processed. Reference No:402517801476, Approval Code:801476.",
    "Transaction from 3368 on 21/01/24 at 17:17:34 for MVR167.00 at GRILL HUT was processed. Reference No:012195154627, Approval Code:154627.",
    "Transaction from 3368 on 18/01/24 at 18:54:21 for MVR70.00 at VICTORIOUS CAFE was processed. Reference No:011894439211, Approval Code:439211.",
    "Transaction from 3368 on 09/01/24 at 08:11:18 for MVR25000.00 at VILIMALE' BRANCH          was processed. Reference No:400908196250, Approval Code:196250.",
    "Transaction from 3368 on 08/01/24 at 17:33:08 for MVR105.00 at VICTORIOUS CAFE was processed. Reference No:010891749509, Approval Code:749509.",
    "Transaction from 3368 on 05/01/24 at 06:07:39 for MVR808.92 at DHIRAAGU                  was processed. Reference No:400501306577, Approval Code:306577.",
    "Transaction from 3368 on 02/01/24 at 11:07:53 for USD2.00 at aliexpress                was processed. Reference No:400206223938, Approval Code:223938.",
    "Transaction from 3368 on 30/12/23 at 22:07:05 for MVR50.00 at FAHI PLAZA was processed. Reference No:123089264074, Approval Code:264074.",
    "Transaction from 3368 on 29/12/23 at 20:09:23 for MVR200.00 at RTL                       was processed. Reference No:336315177695, Approval Code:177695.",
    "Transaction from 3368 on 29/12/23 at 21:51:05 for MVR317.00 at GRILL HUT was processed. Reference No:122988969324, Approval Code:969324.",
  ];

  for (var testString in testStrings) {
    if (transactionRegex.hasMatch(testString)) {
      print("Matched TransactionRegex: $testString");
    } else if (bMLFundsReceivedRegex.hasMatch(testString)) {
      print("Matched BMLFundsReceivedRegex: $testString");
    } else if (bMLFundsTransferredRegex.hasMatch(testString)) {
      print("Matched BMLFundsTransferredRegex: $testString");
    } else {
      print("No match found for: $testString");
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  //testRegexes();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => TempTransactionsModel()),
        ChangeNotifierProvider(create: (context) => FinancialDataNotifier()),
      ],
        child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState()=> _MyAppState();
}

class _MyAppState extends State<MyApp> {
  User? user;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Start listening to profile changes if the user is logged in
      ProfileDB().listenToProfileChanges(user!.uid);
      AccountsDB().listenToAccountChanges(user!.uid);
      CategoriesDB().listenToCategoryChanges(user!.uid);
      TransactionsDB().listenToTransactionChanges(user!.uid);
    }

    // Set up an auth state change listener
    FirebaseAuth.instance.authStateChanges().listen((User? currentUser) {
      setState(() {
        user = currentUser;
        if (user != null) {
          ProfileDB().listenToProfileChanges(user!.uid);
          AccountsDB().listenToAccountChanges(user!.uid);
          CategoriesDB().listenToCategoryChanges(user!.uid);
          TransactionsDB().listenToTransactionChanges(user!.uid);
        }
      });
    });
  }

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
            backgroundColor: Colors.blueAccent,
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
      home: user == null ? SignInScreen() : HomePage(),
    );
  }
}
