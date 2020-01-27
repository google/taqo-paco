import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../main.dart';
import '../model/action_specification.dart';
import '../model/experiment.dart';
import '../model/notification_holder.dart';
import '../storage/local_database.dart';
import '../pages/survey/survey_page.dart';
import 'alarm_service.dart' as alarm_manager;
import 'experiment_service.dart';

class _ReceivedNotification {
  final int id;
  final String title;
  final String body;
  final String payload;

  _ReceivedNotification(this.id, this.title, this.body, this.payload);
}

const _ANDROID_NOTIFICATION_CHANNEL_ID = "com.taqo.survey.taqosurvey.NOTIFICATIONS";
const _ANDROID_NOTIFICATION_CHANNEL_NAME = "Experiment Reminders";
const _ANDROID_NOTIFICATION_CHANNEL_DESC = "Reminders to participate in Experiments";
const _ANDROID_ICON = "paco256";
const _ANDROID_SOUND = "deepbark_trial";

final _plugin = FlutterLocalNotificationsPlugin();

// For iOS only, when notification is received while app has foreground
final _receivedNotifications = StreamController<_ReceivedNotification>();
final _selectedNotifications = StreamController<String>();

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

/// The callback when a notification is tapped by the user
void _handleNotification(String payload) async {
  print('handle $payload');
  getLaunchDetails().then((launchDetails) {
    if (!launchDetails.didNotificationLaunchApp) {
      openSurvey(payload);
    }
  });
}

/// Initialize the plugin
Future<void> init() async {
  WidgetsFlutterBinding.ensureInitialized();

  final initSettingsAndroid = AndroidInitializationSettings(_ANDROID_ICON);
  final initSettingsIOS = IOSInitializationSettings(
      onDidReceiveLocalNotification: (int id, String title, String body, String payload) async {
    // TODO Can we just add the payload to one Stream?
    _receivedNotifications.add(_ReceivedNotification(id, title, body, payload));
  });

  final initSettings = InitializationSettings(initSettingsAndroid, initSettingsIOS);
  await _plugin.initialize(initSettings, onSelectNotification: (String payload) async {
    // TODO Is this all I need?
    _selectedNotifications.add(payload);
  });

  // Listen
  _receivedNotifications.stream.listen((_ReceivedNotification notification) {
    _handleNotification(notification.payload);
  });
  _selectedNotifications.stream.listen((String payload) {
    _handleNotification(payload);
  });
}

void dispose() {
  if (_selectedNotifications != null) {
    _selectedNotifications.close();
  }
  if (_receivedNotifications != null) {
    _receivedNotifications.close();
  }
}

/// For finding out if the app was launched in response to a notification being tapped
Future<NotificationAppLaunchDetails> getLaunchDetails() =>
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

  // Cancel timeout
  (await LocalDatabase().getAllAlarms()).entries.forEach((alarm) async {
    if (notificationHolder.matchesAction(alarm.value)) {
      alarm_manager.cancel(alarm.key);
    }
  });

  try {
    final e = ExperimentService()
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
