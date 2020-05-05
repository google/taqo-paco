// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'validation_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ValidationMessage _$ValidationMessageFromJson(Map<String, dynamic> json) {
  return ValidationMessage(
    json['msg'] as String,
    json['importance'] as int,
  );
}

Map<String, dynamic> _$ValidationMessageToJson(ValidationMessage instance) =>
    <String, dynamic>{
      'importance': instance.importance,
      'msg': instance.msg,
    };
