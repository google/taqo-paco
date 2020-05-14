import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:sqlite3/sqlite.dart';
import 'package:taqo_common/model/action_specification.dart';
import 'package:taqo_common/model/event.dart';
import 'package:taqo_common/model/notification_holder.dart';
import 'package:taqo_common/storage/dart_file_storage.dart';

import 'raw_sql.dart';

class SqliteDatabase {
  static const _dbFile = 'experiments.db';

  static Completer<SqliteDatabase> _completer;
  static SqliteDatabase _instance;

  Database _db;

  SqliteDatabase._();

  static Future<SqliteDatabase> get() {
    if (_completer != null && !_completer.isCompleted) {
      return _completer.future;
    }
    if (_instance == null) {
      _completer = Completer<SqliteDatabase>();
      final temp = SqliteDatabase._();
      temp._initialize().then((db) {
        _instance = temp;
        _completer.complete(_instance);
      });
      return _completer.future;
    }
    return Future.value(_instance);
  }

  Future<Database> _initialize() async {
    final taqoDir = DartFileStorage.getLocalStorageDir().path;
    final dbPath = '$taqoDir/$_dbFile';
    return File(dbPath).create(recursive: true).then((_) async {
      _db = Database(dbPath);
      await _createTables();
      return _db;
    });
  }

  Future close() async {
    if (_db != null) {
      _db.close();
      _db = null;
    }
    _instance = null;
    _completer = null;
  }

  String _checkTableExistsQuery(String tableName) =>
      "SELECT COUNT(1) FROM sqlite_master WHERE type='table' AND name='$tableName'";

  final _createTableStatement = <String, String>{
    'alarms': createAlarmsTable,
    'notifications': createNotificationsTable,
    'events': createEventsTable,
    'outputs': createOutputsTable,
  };

  Future _maybeCreateTable(String tableName) async {
    final result = _db.query(_checkTableExistsQuery(tableName));
    bool exists = true;
    for (Row row in result) {
      exists = row.readColumnByIndexAsInt(0) > 0;
    }
    if (!exists) {
      await _db.execute(_createTableStatement[tableName]);
    }
  }

  Future _createTables() async {
    for (var table in _createTableStatement.keys) {
      _maybeCreateTable(table);
    }
  }

  Future<int> insertAlarm(ActionSpecification actionSpecification) async {
    return _db.execute(insertAlarmCommand,
        params: [jsonEncode(actionSpecification)]);
  }

  Future<ActionSpecification> getAlarm(int id) async {
    final result = _db.query(selectAlarmByIdCommand, params: [id]);
    var json;
    for (Row row in result) {
      json = row.readColumnAsText('json');
    }
    return ActionSpecification.fromJson(jsonDecode(json));
  }

  Future<Map<int, ActionSpecification>> getAllAlarms() async {
    final result = _db.query(selectAllAlarmsCommand);
    final alarms = <int, ActionSpecification>{};
    for (var row in result) {
      final id = row.readColumnByIndexAsInt(0);
      final json = row.readColumnAsText('json');
      alarms[id] = ActionSpecification.fromJson(jsonDecode(json));
    }
    return alarms;
  }

  Future removeAlarm(int id) async {
    _db.execute(deleteAlarmByIdCommand, params: [id]);
  }

  Future<int> insertNotification(NotificationHolder notificationHolder) async {
    return _db.execute(insertNotificationCommand,
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

  NotificationHolder _buildNotificationHolder(Row row) =>
      NotificationHolder.fromJson({
        'id': row.readColumnByIndexAsInt(0),
        'alarmTime': row.readColumnByIndexAsInt(1),
        'experimentId': row.readColumnByIndexAsInt(2),
        'noticeCount': row.readColumnByIndexAsInt(3),
        'timeoutMillis': row.readColumnByIndexAsInt(4),
        'notificationSource': row.readColumnByIndexAsText(5),
        'message': row.readColumnByIndexAsText(6),
        'experimentGroupName': row.readColumnByIndexAsText(7),
        'actionTriggerId': row.readColumnByIndexAsInt(8),
        'actionId': row.readColumnByIndexAsInt(9),
        'actionTriggerSpecId': row.readColumnByIndexAsInt(10),
        'snoozeTime': row.readColumnByIndexAsInt(11),
        'snoozeCount': row.readColumnByIndexAsInt(12),
      });

  Future<NotificationHolder> getNotification(int id) async {
    final result = _db.query(selectNotificationByIdCommand, params: [id]);
    var notification;
    for (Row row in result) {
      notification = _buildNotificationHolder(row);
    }
    return notification;
  }

  Future<List<NotificationHolder>> getAllNotifications() async {
    final result = _db.query(selectAllNotificationsCommand);
    final notifications = <NotificationHolder>[];
    for (var row in result) {
      notifications.add(_buildNotificationHolder(row));
    }
    return notifications;
  }

  Future<List<NotificationHolder>> getAllNotificationsForExperiment(int experimentId) async {
    final result = _db.query(selectNotificationByExperimentCommand, params: [experimentId]);
    final notifications = <NotificationHolder>[];
    for (var row in result) {
      notifications.add(_buildNotificationHolder(row));
    }
    return notifications;
  }

  Future<void> removeNotification(int id) async {
    _db.execute(deleteNotificationByIdCommand, params: [id]);
  }

  Future<void> removeAllNotifications() async {
    _db.execute(deleteAllNotificationsCommand);
  }

  Future<int> insertEvent(Event event) async {
    event.id = await _db.execute(insertEventCommand,
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
      await _db.execute(insertOutputCommand,
          params: [
            '${event.id}',
            '${responseEntry.key}',
            '${responseEntry.value}']);
    }
    return event.id;
  }
}
