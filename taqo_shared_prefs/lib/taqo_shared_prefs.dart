import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart';

final _logger = Logger('TaqoSharedPrefs');

class TaqoSharedPrefs {
  static const _sharedPrefDbFile = 'taqo_shared_prefs.db';

  String _sharedPrefDbPath;
  Map<String, dynamic> _sharedPrefMap;

  TaqoSharedPrefs(String path)
      : _sharedPrefDbPath = join(path, _sharedPrefDbFile),
        _sharedPrefMap = <String, dynamic>{};

  Future _loadPrefs() async {
    _sharedPrefMap.clear();

    final dbFile = await File(_sharedPrefDbPath);
    if (!(await dbFile.exists())) {
      return;
    }

    final contents = await dbFile.readAsString();
    try {
      var jsonDecoded = jsonDecode(contents);
      _sharedPrefMap.addAll(jsonDecoded);
    } catch (e) {
      _logger.warning(e);
    }
  }

  Future _writePrefs() async {
    final dbFile = await File(_sharedPrefDbPath);
    final contents = jsonEncode(_sharedPrefMap);
    return dbFile.writeAsString(contents, mode: FileMode.write);
  }

  /// Returns all keys in the persistent storage
  Future<Set<String>> getKeys() async {
    await _loadPrefs();
    return Set.from(_sharedPrefMap.keys);
  }

  /// Reads a value of any type from the persistent storage
  Future get(String key) async {
    await _loadPrefs();
    return _sharedPrefMap[key];
  }

  /// Reads a bool value from the persistent storage or throws an Exception if it's not a bool
  Future<bool> getBool(String key) async => (await get(key)) as bool;

  /// Reads an int value from the persistent storage or throws an Exception if it's not a int
  Future<int> getInt(String key) async => (await get(key) as int);

  /// Reads a double value from the persistent storage or throws an Exception if it's not a double
  Future<double> getDouble(String key) async => (await get(key) as double);

  /// Reads a String value from the persistent storage or throws an Exception if it's not a String
  Future<String> getString(String key) async => (await get(key) as String);

  /// Returns true if the persistent storage contains the given key
  Future<bool> containsKey(String key) async => (await getKeys()).contains(key);

  Future _setValue(String key, dynamic value) async {
    _loadPrefs();
    _sharedPrefMap[key] = value;
    await _writePrefs();
    return value;
  }

  /// Saves a value of any type to the persistent storage
  Future<bool> setValue(String key, dynamic value) =>
      _setValue(key, value).then((stored) => stored == value);

  /// Saves a bool to the persistent storage
  Future<bool> setBool(String key, bool value) =>
      _setValue(key, value).then((stored) => stored == value);

  /// Saves an int to the persistent storage
  Future<bool> setInt(String key, int value) =>
      _setValue(key, value).then((stored) => stored == value);

  /// Saves a double to the persistent storage
  Future<bool> setDouble(String key, double value) =>
      _setValue(key, value).then((stored) => stored == value);

  /// Saves a String to the persistent storage
  Future<bool> setString(String key, String value) =>
      _setValue(key, value).then((stored) => stored == value);

  /// Removes a value from the persistent storage
  Future remove(String key) async {
    final value = _sharedPrefMap.remove(key);
    await _writePrefs();
    return value;
  }

  /// Removes all values from the persistent storage
  Future clear() async {
    _sharedPrefMap.clear();
    return _writePrefs();
  }
}
