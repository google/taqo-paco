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

import 'package:json_annotation/json_annotation.dart';

import '../util/date_time_util.dart';
import 'experiment_core.dart';
import 'experiment_group.dart';
import 'schedule.dart';
import 'schedule_trigger.dart';
import 'signal_time.dart';
import 'visualization.dart';

part 'experiment.g.dart';

@JsonSerializable()
class Experiment extends ExperimentCore {
  static const DEFAULT_POST_INSTALL_INSTRUCTIONS =
      "<b>You have successfully joined the experiment!</b><br/><br/>"
      "No need to do anything else for now.<br/><br/>"
      "Paco will send you a notification when it is time to participate.<br/><br/>"
      "Be sure your ringer/buzzer is on so you will hear the notification.";

  String modifyDate;
  bool published;
  List<String> admins;
  List<String> publishedUsers;
  int version = 1;

  List<ExperimentGroup> groups;
  String ringtoneUri;
  String postInstallInstructions;

  @JsonKey(defaultValue: false)
  bool anonymousPublic;
  int participantId;
  List<Visualization> visualizations;

  Experiment();

  factory Experiment.fromJson(Map<String, dynamic> json) =>
      _$ExperimentFromJson(json);

  Map<String, dynamic> toJson() => _$ExperimentToJson(this);

  @JsonKey(ignore: true)
  bool active = false;

  @JsonKey(ignore: true)
  bool paused = false;

  List<ExperimentGroup> getSurveys() {
    return groups
        .where((group) =>
            group.groupType == GroupTypeEnum.SURVEY ||
            (group.groupType == null && group.inputs.isNotEmpty))
        .toList();
  }

  List<ExperimentGroup> getActiveSurveys() {
    var now = DateTime.now();
    return getSurveys().where((survey) => !survey.isOver(now)).toList();
  }

  DateTime getFirstGroupStartTime() {
    final startTimes = groups
        .where((g) => g.groupType != GroupTypeEnum.SYSTEM && g.fixedDuration)
        .map((g) => parseYMDTime(g.startDate))
        .toList(growable: false);
    startTimes.sort();
    return startTimes.first;
  }

  DateTime getLastGroupEndTime() {
    final endTimes = groups
        .where((g) => g.groupType != GroupTypeEnum.SYSTEM && g.fixedDuration)
        .map((g) => parseYMDTime(g.endDate))
        .toList(growable: false);
    endTimes.sort();
    return endTimes.last;
  }

  bool isOver([DateTime now]) {
    now ??= DateTime.now();
    return groups.every((group) => group.isOver(now));
  }

  bool isStarted(DateTime now) {
    if (!areAllGroupsFixed()) {
      return true;
    }
    final firstGroupStartTime = getFirstGroupStartTime();
    return now.isAtSameMomentAs(firstGroupStartTime) ||
        now.isAfter(firstGroupStartTime);
  }

  DateTime getEndTime() {
    DateTime lastSignalTime;
    for (var g in groups) {
      DateTime lastGroupSignalTime =
          parseYMDTime(g.endDate).add(Duration(days: 1));

      for (var trigger in g.actionTriggers) {
        if (trigger is ScheduleTrigger) {
          for (var schedule in trigger.schedules) {
            if (schedule.scheduleType == Schedule.WEEKDAY) {
              final lastSignal = schedule.signalTimes.last;
              if (lastSignal != null &&
                  lastSignal.type == SignalTime.FIXED_TIME) {
                // TODO actually compute the last time based on all of the rules for offset times
                // TODO and skip if missed rules
                lastGroupSignalTime = parseYMDTime(g.endDate);
                lastGroupSignalTime.add(Duration(
                    milliseconds: lastSignal.fixedTimeMillisFromMidnight));
              }
            }
          }
        }

        if (lastSignalTime == null ||
            lastGroupSignalTime.isAfter(lastSignalTime)) {
          lastSignalTime = lastGroupSignalTime;
        }
      }
    }

    return lastSignalTime;
  }

  ExperimentGroup getGroupNamed(String experimentGroupName) {
    return groups.singleWhere((grp) => grp.name == experimentGroupName);
  }

  bool userCanEditAtLeastOneSchedule() {
    for (var group in groups) {
      if (group.actionTriggers
          .where((trigger) => trigger is ScheduleTrigger)
          .map((trigger) => (trigger as ScheduleTrigger)
              .schedules
              .any((schedule) => schedule.userEditable))
          .any((x) => x)) {
        return true;
      }
    }
    return false;
  }

  void updateSchedule(int scheduleId, Schedule newSchedule) {
    groups.forEach((group) {
      group.actionTriggers
          .where((trigger) => trigger is ScheduleTrigger)
          .forEach((trigger) {
        final schedules = (trigger as ScheduleTrigger).schedules;
        for (var i = 0; i < schedules.length; i++) {
          if (schedules[i].id == scheduleId) {
            schedules[i] = newSchedule;
            return;
          }
        }
      });
    });
  }

  bool areAllGroupsFixed() => groups
      .where((g) => g.groupType != GroupTypeEnum.SYSTEM)
      .every((g) => g.fixedDuration);
}
