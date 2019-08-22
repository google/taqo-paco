// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paco_action_all_others.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PacoActionAllOthers _$PacoActionAllOthersFromJson(Map<String, dynamic> json) {
  return PacoActionAllOthers()
    ..id = json['id'] as int
    ..type = json['type'] as String
    ..actionCode = json['actionCode'] as int
    ..customScript = json['customScript'] as String;
}

Map<String, dynamic> _$PacoActionAllOthersToJson(
        PacoActionAllOthers instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'actionCode': instance.actionCode,
      'customScript': instance.customScript
    };
