// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'visualization.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Visualization _$VisualizationFromJson(Map<String, dynamic> json) {
  return Visualization()
    ..id = json['id'] as int
    ..experimentId = json['experimentId'] as int
    ..title = json['title'] as String
    ..modifyDate = json['modifyDate'] == null
        ? null
        : DateTime.parse(json['modifyDate'] as String)
    ..question = json['question'] as String
    ..xAxisVariable = json['xAxisVariable'] == null
        ? null
        : VizVariable.fromJson(json['xAxisVariable'] as Map<String, dynamic>)
    ..yAxisVariables = (json['yAxisVariables'] as List)
        ?.map((e) =>
            e == null ? null : VizVariable.fromJson(e as Map<String, dynamic>))
        ?.toList()
    ..participants =
        (json['participants'] as List)?.map((e) => e as String)?.toList()
    ..type = json['type'] as String
    ..description = json['description'] as String
    ..startDatetime = json['startDatetime'] == null
        ? null
        : DateTime.parse(json['startDatetime'] as String)
    ..endDatetime = json['endDatetime'] == null
        ? null
        : DateTime.parse(json['endDatetime'] as String);
}

Map<String, dynamic> _$VisualizationToJson(Visualization instance) =>
    <String, dynamic>{
      'id': instance.id,
      'experimentId': instance.experimentId,
      'title': instance.title,
      'modifyDate': instance.modifyDate?.toIso8601String(),
      'question': instance.question,
      'xAxisVariable': instance.xAxisVariable,
      'yAxisVariables': instance.yAxisVariables,
      'participants': instance.participants,
      'type': instance.type,
      'description': instance.description,
      'startDatetime': instance.startDatetime?.toIso8601String(),
      'endDatetime': instance.endDatetime?.toIso8601String()
    };
