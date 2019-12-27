import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:taqo_client/model/action_specification.dart';
import 'package:taqo_client/model/notification_holder.dart';

// TODO Extend LocalFileStorage->Key/Value Storage
class PendingAlarms {
  static const _filename = 'alarms.txt';

  static Future<Directory> get _localStorageDir async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      return await getApplicationDocumentsDirectory();
    } on MissingPluginException {
      // Workaround to support file storage during tests
      return Directory.systemTemp;
    }
  }

  static Future<String> get _localPath async => (await _localStorageDir).path;

  @protected
  static Future<File> get localFile async => File(path.join(await _localPath, _filename));

  Future<void> clear() async {
    final file = await localFile;
    if (await file.exists()) {
      await file.delete();
    }
  }

  // Completes with the singleton PendingNotifications object
  static Completer<PendingAlarms> _instance;

  final Map<int, ActionSpecification> _alarms;

  PendingAlarms._(this._alarms) {
    _loadAlarms();
  }

  // static method because factory constructors cannot be async or return Futures
  static Future<PendingAlarms> getInstance() async {
    if (_instance == null) {
      _instance = Completer<PendingAlarms>();
      try {
        _instance.complete(PendingAlarms._(await _loadAlarms()));
      } on Exception catch (e) {
        print('PendingAlarms: error loading file: $e');
        _instance.completeError(e);
      }
    }
    return _instance.future;
  }

  static Future<Map<int, ActionSpecification>> _loadAlarms() async {
    final file = await localFile;
    if (!(await file.exists())) {
      print('PendingAlarms: file does not exist');
      return {};
    }
    var json = {};
    try {
      json = jsonDecode(await file.readAsString());
    } catch (e) {
      print(file.readAsStringSync());
    }
    final loaded = <int, ActionSpecification>{};
    for (var k in json.keys) {
      loaded[int.tryParse(k)] = ActionSpecification.fromJson(json[k]);
    }
    return loaded;
  }

  void _saveAlarms() async {
    final json = Map.fromIterable(_alarms.keys, key: (k) => k.toString(), value: (k) =>_alarms[k]);
    try {
      (await localFile).writeAsString(jsonEncode(json), flush: true);
    } on FileSystemException catch (e) {
      print('PendingAlarms: error writing file: $e');
    }
  }

  Map<int, ActionSpecification> getAll() {
    final alarms = <int, ActionSpecification>{};
    for (var k in _alarms.keys) {
      alarms[k] = _alarms[k];
    }
    return alarms;
  }

  void remove(int key) {
    _alarms.remove(key);
    _saveAlarms();
  }

  ActionSpecification operator [](int key) {
    return _alarms[key];
  }

  operator []=(int key, ActionSpecification value) {
    _alarms[key] = value;
    _saveAlarms();
  }
}
