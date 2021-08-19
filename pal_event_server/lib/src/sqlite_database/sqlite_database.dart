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
import 'dart:convert';
import 'dart:io';

import 'package:pedantic/pedantic.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:taqo_common/model/action_specification.dart';
import 'package:taqo_common/model/event.dart';
import 'package:taqo_common/model/experiment.dart';
import 'package:taqo_common/model/notification_holder.dart';
import 'package:taqo_common/service/sync_service.dart';
import 'package:taqo_common/storage/base_database.dart';
import 'package:taqo_common/storage/dart_file_storage.dart';
import 'package:taqo_common/util/zoned_date_time.dart';

import 'raw_sql.dart';

class SqliteDatabase implements BaseDatabase {
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
      _db = sqlite3.open(dbPath);
      await _createTables();
      return _db;
    });
  }

  Future close() async {
    if (_db != null) {
      _db.dispose();
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
    'experiments': createExperimentsTable,
  };

  Future _maybeCreateTable(String tableName) async {
    final result = _db.select(_checkTableExistsQuery(tableName));
    bool exists = true;
    for (Row row in result) {
      exists = row.columnAt(0) > 0;
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
    _db.execute(insertAlarmCommand, [jsonEncode(actionSpecification)]);
    return _db.lastInsertRowId;
  }

  Future<ActionSpecification> getAlarm(int id) async {
    final result = _db.select(selectAlarmByIdCommand, [id]);
    var json;
    for (Row row in result) {
      json = row['json'];
    }
    return ActionSpecification.fromJson(jsonDecode(json));
  }

  Future<Map<int, ActionSpecification>> getAllAlarms() async {
    final result = _db.select(selectAllAlarmsCommand);
    final alarms = <int, ActionSpecification>{};
    for (var row in result) {
      final id = row.columnAt(0);
      final json = row['json'];
      alarms[id] = ActionSpecification.fromJson(jsonDecode(json));
    }
    return alarms;
  }

  Future removeAlarm(int id) async {
    _db.execute(deleteAlarmByIdCommand, [id]);
  }

  Future<int> insertNotification(NotificationHolder notificationHolder) async {
    _db.execute(insertNotificationCommand, [
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
      '${notificationHolder.snoozeCount ?? 0}'
    ]);
    return _db.lastInsertRowId;
  }

  NotificationHolder _buildNotificationHolder(Row row) =>
      NotificationHolder.fromJson({
        'id': row.columnAt(0),
        'alarmTime': row.columnAt(1),
        'experimentId': row.columnAt(2),
        'noticeCount': row.columnAt(3),
        'timeoutMillis': row.columnAt(4),
        'notificationSource': row.columnAt(5),
        'message': row.columnAt(6),
        'experimentGroupName': row.columnAt(7),
        'actionTriggerId': row.columnAt(8),
        'actionId': row.columnAt(9),
        'actionTriggerSpecId': row.columnAt(10),
        'snoozeTime': row.columnAt(11),
        'snoozeCount': row.columnAt(12),
      });

  Future<NotificationHolder> getNotification(int id) async {
    final result = _db.select(selectNotificationByIdCommand, [id]);
    var notification;
    for (Row row in result) {
      notification = _buildNotificationHolder(row);
    }
    return notification;
  }

  Future<List<NotificationHolder>> getAllNotifications() async {
    final result = _db.select(selectAllNotificationsCommand);
    final notifications = <NotificationHolder>[];
    for (var row in result) {
      notifications.add(_buildNotificationHolder(row));
    }
    return notifications;
  }

  Future<List<NotificationHolder>> getAllNotificationsForExperiment(
      Experiment experiment) async {
    final result =
        _db.select(selectNotificationByExperimentCommand, [experiment.id]);
    final notifications = <NotificationHolder>[];
    for (var row in result) {
      notifications.add(_buildNotificationHolder(row));
    }
    return notifications;
  }

  Future<void> removeNotification(int id) async {
    _db.execute(deleteNotificationByIdCommand, [id]);
  }

  Future<void> removeAllNotifications() async {
    _db.execute(deleteAllNotificationsCommand);
  }

  Future<int> insertEvent(Event event, {bool notifySyncService = true}) async {
    _db.execute(insertEventCommand, [
      event.experimentId,
      event.experimentName,
      event.experimentVersion,
      event.scheduleTime?.toIso8601String(withColon: true),
      event.responseTime?.toIso8601String(withColon: true),
      event.uploaded ? 1 : 0,
      event.groupName,
      event.actionTriggerId,
      event.actionTriggerSpecId,
      event.actionId
    ]);
    event.id = _db.lastInsertRowId;
    for (var responseEntry in event.responses.entries) {
      _db.execute(insertOutputCommand,
          [event.id, '${responseEntry.key}', '${responseEntry.value}']);
    }
    if (notifySyncService) {
      unawaited(SyncService.syncData());
    }
    return event.id;
  }

  ZonedDateTime _buildZonedDateTime(String string) {
    return string == null ? null : ZonedDateTime.fromIso8601String(string);
  }

  Event _buildEvent(Row row) {
    var event = Event()
      ..id = row.columnAt(0)
      ..experimentId = row.columnAt(1)
      ..experimentName = row.columnAt(2)
      ..experimentVersion = row.columnAt(3)
      ..scheduleTime = _buildZonedDateTime(row.columnAt(4))
      ..responseTime = _buildZonedDateTime(row.columnAt(5))
      ..uploaded = (row.columnAt(6) == 1)
      ..groupName = row.columnAt(7)
      ..actionTriggerId = row.columnAt(8)
      ..actionTriggerSpecId = row.columnAt(9)
      ..actionId = row.columnAt(10);
    final result = _db.select(selectOutputsCommand, [event.id]);
    event.responses = Map.fromIterable(result,
        key: (row) => row.readColumnByIndexAsText(0),
        value: (row) => row.readColumnByIndex(1));
    return event;
  }

  @override
  Future<List<Event>> getUnuploadedEvents() async {
    final result = _db.select(selectUnuploadedEventsCommand);
    return [for (var row in result) _buildEvent(row)];
  }

  @override
  Future<void> markEventsAsUploaded(Iterable<Event> events) async {
    _db.execute(buildMarkEventAsUploadedCommand(events.length),
        [for (var event in events) event.id]);
  }

  @override
  Future<Experiment> getExperimentById(int experimentId) async {
    final result = _db.select(selectExperimentByIdCommand, [experimentId]);
    var experiments = <Experiment>[
      for (var row in result) Experiment.fromJson(jsonDecode(row.columnAt(0)))
    ];
    if (experiments.length > 0) {
      assert(experiments.length == 1);
      return experiments[0];
    } else {
      return null;
    }
  }

  @override
  Future<List<Experiment>> getJoinedExperiments() async {
    final result = _db.select(selectJoindExperimentsCommand);
    return [
      for (var row in result) Experiment.fromJson(jsonDecode(row.columnAt(0)))
    ];
  }

  @override
  Future<void> saveJoinedExperiments(Iterable<Experiment> experiments) async {
    _db.execute(beginTransactionCommand);
    _db.execute(quitAllExperimentsCommand);
    for (var experiment in experiments) {
      _db.execute(insertOrUpdateJoinedExperimentsCommand,
          [experiment.id, jsonEncode(experiment)]);
    }
    _db.execute(resetPauseStatusCommand);
    _db.execute(commitCommand);
  }

  @override
  Future<Map<int, bool>> getExperimentsPausedStatus(
      Iterable<Experiment> experiments) async {
    final result = _db.select(
        buildQueryExperimentPausedStatusCommand(experiments.length),
        [for (var experiment in experiments) experiment.id]);
    return <int, bool>{
      for (var row in result) row.columnAt(0): row.columnAt(1) == 1
    };
  }

  @override
  Future<void> setExperimentPausedStatus(
      Experiment experiment, bool paused) async {
    _db.execute(
        updateExperimentPausedStatusCommand, [paused ? 1 : 0, experiment.id]);
  }
}
