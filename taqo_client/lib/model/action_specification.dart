import 'package:json_annotation/json_annotation.dart';
import 'package:taqo_client/model/experiment.dart';
import 'package:taqo_client/model/experiment_group.dart';
import 'package:taqo_client/model/paco_notification_action.dart';

import 'action_trigger.dart';

part 'action_specification.g.dart';

@JsonSerializable()
class ActionSpecification implements Comparable<ActionSpecification> {
  DateTime time;
  DateTime timeUTC;
  Experiment experiment;
  ExperimentGroup experimentGroup;

  ActionTrigger actionTrigger;

  PacoNotificationAction action;
  int actionTriggerSpecId;

  ActionSpecification(this.time, this.experiment, this.experimentGroup, this.actionTrigger,
      this.action, this.actionTriggerSpecId) {
    timeUTC = time.toUtc();
  }

  factory ActionSpecification.fromJson(Map<String, dynamic> json) => _$ActionSpecificationFromJson(json);

  Map<String, dynamic> toJson() => _$ActionSpecificationToJson(this);

  @override
  int compareTo(ActionSpecification other) => time.compareTo(other.time);

  @override
  String toString() => '${experiment.title} - ${experimentGroup.name} - ${actionTriggerSpecId} - '
      '${time.toIso8601String()}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ActionSpecification &&
              runtimeType == other.runtimeType &&
              time == other.time &&
              experiment.id == other.experiment.id &&
              experimentGroup.name == other.experimentGroup.name;

  @override
  int get hashCode =>
      time.hashCode ^
      experiment.id.hashCode ^
      experimentGroup.name.hashCode;
}
