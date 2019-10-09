import 'dart:convert';
import 'dart:io';

class UserPreferences {
  static const PAUSED_KEY = "paused";

  var _preferences = {};


  UserPreferences._privateConstructor() {
   readPreferences();
  }

  static final UserPreferences _instance = UserPreferences._privateConstructor();

  factory UserPreferences() {
    return _instance;
  }


  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/preferences.txt');
  }

  Future<Null> readPreferences() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        String contents = await file.readAsString();
        Map preferences = jsonDecode(contents);
        _preferences = preferences;
      }
      print("preferences file does not exist or is corrupted");
//      return {};
    } catch (e) {
      print("Error loading preferences file: $e");
//      return {};
    }
  }

  Future<File>  savePreferences() async {
    // TODO for mobile platforms use secure storage apis
    // for desktop, use local secure storage apis, e.g., Macos use keychain..
    // for Fuchsia ...?

    final file = await _localFile;
    var preferencesJson = jsonEncode(_preferences);
    return file.writeAsString(preferencesJson, flush: true);
  }

  getApplicationDocumentsDirectory() {
    return Directory.systemTemp;
  }

  bool get paused {
    if (_preferences != null) {
      var stored = _preferences[PAUSED_KEY];
      if (stored != null) {
        return stored;
      }
    }
    return false;
  }

  void set paused(state) {
      _preferences[PAUSED_KEY] = state;
      savePreferences();
  }

}
