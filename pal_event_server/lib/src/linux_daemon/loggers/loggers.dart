import 'dart:async';

import 'package:taqo_common/model/event.dart';
import 'package:taqo_common/storage/dart_file_storage.dart';
import 'package:taqo_shared_prefs/taqo_shared_prefs.dart';

import '../../utils.dart';
import 'pal_event_helper.dart';

abstract class PacoEventLogger {
  final Duration sendInterval;
  bool active;

  PacoEventLogger({
    sendIntervalMs = 10000,
  }) : sendInterval = Duration(milliseconds: sendIntervalMs);

  void start();
  void stop();

  void sendToPal(List<Event> events, Timer timer) {
    if (events.isNotEmpty) {
      storePacoEvent(events);
    }

    if (!active) {
      timer.cancel();
    }
  }
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
