import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../main.dart';
import '../../model/action_specification.dart';
import '../../model/experiment.dart';
import '../../model/notification_holder.dart';
import '../../pages/survey/survey_page.dart';
import '../../storage/local_database.dart';
import '../experiment_service.dart';

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
Future<int> _notify(ActionSpecification actionSpec, {DateTime when}) async {
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

  // Cancel existing notifications for the same survey
  final pending = await LocalDatabase().getAllNotificationsForExperiment(actionSpec.experiment);
  for (var n in pending) {
    if (notificationHolder.sameGroupAs(n)) {
      cancelNotification(n.id);
    }
  }

  final id = await LocalDatabase().insertNotification(notificationHolder);
  print('Showing notification id: $id @ ${actionSpec.time}');

  final androidDetails = AndroidNotificationDetails(
    _ANDROID_NOTIFICATION_CHANNEL_ID,
    _ANDROID_NOTIFICATION_CHANNEL_NAME,
    _ANDROID_NOTIFICATION_CHANNEL_DESC,
    sound: _ANDROID_SOUND,
  );
  final iOSDetails = IOSNotificationDetails();
  final details = NotificationDetails(androidDetails, iOSDetails);

  if (when != null) {
    await _plugin.show(
        id, actionSpec.experiment.title, notificationHolder.message, details, payload: "$id");
  } else {
    await _plugin.schedule(
        id, actionSpec.experiment.title, notificationHolder.message, actionSpec.time, details,
        payload: "$id", androidAllowWhileIdle: true);
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

  final initSettings = InitializationSettings(initSettingsAndroid, initSettingsIOS);
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
  LocalDatabase().removeNotification(id);

  if (notificationHolder == null) {
    print('No holder for payload: $payload');
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
Future<int> showNotification(ActionSpecification actionSpec) {
  return _notify(actionSpec);
}

/// Schedule a notification at [actionSpec.time]
Future<int> scheduleNotification(ActionSpecification actionSpec) {
  return _notify(actionSpec, when: actionSpec.time);
}

/// Cancel notification with [id]
void cancelNotification(int id) {
  _plugin.cancel(id).catchError((e, st) => print("Error canceling notification id $id: $e"));
  LocalDatabase().removeNotification(id);
}

/// Cancel all notifications for [experiment]
void cancelForExperiment(Experiment experiment) async {
  LocalDatabase().getAllNotificationsForExperiment(experiment)
      .then((List<NotificationHolder> notifications) =>
      notifications.forEach((n) => cancelNotification(n.id)))
      .catchError((e, st) => "Error canceling notifications: $e");
}

/// Cancel all notifications
void cancelAllNotifications() {
  _plugin.cancelAll().catchError((e, st) => print("Error canceling notifications: $e"));
  LocalDatabase().removeAllNotifications();
}
