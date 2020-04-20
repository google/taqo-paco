import 'package:pal_event_server/src/user_preferences.dart';

import 'constants.dart';

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
  UserDefaults.get().then((userPreferences) {
    userPreferences[pauseCommand] = true;
  });
}

void resumeDataUpload() {
  UserDefaults.get().then((userPreferences) {
    userPreferences[pauseCommand] = false;
  });
}

void setWhitelistedDataOnly() {
  UserDefaults.get().then((userPreferences) {
    userPreferences[whiteListCommand] = true;
  });
}

void setAllDataOnly() {
  UserDefaults.get().then((userPreferences) {
    userPreferences[whiteListCommand] = false;
  });
}

Future<bool> isPaused() async {
  final userPreferences = await UserDefaults.get();
  final paused = await userPreferences[pauseCommand];
  return paused ?? false;
}

Future<bool> isRunning() async {
  final userPreferences = await UserDefaults.get();
  return (await userPreferences[experimentKey]) != null;
}

Future<bool> isWhitelistedDataOnly() async {
  final userPreferences = await UserDefaults.get();
  final whiteList = await userPreferences[whiteListCommand];
  return whiteList ?? false;
}
