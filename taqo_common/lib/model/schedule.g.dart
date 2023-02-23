// GENERATED CODE - DO NOT MODIFY BY HAND
// @dart=2.9

part of 'schedule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Schedule _$ScheduleFromJson(Map<String, dynamic> json) {
  return Schedule(
    json['scheduleType'] as int,
    json['byDayOfMonth'] as bool,
    json['dayOfMonth'] as int,
    json['esmEndHour'] as int,
    json['esmFrequency'] as int,
    json['esmPeriodInDays'] as int,
    json['esmStartHour'] as int,
    json['nthOfMonth'] as int,
    json['repeatRate'] as int,
    (json['signalTimes'] as List)
        ?.map((e) =>
            e == null ? null : SignalTime.fromJson(e as Map<String, dynamic>))
        ?.toList(),
    json['weekDaysScheduled'] as int,
    json['esmWeekends'] as bool,
    json['minimumBuffer'] as int,
  )
    ..joinDateMillis = json['joinDateMillis'] as int
    ..beginDate = json['beginDate'] as int
    ..id = json['id'] as int
    ..onlyEditableOnJoin = json['onlyEditableOnJoin'] as bool
    ..userEditable = json['userEditable'] as bool;
}

Map<String, dynamic> _$ScheduleToJson(Schedule instance) => <String, dynamic>{
      'scheduleType': instance.scheduleType,
      'esmFrequency': instance.esmFrequency,
      'esmPeriodInDays': instance.esmPeriodInDays,
      'esmStartHour': instance.esmStartHour,
      'esmEndHour': instance.esmEndHour,
      'signalTimes': instance.signalTimes,
      'repeatRate': instance.repeatRate,
      'weekDaysScheduled': instance.weekDaysScheduled,
      'nthOfMonth': instance.nthOfMonth,
      'byDayOfMonth': instance.byDayOfMonth,
      'dayOfMonth': instance.dayOfMonth,
      'esmWeekends': instance.esmWeekends,
      'minimumBuffer': instance.minimumBuffer,
      'joinDateMillis': instance.joinDateMillis,
      'beginDate': instance.beginDate,
      'id': instance.id,
      'onlyEditableOnJoin': instance.onlyEditableOnJoin,
      'userEditable': instance.userEditable,
    };
