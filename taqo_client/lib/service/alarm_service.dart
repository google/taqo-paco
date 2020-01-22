import 'dart:isolate';

import 'package:android_alarm_manager/android_alarm_manager.dart';
import 'package:taqo_client/model/action_specification.dart';
import 'package:taqo_client/scheduling/action_schedule_generator.dart';
import 'package:taqo_client/service/notification_service.dart';
import 'package:taqo_client/storage/local_database.dart';
import 'package:taqo_client/storage/pending_alarm_storage.dart';

/// Gets the initial alarm ID. Afterwards, the ID is just incremented.
/// Using this method should allow for unique IDs that never overlap (ever)
/// Note: Dart uses 64-bit ints but Android uses 32-bits
Future<int> _getNextAlarmId() async {
  var max = -1;
  (await PendingAlarms.getInstance()).getAll().keys.forEach((k) {
    if (k != null && k > max) {
      max = k;
    }
  });
  return max + 1;
}

/// Schedule an alarm for [actionSpec] at [when] to run [callback]
void _schedule(int alarmId, ActionSpecification actionSpec, DateTime when, Function(int) callback) {
  AndroidAlarmManager.initialize().then((success) async {
    if (success) {
      AndroidAlarmManager.oneShotAt(when, alarmId, callback,
          allowWhileIdle: true, exact: true, rescheduleOnReboot: true, wakeup: true);
      (await PendingAlarms.getInstance())[alarmId] = actionSpec;
    }
  });
}

Future<bool> _scheduleNotification(int alarmId, ActionSpecification actionSpec) async {
  // Don't show a notification that's already pending
  final pending = (await PendingAlarms.getInstance()).getAll();
  for (var as in pending.values) {
    if (as == actionSpec) {
      print('Notification for $actionSpec already scheduled');
      return false;
    }
  }

  _schedule(alarmId, actionSpec, actionSpec.time, _notifyCallback);
  print('_scheduleNotification: alarmId: $alarmId when: ${actionSpec.time}'
      ' isolate: ${Isolate.current.hashCode}');
  return true;
}

void _scheduleTimeout(int alarmId, ActionSpecification actionSpec) {
  var timeout = 59;
  if (actionSpec.action != null) {
    timeout = actionSpec.action.timeout ?? timeout;
  }
  _schedule(alarmId, actionSpec, actionSpec.time.add(Duration(minutes: timeout)), _expireCallback);
  print('_scheduleTimeout: alarmId: $alarmId'
      ' when: ${actionSpec.time.add(Duration(minutes: timeout))}'
      ' isolate: ${Isolate.current.hashCode}');
}

void _notifyCallback(int alarmId) async {
  // This is running in a different (background) Isolate
  print('notify: alarmId: $alarmId isolate: ${Isolate.current.hashCode}');
  final actionSpec = (await PendingAlarms.getInstance())[alarmId];
  if (actionSpec != null) {
    NotificationManager().showNotification(actionSpec);
  }
  // Cleanup alarm
  cancel(alarmId);
  // schedule the next one
  _scheduleNextNotification();
}

void _expireCallback(int alarmId) async {
  // This is running in a different (background) Isolate
  print('expire: alarmId: $alarmId isolate: ${Isolate.current.hashCode}');
  // Cancel notification
  final toCancel = (await PendingAlarms.getInstance())[alarmId];
  // TODO Move the matches() logic to SQL
  final notifications = await LocalDatabase().getAllNotifications();
  if (notifications != null) {
    final match = notifications.firstWhere((notificationHolder) =>
        notificationHolder.matches(toCancel), orElse: () => null);
    if (match != null) {
      NotificationManager().cancelNotification(match.id);
    }
  }

  // Cleanup alarm
  cancel(alarmId);
}

void _scheduleNextNotification() async {
  getNextAlarmTime().then((ActionSpecification actionSpec) async {
    if (actionSpec != null) {
      var alarmId = await _getNextAlarmId();
      // Schedule a notification (android_alarm_manager)
      _scheduleNotification(alarmId, actionSpec).then((scheduled) {
        if (scheduled) {
          // Schedule a timeout (android_alarm_manager)
          _scheduleTimeout(++alarmId, actionSpec);
        }
      });
    }
  });
}

void scheduleNextNotification() async {
  // TODO cancelAll except timeouts for already showing notifications
  _scheduleNextNotification();
}

Future<void> cancel(int alarmId) async {
  AndroidAlarmManager.initialize().then((bool success) {
    if (success) {
      AndroidAlarmManager.cancel(alarmId);
    }
  });
  (await PendingAlarms.getInstance()).remove(alarmId);
}

Future<void> cancelAll() async {
  (await PendingAlarms.getInstance()).getAll().keys.forEach((alarmId) async => await cancel(alarmId));
}
