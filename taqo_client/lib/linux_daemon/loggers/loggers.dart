import 'dart:async';

import 'package:taqo_shared_prefs/taqo_shared_prefs.dart';

import '../../model/experiment.dart';
import '../../storage/dart_file_storage.dart';
import '../util.dart';

typedef CreateEventFunc = Future<Map<String, dynamic>> Function(
    Experiment experiment, String groupname, Map<String, dynamic> response);

Future<List<Map<String, dynamic>>> createLoggerPacoEvents(
    Map<String, dynamic> response, CreateEventFunc func) async {
  final events = <Map<String, dynamic>>[];

  final storageDir = DartFileStorage.getLocalStorageDir().path;
  final sharedPrefs = TaqoSharedPrefs(storageDir);
  final experiments = await readJoinedExperiments();

  for (var e in experiments) {
    final paused = await sharedPrefs.getBool("${sharedPrefsExperimentPauseKey}_${e.id}");
    if (e.isOver() || (paused ?? false)) {
      continue;
    }

    for (var g in e.groups) {
      if (g.isAppUsageLoggingGroup) {
        events.add(await func(e, g.name, response));
      }
    }
  }

  return events;
}

Future<bool> shouldStartLoggers() async {
  final storageDir = DartFileStorage.getLocalStorageDir().path;
  final sharedPrefs = TaqoSharedPrefs(storageDir);
  final experiments = await readJoinedExperiments();

  for (var e in experiments) {
    final paused = await sharedPrefs.getBool("${sharedPrefsExperimentPauseKey}_${e.id}");
    if (e.isOver() || (paused ?? false)) {
      continue;
    }

    for (var g in e.groups) {
      if (g.isAppUsageLoggingGroup) {
        return true;
      }
    }
  }

  return false;
}
