// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'action_trigger.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActionTrigger _$ActionTriggerFromJson(Map<String, dynamic> json) {
  return ActionTrigger()
    ..type = json['type'] as String
    ..actions = (json['actions'] as List)
        ?.map((e) =>
            e == null ? null : PacoAction.fromJson(e as Map<String, dynamic>))
        ?.toList()
    ..id = json['id'] as int;
}

Map<String, dynamic> _$ActionTriggerToJson(ActionTrigger instance) =>
    <String, dynamic>{
      'type': instance.type,
      'actions': instance.actions,
      'id': instance.id
    };
