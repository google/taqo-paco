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

// @dart=2.9

import 'package:taqo_common/model/action_specification.dart';
import 'package:taqo_common/model/paco_action.dart';
import 'package:taqo_common/model/experiment.dart';
import 'package:taqo_common/model/experiment_group.dart';
import 'package:taqo_common/model/interrupt_cue.dart';
import 'package:taqo_common/model/interrupt_trigger.dart';
import 'package:taqo_common/model/paco_notification_action.dart';
import 'package:taqo_common/storage/dart_file_storage.dart';
import 'package:taqo_common/util/date_time_util.dart';
import 'package:taqo_shared_prefs/taqo_shared_prefs.dart';

import '../daemon/alarm_manager.dart' as alarm_manager;
import '../experiment_service_local.dart';
import '../utils.dart';

class TriggerEvent {
  DateTime dateTime;
  int code;
  String sourceId;

  String packageName;
  String className;
  String eventText;
  String eventContentDescription;

  TriggerEvent(
    this.dateTime,
    this.code,
    this.sourceId, {
    this.packageName,
    this.className,
    this.eventText,
    this.eventContentDescription,
  });
}

mixin EventTriggerSource {
  static const sharedPrefsRecentlyTriggeredKey = 'recentlyTriggered';

  /// Create [TriggerEvent] objects
  TriggerEvent createEventTriggers(int code, String sourceId,
      {String packageName,
      String className,
      String eventText,
      String eventContentDesc}) {
    return TriggerEvent(DateTime.now(), code, sourceId);
  }

  /// Process triggers for running Experiments
  void broadcastEventsForTriggers(List<TriggerEvent> events) async {
    final storageDir = DartFileStorage.getLocalStorageDir().path;
    final sharedPrefs = TaqoSharedPrefs(storageDir);
    final experimentService = await ExperimentServiceLocal.getInstance();
    final experiments = await experimentService.getJoinedExperiments();

    for (final event in events) {
      for (Experiment experiment in experiments) {
        final paused = await sharedPrefs
            .getBool("${sharedPrefsExperimentPauseKey}_${experiment.id}");
        if (experiment.isOver() || (paused ?? false)) {
          // TODO Handle InterruptCue.PACO_EXPERIMENT_ENDED_EVENT
          continue;
        }

        _broadcastTriggerForExperiment(event, experiment);
      }
    }
  }

  /// Process trigger for experiment
  Future _broadcastTriggerForExperiment(
      TriggerEvent event, Experiment experiment) async {
    final groupsToTrigger = _shouldTriggerBy(experiment, event);
    for (final triggerInfo in groupsToTrigger) {
      final uniqueStringForTrigger =
          _createUniqueTriggerString(experiment, triggerInfo);

      final InterruptTrigger interruptTrigger = triggerInfo[1];
      if (await _recentlyTriggered(event.dateTime, uniqueStringForTrigger,
          interruptTrigger.minimumBuffer)) {
        continue;
      }

      _setRecentlyTriggered(event.dateTime, uniqueStringForTrigger);

      for (final action in interruptTrigger.actions) {
        final ExperimentGroup group = triggerInfo[0];
        final InterruptCue interruptCue = triggerInfo[2];
        final actionTriggerSpecId = interruptCue?.id;

        switch (action.actionCode) {
          case PacoAction.NOTIFICATION_TO_PARTICIPATE_ACTION_CODE:
            final PacoNotificationAction notificationAction =
                action as PacoNotificationAction;
            final delay = Duration(milliseconds: notificationAction.delay ?? 0);
            final actionSpec = ActionSpecification(
                event.dateTime.add(delay),
                experiment,
                group,
                interruptTrigger,
                notificationAction,
                actionTriggerSpecId);

            alarm_manager.createNotificationWithTimeout(actionSpec);
            break;
          case PacoAction.NOTIFICATION_ACTION_CODE:
          case PacoAction.LOG_EVENT_ACTION_CODE:
          case PacoAction.EXECUTE_SCRIPT_ACTION_CODE:
            break;
        }
      }
    }
  }

  List _shouldTriggerBy(Experiment experiment, TriggerEvent event) {
    final groupsToTrigger = [];

    for (final group in experiment.groups) {
      if (group.isOver(event.dateTime) ||
          group.groupType == GroupTypeEnum.SYSTEM) {
        continue;
      }

      for (final actionTrigger in group.actionTriggers) {
        if (actionTrigger is! InterruptTrigger) {
          continue;
        }

        final interruptTrigger = actionTrigger as InterruptTrigger;

        if (!_withinTriggerTimeWindow(event.dateTime, interruptTrigger)) {
          continue;
        }

        for (final interruptCue in interruptTrigger.cues) {
          if (interruptCue.cueCode != event.code) {
            continue;
          }

          bool cueFiltersMatch = false;

          if (_usesSourceId(interruptCue)) {
            if (_isAccessibilityRelatedCueCodeAndMatchesPatterns(
                interruptCue.cueCode)) {
              cueFiltersMatch = _isMatchingAccessibilitySource(
                  event.packageName,
                  event.className,
                  event.eventContentDescription,
                  event.eventText,
                  interruptCue);
            } else {
              cueFiltersMatch = eventMatchesCueSource(interruptCue.cueSource, event.sourceId);
            }
          } else if (_isExperimentLifecycleEventTrigger(interruptCue)) {
            cueFiltersMatch = (event.sourceId?.isNotEmpty ?? false) &&
                (int.tryParse(event.sourceId) == experiment.id);
          } else {
            cueFiltersMatch = true;
          }

          if (cueFiltersMatch) {
            groupsToTrigger.add([group, interruptTrigger, interruptCue]);
          }
        }
      }
    }

    return groupsToTrigger;
  }

  bool _withinTriggerTimeWindow(DateTime when, InterruptTrigger trigger) {
    if (!trigger.timeWindow) {
      return true;
    }

    if (!trigger.weekends) {
      if (when.weekday >= DateTime.saturday) {
        return false;
      }
    }

    final currTimeMillis = getMillisFromMidnight(when);
    return trigger.startTimeMillis <= currTimeMillis &&
        currTimeMillis < trigger.endTimeMillis;
  }

  bool _usesSourceId(InterruptCue interruptCue) {
    final cueCode = interruptCue.cueCode;
    return cueCode == InterruptCue.PACO_ACTION_EVENT ||
        cueCode == InterruptCue.APP_USAGE ||
        cueCode == InterruptCue.APP_CLOSED ||
        cueCode == InterruptCue.ACCESSIBILITY_EVENT_VIEW_CLICKED ||
        cueCode == InterruptCue.NOTIFICATION_CREATED ||
        cueCode == InterruptCue.NOTIFICATION_TRAY_SWIPE_DISMISS ||
        cueCode == InterruptCue.NOTIFICATION_CLICKED ||
        cueCode == InterruptCue.APP_USAGE_DESKTOP ||
        cueCode == InterruptCue.APP_CLOSED_DESKTOP ||
        cueCode == InterruptCue.APP_USAGE_SHELL ||
        cueCode == InterruptCue.APP_CLOSED_SHELL ||
        cueCode == InterruptCue.IDE_IDEA_USAGE;
  }

  bool _isExperimentLifecycleEventTrigger(InterruptCue interruptCue) {
    final cueCode = interruptCue.cueCode;
    return cueCode == InterruptCue.PACO_EXPERIMENT_JOINED_EVENT ||
        cueCode == InterruptCue.PACO_EXPERIMENT_ENDED_EVENT ||
        cueCode == InterruptCue.PACO_EXPERIMENT_RESPONSE_RECEIVED_EVENT;
  }

  bool _isAccessibilityRelatedCueCodeAndMatchesPatterns(int cueCode) {
    return cueCode == InterruptCue.ACCESSIBILITY_EVENT_VIEW_CLICKED ||
        cueCode == InterruptCue.NOTIFICATION_CREATED ||
        cueCode == InterruptCue.NOTIFICATION_TRAY_SWIPE_DISMISS ||
        cueCode == InterruptCue.NOTIFICATION_CLICKED;
  }

  bool _isMatchingAccessibilitySource(
      String packageName,
      String className,
      String eventContentDescription,
      String eventText,
      InterruptCue interruptCue) {
    if (interruptCue.cueSource?.isNotEmpty ?? false) {
      if (interruptCue.cueSource != packageName) {
        return false;
      }
    }

    if (interruptCue.cueAEContentDescription?.isNotEmpty ?? false) {
      if (interruptCue.cueAEContentDescription != eventContentDescription &&
          interruptCue.cueAEContentDescription != eventText) {
        return false;
      }
    }

    if (interruptCue.cueAEClassName?.isNotEmpty ?? false) {
      if (interruptCue.cueAEClassName != className) {
        return false;
      }
    }

    return true;
  }

  String _createUniqueTriggerString(Experiment experiment, List triggerInfo) {
    final ExperimentGroup group = triggerInfo[0];
    final InterruptTrigger interruptTrigger = triggerInfo[1];
    return '${experiment.id}:${group.name}:${interruptTrigger.id}';
  }

  Future<bool> _recentlyTriggered(
      DateTime when, String uniqueTriggerString, int minBuffer) async {
    final storageDir = DartFileStorage.getLocalStorageDir().path;
    final sharedPrefs = TaqoSharedPrefs(storageDir);

    final triggered = await sharedPrefs
        .getInt("${sharedPrefsRecentlyTriggeredKey}_${uniqueTriggerString}");
    if (triggered == null) {
      return false;
    }

    return DateTime.fromMillisecondsSinceEpoch(triggered)
        .add(Duration(minutes: minBuffer))
        .isAfter(when);
  }

  Future _setRecentlyTriggered(
      DateTime when, String uniqueTriggerString) async {
    final storageDir = DartFileStorage.getLocalStorageDir().path;
    final sharedPrefs = TaqoSharedPrefs(storageDir);
    sharedPrefs.setInt(
        "${sharedPrefsRecentlyTriggeredKey}_${uniqueTriggerString}",
        when.millisecondsSinceEpoch);
  }
}

bool eventMatchesCueSource(String cueSource, String eventSource) {
  if ((eventSource?.isEmpty ?? true) && (cueSource?.isEmpty ?? true)) {
    return true;
  }
  return RegExp(cueSource).hasMatch(eventSource);
}
