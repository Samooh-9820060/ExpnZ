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
    } on NotificationException {
      _controller.sink.add(false);
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
    if (!_isSimilarNotificationExists(event, const Duration(minutes: 1))) {
      log.add(event);

      TempTransactionsDB tempTransDB = TempTransactionsDB();

      //BML Funds Received Notification
      if (event.packageName == "mv.com.bml.mib" && event.title == "Funds Received") {
        final match = bMLFundsReceivedRegex.firstMatch(event.message ?? "");
        if (match != null) {
          String currencyCode = match.group(1) ?? "";
          String amountReceived = match.group(2) ?? "";
          String senderName = match.group(3) ?? "";
          String accountNumber = match.group(4) ?? "";
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
        }
      }

      //BML Funds Transferred Notification
      if (event.packageName == "mv.com.bml.mib" && event.title == "Funds Transferred") {
        final match = bMLFundsTransferredRegex.firstMatch(event.message ?? "");
        if (match != null) {
          String currencyCode = match.group(1) ?? "";
          String amountSent = match.group(2) ?? "";
          String accountNumber = match.group(3) ?? "";
          String recipientName = match.group(4) ?? "";
          DateTime? timeStamp = event.timeStamp;
          String date = timeStamp != null ? "${timeStamp.year}-${timeStamp.month}-${timeStamp.day}" : "";
          String time = timeStamp != null ? "${timeStamp.hour}:${timeStamp.minute}:${timeStamp.second}" : "";

          Map<String, dynamic> row = {
            TempTransactionsDB.columnTitle: event.title,
            TempTransactionsDB.columnContent: event.message,
            TempTransactionsDB.columnType: TransactionType.expense.toString().split('.').last,
            TempTransactionsDB.columnName: recipientName,
            TempTransactionsDB.columnAmount: double.tryParse(amountSent) ?? 0.0,
            TempTransactionsDB.columnDate: date,
            TempTransactionsDB.columnTime: time,
            TempTransactionsDB.columnDescription: accountNumber,
          };

          // Insert the transaction into the database
          tempTransDB.insertTransaction(row);
        }
      }

      if (event.packageName == "com.google.android.apps.messaging" &&
          (event.title == "455" || event.title == "+455")) {
        final match = transactionRegex.firstMatch(event.message ?? "");
        if (match != null) {
          String cardDigits = match.group(1) ?? "";
          String date = match.group(2) ?? "";
          String time = match.group(3) ?? "";
          String currencyCode = match.group(4) ?? "";
          String amount = match.group(5) ?? "";
          String placeName = match.group(6) ?? "";
          String referenceNo = match.group(7) ?? "";
          String approvalCode = match.group(8) ?? "";


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
        }
      }
    }
  }


  //regexes
  final RegExp transactionRegex = RegExp(
      r"Transaction from (\d{4}) on (\d{2}/\d{2}/\d{2}) at (\d{2}:\d{2}:\d{2}) for ([A-Z]{3}) ?(\d+(\.\d{1,2})?) at (.+?) was processed\. Reference No:(\d+), Approval Code:(\d+)"
  );
  final RegExp bMLFundsReceivedRegex = RegExp(
      r"You have received ([A-Z]{3})\s(\d+\.\d{1,2}) from ([A-Z .]+) to (\d+\*\d+)"
  );

  final RegExp bMLFundsTransferredRegex = RegExp(
      r"You have sent ([A-Z]{3})\s(\d+\.\d{1,2}) from (\d+\*\d+) to ([A-Z0-9\\.* ]+)"
  );
}
