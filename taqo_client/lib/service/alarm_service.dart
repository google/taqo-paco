import 'dart:isolate';

import 'package:android_alarm_manager/android_alarm_manager.dart';

import '../model/action_specification.dart';
import '../scheduling/action_schedule_generator.dart';
import '../storage/local_database.dart';
import 'notification_service.dart' as notification_manager;

/// Schedule an alarm for [actionSpec] at [when] to run [callback]
Future<int> _schedule(ActionSpecification actionSpec, DateTime when, Function(int) callback) {
  return AndroidAlarmManager.initialize().then((success) async {
    if (success) {
      final alarmId = await LocalDatabase().insertAlarm(actionSpec);
      AndroidAlarmManager.oneShotAt(when, alarmId, callback,
          allowWhileIdle: true, exact: true, rescheduleOnReboot: true, wakeup: true);
      return alarmId;
    }
    return -1;
  });
}

Future<bool> _scheduleNotification(ActionSpecification actionSpec) async {
  // Don't show a notification that's already pending
  final alarms = await LocalDatabase().getAllAlarms();
  for (var as in alarms.values) {
    if (as == actionSpec) {
      print('Notification for $actionSpec already scheduled');
      return false;
    }
  }

  final alarmId = await _schedule(actionSpec, actionSpec.time, _notifyCallback);
  print('_scheduleNotification: alarmId: $alarmId when: ${actionSpec.time}'
      ' isolate: ${Isolate.current.hashCode}');
  return true;
}

void _scheduleTimeout(ActionSpecification actionSpec) async {
  var timeout = 59;
  if (actionSpec.action != null) {
    timeout = actionSpec.action.timeout ?? timeout;
  }
  final alarmId = await _schedule(actionSpec, actionSpec.time.add(Duration(minutes: timeout)), _expireCallback);
  print('_scheduleTimeout: alarmId: $alarmId'
      ' when: ${actionSpec.time.add(Duration(minutes: timeout))}'
      ' isolate: ${Isolate.current.hashCode}');
}

void _notifyCallback(int alarmId) async {
  // This is running in a different (background) Isolate
  print('notify: alarmId: $alarmId isolate: ${Isolate.current.hashCode}');
  final actionSpec = await LocalDatabase().getAlarm(alarmId);
  if (actionSpec != null) {
    notification_manager.showNotification(actionSpec);
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
  final toCancel = await LocalDatabase().getAlarm(alarmId);
  // TODO Move the matches() logic to SQL
  final notifications = await LocalDatabase().getAllNotifications();
  if (notifications != null) {
    final match = notifications.firstWhere((notificationHolder) =>
        notificationHolder.matchesAction(toCancel), orElse: () => null);
    if (match != null) {
      notification_manager.cancelNotification(match.id);
    }
  }

  // Cleanup alarm
  cancel(alarmId);
}

void _scheduleNextNotification() async {
  getNextAlarmTime().then((ActionSpecification actionSpec) async {
    if (actionSpec != null) {
      // Schedule a notification (android_alarm_manager)
      _scheduleNotification(actionSpec).then((scheduled) {
        if (scheduled) {
          // Schedule a timeout (android_alarm_manager)
          _scheduleTimeout(actionSpec);
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
  LocalDatabase().removeAlarm(alarmId);
}

Future<void> cancelAll() async {
  (await LocalDatabase().getAllAlarms()).keys.forEach((alarmId) async => await cancel(alarmId));
}
