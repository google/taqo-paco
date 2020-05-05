// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feedback.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Feedback _$FeedbackFromJson(Map<String, dynamic> json) {
  return Feedback(
    text: json['text'] as String,
  )..type = json['type'] as int;
}

Map<String, dynamic> _$FeedbackToJson(Feedback instance) => <String, dynamic>{
      'text': instance.text,
      'type': instance.type,
    };
