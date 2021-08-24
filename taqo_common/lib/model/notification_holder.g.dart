// GENERATED CODE - DO NOT MODIFY BY HAND

// @dart=2.9

part of 'notification_holder.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationHolder _$NotificationHolderFromJson(Map<String, dynamic> json) {
  return NotificationHolder(
    json['id'] as int,
    json['alarmTime'] as int,
    json['experimentId'] as int,
    json['noticeCount'] as int,
    json['timeoutMillis'] as int,
    json['experimentGroupName'] as String,
    json['actionTriggerId'] as int,
    json['actionId'] as int,
    json['notificationSource'] as String,
    json['message'] as String,
    json['actionTriggerSpecId'] as int,
  )
    ..snoozeTime = json['snoozeTime'] as int
    ..snoozeCount = json['snoozeCount'] as int;
}

Map<String, dynamic> _$NotificationHolderToJson(NotificationHolder instance) =>
    <String, dynamic>{
      'id': instance.id,
      'alarmTime': instance.alarmTime,
      'experimentId': instance.experimentId,
      'noticeCount': instance.noticeCount,
      'timeoutMillis': instance.timeoutMillis,
      'notificationSource': instance.notificationSource,
      'message': instance.message,
      'experimentGroupName': instance.experimentGroupName,
      'actionTriggerId': instance.actionTriggerId,
      'actionId': instance.actionId,
      'actionTriggerSpecId': instance.actionTriggerSpecId,
      'snoozeTime': instance.snoozeTime,
      'snoozeCount': instance.snoozeCount,
    };
