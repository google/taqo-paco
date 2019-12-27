import 'package:json_annotation/json_annotation.dart';
import 'package:taqo_client/model/experiment_group.dart';
import 'package:taqo_client/model/schedule.dart';
import 'package:taqo_client/model/schedule_trigger.dart';
import 'package:taqo_client/model/signal_time.dart';
import 'package:taqo_client/model/visualization.dart';
import 'package:taqo_client/storage/user_preferences.dart';
import 'package:taqo_client/util/date_time_util.dart';
import "experiment_core.dart";

part 'experiment.g.dart';

@JsonSerializable()
class Experiment extends ExperimentCore {

  static const DEFAULT_POST_INSTALL_INSTRUCTIONS = "<b>You have successfully joined the experiment!</b><br/><br/>"
      + "No need to do anything else for now.<br/><br/>"
      +
      "Paco will send you a notification when it is time to participate.<br/><br/>"
      + "Be sure your ringer/buzzer is on so you will hear the notification.";
  static const EXPERIMENT_PAUSED_KEY_PREFIX = "paused";

  String modifyDate;
  bool published;
  List<String> admins;
  List<String> publishedUsers;
  int version = 1;

  List<ExperimentGroup> groups;
  String ringtoneUri;
  String postInstallInstructions;
  bool anonymousPublic;
  List<Visualization> visualizations;

  @JsonKey(ignore: true)
  Future<bool> isPaused() async {
    return await UserPreferences()["${EXPERIMENT_PAUSED_KEY_PREFIX}_$id"] ?? false;
  }

  @JsonKey(ignore: true)
  void setPaused(bool value) {
    UserPreferences()["${EXPERIMENT_PAUSED_KEY_PREFIX}_$id"] = value;
  }

  Experiment();

  factory Experiment.fromJson(Map<String, dynamic> json) => _$ExperimentFromJson(json);

  Map<String, dynamic> toJson() => _$ExperimentToJson(this);


  List<ExperimentGroup> getSurveys() {
    return groups.where((group) => group.groupType == GroupTypeEnum.SURVEY ||
        (group.groupType == null && group.inputs.isNotEmpty)).toList();
  }

  List<ExperimentGroup> getActiveSurveys() {
    var now = DateTime.now();
    return getSurveys().where((survey) => !survey.isOver(now)).toList();
  }

  DateTime getFirstGroupStartTime() {
    final startTimes = groups.where((g) => g.groupType != GroupTypeEnum.SYSTEM && g.fixedDuration)
        .map((g) => parseYMDTime(g.startDate)).toList(growable: false);
    startTimes.sort();
    return startTimes.first;
  }

  DateTime getLastGroupEndTime() {
    final endTimes = groups.where((g) => g.groupType != GroupTypeEnum.SYSTEM && g.fixedDuration)
        .map((g) => parseYMDTime(g.endDate)).toList(growable: false);
    endTimes.sort();
    return endTimes.last;
  }

  bool isOver([DateTime now]) {
    now ??= DateTime.now();
    return groups.every((group) => group.isOver(now));
  }

  bool isStarted(DateTime now) => areAllGroupsFixed() && now.isBefore(getFirstGroupStartTime());

  DateTime getEndTime() {
    DateTime lastSignalTime;
    for (var g in groups) {
      DateTime lastGroupSignalTime = parseYMDTime(g.endDate).add(
          Duration(days: 1));

      for (var trigger in g.actionTriggers) {
        if (trigger is ScheduleTrigger) {
          for (var schedule in trigger.schedules) {
            if (schedule.scheduleType == Schedule.WEEKDAY) {
              final lastSignal = schedule.signalTimes.last;
              if (lastSignal != null && lastSignal.type == SignalTime.FIXED_TIME) {
                // TODO actually compute the last time based on all of the rules for offset times
                // TODO and skip if missed rules
                lastGroupSignalTime = parseYMDTime(g.endDate);
                lastGroupSignalTime.add(
                    Duration(milliseconds: lastSignal.fixedTimeMillisFromMidnight));
              }
            }
          }
        }

        if (lastSignalTime == null || lastGroupSignalTime.isAfter(lastSignalTime)) {
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
          .map((trigger) => (trigger as ScheduleTrigger).schedules.any((schedule) => schedule.userEditable))
          .any((x) => x)) {
        return true;
      }
    }
    return false;
  }

  void updateSchedule(int scheduleId, Schedule newSchedule) {
    groups.forEach((group) {
      group.actionTriggers.where((trigger) => trigger is ScheduleTrigger).forEach((trigger) {
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

  bool areAllGroupsFixed() =>
      groups.where((g) => g.groupType != GroupTypeEnum.SYSTEM)
          .map((g) => g.fixedDuration)
          .every((b) => b);
}
