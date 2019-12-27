// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'action_specification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActionSpecification _$ActionSpecificationFromJson(Map<String, dynamic> json) {
  return ActionSpecification(
      json['time'] == null ? null : DateTime.parse(json['time'] as String),
      json['experiment'] == null
          ? null
          : Experiment.fromJson(json['experiment'] as Map<String, dynamic>),
      json['experimentGroup'] == null
          ? null
          : ExperimentGroup.fromJson(
              json['experimentGroup'] as Map<String, dynamic>),
      json['actionTrigger'] == null
          ? null
          : ActionTrigger.fromJson(
              json['actionTrigger'] as Map<String, dynamic>),
      json['action'] == null
          ? null
          : PacoNotificationAction.fromJson(
              json['action'] as Map<String, dynamic>),
      json['actionTriggerSpecId'] as int);
}

Map<String, dynamic> _$ActionSpecificationToJson(
        ActionSpecification instance) =>
    <String, dynamic>{
      'time': instance.time?.toIso8601String(),
      'experiment': instance.experiment,
      'experimentGroup': instance.experimentGroup,
      'actionTrigger': instance.actionTrigger,
      'action': instance.action,
      'actionTriggerSpecId': instance.actionTriggerSpecId
    };
