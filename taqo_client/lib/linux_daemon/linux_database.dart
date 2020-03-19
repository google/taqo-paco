import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:sqlite2/sqlite.dart';

import '../model/action_specification.dart';
import '../model/event.dart';
import '../model/experiment.dart';
import '../model/notification_holder.dart';
import '../storage/dart_file_storage.dart';

class LinuxDatabase {
  static const _dbFile = 'experiments.db';

  static Completer<LinuxDatabase> _completer;
  static LinuxDatabase _instance;

  Database _db;

  LinuxDatabase._();

  static Future<LinuxDatabase> get() {
    if (_completer != null && !_completer.isCompleted) {
      return _completer.future;
    }
    if (_instance == null) {
      _completer = Completer<LinuxDatabase>();
      final temp = LinuxDatabase._();
      temp._initialize().then((db) {
        _instance = temp;
        _completer.complete(_instance);
      });
      return _completer.future;
    }
    return Future.value(_instance);
  }

  Future<Database> _initialize() async {
    final dbPath = '$taqoDir/$_dbFile';
    return File(dbPath).create(recursive: true).then((_) async {
      _db = Database(dbPath);
      await _createTables();
      return _db;
    });
  }

  Future _createTables() async {
    var stream = _db.query("""SELECT COUNT(1) FROM sqlite_master WHERE type='table' AND name='alarms'""");
    var table = await stream.first;
    var exists = table.toList().first ?? 0;
    if (exists == 0) {
      await _db.execute(
'''CREATE TABLE alarms (
_id INTEGER PRIMARY KEY AUTOINCREMENT,
json TEXT
);
'''
      );
    }

    stream = _db.query("""SELECT COUNT(1) FROM sqlite_master WHERE type='table' AND name='notifications'""");
    table = await stream.first;
    exists = table.toList().first ?? 0;
    if (exists == 0) {
      await _db.execute(
'''CREATE TABLE notifications (
_id INTEGER PRIMARY KEY AUTOINCREMENT,
alarm_time INTEGER, 
experiment_id INTEGER, 
notice_count INTEGER, 
timeout_millis INTEGER, 
notification_source TEXT, 
message TEXT, 
experiment_group_name TEXT, 
action_trigger_id INTEGER, 
action_id INTEGER, 
action_trigger_spec_id INTEGER, 
snooze_time INTEGER, 
snooze_count INTEGER
);
'''
      );
    }

    stream = _db.query("""SELECT COUNT(1) FROM sqlite_master WHERE type='table' AND name='events'""");
    table = await stream.first;
    exists = table.toList().first ?? 0;
    if (exists == 0) {
      await _db.execute(
'''CREATE TABLE events (
_id INTEGER PRIMARY KEY AUTOINCREMENT,
experiment_id INTEGER,
experiment_server_id INTEGER,
experiment_name TEXT,
experiment_version INTEGER,
schedule_time TEXT,
response_time TEXT,
uploaded INTEGER,
group_name TEXT,
action_trigger_id INTEGER,
action_trigger_spec_id INTEGER,
action_id INTEGER
);
'''
      );
    }

    stream = _db.query("""SELECT COUNT(1) FROM sqlite_master WHERE type='table' AND name='outputs'""");
    table = await stream.first;
    exists = table.toList().first ?? 0;
    if (exists == 0) {
      await _db.execute(
'''CREATE TABLE outputs (
_id INTEGER PRIMARY KEY AUTOINCREMENT,
event_id INTEGER,
text TEXT,
answer TEXT
);
'''
      );
    }
  }

  Future<int> insertAlarm(ActionSpecification actionSpecification) async {
    return _db.execute("""INSERT INTO alarms (json) VALUES (?)""",
        params: [jsonEncode(actionSpecification)]);
  }

  Future<ActionSpecification> getAlarm(int id) async {
    final stream = _db.query("""SELECT * FROM alarms WHERE _id = ${id}""");
    final alarm = await stream.first;
    return ActionSpecification.fromJson(jsonDecode(alarm.toMap()['json']));
  }

  Future<Map<int, ActionSpecification>> getAllAlarms() async {
    final stream = _db.query("""SELECT * FROM alarms""");
    final alarms = <int, ActionSpecification>{};
    await for (var a in stream) {
      alarms[a.toList().first] = ActionSpecification.fromJson(jsonDecode(a.toMap()['json']));
    }
    return alarms;
  }

  void removeAlarm(int id) {
    _db.execute("""DELETE FROM alarms WHERE _id = ${id}""");
  }

  Future<int> insertNotification(NotificationHolder notificationHolder) async {
    return _db.execute("""INSERT INTO notifications (alarm_time, experiment_id, notice_count, timeout_millis, notification_source, message, experiment_group_name, action_trigger_id, action_id, action_trigger_spec_id, snooze_time, snooze_count) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
        params: [
          '${notificationHolder.alarmTime}',
          '${notificationHolder.experimentId}',
          '${notificationHolder.noticeCount}',
          '${notificationHolder.timeoutMillis}',
          '${notificationHolder.notificationSource}',
          notificationHolder.message,
          notificationHolder.experimentGroupName,
          '${notificationHolder.actionTriggerId}',
          '${notificationHolder.actionId}',
          '${notificationHolder.actionTriggerSpecId}',
          '${notificationHolder.snoozeTime ?? 0}',
          '${notificationHolder.snoozeCount ?? 0}']);
  }

  NotificationHolder _buildNotificationHolder(Map<String, dynamic> json) =>
      NotificationHolder.fromJson({
        'id': json['_id'],
        'alarmTime': json['alarm_time'],
        'experimentId': json['experiment_id'],
        'noticeCount': json['notice_count'],
        'timeoutMillis': json['timeout_millis'],
        'notificationSource': json['notification_source'],
        'message': json['message'],
        'experimentGroupName': json['experiment_group_name'],
        'actionTriggerId': json['action_trigger_id'],
        'actionId': json['action_id'],
        'actionTriggerSpecId': json['action_trigger_spec_id'],
        'snoozeTime': json['snooze_time'],
        'snoozeCount': json['snooze_count'],
      });

  Future<NotificationHolder> getNotification(int id) async {
    final stream = _db.query("""SELECT * FROM notifications WHERE _id = ${id}""");
    final notification = await stream.first;
    return _buildNotificationHolder(notification.toMap());
  }

  Future<List<NotificationHolder>> getAllNotifications() async {
    final stream = _db.query("""SELECT * FROM notifications""");
    final notifications = <NotificationHolder>[];
    await for (var n in stream) {
      notifications.add(_buildNotificationHolder(n.toMap()));
    }
    return notifications;
  }

  Future<List<NotificationHolder>> getAllNotificationsForExperiment(
      Experiment experiment) async {
    final stream = _db.query("""SELECT * FROM notifications WHERE experiment_id = ${experiment.id}""");
    final notifications = <NotificationHolder>[];
    await for (var n in stream) {
      notifications.add(_buildNotificationHolder(n.toMap()));
    }
    return notifications;
  }

  Future<void> removeNotification(int id) async {
    _db.execute("""DELETE FROM notifications WHERE _id = ${id}""");
  }

  Future<void> removeAllNotifications() async {
    _db.execute("""DELETE FROM notifications""");
  }

  Future<int> insertEvent(Event event) async {
    event.id = await _db.execute("""INSERT INTO events (experiment_id, experiment_server_id, experiment_name, experiment_version, schedule_time, response_time, uploaded, group_name, action_trigger_id, action_trigger_spec_id, action_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
        params: [
          '${event.experimentId}',
          '${event.experimentServerId}',
          event.experimentName,
          '${event.experimentVersion}',
          event.scheduleTime?.toIso8601String(withColon: true),
          event.responseTime?.toIso8601String(withColon: true),
          '${event.uploaded}',
          event.groupName,
          '${event.actionTriggerId}',
          '${event.actionTriggerSpecId}',
          '${event.actionId}']);
    for (var responseEntry in event.responses.entries) {
      await _db.execute("""INSERT INTO outputs (event_id, text, answer) VALUES (?, ?, ?)""",
          params: [
            '${event.id}',
            '${responseEntry.key}',
            '${responseEntry.value}']);
    }
    return event.id;
  }
}
