import 'dart:async';
import 'package:notifications/notifications.dart';

class AppNotificationListener {
  Notifications? _notifications;
  StreamSubscription<NotificationEvent>? _subscription;
  List<NotificationEvent> log = [];
  bool started = false;

  void startListening(Function(NotificationEvent) onData) {
    _notifications = Notifications();
    try {
      _subscription = _notifications!.notificationStream!.listen(onData);
      started = true;
    } on NotificationException catch (exception) {
      print(exception);
    }
  }

  void stopListening() {
    _subscription?.cancel();
    started = false;
  }
}
