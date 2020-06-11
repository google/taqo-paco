import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:taqo_common/model/event.dart';
import 'package:taqo_common/model/experiment.dart';
import 'package:taqo_common/model/notification_holder.dart';
import 'package:taqo_common/util/date_time_util.dart';

import '../../main.dart';
import '../../pages/running_experiments_page.dart';
import '../../pages/survey/survey_page.dart';
import '../experiment_service.dart';
import '../platform_service.dart' as platform_service;
import 'android_alarm_manager.dart' as android_alarm_manager;
import 'flutter_local_notifications.dart' as flutter_local_notifications;
import 'ios_notification_scheduler.dart' as ios_notification_scheduler;

final _logger = Logger('TaqoAlarm');

Future init() {
  if (Platform.isLinux) {
    return schedule(cancelAndReschedule: false);
  } else {
    return flutter_local_notifications.init().then((_) =>
        schedule(cancelAndReschedule: false));
  }
}

Future<bool> checkActiveNotification() async {
  final db = await platform_service.databaseImpl;
  final activeNotifications = (await db.getAllNotifications()).where(
          (n) => n.isActive);
  return activeNotifications.isNotEmpty;
}

Future schedule({bool cancelAndReschedule=true}) async {
  // TODO schedule alarms in background
  // TODO the calculate() API currently doesn't support using plugins
  if (Platform.isAndroid) {
    android_alarm_manager.scheduleNextNotification();
  } else if (Platform.isIOS || Platform.isMacOS) {
    if (cancelAndReschedule) {
      await flutter_local_notifications.cancelAllNotifications();
    }
    ios_notification_scheduler.schedule();
  } else if (Platform.isLinux) {
    try {
      platform_service.tespClient.then((tespClient) {
        tespClient.alarmSchedule();
      });
    } catch (e) {
      _logger.warning(e);
    }
  }
}

Future cancel(int id) async {
  if (Platform.isAndroid) {
    flutter_local_notifications.cancelNotification(id);
  } else if (Platform.isIOS || Platform.isMacOS) {
    await flutter_local_notifications.cancelNotification(id);
    await schedule(cancelAndReschedule: false);
  } else if (Platform.isLinux) {
    try {
      platform_service.tespClient.then((tespClient) {
        tespClient.notificationCancel(id);
      });
    } catch (e) {
      _logger.warning(e);
    }
  }
}

Future cancelForExperiment(Experiment experiment) async {
  if (Platform.isAndroid) {
    flutter_local_notifications.cancelForExperiment(experiment);
  } else if (Platform.isIOS || Platform.isMacOS) {
    await flutter_local_notifications.cancelForExperiment(experiment);
    await schedule(cancelAndReschedule: false);
  } else if (Platform.isLinux) {
    try {
      platform_service.tespClient.then((tespClient) {
        tespClient.notificationCancelByExperiment(experiment.id);
      });
    } catch (e) {
      _logger.warning(e);
    }
  }
}

Future timeout(int id) async {
  cancel(id);
  _createMissedEvent(id);
}

/// Open the survey that triggered the notification
Future<void> openSurvey(String payload) async {
  final id = int.tryParse(payload);

  final db = await platform_service.databaseImpl;
  final notificationHolder = await db.getNotification(id);

  if (notificationHolder == null) {
    _logger.info('No holder for payload: $payload');
    return;
  }

  // TODO Timezone could have changed?
  if (!notificationHolder.isActive && !notificationHolder.isFuture) {
    await timeout(id);
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
    _logger.warning('StateError: $e');
    _logger.info(stack);
  }
}

void _createMissedEvent(int notificationId) async {
  final db = await platform_service.databaseImpl;
  final NotificationHolder notification = await db.getNotification(notificationId);
  if (notification == null) return;

  final service = await ExperimentService.getInstance();
  final experiment = await service.getExperimentFromServerById(notification.experimentId);
  if (experiment == null) {
    return;
  }

  final event = Event();
  event.experimentId = experiment.id;
  event.experimentName = experiment.title;
  event.groupName = notification.experimentGroupName;
  event.actionId = notification.actionId;
  event.actionTriggerId = notification.actionTriggerId;
  event.actionTriggerSpecId = notification.actionTriggerSpecId;
  event.experimentVersion = experiment.version;
  event.scheduleTime = getZonedDateTime(DateTime.fromMillisecondsSinceEpoch(notification.alarmTime));

  db.insertEvent(event);
}
