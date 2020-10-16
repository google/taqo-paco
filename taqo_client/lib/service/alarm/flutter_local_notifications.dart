import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logging/logging.dart';
import 'package:taqo_common/model/action_specification.dart';
import 'package:taqo_common/model/experiment.dart';
import 'package:taqo_common/model/notification_holder.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../service/platform_service.dart' as platform_service;
import 'taqo_alarm.dart' as taqo_alarm;

final _logger = Logger('FlutterLocalNotifications');

const _androidSoundResource =
    RawResourceAndroidNotificationSound("deepbark_trial");
const _appleSoundFile = "deepbark_trial.m4a";

const _androidNotificationChannelId =
    "com.taqo.survey.taqosurvey.NOTIFICATIONS";
const _androidNotificationChannelName = "Experiment Reminders";
const _androidNotificationChannelDesc =
    "Reminders to participate in Experiments";
const _androidIconResource = "paco256";

final _plugin = FlutterLocalNotificationsPlugin();

final _notificationHandledStream = StreamController<String>();

/// The callback when a notification is tapped by the user
void _handleNotification(String payload) async {
  _logger.info('Handle $payload');
  taqo_alarm.openSurvey(payload);
}

/// Shows or schedules a notification with the plugin
Future<int> _notify(ActionSpecification actionSpec,
    {DateTime when, bool cancelPending = true}) async {
  final notificationHolder = NotificationHolder(
    -1, // placeholder, the real ID will be assigned by sqlite
    actionSpec.time.millisecondsSinceEpoch,
    actionSpec.experiment.id,
    0,
    1000 * 60 * actionSpec.action.timeout,
    actionSpec.experimentGroup.name,
    actionSpec.actionTrigger.id,
    actionSpec.action?.id,
    null,
    actionSpec.action == null
        ? "Time to participate"
        : actionSpec.action.msgText,
    actionSpec.actionTriggerSpecId,
  );

  // Cancel existing (pending) notifications for the same survey
  // On Android, we create the notification at the time of the alarm
  // Therefore we should timeout any pending notifications for the same survey
  // We don't want to do this on iOS where we are aggressively pre-scheduling
  // notifications
  final db = await platform_service.databaseImpl;
  if (cancelPending) {
    final pendingNotifications =
        await db.getAllNotificationsForExperiment(actionSpec.experiment);
    await Future.forEach(pendingNotifications, (pn) async {
      if (notificationHolder.sameGroupAs(pn)) {
        await taqo_alarm.timeout(pn.id);
      }
    });
  }

  final id = await db.insertNotification(notificationHolder);

  final androidDetails = AndroidNotificationDetails(
    _androidNotificationChannelId,
    _androidNotificationChannelName,
    _androidNotificationChannelDesc,
    sound: _androidSoundResource,
  );
  final iOSDetails = IOSNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: _appleSoundFile);
  final macOSDetails = MacOSNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: _appleSoundFile);
  final details = NotificationDetails(
      android: androidDetails, iOS: iOSDetails, macOS: macOSDetails);

  if (when != null) {
    // Because system time zone changes trigger re-scheduling, we can always assume local here
    final tzWhen = tz.TZDateTime.local(
        when.year, when.month, when.day, when.hour, when.minute, when.second);
    await _plugin.zonedSchedule(id, actionSpec.experiment.title,
        notificationHolder.message, tzWhen, details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.wallClockTime,
        payload: "$id",
        androidAllowWhileIdle: true);
  } else {
    await _plugin.show(
        id, actionSpec.experiment.title, notificationHolder.message, details,
        payload: "$id");
  }

  return id;
}

/// Initialize the plugin
Future init() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();

  final initSettingsAndroid =
      AndroidInitializationSettings(_androidIconResource);
  final initSettingsIOS = IOSInitializationSettings(
      onDidReceiveLocalNotification:
          (int id, String title, String body, String payload) async {
    _notificationHandledStream.add(payload);
  });
  final initSettingsMacOS = MacOSInitializationSettings();

  final initSettings = InitializationSettings(
      android: initSettingsAndroid,
      iOS: initSettingsIOS,
      macOS: initSettingsMacOS);
  await _plugin.initialize(initSettings,
      onSelectNotification: (String payload) async {
    _notificationHandledStream.add(payload);
  });

  _notificationHandledStream.stream.listen((String payload) {
    _handleNotification(payload);
  });
}

/// For finding out if the app was launched from a notification
Future<NotificationAppLaunchDetails> get launchDetails =>
    _plugin.getNotificationAppLaunchDetails();

/// Show a notification now
Future<int> showNotification(ActionSpecification actionSpec) async {
  final id = await _notify(actionSpec);
  _logger.info('Showing notification id: $id @ ${actionSpec.time}');
  return id;
}

/// Schedule a notification at [actionSpec.time]
Future<int> scheduleNotification(ActionSpecification actionSpec,
    {bool cancelPending}) async {
  final id = await _notify(actionSpec,
      when: actionSpec.time, cancelPending: cancelPending);
  _logger.info('Scheduling notification id: $id @ ${actionSpec.time}');
  return id;
}

/// Cancel notification with [id]
Future cancelNotification(int id) async {
  _plugin.cancel(id).catchError(
      (e, st) => _logger.warning("Error canceling notification id $id: $e"));
  final db = await platform_service.databaseImpl;
  return db.removeNotification(id);
}

/// Cancel all notifications for [experiment]
Future cancelForExperiment(Experiment experiment) async {
  final db = await platform_service.databaseImpl;
  return db
      .getAllNotificationsForExperiment(experiment)
      .then((List<NotificationHolder> notifications) =>
          notifications.forEach((n) => cancelNotification(n.id)))
      .catchError((e, st) => "Error canceling notifications: $e");
}

/// Cancel all notifications, except ones that fired and are still pending
Future cancelAllNotifications() async {
  final db = await platform_service.databaseImpl;
  return db
      .getAllNotifications()
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
