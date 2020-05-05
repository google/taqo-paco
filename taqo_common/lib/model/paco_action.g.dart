// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paco_action.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PacoAction _$PacoActionFromJson(Map<String, dynamic> json) {
  return PacoAction()
    ..id = json['id'] as int
    ..type = json['type'] as String
    ..actionCode = json['actionCode'] as int;
}

Map<String, dynamic> _$PacoActionToJson(PacoAction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'actionCode': instance.actionCode,
    };
