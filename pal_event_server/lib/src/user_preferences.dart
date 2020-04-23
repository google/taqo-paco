import 'dart:async';
import 'dart:io' show File;

import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

import 'utils.dart' as utils;

class UserDefaults {
  static const _dbFile = 'user_prefs.db';

  static UserDefaults _instance;

  Database _db;

  UserDefaults._();

  static Future<UserDefaults> get() {
    if (_instance == null) {
      final completer = Completer<UserDefaults>();
      final temp = UserDefaults._();
      temp._initialize().then((db) {
        _instance = temp;
        completer.complete(_instance);
      });
      return completer.future;
    }
    return Future.value(_instance);
  }

  Future<Database> _initialize() {
    final dbPath = '${utils.taqoDir}/$_dbFile';
    return File(dbPath).create(recursive: true).then((_) {
      final factory = databaseFactoryIo;
      return factory.openDatabase(dbPath).then((db) {
        _db = db;
        return db;
      });
    });
  }

  Future operator [](String key) async {
    final store = StoreRef.main();
    return store.record(key).get(_db);
  }

  void operator []=(String key, dynamic value) async {
    final store = StoreRef.main();
    return store.record(key).put(_db, value);
  }
}
