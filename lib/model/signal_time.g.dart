// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signal_time.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SignalTime _$SignalTimeFromJson(Map<String, dynamic> json) {
  return SignalTime(
      json['type'] as int,
      json['basis'] as int,
      json['fixedTimeMillisFromMidnight'] as int,
      json['missedBasisBehavior'] as int,
      json['offsetTimeMillis'] as int,
      json['label'] as String);
}

Map<String, dynamic> _$SignalTimeToJson(SignalTime instance) =>
    <String, dynamic>{
      'type': instance.type,
      'fixedTimeMillisFromMidnight': instance.fixedTimeMillisFromMidnight,
      'basis': instance.basis,
      'offsetTimeMillis': instance.offsetTimeMillis,
      'missedBasisBehavior': instance.missedBasisBehavior,
      'label': instance.label
    };
