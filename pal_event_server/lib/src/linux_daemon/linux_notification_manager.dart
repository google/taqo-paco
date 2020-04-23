import 'dart:async';

import 'package:taqo_common/model/action_specification.dart';
import 'package:taqo_common/model/notification_holder.dart';

import '../sqlite_database/sqlite_database.dart';
import 'dbus_notifications.dart';
import 'linux_alarm_manager.dart' show timeout;

const _appName = 'Taqo';

/// Shows or schedules a notification with the plugin
Future<int> _notify(ActionSpecification actionSpec, {DateTime when,
  bool cancelPending=true}) async {
  final notificationHolder = NotificationHolder(
    -1,   // placeholder, the real ID will be assigned by sqlite
    actionSpec.time.millisecondsSinceEpoch,
    actionSpec.experiment.id,
    0,
    1000 * 60 * actionSpec.action.timeout,
    actionSpec.experimentGroup.name,
    actionSpec.actionTrigger.id,
    actionSpec.action?.id,
    null,
    actionSpec.action == null ? "Time to participate" : actionSpec.action.msgText,
    actionSpec.actionTriggerSpecId,
  );

  // Cancel existing (pending) notifications for the same survey
  // On Linux, we create the notification at the time of the alarm
  // Therefore we should timeout any pending notifications for the same survey
  // We don't want to do this on iOS where we are aggressively pre-scheduling
  // notifications
  if (cancelPending) {
    final database = await SqliteDatabase.get();
    final pendingNotifications = await database
        .getAllNotificationsForExperiment(actionSpec.experiment.id);
    await Future.forEach(pendingNotifications, (pn) async {
      if (notificationHolder.sameGroupAs(pn)) {
        timeout(pn.id);
      }
    });
  }

  final database = await SqliteDatabase.get();
  final id = await database.insertNotification(notificationHolder);
  await notify(id, _appName, 0, actionSpec.experiment.title, notificationHolder.message);
  return id;
}

/// Show a notification now
Future<int> showNotification(ActionSpecification actionSpec) async {
  final id = await _notify(actionSpec);
  print('Showing notification id: $id @ ${actionSpec.time}');
  return id;
}

/// Cancel notification with [id]
Future cancelNotification(int id) async {
  cancel(id);
  final database = await SqliteDatabase.get();
  return database.removeNotification(id);
}

/// Cancel all notifications for [experiment]
Future cancelForExperiment(int experimentId) async {
  final database = await SqliteDatabase.get();
  return database.getAllNotificationsForExperiment(experimentId)
      .then((List<NotificationHolder> notifications) =>
      notifications.forEach((n) => cancelNotification(n.id)))
      .catchError((e, st) => "Error canceling notifications: $e");
}

/// Cancel all notifications, except ones that fired and are still pending
Future cancelAllNotifications() async {
  final database = await SqliteDatabase.get();
  return database.getAllNotifications()
      .then(((List<NotificationHolder> notifications) {
    for (var n in notifications) {
      final dt = DateTime.fromMillisecondsSinceEpoch(n.alarmTime);
      if (dt.isBefore(DateTime.now())) {
        continue;
      }
      cancelNotification(n.id);
    }
  })).catchError((e, st) => "Error canceling notifications: $e");
}
