import 'dart:async';
import 'dart:io';

import 'android_alarm_manager.dart' as android_alarm_manager;
import 'flutter_local_notifications.dart' as flutter_local_notifications;

Future init() {
  // Init the actual notification plugin
  return flutter_local_notifications.init().then((value) => schedule());
}

/// Schedule notifications in a platform-dependent way
void schedule() {
  if (Platform.isAndroid) {
    android_alarm_manager.scheduleNextNotification();
  }
}

void cancel(int alarmId) {
  if (Platform.isAndroid) {
    android_alarm_manager.cancel(alarmId);
  }
}
