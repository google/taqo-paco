// GENERATED CODE - DO NOT MODIFY BY HAND

// @dart=2.9

part of 'interrupt_trigger.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InterruptTrigger _$InterruptTriggerFromJson(Map<String, dynamic> json) {
  return InterruptTrigger()
    ..type = json['type'] as String
    ..actions = (json['actions'] as List)
        ?.map((e) =>
            e == null ? null : PacoAction.fromJson(e as Map<String, dynamic>))
        ?.toList()
    ..id = json['id'] as int
    ..cues = (json['cues'] as List)
        ?.map((e) =>
            e == null ? null : InterruptCue.fromJson(e as Map<String, dynamic>))
        ?.toList()
    ..minimumBuffer = json['minimumBuffer'] as int
    ..timeWindow = json['timeWindow'] as bool
    ..startTimeMillis = json['startTimeMillis'] as int
    ..endTimeMillis = json['endTimeMillis'] as int
    ..weekends = json['weekends'] as bool;
}

Map<String, dynamic> _$InterruptTriggerToJson(InterruptTrigger instance) =>
    <String, dynamic>{
      'type': instance.type,
      'actions': instance.actions,
      'id': instance.id,
      'cues': instance.cues,
      'minimumBuffer': instance.minimumBuffer,
      'timeWindow': instance.timeWindow,
      'startTimeMillis': instance.startTimeMillis,
      'endTimeMillis': instance.endTimeMillis,
      'weekends': instance.weekends,
    };
