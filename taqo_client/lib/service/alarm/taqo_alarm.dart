import 'dart:async';
import 'dart:io';

import '../../model/event.dart';
import '../../model/notification_holder.dart';
import '../../storage/local_database.dart';
import '../../util/date_time_util.dart';
import '../experiment_service.dart';
import 'android_alarm_manager.dart' as android_alarm_manager;
import 'flutter_local_notifications.dart' as flutter_local_notifications;
import 'ios_notification_scheduler.dart' as ios_notification_scheduler;

Future init() {
  // Init the actual notification plugin
  return flutter_local_notifications.init().then((value) => schedule());
}

Future schedule({bool cancelAll=false}) async {
  // TODO schedule alarms in background
  // TODO the calculate() API currently doesn't support using plugins
  if (Platform.isAndroid) {
    android_alarm_manager.scheduleNextNotification();
  } else if (Platform.isIOS || Platform.isMacOS) {
    if (cancelAll) {
      await flutter_local_notifications.cancelAllNotifications();
    }
    ios_notification_scheduler.schedule();
  }
}

void cancel(int id) {
  if (Platform.isAndroid) {
    android_alarm_manager.cancel(id);
  } else if (Platform.isIOS || Platform.isMacOS) {
    flutter_local_notifications.cancelNotification(id);
    schedule();
  }
}

Future timeout(int id) async {
  _createMissedEvent(await LocalDatabase().getNotification(id));
  return flutter_local_notifications.cancelNotification(id);
}

void _createMissedEvent(NotificationHolder notification) async {
  print('_createMissedEvent: ${notification.id}');
  final service = await ExperimentService.getInstance();
  final experiment = await service.getExperimentFromServerById(notification.experimentId);
  final event = Event();
  event.experimentId = experiment.id;
  event.experimentServerId = experiment.id;
  event.experimentName = experiment.title;
  event.groupName = notification.experimentGroupName;
  event.actionId = notification.actionId;
  event.actionTriggerId = notification.actionTriggerId;
  event.actionTriggerSpecId = notification.actionTriggerSpecId;
  event.experimentVersion = experiment.version;
  event.scheduleTime = getZonedDateTime(DateTime.fromMillisecondsSinceEpoch(notification.alarmTime));
  LocalDatabase().insertEvent(event);
}
