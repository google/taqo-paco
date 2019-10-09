import 'package:json_annotation/json_annotation.dart';
import 'package:taqo_client/model/experiment_group.dart';
import 'package:taqo_client/model/visualization.dart';
import "experiment_core.dart";

part 'experiment.g.dart';

@JsonSerializable()
class Experiment extends ExperimentCore {

  static const DEFAULT_POST_INSTALL_INSTRUCTIONS = "<b>You have successfully joined the experiment!</b><br/><br/>"
      + "No need to do anything else for now.<br/><br/>"
      +
      "Paco will send you a notification when it is time to participate.<br/><br/>"
      + "Be sure your ringer/buzzer is on so you will hear the notification.";

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

  Experiment();

  factory Experiment.fromJson(Map<String, dynamic> json) => _$ExperimentFromJson(json);

  Map<String, dynamic> toJson() => _$ExperimentToJson(this);


  List<ExperimentGroup> getSurveys() {
    return groups.where((group) => group.groupType == GroupTypeEnum.SURVEY).toList();
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

}