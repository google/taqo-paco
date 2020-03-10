import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:taqo_notify_plugin/taqo_notify_plugin.dart' as taqo_notify_plugin;

import '../../main.dart';
import '../../model/action_specification.dart';
import '../../model/experiment.dart';
import '../../model/notification_holder.dart';
import '../../pages/running_experiments_page.dart';
import '../../pages/survey/survey_page.dart';
import '../../storage/local_database.dart';
import '../experiment_service.dart';
import 'taqo_alarm.dart' as taqo_alarm;

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
    final pendingNotifications = await LocalDatabase()
        .getAllNotificationsForExperiment(actionSpec.experiment);
    await Future.forEach(pendingNotifications, (pn) async {
      if (notificationHolder.sameGroupAs(pn)) {
        await taqo_alarm.timeout(pn.id);
      }
    });
  }

  final id = await LocalDatabase().insertNotification(notificationHolder);

  await taqo_notify_plugin.showNotification(id, actionSpec.experiment.title, notificationHolder.message);

  return id;
}

/// Initialize the plugin
Future init() async {
  WidgetsFlutterBinding.ensureInitialized();
  return taqo_notify_plugin.initialize(openSurvey);
}

/// Open the survey that triggered the notification
Future<void> openSurvey(int payload) async {
  final id = payload;
  final notificationHolder = await LocalDatabase().getNotification(id);

  if (notificationHolder == null) {
    print('No holder for payload: $payload');
    return;
  }

  if (!notificationHolder.isActive && !notificationHolder.isFuture) {
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

/// Cancel notification with [id]
Future cancelNotification(int id) {
  taqo_notify_plugin.cancel(id).catchError((e, st) => print("Error canceling notification id $id: $e"));
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
