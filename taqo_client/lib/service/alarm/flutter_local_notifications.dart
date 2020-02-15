import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../main.dart';
import '../../model/action_specification.dart';
import '../../model/experiment.dart';
import '../../model/notification_holder.dart';
import '../../pages/running_experiments_page.dart';
import '../../pages/survey/survey_page.dart';
import '../../storage/local_database.dart';
import '../experiment_service.dart';
import 'taqo_alarm.dart' as taqo_alarm;

const _ANDROID_NOTIFICATION_CHANNEL_ID = "com.taqo.survey.taqosurvey.NOTIFICATIONS";
const _ANDROID_NOTIFICATION_CHANNEL_NAME = "Experiment Reminders";
const _ANDROID_NOTIFICATION_CHANNEL_DESC = "Reminders to participate in Experiments";
const _ANDROID_ICON = "paco256";
const _ANDROID_SOUND = "deepbark_trial";

final _plugin = FlutterLocalNotificationsPlugin();

final _notificationHandledStream = StreamController<String>();

/// The callback when a notification is tapped by the user
void _handleNotification(String payload) async {
  print('Handle $payload');
  openSurvey(payload);
}

/// Shows or schedules a notification with the plugin
Future<int> _notify(ActionSpecification actionSpec, {DateTime when,
    bool cancelPending=true}) async {
  var timeout = 59;
  if (actionSpec.action != null) {
    timeout = actionSpec.action.timeout ?? timeout;
  }

  final notificationHolder = NotificationHolder(
    -1,   // placeholder, the real ID will be assigned by sqlite
    actionSpec.time.millisecondsSinceEpoch,
    actionSpec.experiment.id,
    0,
    1000 * 60 * timeout,
    actionSpec.experimentGroup.name,
    actionSpec.actionTrigger.id,
    actionSpec.action?.id,
    null,
    actionSpec.action == null ? "Time to participate" : actionSpec.action.msgText,
    actionSpec.actionTriggerSpecId,
  );

  // Cancel existing (pending) notifications for the same survey
  // On Android, we create the notification at the time of the alarm
  // Therefore we should timeout any pending notifications for the same survey
  // We don't want to do this on iOS where we are aggressively pre-scheduling
  // notifications
  if (cancelPending) {
    final pendingNotifications = await LocalDatabase()
        .getAllNotificationsForExperiment(actionSpec.experiment);
    await Future.forEach(pendingNotifications, (pn) async {
      if (notificationHolder.sameGroupAs(pn)) {
        await taqo_alarm.timeout(pn.id);
      }
    });
  }

  final id = await LocalDatabase().insertNotification(notificationHolder);

  final androidDetails = AndroidNotificationDetails(
    _ANDROID_NOTIFICATION_CHANNEL_ID,
    _ANDROID_NOTIFICATION_CHANNEL_NAME,
    _ANDROID_NOTIFICATION_CHANNEL_DESC,
    sound: _ANDROID_SOUND,
  );
  final iOSDetails = IOSNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'deepbark_trial.m4a');
  final macOSDetails = MacOSNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'deepbark_trial.m4a');
  final details = NotificationDetails(androidDetails, iOSDetails, macOSDetails);

  if (when != null) {
    await _plugin.schedule(
        id, actionSpec.experiment.title, notificationHolder.message, when, details,
        payload: "$id", androidAllowWhileIdle: true);
  } else {
    await _plugin.show(
        id, actionSpec.experiment.title, notificationHolder.message, details, payload: "$id");
  }

  return id;
}

/// Initialize the plugin
Future init() async {
  WidgetsFlutterBinding.ensureInitialized();

  final initSettingsAndroid = AndroidInitializationSettings(_ANDROID_ICON);
  final initSettingsIOS = IOSInitializationSettings(
      onDidReceiveLocalNotification: (int id, String title, String body, String payload) async {
        _notificationHandledStream.add(payload);
      });
  final initSettingsMacOS = MacOSInitializationSettings(
      onDidReceiveLocalNotification: (int id, String title, String body, String payload) async {
        _notificationHandledStream.add(payload);
      });

  final initSettings = InitializationSettings(
      initSettingsAndroid, initSettingsIOS, initSettingsMacOS);
  await _plugin.initialize(initSettings, onSelectNotification: (String payload) async {
    _notificationHandledStream.add(payload);
  });

  _notificationHandledStream.stream.listen((String payload) {
    _handleNotification(payload);
  });
}

/// For finding out if the app was launched from a notification
Future<NotificationAppLaunchDetails> get launchDetails =>
    _plugin.getNotificationAppLaunchDetails();

/// Open the survey that triggered the notification
Future<void> openSurvey(String payload) async {
  final id = int.tryParse(payload);
  final notificationHolder = await LocalDatabase().getNotification(id);

  if (notificationHolder == null) {
    print('No holder for payload: $payload');
    return;
  }

  // Timezone could have changed
  if (!notificationHolder.isActive) {
    await taqo_alarm.timeout(id);
    MyApp.navigatorKey.currentState.pushReplacementNamed(
        RunningExperimentsPage.routeName, arguments: [true, ]);
    return;
  }

  try {
    final service = await ExperimentService.getInstance();
    final e = service
        .getJoinedExperiments()
        .firstWhere((e) => e.id == notificationHolder.experimentId);
    e.groups.firstWhere((g) => g.name == notificationHolder.experimentGroupName);
    MyApp.navigatorKey.currentState.pushReplacementNamed(SurveyPage.routeName,
        arguments: [e, notificationHolder.experimentGroupName]);
  } on StateError catch (e, stack) {
    print('StateError: $e');
    print(stack);
  }
}

/// Show a notification now
Future<int> showNotification(ActionSpecification actionSpec) async {
  final id = await _notify(actionSpec);
  print('Showing notification id: $id @ ${actionSpec.time}');
  return id;
}

/// Schedule a notification at [actionSpec.time]
Future<int> scheduleNotification(ActionSpecification actionSpec,
    {bool cancelPending}) async {
  final id = await _notify(actionSpec, when: actionSpec.time,
      cancelPending: cancelPending);
  print('Scheduling notification id: $id @ ${actionSpec.time}');
  return id;
}

/// Cancel notification with [id]
Future cancelNotification(int id) {
  _plugin.cancel(id).catchError((e, st) => print("Error canceling notification id $id: $e"));
  return LocalDatabase().removeNotification(id);
}

/// Cancel all notifications for [experiment]
Future cancelForExperiment(Experiment experiment) {
  return LocalDatabase().getAllNotificationsForExperiment(experiment)
      .then((List<NotificationHolder> notifications) =>
      notifications.forEach((n) => cancelNotification(n.id)))
      .catchError((e, st) => "Error canceling notifications: $e");
}

/// Cancel all notifications, except ones that fired and are still pending
Future cancelAllNotifications() {
  return LocalDatabase().getAllNotifications()
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
