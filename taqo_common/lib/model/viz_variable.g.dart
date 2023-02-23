// GENERATED CODE - DO NOT MODIFY BY HAND
// @dart=2.9

part of 'viz_variable.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VizVariable _$VizVariableFromJson(Map<String, dynamic> json) {
  return VizVariable()
    ..id = json['id'] as String
    ..group = json['group'] as String
    ..name = json['name'] as String
    ..responseType = json['responseType'] as String;
}

Map<String, dynamic> _$VizVariableToJson(VizVariable instance) =>
    <String, dynamic>{
      'id': instance.id,
      'group': instance.group,
      'name': instance.name,
      'responseType': instance.responseType,
    };
