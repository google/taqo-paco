import 'package:taqo_common/storage/dart_file_storage.dart';
import 'package:taqo_shared_prefs/taqo_shared_prefs.dart';

import '../experiment_service_local.dart';
import 'pal_constants.dart';

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

void setAllowlistedDataOnly() {
  _setBoolPref(allowlistCommand, true);
}

void setAllDataOnly() {
  _setBoolPref(allowlistCommand, false);
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

Future<bool> isAllowlistedDataOnly() async {
  return _getBoolPref(allowlistCommand);
}

Future<bool> isRunning() async {
  final experimentService = await ExperimentServiceLocal.getInstance();
  final experiments = await experimentService.getJoinedExperiments();
  return experiments.isNotEmpty;
}
