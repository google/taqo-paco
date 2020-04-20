import 'package:taqo_shared_prefs/taqo_shared_prefs.dart';

import 'pal_server/pal_constants.dart';
import 'utils.dart';

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

void pauseDataUpload() {
  final sharedPreferences = TaqoSharedPrefs(taqoDir);
  sharedPreferences.setBool(pauseCommand, true);
}

void resumeDataUpload() {
  final sharedPreferences = TaqoSharedPrefs(taqoDir);
  sharedPreferences.setBool(pauseCommand, false);
}

void setWhitelistedDataOnly() {
  final sharedPreferences = TaqoSharedPrefs(taqoDir);
  sharedPreferences.setBool(whiteListCommand, true);
}

void setAllDataOnly() {
  final sharedPreferences = TaqoSharedPrefs(taqoDir);
  sharedPreferences.setBool(whiteListCommand, false);
}

Future<bool> isPaused() async {
  final sharedPreferences = TaqoSharedPrefs(taqoDir);
  final paused = await sharedPreferences.getBool(pauseCommand);
  return paused ?? false;
}

Future<bool> isRunning() async {
  final sharedPreferences = TaqoSharedPrefs(taqoDir);
  final experiment = await sharedPreferences.getBool(experimentKey);
  return experiment != null;
}

Future<bool> isWhitelistedDataOnly() async {
  final sharedPreferences = TaqoSharedPrefs(taqoDir);
  final whiteList = await sharedPreferences.getBool(whiteListCommand);
  return whiteList ?? false;
}
