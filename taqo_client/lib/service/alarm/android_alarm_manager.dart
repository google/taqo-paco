import 'dart:isolate';

import 'package:android_alarm_manager/android_alarm_manager.dart';
import 'package:taqo_common/model/action_specification.dart';
import 'package:taqo_common/scheduling/action_schedule_generator.dart';
import 'package:taqo_common/storage/esm_signal_storage.dart';
import 'package:taqo_common/util/date_time_util.dart';
import 'package:taqo_shared_prefs/taqo_shared_prefs.dart';

import '../../storage/flutter_file_storage.dart';
import '../../storage/local_database.dart';
import '../experiment_service.dart';
import 'flutter_local_notifications.dart' as flutter_local_notifications;
import 'taqo_alarm.dart' as taqo_alarm;

const SHARED_PREFS_LAST_ALARM_TIME = 'lastScheduledAlarm';

/// Schedule an alarm for [actionSpec] at [when] to run [callback]
Future<int> _schedule(ActionSpecification actionSpec, DateTime when, Function(int) callback) {
  return AndroidAlarmManager.initialize().then((success) async {
    if (success) {
      final storage = await LocalDatabase.get(FlutterFileStorage(LocalDatabase.dbFilename));
      final alarmId = await storage.insertAlarm(actionSpec);
      AndroidAlarmManager.oneShotAt(when, alarmId, callback,
          allowWhileIdle: true, exact: true, rescheduleOnReboot: true, wakeup: true);
      return alarmId;
    }
    return -1;
  });
}

Future<bool> _scheduleNotification(ActionSpecification actionSpec) async {
  // Don't show a notification that's already pending
  final storage = await LocalDatabase.get(FlutterFileStorage(LocalDatabase.dbFilename));
  final alarms = await storage.getAllAlarms();
  for (var as in alarms.values) {
    if (as == actionSpec) {
      print('Notification for $actionSpec already scheduled');
      return false;
    }
  }

  final alarmId = await _schedule(actionSpec, actionSpec.time, _notifyCallback);
  print('_scheduleNotification: alarmId: $alarmId when: ${actionSpec.time}'
      ' isolate: ${Isolate.current.hashCode}');
  return alarmId >= 0;
}

void _scheduleTimeout(ActionSpecification actionSpec) async {
  final timeout = actionSpec.action.timeout;
  final alarmId = await _schedule(actionSpec, actionSpec.time.add(Duration(minutes: timeout)), _expireCallback);
  print('_scheduleTimeout: alarmId: $alarmId'
      ' when: ${actionSpec.time.add(Duration(minutes: timeout))}'
      ' isolate: ${Isolate.current.hashCode}');
}

void _notifyCallback(int alarmId) async {
  // This is running in a different (background) Isolate
  print('notify: alarmId: $alarmId isolate: ${Isolate.current.hashCode}');
  DateTime start;
  Duration duration;
  final storage = await LocalDatabase.get(FlutterFileStorage(LocalDatabase.dbFilename));
  final actionSpec = await storage.getAlarm(alarmId);
  if (actionSpec != null) {
    // To handle simultaneous alarms as well as possible delay in alarm callbacks,
    // show all notifications from the originally schedule alarm time until
    // 30 seconds after the current time
    start = actionSpec.time;
    duration = DateTime.now().add(Duration(seconds: 30)).difference(start);
    final service = await ExperimentService.getInstance();
    final experiments = service.getJoinedExperiments();
    final allAlarms = await getAllAlarmsWithinRange(FlutterFileStorage(ESMSignalStorage.filename),
        experiments, start: start, duration: duration);
    print('Showing ${allAlarms.length} alarms from: $start to: ${start.add(duration)}');
    var i = 0;
    for (var a in allAlarms) {
      print('[${i++}] Showing ${a.time}');
      flutter_local_notifications.showNotification(a);
    }

    // Store last shown notification time
    final storageDir = (await FlutterFileStorage.getLocalStorageDir()).path;
    final sharedPreferences = TaqoSharedPrefs(storageDir);
    print('Storing ${start.add(duration)}');
    sharedPreferences.setString(SHARED_PREFS_LAST_ALARM_TIME, start.add(duration).toIso8601String());
  }

  // Cleanup alarm
  cancel(alarmId);
  // schedule the next one
  final from = start?.add(duration)?.add(Duration(seconds: 1));
  print('scheduleNext from $from');
  _scheduleNextNotification(from: from);
}

void _expireCallback(int alarmId) async {
  // This is running in a different (background) Isolate
  print('expire: alarmId: $alarmId isolate: ${Isolate.current.hashCode}');
  // Cancel notification
  final storage = await LocalDatabase.get(FlutterFileStorage(LocalDatabase.dbFilename));
  final toCancel = await storage.getAlarm(alarmId);
  // TODO Move the matches() logic to SQL
  final notifications = await storage.getAllNotifications();
  if (notifications != null) {
    final match = notifications.firstWhere((notificationHolder) =>
        notificationHolder.matchesAction(toCancel), orElse: () => null);
    if (match != null) {
      taqo_alarm.timeout(match.id);
    }
  }

  // Cleanup alarm
  cancel(alarmId);
}

void _scheduleNextNotification({DateTime from}) async {
  DateTime lastSchedule;
  final storageDir = (await FlutterFileStorage.getLocalStorageDir()).path;
  final sharedPreferences = TaqoSharedPrefs(storageDir);
  final dt = await sharedPreferences.getString(SHARED_PREFS_LAST_ALARM_TIME);
  print('loaded $dt');
  if (dt != null) {
    lastSchedule = DateTime.parse(dt).add(Duration(seconds: 1));
  }

  // To avoid scheduling an alarm that was already shown by the logic in _notifyCallback
  from ??= DateTime.now();
  from = getLater(from, lastSchedule);
  print('_scheduleNextNotification from: $from');

  final service = await ExperimentService.getInstance();
  final experiments = service.getJoinedExperiments();
  getNextAlarmTime(FlutterFileStorage(ESMSignalStorage.filename), experiments, now: from)
      .then((ActionSpecification actionSpec) async {
    if (actionSpec != null) {
      // Schedule a notification (android_alarm_manager)
      _scheduleNotification(actionSpec).then((scheduled) {
        if (scheduled) {
          // Schedule a timeout (android_alarm_manager)
          _scheduleTimeout(actionSpec);
        }
      });
    }
  });
}

void scheduleNextNotification() async {
  // Cancel all alarms, except for timeouts for past notifications
  final storage = await LocalDatabase.get(FlutterFileStorage(LocalDatabase.dbFilename));
  final allAlarms = await storage.getAllAlarms();
  for (var alarm in allAlarms.entries) {
    // On Android, AlarmManager adjusts alarms relative to time changes
    // Since timeouts reflect elapsed time since the notification, this is fine for already set
    // timeout alarms.
    // For all other (future) alarms, we cancel them and reschedule the next one
    // TODO to determine what is required on other platforms
    if (alarm.value.timeUTC.isAfter(DateTime.now().toUtc())) {
      await cancel(alarm.key);
    }
  }
  // reschedule
  _scheduleNextNotification();
}

Future<void> cancel(int alarmId) async {
  AndroidAlarmManager.initialize().then((bool success) {
    if (success) {
      AndroidAlarmManager.cancel(alarmId);
    }
  });
  final storage = await LocalDatabase.get(FlutterFileStorage(LocalDatabase.dbFilename));
  storage.removeAlarm(alarmId);
}

Future<void> cancelAll() async {
  final storage = await LocalDatabase.get(FlutterFileStorage(LocalDatabase.dbFilename));
  (await storage.getAllAlarms()).keys.forEach((alarmId) async => await cancel(alarmId));
}
