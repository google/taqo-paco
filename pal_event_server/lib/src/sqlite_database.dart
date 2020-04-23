import 'dart:async';
import 'dart:io';

import 'package:sqlite3/sqlite.dart';

import 'sql_commands.dart';
import 'utils.dart';

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

  // TODO Share Taqo model (Event class) with pal_event_server
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
