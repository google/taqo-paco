import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:sqlite3/sqlite.dart';

import 'sql_commands.dart';
import '../utils.dart';

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

  // TODO Share Taqo model (e.g. Event class, etc.) with pal_event_server

  Future<int> insertAlarm(String actionSpecification) async {
    return _db.execute(insertAlarmCommand,
        params: [actionSpecification]);
  }

  Future<Map<String, dynamic>> getAlarm(int id) async {
    final result = _db.query(selectAlarmByIdCommand, params: [id]);
    var json;
    for (Row row in result) {
      json = row.readColumnAsText('json');
    }
    return jsonDecode(json);
  }

  Future<Map<int, Map<String, dynamic>>> getAllAlarms() async {
    final result = _db.query(selectAllAlarmsCommand);
    final alarms = <int, Map<String, dynamic>>{};
    for (var row in result) {
      final id = row.readColumnByIndexAsInt(0);
      final json = row.readColumnAsText('json');
      alarms[id] = jsonDecode(json);
    }
    return alarms;
  }

  Future removeAlarm(int id) async {
    return _db.execute(deleteAlarmByIdCommand, params: [id]);
  }

  Future<int> insertNotification(Map<String, dynamic> notificationHolder) async {
    return _db.execute(insertNotificationCommand,
        params: [
          '${notificationHolder['alarmTime']}',
          '${notificationHolder['experimentId']}',
          '${notificationHolder['noticeCount']}',
          '${notificationHolder['timeoutMillis']}',
          '${notificationHolder['notificationSource']}',
          '${notificationHolder['message']}',
          '${notificationHolder['experimentGroupName']}',
          '${notificationHolder['actionTriggerId']}',
          '${notificationHolder['actionId']}',
          '${notificationHolder['actionTriggerSpecId']}',
          '${notificationHolder['snoozeTime'] ?? 0}',
          '${notificationHolder['snoozeCount'] ?? 0}'
        ]);
  }

  Map<String, dynamic> _buildNotificationHolder(Row row) => {
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
  };

  Future<Map<String, dynamic>> getNotification(int id) async {
    final result = _db.query(selectNotificationByIdCommand, params: [id]);
    var notification;
    for (Row row in result) {
      notification = _buildNotificationHolder(row);
    }
    return notification;
  }

  Future<List<Map<String, dynamic>>> getAllNotifications() async {
    final result = _db.query(selectAllNotificationsCommand);
    final notifications = <Map<String, dynamic>>[];
    for (var row in result) {
      notifications.add(_buildNotificationHolder(row));
    }
    return notifications;
  }

  Future<List<Map<String, dynamic>>> getAllNotificationsForExperiment(int experimentId) async {
    final result = _db.query(selectNotificationByExperimentCommand, params: [experimentId]);
    final notifications = <Map<String, dynamic>>[];
    for (var row in result) {
      notifications.add(_buildNotificationHolder(row));
    }
    return notifications;
  }

  Future removeNotification(int id) async {
    return _db.execute(deleteNotificationByIdCommand, params: [id]);
  }

  Future removeAllNotifications() async {
    return _db.execute(deleteAllNotificationsCommand);
  }

  Future<int> insertEvent(Map<String, dynamic> event) async {
    final eventId = await _db.execute(insertEventCommand,
        params: [
          '${event['experimentId']}',
          '${event['experimentId']}',
          '${event['experimentName']}',
          '${event['experimentVersion']}',
          '${event['scheduleTime']}',
          '${event['responseTime']}',
          '${event['uploaded']}',
          '${event['experimentGroupName']}',
          '${event['actionTriggerId']}',
          '${event['actionTriggerSpecId']}',
          '${event['actionId']}'
        ]);
    for (var responseEntry in event['responses']) {
      await _db.execute(insertOutputCommand,
          params: [
            '$eventId',
            '${responseEntry['name']}',
            '${responseEntry['answer']}']);
    }
    return eventId;
  }
}
