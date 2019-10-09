// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_trigger.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScheduleTrigger _$ScheduleTriggerFromJson(Map<String, dynamic> json) {
  return ScheduleTrigger()
    ..type = json['type'] as String
    ..actions = (json['actions'] as List)
        ?.map((e) =>
            e == null ? null : PacoAction.fromJson(e as Map<String, dynamic>))
        ?.toList()
    ..id = json['id'] as int
    ..schedules = (json['schedules'] as List)
        ?.map((e) =>
            e == null ? null : Schedule.fromJson(e as Map<String, dynamic>))
        ?.toList();
}

Map<String, dynamic> _$ScheduleTriggerToJson(ScheduleTrigger instance) =>
    <String, dynamic>{
      'type': instance.type,
      'actions': instance.actions,
      'id': instance.id,
      'schedules': instance.schedules
    };
