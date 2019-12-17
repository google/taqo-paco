import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:taqo_client/model/experiment_group.dart';
import 'package:taqo_client/model/schedule.dart';
import 'package:taqo_client/model/schedule_trigger.dart';
import 'package:taqo_client/model/visualization.dart';
import 'package:taqo_client/storage/user_preferences.dart';
import "experiment_core.dart";

part 'experiment.g.dart';

@JsonSerializable()
class Experiment extends ExperimentCore with ChangeNotifier {

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
  bool _paused = false;

  @JsonKey(ignore: true)
  bool get paused {
    UserPreferences()["${EXPERIMENT_PAUSED_KEY_PREFIX}_$id"].then((dynamic fromPref) {
      _paused = fromPref ?? false;
      notifyListeners();
    });
    return _paused;
  }

  @JsonKey(ignore: true)
  set paused(bool value) {
    UserPreferences()["${EXPERIMENT_PAUSED_KEY_PREFIX}_$id"] = value;
    _paused = value;
    notifyListeners();
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

  bool isOver() {
    DateTime now = DateTime.now();
    return groups.every((group) => group.isOver(now));
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
}
