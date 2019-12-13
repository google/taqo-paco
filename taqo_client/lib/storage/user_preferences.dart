import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:taqo_client/storage/local_storage.dart';

class UserPreferences extends LocalFileStorage {
  static const filename = 'preferences.txt';
  static const PAUSED_KEY = "paused";

  static final _instance = UserPreferences._();

  UserPreferences._() : super(filename) {
    _loadPreferences();
  }

  factory UserPreferences() {
    return _instance;
  }

  final _prefMap = <String, dynamic>{};

  Future<Map<String, dynamic>> get _preferences async {
    await _lock?.future;
    return _prefMap;
  }

  /// Access to [_prefMap] is synchronized:
  /// 1. Always load saved preferences before allowing any access (read or write)
  /// 2. Writes must complete before reads
  /// 3. Calls to [_savePreferences] are synchronized
  Completer _lock = Completer();
  Completer _saveLock;

  void _loadPreferences() async {
    _lock = Completer();
    try {
      final file = await localFile;
      if (await file.exists()) {
        String contents = await file.readAsString();
        _prefMap.addAll(jsonDecode(contents));
      } else {
        print("preferences file does not exist or is corrupted");
      }
    } catch (e) {
      print("Error loading preferences file: $e");
    }

    _lock.complete();
  }

  void _savePreferences() async {
    await _saveLock?.future;
    _saveLock = Completer();
    await (await localFile).writeAsString(jsonEncode(await _preferences), flush: true);
    _saveLock.complete();
  }

  Future operator [](String key) async {
    final value = (await _preferences)[key];
    return value;
  }

  operator []=(String key, dynamic value) async {
    final prefs = await _preferences;
    _lock = Completer();
    prefs[key] = value;
    _lock.complete();
    _savePreferences();
  }

  // TODO "paused" should be an attribute of each Experiment
  Future<bool> isPaused() async {
    final paused = await _instance[PAUSED_KEY];
    if (paused == null) {
      return false;
    }
    return paused is bool ? paused : false;
  }

  void setPaused(bool state) {
    _instance[PAUSED_KEY] = state;
  }
}
