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
    ..modifyDate =
        Visualization._zonedDateTimeFromMillis(json['modifyDate'] as int)
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
    ..startDatetime =
        Visualization._zonedDateTimeFromMillis(json['startDatetime'] as int)
    ..endDatetime =
        Visualization._zonedDateTimeFromMillis(json['endDatetime'] as int);
}

Map<String, dynamic> _$VisualizationToJson(Visualization instance) =>
    <String, dynamic>{
      'id': instance.id,
      'experimentId': instance.experimentId,
      'title': instance.title,
      'modifyDate': Visualization._zonedDateTimeToMillis(instance.modifyDate),
      'question': instance.question,
      'xAxisVariable': instance.xAxisVariable,
      'yAxisVariables': instance.yAxisVariables,
      'participants': instance.participants,
      'type': instance.type,
      'description': instance.description,
      'startDatetime':
          Visualization._zonedDateTimeToMillis(instance.startDatetime),
      'endDatetime': Visualization._zonedDateTimeToMillis(instance.endDatetime),
    };
