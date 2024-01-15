import 'dart:async';
import 'package:notifications/notifications.dart';

import '../database/TempTransactionsDB.dart';

enum TransactionType { income, expense, transfer }
class AppNotificationListener {
  Notifications? _notifications;
  StreamSubscription<NotificationEvent>? _subscription;
  List<NotificationEvent> log = [];
  bool started = false;
  final _controller = StreamController<bool>.broadcast();
  Stream<bool> get statusStream => _controller.stream;


  void startListening() {
    _notifications = Notifications();
    try {
      _subscription = _notifications!.notificationStream!.listen(_processNotification);
      started = true;
      _controller.sink.add(true);
    } on NotificationException catch (exception) {
      _controller.sink.add(false);
      print(exception);
    }
  }

  bool isListeningActive() {
    return started;
  }

  void stopListening() {
    _subscription?.cancel();
    started = false;
    _controller.sink.add(false);
  }

  bool _isSimilarNotificationExists(NotificationEvent newEvent, Duration duration) {
    return log.any((existingEvent) =>
    existingEvent.message == newEvent.message &&
        (newEvent.timeStamp?.difference(existingEvent.timeStamp ?? DateTime.now()).inMinutes.abs() ?? 0) <= duration.inMinutes);
  }

  void _processNotification(NotificationEvent event) {
    // Add the event to the log
    if (!_isSimilarNotificationExists(event, Duration(minutes: 1))) {
      log.add(event);

      print(event);

      TempTransactionsDB tempTransDB = TempTransactionsDB();

      //BML Funds Received Notification
      if (event.packageName == "mv.com.bml.mib" && event.title == "Funds Received") {
        final match = BMLFundsReceivedRegex.firstMatch(event.message ?? "");
        print("Funds Received");
        print(match);
        if (match != null) {
          String amountReceived = match.group(1) ?? "";
          String senderName = match.group(2) ?? "";
          String accountNumber = match.group(3) ?? "";
          DateTime? timeStamp = event.timeStamp;
          String date = timeStamp != null ? "${timeStamp.year}-${timeStamp.month}-${timeStamp.day}" : "";
          String time = timeStamp != null ? "${timeStamp.hour}:${timeStamp.minute}:${timeStamp.second}" : "";

          Map<String, dynamic> row = {
            TempTransactionsDB.columnTitle: event.title,
            TempTransactionsDB.columnContent: event.message,
            TempTransactionsDB.columnType: TransactionType.income.toString().split('.').last,
            TempTransactionsDB.columnName: senderName,
            TempTransactionsDB.columnAmount: double.tryParse(amountReceived) ?? 0.0,
            TempTransactionsDB.columnDate: date,
            TempTransactionsDB.columnTime: time,
            TempTransactionsDB.columnDescription: accountNumber,
          };

          // Insert the transaction into the database
          tempTransDB.insertTransaction(row);
          print("Amount Received: $amountReceived, Sender: $senderName, Account Number: $accountNumber, Date: $date, Time: $time");
        }
      }

      //BML Funds Transferred Notification
      if (event.packageName == "mv.com.bml.mib" && event.title == "Funds Transferred") {
        final match = BMLFundsTransferredRegex.firstMatch(event.message ?? "");
        print("Funds Transferred");
        print(match);
        if (match != null) {
          String amountSent = match.group(1) ?? "";
          String accountNumber = match.group(2) ?? "";
          String senderName = match.group(3) ?? "";
          DateTime? timeStamp = event.timeStamp;
          String date = timeStamp != null ? "${timeStamp.year}-${timeStamp.month}-${timeStamp.day}" : "";
          String time = timeStamp != null ? "${timeStamp.hour}:${timeStamp.minute}:${timeStamp.second}" : "";

          Map<String, dynamic> row = {
            TempTransactionsDB.columnTitle: event.title,
            TempTransactionsDB.columnContent: event.message,
            TempTransactionsDB.columnType: TransactionType.expense.toString().split('.').last,
            TempTransactionsDB.columnName: senderName,
            TempTransactionsDB.columnAmount: double.tryParse(amountSent) ?? 0.0,
            TempTransactionsDB.columnDate: date,
            TempTransactionsDB.columnTime: time,
            TempTransactionsDB.columnDescription: accountNumber,
          };

          // Insert the transaction into the database
          tempTransDB.insertTransaction(row);
          print("Amount Received: $amountSent, Sender: $senderName, Account Number: $accountNumber, Date: $date, Time: $time");
        }
      }

      if (event.packageName == "com.google.android.apps.messaging" &&
          (event.title == "455" || event.title == "+455")) {
        final match = transactionRegex.firstMatch(event.message ?? "");
        print(match);
        if (match != null) {
          String cardDigits = match.group(1) ?? "";
          String date = match.group(2) ?? "";
          String time = match.group(3) ?? "";
          String amount = match.group(4) ?? "";
          String placeName = match.group(5) ?? "";
          String referenceNo = match.group(6) ?? "";
          String approvalCode = match.group(7) ?? "";


          Map<String, dynamic> row = {
            TempTransactionsDB.columnTitle: 'Card Transaction',
            TempTransactionsDB.columnContent: event.message,
            TempTransactionsDB.columnType: TransactionType.expense.toString().split('.').last,
            TempTransactionsDB.columnName: placeName,
            TempTransactionsDB.columnAmount: double.tryParse(amount) ?? 0.0,
            TempTransactionsDB.columnDate: date,
            TempTransactionsDB.columnTime: time,
            TempTransactionsDB.columnDescription: "$referenceNo - $approvalCode",
            TempTransactionsDB.columnCardDigits: cardDigits,
          };

          // Insert the transaction into the database
          tempTransDB.insertTransaction(row);
          // Now you can use these extracted details
          print("Card Digits: $cardDigits, Date: $date, Time: $time, Amount: $amount, Place: $placeName, Reference No: $referenceNo, Approval Code: $approvalCode");
        }
      }
    }
  }


  //regexes
  final RegExp transactionRegex = RegExp(
      r"Transaction from (\d{4}) on (\d{2}/\d{2}/\d{2}) at (\d{2}:\d{2}:\d{2}) for MVR(\d+\.\d{2}) at ([^ ]+) was processed\. Reference No: (\d+), Approval Code:(\d+)"
  );
  final RegExp BMLFundsReceivedRegex = RegExp(
      r"You have received MVR (\d+\.\d{2}) from ([A-Z .]+) to (\d+\*\d+)"
  );
  final RegExp BMLFundsTransferredRegex = RegExp(
      r"You have sent MVR (\d+\.\d{1,2}) from (\d+\*\d+) to ([A-Z\\. ]+)"
  );
}
