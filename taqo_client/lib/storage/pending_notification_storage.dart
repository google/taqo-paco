import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:taqo_client/model/notification_holder.dart';

// TODO Extend LocalFileStorage->Key/Value Storage
class PendingNotifications {
  static const _filename = 'notifications.txt';

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
  static Completer<PendingNotifications> _instance;

  final Map<int, NotificationHolder> _notifications;

  PendingNotifications._(this._notifications) {
    _loadNotifications();
  }

  // static method because factory constructors cannot be async or return Futures
  static Future<PendingNotifications> getInstance() async {
    if (_instance == null) {
      _instance = Completer<PendingNotifications>();
      try {
        _instance.complete(PendingNotifications._(await _loadNotifications()));
      } on Exception catch (e) {
        print('PendingNotifications: error loading file: $e');
        _instance.completeError(e);
      }
    }
    return _instance.future;
  }

  static Future<Map<int, NotificationHolder>> _loadNotifications() async {
    final file = await localFile;
    if (!(await file.exists())) {
      print('PendingNotifications: file does not exist');
      return {};
    }
    final json = jsonDecode(await file.readAsString());
    final loaded = <int, NotificationHolder>{};
    for (var k in json.keys) {
      loaded[int.tryParse(k)] = NotificationHolder.fromJson(json[k]);
    }
    return loaded;
  }

  void _saveNotifications() async {
    final json = Map.fromIterable(
        _notifications.keys, key: (k) => k.toString(), value: (k) => _notifications[k]);
    try {
      (await localFile).writeAsString(jsonEncode(json), flush: true);
    } on FileSystemException catch (e) {
      print('PendingNotifications: error writing file: $e');
    }
  }

  Map<int, NotificationHolder> getAll() {
    final notifications = <int, NotificationHolder>{};
    for (var k in _notifications.keys) {
      notifications[k] = _notifications[k];
    }
    return notifications;
  }

  void remove(int key) {
    _notifications.remove(key);
    _saveNotifications();
  }

  NotificationHolder operator [](int key) {
    return _notifications[key];
  }

  operator []=(int key, NotificationHolder value) {
    _notifications[key] = value;
    _saveNotifications();
  }
}
