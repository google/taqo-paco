import 'package:taqo_common/storage/dart_file_storage.dart';
import 'package:taqo_shared_prefs/taqo_shared_prefs.dart';

import 'pal_constants.dart';
import '../utils.dart';

bool isPalCommandMessage(dynamic eventJson) =>
    eventJson is Map<String, dynamic> && eventJson[palCommandKey] != null;

bool isPauseMessage(dynamic eventJson) =>
    isPalCommandMessage(eventJson) && eventJson[palCommandKey] == pauseCommand;

bool isResumeMessage(dynamic eventJson) =>
    isPalCommandMessage(eventJson) && eventJson[palCommandKey] == resumeCommand;

bool isWhitelistedDataOnlyMessage(dynamic eventJson) =>
    isPalCommandMessage(eventJson) && eventJson[palCommandKey] == whiteListCommand;

bool isAllDataMessage(dynamic eventJson) =>
    isPalCommandMessage(eventJson) && eventJson[palCommandKey] == allCommand;

void _setBoolPref(String pref, bool value) async {
  final taqoDir = DartFileStorage.getLocalStorageDir().path;
  final sharedPreferences = TaqoSharedPrefs(taqoDir);
  sharedPreferences.setBool(pref, value);
}

void pauseDataUpload() {
  _setBoolPref(pauseCommand, true);
}

void resumeDataUpload() {
  _setBoolPref(pauseCommand, false);
}

void setWhitelistedDataOnly() {
  _setBoolPref(whiteListCommand, true);
}

void setAllDataOnly() {
  _setBoolPref(whiteListCommand, false);
}

Future<bool> _getBoolPref(String pref) async {
  final taqoDir = DartFileStorage.getLocalStorageDir().path;
  final sharedPreferences = TaqoSharedPrefs(taqoDir);
  final val = await sharedPreferences.getBool(pref);
  return val ?? false;
}

Future<bool> isPaused() async {
  return _getBoolPref(pauseCommand);
}

Future<bool> isWhitelistedDataOnly() async {
  return _getBoolPref(whiteListCommand);
}

Future<bool> isRunning() async {
  final experiments = await readJoinedExperiments();
  return experiments.isNotEmpty;
}
