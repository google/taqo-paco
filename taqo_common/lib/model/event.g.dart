// GENERATED CODE - DO NOT MODIFY BY HAND

// @dart=2.9

part of 'event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Event _$EventFromJson(Map<String, dynamic> json) {
  return Event()
    ..responses = Event._responsesFromListOfMap(json['responses'] as List)
    ..experimentName = json['experimentName'] as String
    ..scheduleTime =
        Event._zonedDateTimeFromString(json['scheduledTime'] as String)
    ..responseTime =
        Event._zonedDateTimeFromString(json['responseTime'] as String)
    ..experimentVersion = json['experimentVersion'] as int
    ..groupName = json['experimentGroupName'] as String
    ..actionTriggerId = json['actionTriggerId'] as int
    ..actionTriggerSpecId = json['actionTriggerSpecId'] as int
    ..actionId = json['actionId'] as int
    ..experimentId = json['experimentId'] as int;
}

Map<String, dynamic> _$EventToJson(Event instance) => <String, dynamic>{
      'responses': Event._responsesToListOfMap(instance.responses),
      'experimentName': instance.experimentName,
      'scheduledTime': Event._zonedDateTimeToString(instance.scheduleTime),
      'responseTime': Event._zonedDateTimeToString(instance.responseTime),
      'experimentVersion': instance.experimentVersion,
      'experimentGroupName': instance.groupName,
      'actionTriggerId': instance.actionTriggerId,
      'actionTriggerSpecId': instance.actionTriggerSpecId,
      'actionId': instance.actionId,
      'experimentId': instance.experimentId,
    };
