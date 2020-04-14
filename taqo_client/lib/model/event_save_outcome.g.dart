// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_save_outcome.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EventSaveOutcome _$EventSaveOutcomeFromJson(Map<String, dynamic> json) {
  return EventSaveOutcome()
    ..eventId = json['eventId'] as int
    ..status = json['status'] as bool
    ..errorMessage = json['errorMessage'] as String;
}

Map<String, dynamic> _$EventSaveOutcomeToJson(EventSaveOutcome instance) =>
    <String, dynamic>{
      'eventId': instance.eventId,
      'status': instance.status,
      'errorMessage': instance.errorMessage
    };
