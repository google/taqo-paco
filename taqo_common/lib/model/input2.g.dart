// GENERATED CODE - DO NOT MODIFY BY HAND
// @dart=2.9

part of 'input2.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Input2 _$Input2FromJson(Map<String, dynamic> json) {
  return Input2(
    json['name'] as String,
    json['responseType'] as String,
    json['text'] as String,
    json['required'] as bool,
    json['likertSteps'] as int,
    json['conditional'] as bool,
    json['conditionExpression'] as String,
    json['leftSideLabel'] as String,
    json['rightSideLabel'] as String,
    (json['listChoices'] as List)?.map((e) => e as String)?.toList(),
    json['multiselect'] as bool,
  );
}

Map<String, dynamic> _$Input2ToJson(Input2 instance) => <String, dynamic>{
      'name': instance.name,
      'required': instance.required,
      'conditional': instance.conditional,
      'conditionExpression': instance.conditionExpression,
      'responseType': instance.responseType,
      'text': instance.text,
      'likertSteps': instance.likertSteps,
      'leftSideLabel': instance.leftSideLabel,
      'rightSideLabel': instance.rightSideLabel,
      'listChoices': instance.listChoices,
      'multiselect': instance.multiselect,
    };
