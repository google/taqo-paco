// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Event _$EventFromJson(Map<String, dynamic> json) {
  return Event()
    ..responses = json['responses'] == null
        ? null
        : Event._responsesFromListOfMap(
            json['responses'] as List<Map<String, dynamic>>)
    ..experimentServerId = json['experimentId'] as int
    ..experimentName = json['experimentName'] as String
    ..scheduleTime = json['scheduledTime'] == null
        ? null
        : Event._zonedDateTimeFromString(json['scheduledTime'] as String)
    ..responseTime = json['responseTime'] == null
        ? null
        : Event._zonedDateTimeFromString(json['responseTime'] as String)
    ..experimentVersion = json['experimentVersion'] as int
    ..groupName = json['experimentGroupName'] as String
    ..actionTriggerId = json['actionTriggerId'] as int
    ..actionTriggerSpecId = json['actionTriggerSpecId'] as int
    ..actionId = json['actionId'] as int;
}

Map<String, dynamic> _$EventToJson(Event instance) => <String, dynamic>{
      'responses': instance.responses == null
          ? null
          : Event._responsesToListOfMap(instance.responses),
      'experimentId': instance.experimentServerId,
      'experimentName': instance.experimentName,
      'scheduledTime': instance.scheduleTime == null
          ? null
          : Event._zonedDateTimeToString(instance.scheduleTime),
      'responseTime': instance.responseTime == null
          ? null
          : Event._zonedDateTimeToString(instance.responseTime),
      'experimentVersion': instance.experimentVersion,
      'experimentGroupName': instance.groupName,
      'actionTriggerId': instance.actionTriggerId,
      'actionTriggerSpecId': instance.actionTriggerSpecId,
      'actionId': instance.actionId
    };
