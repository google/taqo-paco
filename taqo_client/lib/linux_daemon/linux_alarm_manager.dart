import 'dart:async';

import 'package:taqo_shared_prefs/taqo_shared_prefs.dart';

import '../model/action_specification.dart';
import '../model/event.dart';
import '../model/notification_holder.dart';
import '../scheduling/action_schedule_generator.dart';
import '../storage/dart_file_storage.dart';
import '../storage/esm_signal_storage.dart';
import '../util/date_time_util.dart';
import 'database/linux_database.dart';
import 'linux_notification_manager.dart' as linux_notification_manager;
import 'rpc_constants.dart';
import 'util.dart';

const _sharedPrefsLastAlarmKey = 'lastScheduledAlarm';

final _alarms = <int, ActionSpecification>{};

void _notify(int alarmId) async {
  print('notify: alarmId: $alarmId');
  DateTime start;
  Duration duration;
  final database = await LinuxDatabase.get();
  final actionSpec = await database.getAlarm(alarmId);
  if (actionSpec != null) {
    // To handle simultaneous alarms as well as possible delay in alarm callbacks,
    // show all notifications from the originally schedule alarm time until
    // 30 seconds after the current time
    start = actionSpec.time;
    duration = DateTime.now().add(Duration(seconds: 30)).difference(start);
    final experiments = await readJoinedExperiments();
    final allAlarms = await getAllAlarmsWithinRange(DartFileStorage(ESMSignalStorage.filename),
        experiments, start: start, duration: duration);
    print('Showing ${allAlarms.length} alarms from: $start to: ${start.add(duration)}');
    var i = 0;
    for (var a in allAlarms) {
      print('[${i++}] Showing ${a.time}');
      linux_notification_manager.showNotification(a);
    }

    // Store last shown notification time
    final storageDir = DartFileStorage.getLocalStorageDir().path;
    final sharedPreferences = TaqoSharedPrefs(storageDir);
    print('Storing ${start.add(duration)}');
    sharedPreferences.setString(_sharedPrefsLastAlarmKey, start.add(duration).toIso8601String());
  }

  // Cleanup alarm
  cancel(alarmId);
  // schedule the next one
  final from = start?.add(duration)?.add(Duration(seconds: 1));
  print('scheduleNext from $from');
  _scheduleNextNotification(from: from);
}

void _expire(int alarmId) async {
  print('expire: alarmId: $alarmId');
  // Cancel notification
  final database = await LinuxDatabase.get();
  final toCancel = await database.getAlarm(alarmId);
  // TODO Move the matches() logic to SQL
  final notifications = await database.getAllNotifications();
  if (notifications != null) {
    final match = notifications.firstWhere((notificationHolder) =>
        notificationHolder.matchesAction(toCancel), orElse: () => null);
    if (match != null) {
      timeout(match.id);
    }
  }

  // Cleanup alarm
  cancel(alarmId);
}

/// Schedule an alarm for [actionSpec] at [when] to run [callback]
Future<int> _schedule(ActionSpecification actionSpec, DateTime when, String what) async {
  final duration = when.difference(DateTime.now());
  if (duration.inMilliseconds < 0) return -1;

  final database = await LinuxDatabase.get();
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
      print('Notification for $actionSpec already scheduled');
      return false;
    }
  }

  final alarmId = await _schedule(actionSpec, actionSpec.time, notifyMethod);
  print('_scheduleNotification: alarmId: $alarmId when: ${actionSpec.time}');
  return alarmId >= 0;
}

void _scheduleTimeout(ActionSpecification actionSpec) async {
  final timeout = actionSpec.action.timeout;
  final alarmId = await _schedule(actionSpec, actionSpec.time.add(Duration(minutes: timeout)), expireMethod);
  print('_scheduleTimeout: alarmId: $alarmId'
      ' when: ${actionSpec.time.add(Duration(minutes: timeout))}');
}

void _scheduleNextNotification({DateTime from}) async {
  DateTime lastSchedule = DateTime.now();
  final storageDir = DartFileStorage.getLocalStorageDir().path;
  final sharedPreferences = TaqoSharedPrefs(storageDir);
  final dt = await sharedPreferences.getString(_sharedPrefsLastAlarmKey);
  //print('lastScheduledAlarm: $dt');
  if (dt != null) {
    lastSchedule = DateTime.parse(dt).add(Duration(seconds: 1));
  }

  // To avoid scheduling an alarm that was already shown by the logic in _notifyCallback
  from ??= DateTime.now();
  from = getLater(from, lastSchedule);
  print('_scheduleNextNotification from: $from');

  final experiments = await readJoinedExperiments();
  getNextAlarmTime(DartFileStorage(ESMSignalStorage.filename), experiments, now: from)
      .then((actionSpec) async {
    if (actionSpec != null) {
      // Schedule a notification
      _scheduleNotification(actionSpec).then((scheduled) {
        if (scheduled) {
          // Schedule a timeout
          _scheduleTimeout(actionSpec);
        }
      });
    }
  });
}

void scheduleNextNotification() async {
  // Cancel all alarms, except for timeouts for past notifications
  final database = await LinuxDatabase.get();
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
  final database = await LinuxDatabase.get();
  database.removeAlarm(alarmId);
  _alarms.remove(alarmId);
}

Future<void> cancelAll() async {
  final database = await LinuxDatabase.get();
  (await database.getAllAlarms()).keys.forEach((alarmId) async => await cancel(alarmId));
}

void timeout(int id) async {
  final storage = await LinuxDatabase.get();
  _createMissedEvent(await storage.getNotification(id));
  linux_notification_manager.cancelNotification(id);
}

void _createMissedEvent(NotificationHolder notification) async {
  if (notification == null) return;
  print('_createMissedEvent: ${notification.id}');
  // TODO In Taqo, we query the server for the Experiments here... is that necessary?
  final experiments = await readJoinedExperiments();
  final experiment = experiments.firstWhere((e) => e.id == notification.experimentId);
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
  final storage = await LinuxDatabase.get();
  storage.insertEvent(event);
}
