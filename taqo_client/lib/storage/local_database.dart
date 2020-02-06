import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';
import 'package:taqo_client/model/action_specification.dart';
import 'package:taqo_client/model/event.dart';
import 'package:taqo_client/model/experiment.dart';
import 'package:taqo_client/model/notification_holder.dart';
import 'package:taqo_client/storage/local_storage.dart';
import 'package:taqo_client/util/zoned_date_time.dart';

part 'local_database.inc.dart';
part 'local_database.workaround.dart';

/// Global reference of the database connection, using singleton pattern
class LocalDatabase extends LocalFileStorage {
  /// Singleton implementation

  /// The private constructor
  LocalDatabase._() : super(dbFilename) {
    _init();
  }

  static final LocalDatabase _instance = LocalDatabase._();

  factory LocalDatabase() {
    return _instance;
  }

  /// Actual content of the class
  static const dbFilename = 'experiments.db';
  Future<Database> _db;

  /// The actual initializer, which should only be called from the private constructor
  void _init() {
    _db = _openDatabase();
  }

  Future<Database> _openDatabase() async {
    return await openDatabase((await localFile).path,
        version: _dbVersion, onCreate: _onCreate);
  }

  Future<void> insertEvent(Event event) async {
    final db = await _db;
    await _insertEvent(db, event);
  }

  Future<int> insertNotification(NotificationHolder notificationHolder) async {
    final db = await _db;
    return _insertNotification(db, notificationHolder);
  }

  Future<NotificationHolder> getNotification(int id) async {
    final db = await _db;
    return _getNotification(db, id);
  }

  Future<List<NotificationHolder>> getAllNotifications() async {
    final db = await _db;
    return _getAllNotifications(db);
  }

  Future<List<NotificationHolder>> getAllNotificationsForExperiment(
      Experiment experiment) async {
    final db = await _db;
    return _getAllNotificationsForExperiment(db, experiment.id);
  }

  Future<void> removeNotification(int id) async {
    final db = await _db;
    return _removeNotification(db, id);
  }

  Future<void> removeAllNotifications() async {
    final db = await _db;
    return _removeAllNotifications(db);
  }

  Future<int> insertAlarm(ActionSpecification actionSpecification) async {
    final db = await _db;
    return _insertAlarm(db, actionSpecification);
  }

  Future<ActionSpecification> getAlarm(int id) async {
    final db = await _db;
    return _getAlarm(db, id);
  }

  Future<Map<int, ActionSpecification>> getAllAlarms() async {
    final db = await _db;
    return _getAllAlarms(db);
  }

  Future<void> removeAlarm(int id) async {
    final db = await _db;
    return _removeAlarm(db, id);
  }

  Future<Iterable<Event>> getUnuploadedEvents() async {
    final db = await _db;
    final eventFieldsMaps = await db.query('events', where: 'uploaded=0');
    return Future.wait(eventFieldsMaps
        .map((e) async => await _createEventFromColumnValueMap(db, e)));
  }

  Future<void> markEventsAsUploaded(Iterable<Event> events) async {
    final db = await _db;
    db.transaction((txn) async {
      var batch = txn.batch();
      for (var event in events) {
        batch.update('events', {'uploaded': 1},
            where: '_id=?', whereArgs: [event.id]);
      }
      await batch.commit(noResult: true);
    });
  }
}
