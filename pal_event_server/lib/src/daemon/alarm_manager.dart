// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// @dart=2.9

import 'dart:async';

import 'package:logging/logging.dart';
import 'package:taqo_shared_prefs/taqo_shared_prefs.dart';

import 'package:taqo_common/model/action_specification.dart';
import 'package:taqo_common/model/event.dart';
import 'package:taqo_common/model/notification_holder.dart';
import 'package:taqo_common/rpc/rpc_constants.dart';
import 'package:taqo_common/scheduling/action_schedule_generator.dart';
import 'package:taqo_common/storage/dart_file_storage.dart';
import 'package:taqo_common/storage/esm_signal_storage.dart';
import 'package:taqo_common/util/date_time_util.dart';

import '../experiment_service_local.dart';
import '../sqlite_database/sqlite_database.dart';
import 'notification_manager.dart' as notification_manager;

final _logger = Logger('DaemonAlarmManager');

const _sharedPrefsLastAlarmKey = 'lastScheduledAlarm';

final _alarms = <int, ActionSpecification>{};

void _notify(int alarmId) async {
  _logger.info('notify: alarmId: $alarmId');
  DateTime start;
  Duration duration;
  final database = await SqliteDatabase.get();
  final actionSpec = await database.getAlarm(alarmId);
  if (actionSpec != null) {
    final allAlarms = Set.from([actionSpec]);
    // To handle simultaneous alarms as well as possible delay in alarm callbacks,
    // show all notifications from the originally schedule alarm time until
    // 30 seconds after the current time
    start = actionSpec.time;
    duration = DateTime.now().add(Duration(seconds: 30)).difference(start);
    final experimentService = await ExperimentServiceLocal.getInstance();
    final experiments = await experimentService.getJoinedExperiments();
    allAlarms.addAll(await getAllAlarmsWithinRange(
        DartFileStorage(ESMSignalStorage.filename), experiments,
        start: start, duration: duration));
    _logger.info(
        'Showing ${allAlarms.length} alarms from: $start to: ${start.add(duration)}');
    var i = 0;
    for (var a in allAlarms) {
      _logger.info('[${i++}] Showing ${a.time}');
      notification_manager.showNotification(a);
    }

    // Store last shown notification time
    final storageDir = DartFileStorage.getLocalStorageDir().path;
    final sharedPreferences = TaqoSharedPrefs(storageDir);
    _logger.info('Storing ${start.add(duration)}');
    sharedPreferences.setString(
        _sharedPrefsLastAlarmKey, start.add(duration).toIso8601String());
  }

  // Cleanup alarm
  cancel(alarmId);
  // schedule the next one
  final from = start?.add(duration)?.add(Duration(seconds: 1));
  _logger.info('scheduleNext from $from');
  _scheduleNextNotification(from: from);
}

void _expire(int alarmId) async {
  _logger.info('expire: alarmId: $alarmId');
  // Cancel notification
  final database = await SqliteDatabase.get();
  final toCancel = await database.getAlarm(alarmId);
  // TODO Move the matches() logic to SQL
  final notifications = await database.getAllNotifications();
  if (notifications != null) {
    final match = notifications.firstWhere(
        (notificationHolder) => notificationHolder.matchesAction(toCancel),
        orElse: () => null);
    if (match != null) {
      timeout(match.id);
    }
  }

  // Cleanup alarm
  cancel(alarmId);
}

/// Schedule an alarm for [actionSpec] at [when] to run [callback]
Future<int> _schedule(
    ActionSpecification actionSpec, DateTime when, String what) async {
  final database = await SqliteDatabase.get();
  final alarmId = await database.insertAlarm(actionSpec);

  final alarm = Future.delayed(when.difference(DateTime.now()));
  alarm.then((_) {
    // Dart doesn't allow a Future to be "canceled"
    // So we use the Map to track which timers are still active
    if (_alarms.containsKey(alarmId)) {
      if (notifyMethod == what) {
        _notify(alarmId);
      } else if (expireMethod == what) {
        _expire(alarmId);
      }
    }
  });

  _alarms[alarmId] = actionSpec;
  return alarmId;
}

Future<bool> _scheduleNotification(ActionSpecification actionSpec) async {
  // Don't show a notification that's already pending
  for (var as in _alarms.values) {
    if (as == actionSpec) {
      _logger.info('Notification for $actionSpec already scheduled');
      return false;
    }
  }

  final alarmId = await _schedule(actionSpec, actionSpec.time, notifyMethod);
  _logger.info(
      '_scheduleNotification: alarmId: $alarmId when: ${actionSpec.time}');
  return alarmId >= 0;
}

void _scheduleTimeout(ActionSpecification actionSpec) async {
  final timeout = actionSpec.action.timeout;
  final alarmId = await _schedule(actionSpec,
      actionSpec.time.add(Duration(minutes: timeout)), expireMethod);
  _logger.info('_scheduleTimeout: alarmId: $alarmId'
      ' when: ${actionSpec.time.add(Duration(minutes: timeout))}');
}

void _scheduleNextNotification({DateTime from}) async {
  DateTime lastSchedule = DateTime.now();
  final storageDir = DartFileStorage.getLocalStorageDir().path;
  final sharedPreferences = TaqoSharedPrefs(storageDir);
  final dt = await sharedPreferences.getString(_sharedPrefsLastAlarmKey);
  //_logger.info('lastScheduledAlarm: $dt');
  if (dt != null) {
    lastSchedule = DateTime.parse(dt).add(Duration(seconds: 1));
  }

  // To avoid scheduling an alarm that was already shown by the logic in _notifyCallback
  from ??= DateTime.now();
  from = getLater(from, lastSchedule);
  _logger.info('_scheduleNextNotification from: $from');

  final experimentService = await ExperimentServiceLocal.getInstance();
  final experiments = await experimentService.getJoinedExperiments();
  getNextAlarmTime(DartFileStorage(ESMSignalStorage.filename), experiments,
          now: from)
      .then((actionSpec) async {
    if (actionSpec != null) {
      createNotificationWithTimeout(actionSpec);
    }
  });
}

void createNotificationWithTimeout(ActionSpecification actionSpec) {
  // Schedule a notification
  _scheduleNotification(actionSpec).then((scheduled) {
    if (scheduled) {
      // Schedule a timeout
      _scheduleTimeout(actionSpec);
    }
  });
}

void scheduleNextNotification() async {
  // Cancel all alarms, except for timeouts for past notifications
  final database = await SqliteDatabase.get();
  final allAlarms = await database.getAllAlarms();
  for (var alarm in allAlarms.entries) {
    // TODO Handle timezone change on Linux
    if (alarm.value.timeUTC.isAfter(DateTime.now().toUtc())) {
      await cancel(alarm.key);
    }
  }
  // reschedule
  _scheduleNextNotification();
}

Future<void> cancel(int alarmId) async {
  final database = await SqliteDatabase.get();
  database.removeAlarm(alarmId);
  _alarms.remove(alarmId);
}

Future<void> cancelAll() async {
  final database = await SqliteDatabase.get();
  (await database.getAllAlarms())
      .keys
      .forEach((alarmId) async => await cancel(alarmId));
}

void timeout(int id) async {
  final storage = await SqliteDatabase.get();
  _createMissedEvent(await storage.getNotification(id));

  notification_manager.cancelNotification(id);
}

void _createMissedEvent(NotificationHolder notification) async {
  if (notification == null) return;
  _logger.info('_createMissedEvent: ${notification.id}');
  // TODO In Taqo, we query the server for the Experiments here... is that necessary?
  final experimentService = await ExperimentServiceLocal.getInstance();
  final experiments = await experimentService.getJoinedExperiments();
  final experiment =
      experiments.firstWhere((e) => e.id == notification.experimentId);
  final event = Event();
  event.experimentId = experiment.id;
  event.experimentName = experiment.title;
  event.groupName = notification.experimentGroupName;
  event.actionId = notification.actionId;
  event.actionTriggerId = notification.actionTriggerId;
  event.actionTriggerSpecId = notification.actionTriggerSpecId;
  event.experimentVersion = experiment.version;
  event.scheduleTime = getZonedDateTime(
      DateTime.fromMillisecondsSinceEpoch(notification.alarmTime));
  final storage = await SqliteDatabase.get();
  storage.insertEvent(event);
}
