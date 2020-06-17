import 'dart:async';

import 'package:taqo_common/model/event.dart';
import 'package:taqo_common/model/experiment.dart';
import 'package:taqo_common/model/experiment_group.dart';
import 'package:taqo_common/storage/dart_file_storage.dart';
import 'package:taqo_shared_prefs/taqo_shared_prefs.dart';

import '../experiment_service_local.dart';
import '../utils.dart';
import 'app_usage/app_logger.dart';
import 'cmd_line/cmdline_logger.dart';
import 'pal_event_helper.dart';

class ExperimentLoggerInfo {
  final Experiment experiment;
  final groups = <ExperimentGroup>[];
  ExperimentLoggerInfo(this.experiment);
}

abstract class PacoEventLogger {
  final String loggerName;
  final GroupTypeEnum groupType;
  final experimentsBeingLogged = <ExperimentLoggerInfo>[];
  final Duration sendInterval;
  bool active = false;

  PacoEventLogger(this.loggerName, this.groupType, {
    sendIntervalMs = 10000,
  }) : sendInterval = Duration(milliseconds: sendIntervalMs);

  bool _isCurrentlyLogging(int id, String name) {
    for (var info in experimentsBeingLogged) {
      if (info.experiment.id != id) {
        continue;
      }

      for (var g in info.groups) {
        if (g.name == name) {
          return true;
        }
      }
    }

    return false;
  }

  void start(List<ExperimentLoggerInfo> toStartLogging) async {
    final events = <Event>[];

    for (var info in toStartLogging) {
      // Are we already logging some groups for this experiment?
      final currentlyLogging =
          experimentsBeingLogged.firstWhere((i) => i.experiment.id == info.experiment.id,
              orElse: () => null);

      for (var g in info.groups) {
        // Don't start logging the same group if already logging it
        if (_isCurrentlyLogging(info.experiment.id, g.name)) {
          continue;
        }

        // Create Paco Event for logging started
        events.add(await createLoggerStatusPacoEvent(info.experiment, g.name, loggerName, true));

        // If already logging the experiment, track the new group
        if (currentlyLogging != null) {
          currentlyLogging.groups.add(g);
        }
      }

      // If not already logging the experiment, track it
      if (currentlyLogging == null) {
        experimentsBeingLogged.add(info);
      }
    }

    // Sync
    if (events.isNotEmpty) {
      storePacoEvent(events);
    }
  }

  /// Note: The argument [toKeep] is a list of [ExperimentLoggerInfo] to keep, NOT stop
  void stop(List<ExperimentLoggerInfo> toKeep) async {
    final events = <Event>[];

    // Find groups to stop
    final expToRemove = <int>[];
    for (var info in experimentsBeingLogged) {
      // Are there any groups to keep for this experiment?
      final keep = toKeep.firstWhere((i) => i.experiment.id == info.experiment.id,
          orElse: () => null);

      final groupsToRemove = <String>[];
      for (var g in info.groups) {
        if (keep == null) {
          // Remove all groups for this experiment
          // Create Paco Event for logging stopped
          events.add(await createLoggerStatusPacoEvent(info.experiment, g.name, loggerName, false));
        } else {
          final keepGroup = keep.groups.firstWhere((i) => i.name == g.name, orElse: () => null);
          if (keepGroup == null) {
            // Create Paco Event for logging stopped
            events.add(await createLoggerStatusPacoEvent(info.experiment, g.name, loggerName, false));
            groupsToRemove.add(g.name);
          }
        }
      }

      // Stop logging this whole Experiment
      if (keep == null || info.groups.isEmpty) {
        expToRemove.add(info.experiment.id);
      } else {
        info.groups.removeWhere((g) => groupsToRemove.contains(g.name));
      }
    }

    experimentsBeingLogged.removeWhere((info) => expToRemove.contains(info.experiment.id));

    // Sync
    if (events.isNotEmpty) {
      storePacoEvent(events);
    }
  }

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

void startOrStopLoggers() async {
  final typeToLogger = {
    GroupTypeEnum.APPUSAGE_DESKTOP: AppLogger(),
    GroupTypeEnum.APPUSAGE_SHELL: CmdLineLogger(),
  };

  for (var entry in typeToLogger.entries) {
    final type = entry.key;
    final logger = entry.value;
    final experimentsToLog = await _getExperimentsToLogForType(type);
    // Note: parameter to logger.stop() is inverted, i.e. the experiments
    // passed are the experiments to continue logging
    logger.stop(experimentsToLog);
    logger.start(experimentsToLog);
  }
}
/// Return a Map of Experiments and Groups that should enable logging
Future<List<ExperimentLoggerInfo>> _getExperimentsToLogForType(GroupTypeEnum type) async {
  final experimentService = await ExperimentServiceLocal.getInstance();
  final experiments = await experimentService.getJoinedExperiments();

  final experimentsToLog = <ExperimentLoggerInfo>[];

  for (var e in experiments) {
    if (e.isOver() || (e.paused ?? false)) {
      continue;
    }

    final toLog = ExperimentLoggerInfo(e);

    for (var g in e.groups) {
      if (g.groupType == type) {
        toLog.groups.add(g);
      }
    }

    if (toLog.groups.isNotEmpty) {
      experimentsToLog.add(toLog);
    }
  }

  return experimentsToLog;
}
