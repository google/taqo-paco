// GENERATED CODE - DO NOT MODIFY BY HAND

// @dart=2.9

part of 'paco_notification_action.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PacoNotificationAction _$PacoNotificationActionFromJson(
    Map<String, dynamic> json) {
  return PacoNotificationAction()
    ..id = json['id'] as int
    ..type = json['type'] as String
    ..actionCode = json['actionCode'] as int
    ..snoozeCount = json['snoozeCount'] as int
    ..timeout = json['timeout'] as int
    ..delay = json['delay'] as int
    ..color = json['color'] as int
    ..dismissible = json['dismissible'] as bool
    ..msgText = json['msgText'] as String;
}

Map<String, dynamic> _$PacoNotificationActionToJson(
        PacoNotificationAction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'actionCode': instance.actionCode,
      'snoozeCount': instance.snoozeCount,
      'timeout': instance.timeout,
      'delay': instance.delay,
      'color': instance.color,
      'dismissible': instance.dismissible,
      'msgText': instance.msgText,
    };
