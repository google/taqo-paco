// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'interrupt_cue.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InterruptCue _$InterruptCueFromJson(Map<String, dynamic> json) {
  return InterruptCue()
    ..cueCode = json['cueCode'] as int
    ..cueSource = json['cueSource'] as String
    ..cueAEClassName = json['cueAEClassName'] as String
    ..cueAEEventType = json['cueAEEventType'] as int
    ..cueAEContentDescription = json['cueAEContentDescription'] as String
    ..id = json['id'] as int;
}

Map<String, dynamic> _$InterruptCueToJson(InterruptCue instance) =>
    <String, dynamic>{
      'cueCode': instance.cueCode,
      'cueSource': instance.cueSource,
      'cueAEClassName': instance.cueAEClassName,
      'cueAEEventType': instance.cueAEEventType,
      'cueAEContentDescription': instance.cueAEContentDescription,
      'id': instance.id,
    };
