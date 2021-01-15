// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async';

import 'package:taqo_common/model/action_trigger.dart';
import 'package:taqo_common/model/event.dart';
import 'package:taqo_common/model/experiment.dart';
import 'package:taqo_common/model/experiment_group.dart';
import 'package:taqo_common/model/interrupt_cue.dart';
import 'package:taqo_common/model/interrupt_trigger.dart';
import 'package:taqo_common/storage/dart_file_storage.dart';
import 'package:taqo_shared_prefs/taqo_shared_prefs.dart';

import '../experiment_service_local.dart';
import '../utils.dart';
import 'app_usage/app_logger.dart';
import 'cmd_line/cmdline_logger.dart';
import 'intellij/intellij_logger.dart';
import 'pal_event_helper.dart';

class ExperimentLoggerInfo {
  final Experiment experiment;
  final groups = <ExperimentGroup>[];
  ExperimentLoggerInfo(this.experiment);
}

abstract class PacoEventLogger {
  final String loggerName;
  final experimentsBeingLogged = <ExperimentLoggerInfo>[];
  final experimentsBeingTriggered = <ExperimentLoggerInfo>[];
  final Duration sendInterval;
  bool active = false;

  PacoEventLogger(
    this.loggerName, {
    sendIntervalMs = 10000,
  }) : sendInterval = Duration(milliseconds: sendIntervalMs);

  static bool _isCurrentlyTracking(
      List<ExperimentLoggerInfo> list, int id, String name) {
    for (var info in list) {
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

  Future<List<Event>> _start(List<ExperimentLoggerInfo> toStart,
      List<ExperimentLoggerInfo> tracking) async {
    final events = <Event>[];

    for (var info in toStart) {
      // Are we already logging some groups for this experiment?
      final currentlyTracking = tracking.firstWhere(
          (i) => i.experiment.id == info.experiment.id,
          orElse: () => null);

      for (var g in info.groups) {
        // Don't start logging the same group if already logging it
        if (_isCurrentlyTracking(tracking, info.experiment.id, g.name)) {
          continue;
        }

        // Create Paco Event for logging started
        events.add(await createLoggerStatusPacoEvent(
            info.experiment, g.name, loggerName, true));

        // If already logging the experiment, track the new group
        if (currentlyTracking != null) {
          currentlyTracking.groups.add(g);
        }
      }

      // If not already logging the experiment, track it
      if (currentlyTracking == null) {
        tracking.add(info);
      }
    }

    return events;
  }

  void start(List<ExperimentLoggerInfo> toStartLogging,
      List<ExperimentLoggerInfo> toStartTriggering) async {
    final events = <Event>[];
    events.addAll(await _start(toStartLogging, experimentsBeingLogged));
    events.addAll(await _start(toStartTriggering, experimentsBeingTriggered));

    // Sync
    if (events.isNotEmpty) {
      storePacoEvent(events);
    }
  }

  Future<List<Event>> _stop(List<ExperimentLoggerInfo> toKeep,
      List<ExperimentLoggerInfo> tracking) async {
    final events = <Event>[];

    // Find groups to stop
    final expToRemove = <int>[];
    for (var info in tracking) {
      // Are there any groups to keep for this experiment?
      final keep = toKeep.firstWhere(
          (i) => i.experiment.id == info.experiment.id,
          orElse: () => null);

      final groupsToRemove = <String>[];
      for (var g in info.groups) {
        if (keep == null) {
          // Remove all groups for this experiment
          // Create Paco Event for logging stopped
          events.add(await createLoggerStatusPacoEvent(
              info.experiment, g.name, loggerName, false));
        } else {
          final keepGroup = keep.groups
              .firstWhere((i) => i.name == g.name, orElse: () => null);
          if (keepGroup == null) {
            // Create Paco Event for logging stopped
            events.add(await createLoggerStatusPacoEvent(
                info.experiment, g.name, loggerName, false));
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

    tracking.removeWhere((info) => expToRemove.contains(info.experiment.id));

    return events;
  }

  /// Note: The argument [toKeepLogging] is a list of [ExperimentLoggerInfo] to keep, NOT stop
  void stop(List<ExperimentLoggerInfo> toKeepLogging,
      List<ExperimentLoggerInfo> toKeepTriggering) async {
    final events = <Event>[];
    events.addAll(await _stop(toKeepLogging, experimentsBeingLogged));
    events.addAll(await _stop(toKeepTriggering, experimentsBeingTriggered));

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
      final paused =
          await sharedPrefs.getBool("${sharedPrefsExperimentPauseKey}_${e.id}");
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
    GroupTypeEnum.APPUSAGE_DESKTOP: {
      'logger': AppLogger(),
      'cueCodes': [
        InterruptCue.APP_USAGE_DESKTOP,
        InterruptCue.APP_CLOSED_DESKTOP,
      ],
    },
    GroupTypeEnum.APPUSAGE_SHELL: {
      'logger': CmdLineLogger(),
      'cueCodes': [
        InterruptCue.APP_USAGE_SHELL,
        InterruptCue.APP_CLOSED_SHELL,
      ],
    },
    GroupTypeEnum.IDE_IDEA_USAGE: {
      'logger': IntelliJLogger(),
      'cueCodes': [
        InterruptCue.IDE_IDEA_USAGE,
      ],
    }
  };

  for (var entry in typeToLogger.entries) {
    final GroupTypeEnum type = entry.key;
    final List<int> cueCodes = entry.value['cueCodes'];
    final PacoEventLogger logger = entry.value['logger'];
    final experimentsToLog = await getExperimentsToLogForType(type);
    final experimentsToTrigger =
        await _getExperimentsToTriggerForCueCodes(cueCodes);
    // Note: parameters to logger.stop() are inverted, i.e. the experiments
    // passed are the experiments to continue logging/triggering
    logger.stop(experimentsToLog, experimentsToTrigger);
    logger.start(experimentsToLog, experimentsToTrigger);
  }
}

/// Return a Map of Experiments and Groups that should enable logging
Future<List<ExperimentLoggerInfo>> getExperimentsToLogForType(
    GroupTypeEnum groupType) async {
  final experimentService = await ExperimentServiceLocal.getInstance();
  final experiments = await experimentService.getJoinedExperiments();

  final experimentsToLog = <ExperimentLoggerInfo>[];

  for (var e in experiments) {
    if (e.isOver() || (e.paused ?? false)) {
      continue;
    }

    final toLog = ExperimentLoggerInfo(e);

    for (var g in e.groups) {
      // If the group type is the logger type
      if (g.groupType == groupType) {
        toLog.groups.add(g);
      }
    }

    if (toLog.groups.isNotEmpty) {
      experimentsToLog.add(toLog);
    }
  }

  return experimentsToLog;
}

/// Return a Map of Experiments and Groups that should enable logging
Future<List<ExperimentLoggerInfo>> _getExperimentsToTriggerForCueCodes(
    List<int> cueCodes) async {
  final experimentService = await ExperimentServiceLocal.getInstance();
  final experiments = await experimentService.getJoinedExperiments();

  final experimentsToTrigger = <ExperimentLoggerInfo>[];

  for (var e in experiments) {
    if (e.isOver() || (e.paused ?? false)) {
      continue;
    }

    final toLog = ExperimentLoggerInfo(e);

    for (var g in e.groups) {
      // For survey groups, if we have any action triggers this logger
      // cares about
      for (var a in g.actionTriggers) {
        if (a.type == ActionTrigger.INTERRUPT_TRIGGER_TYPE_SPECIFIER) {
          InterruptTrigger t = a;
          if (t.cues.any((c) => cueCodes.contains(c.cueCode))) {
            toLog.groups.add(g);
            break;
          }
        }
      }
    }

    if (toLog.groups.isNotEmpty) {
      experimentsToTrigger.add(toLog);
    }
  }

  return experimentsToTrigger;
}
