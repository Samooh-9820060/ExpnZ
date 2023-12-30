import 'dart:async';
import 'package:notifications/notifications.dart';

class AppNotificationListener {
  Notifications? _notifications;
  StreamSubscription<NotificationEvent>? _subscription;
  List<NotificationEvent> log = [];
  bool started = false;

  void startListening() {
    _notifications = Notifications();
    try {
      _subscription = _notifications!.notificationStream!.listen(_processNotification);
      started = true;
    } on NotificationException catch (exception) {
      print(exception);
    }
  }

  void stopListening() {
    _subscription?.cancel();
    started = false;
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

          // Now you can use these extracted details
          print("Card Digits: $cardDigits, Date: $date, Time: $time, Amount: $amount, Place: $placeName, Reference No: $referenceNo, Approval Code: $approvalCode");

          // Additional processing like adding to a database can be done here
        }
      }
    }
  }


  //regexes
  final RegExp transactionRegex = RegExp(
      r"Transaction from (\d{4}) on (\d{2}/\d{2}/\d{2}) at (\d{2}:\d{2}:\d{2}) for MVR(\d+\.\d{2}) at ([^ ]+) was processed\. Reference No: (\d+), Approval Code:(\d+)"
  );

}
