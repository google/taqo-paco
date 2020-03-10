import 'dart:io';

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:shared_preferences/shared_preferences.dart';

import '../../linux_daemon/linux_daemon.dart' as linux_daemon;
import '../../linux_daemon/socket_channel.dart';
import '../../model/action_specification.dart';
import '../../scheduling/action_schedule_generator.dart';
import '../../storage/local_database.dart';
import '../../util/date_time_util.dart';
import 'linux_notifications.dart' as linux_notifications;
import 'taqo_alarm.dart' as taqo_alarm;

const SHARED_PREFS_LAST_ALARM_TIME = 'lastScheduledAlarm';

const notifyMethod = 'notify';
const expireMethod = 'expire';

json_rpc.Peer _peer;
json_rpc.Peer get linuxDaemonPeer => _peer;

/// Schedule an alarm for [actionSpec] at [when] to run [callback]
Future<int> _schedule(ActionSpecification actionSpec, DateTime when, String what) async {
  final duration = when.difference(DateTime.now());
  if (duration.inMilliseconds < 0) return -1;

  final alarmId = await LocalDatabase().insertAlarm(actionSpec);

  _peer.sendRequest(linux_daemon.scheduleAlarmMethod, {
    'id': alarmId,
    'when': when.toIso8601String(),
    'what': what,
  }).then((response) {
    print('Schedule alarm: $response');
  });

  return alarmId;
}

Future<bool> _scheduleNotification(ActionSpecification actionSpec) async {
  // Don't show a notification that's already pending
  final alarms = await LocalDatabase().getAllAlarms();
  for (var as in alarms.values) {
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

void _notifyCallback(int alarmId) async {
  print('notify: alarmId: $alarmId');
  DateTime start;
  Duration duration;
  final actionSpec = await LocalDatabase().getAlarm(alarmId);
  if (actionSpec != null) {
    // To handle simultaneous alarms as well as possible delay in alarm callbacks,
    // show all notifications from the originally schedule alarm time until
    // 30 seconds after the current time
    start = actionSpec.time;
    duration = DateTime.now().add(Duration(seconds: 30)).difference(start);
    final allAlarms = await getAllAlarmsWithinRange(start: start, duration: duration);
    print('Showing ${allAlarms.length} alarms from: $start to: ${start.add(duration)}');
    var i = 0;
    for (var a in allAlarms) {
      print('[${i++}] Showing ${a.time}');
      linux_notifications.showNotification(a);
    }

    // Store last shown notification time
    final sharedPreferences = await SharedPreferences.getInstance();
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

// Handles a callback from the linux daemon
void _handleNotifyCallback(json_rpc.Parameters args) {
  final alarmId = (args.asMap)['id'] as int;
  _notifyCallback(alarmId);
}

void _expireCallback(int alarmId) async {
  print('expire: alarmId: $alarmId');
  // Cancel notification
  final toCancel = await LocalDatabase().getAlarm(alarmId);
  // TODO Move the matches() logic to SQL
  final notifications = await LocalDatabase().getAllNotifications();
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

// Handles a callback from the linux daemon
void _handleExpireCallback(json_rpc.Parameters args) {
  final alarmId = (args.asMap)['id'] as int;
  _expireCallback(alarmId);
}

void _scheduleNextNotification({DateTime from}) async {
  DateTime lastSchedule;
  final sharedPreferences = await SharedPreferences.getInstance();
  final dt = sharedPreferences.getString(SHARED_PREFS_LAST_ALARM_TIME);
  print('loaded $dt');
  if (dt != null) {
    lastSchedule = DateTime.parse(dt).add(Duration(seconds: 1));
  }

  // To avoid scheduling an alarm that was already shown by the logic in _notifyCallback
  from ??= DateTime.now();
  from = getLater(from, lastSchedule);
  print('_scheduleNextNotification from: $from');

  getNextAlarmTime(now: from).then((ActionSpecification actionSpec) async {
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

Future init() async {
  Socket.connect(linux_daemon.localServerHost, linux_daemon.localServerPort).then((socket) {
    _peer = json_rpc.Peer(SocketChannel(socket), onUnhandledError: (e, st) {
      print('linux_alarm_manager socket error: $e');
    });

    _peer.registerMethod(notifyMethod, _handleNotifyCallback);
    _peer.registerMethod(expireMethod, _handleExpireCallback);
    _peer.registerMethod(linux_notifications.openSurveyMethod, linux_notifications.handleOpenSurvey);
    _peer.listen();

    _peer.done.then((_) {
      print('linux_alarm_manager socket closed');
      _peer = null;
    });
  }).catchError((e) {
    print('Failed to connect to the Linux daemon. Is it running?');
    _peer = null;
  });
}

void scheduleNextNotification() async {
  // Cancel all alarms, except for timeouts for past notifications
  final allAlarms = await LocalDatabase().getAllAlarms();
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
  // TODO Cancel Future?
  LocalDatabase().removeAlarm(alarmId);
}

Future<void> cancelAll() async {
  (await LocalDatabase().getAllAlarms()).keys.forEach((alarmId) async => await cancel(alarmId));
}
