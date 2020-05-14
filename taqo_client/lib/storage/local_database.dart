import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'package:taqo_common/model/action_specification.dart';
import 'package:taqo_common/model/event.dart';
import 'package:taqo_common/model/experiment.dart';
import 'package:taqo_common/model/notification_holder.dart';
import 'package:taqo_common/storage/local_file_storage.dart';
import 'package:taqo_common/util/zoned_date_time.dart';

import 'base_database.dart';

part 'local_database.inc.dart';
part 'local_database.workaround.dart';

/// Global reference of the database connection, using singleton pattern
class LocalDatabase extends BaseDatabase {
  static const dbFilename = 'experiments.db';

  static Completer<LocalDatabase> _completer;
  static LocalDatabase _instance;

  ILocalFileStorage _storageImpl;
  Database _db;

  LocalDatabase._();

  static Future<LocalDatabase> get(ILocalFileStorage storageImpl) async {
    if (_completer != null && !_completer.isCompleted) {
      return _completer.future;
    }
    if (_instance == null) {
      _completer = Completer<LocalDatabase>();
      final temp = LocalDatabase._();
      await temp._initialize(storageImpl).then((db) {
        temp._db = db;
        _instance = temp;
        _completer.complete(_instance);
      });
      return _completer.future;
    }
    return Future.value(_instance);
  }

  Future<Database> _initialize(ILocalFileStorage storageImpl) async {
    _storageImpl = storageImpl;
    return _openDatabase();
  }

  Future<Database> _openDatabase() async {
    return await openDatabase((await _storageImpl.localFile).path,
        version: _dbVersion, onCreate: _onCreate);
  }

  @override
  Future<void> insertEvent(Event event) async {
    await _insertEvent(_db, event);
  }

  @override
  Future<int> insertNotification(NotificationHolder notificationHolder) async {
    return _insertNotification(_db, notificationHolder);
  }

  @override
  Future<NotificationHolder> getNotification(int id) async {
    return _getNotification(_db, id);
  }

  @override
  Future<List<NotificationHolder>> getAllNotifications() async {
    return _getAllNotifications(_db);
  }

  @override
  Future<List<NotificationHolder>> getAllNotificationsForExperiment(
      Experiment experiment) async {
    return _getAllNotificationsForExperiment(_db, experiment.id);
  }

  @override
  Future<void> removeNotification(int id) async {
    return _removeNotification(_db, id);
  }

  @override
  Future<void> removeAllNotifications() async {
    return _removeAllNotifications(_db);
  }

  @override
  Future<int> insertAlarm(ActionSpecification actionSpecification) async {
    return _insertAlarm(_db, actionSpecification);
  }

  @override
  Future<ActionSpecification> getAlarm(int id) async {
    return _getAlarm(_db, id);
  }

  @override
  Future<Map<int, ActionSpecification>> getAllAlarms() async {
    return _getAllAlarms(_db);
  }

  @override
  Future<void> removeAlarm(int id) async {
    return _removeAlarm(_db, id);
  }

  @override
  Future<Iterable<Event>> getUnuploadedEvents() async {
    final eventFieldsMaps = await _db.query('events', where: 'uploaded=0');
    return Future.wait(eventFieldsMaps
        .map((e) async => await _createEventFromColumnValueMap(_db, e)));
  }

  @override
  Future<void> markEventsAsUploaded(Iterable<Event> events) async {
    _db.transaction((txn) async {
      var batch = txn.batch();
      for (var event in events) {
        batch.update('events', {'uploaded': 1},
            where: '_id=?', whereArgs: [event.id]);
      }
      await batch.commit(noResult: true);
    });
  }
}
