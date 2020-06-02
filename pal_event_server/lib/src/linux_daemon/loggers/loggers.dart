import 'dart:async';

import 'package:taqo_common/model/event.dart';
import 'package:taqo_common/storage/dart_file_storage.dart';
import 'package:taqo_shared_prefs/taqo_shared_prefs.dart';

import '../../experiment_service_local.dart';
import '../../utils.dart';
import 'pal_event_helper.dart';

abstract class PacoEventLogger {
  final Duration sendInterval;
  bool active = false;

  PacoEventLogger({
    sendIntervalMs = 10000,
  }) : sendInterval = Duration(milliseconds: sendIntervalMs);

  void start();
  void stop();

  void sendToPal(List<Event> events, Timer timer) async {
    if (events.isNotEmpty) {
      storePacoEvent(events);
    }

    final storageDir = DartFileStorage.getLocalStorageDir().path;
    final sharedPrefs = TaqoSharedPrefs(storageDir);
    final experimentService = await ExperimentServiceLocal.getInstance();
    final experiments = await experimentService.getJoinedExperiments();

    for (var e in experiments) {
      final paused = await sharedPrefs.getBool("${sharedPrefsExperimentPauseKey}_${e.id}");
      if (e.isOver() || (paused ?? false)) {
        continue;
      }

      if (!active) {
        timer.cancel();
      }
    }
  }
}

Future<bool> shouldStartLoggers() async {
  final storageDir = DartFileStorage.getLocalStorageDir().path;
  final sharedPrefs = TaqoSharedPrefs(storageDir);
  final experimentService = await ExperimentServiceLocal.getInstance();
  final experiments = await experimentService.getJoinedExperiments();

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
