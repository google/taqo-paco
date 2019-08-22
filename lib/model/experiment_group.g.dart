// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'experiment_group.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExperimentGroup _$ExperimentGroupFromJson(Map<String, dynamic> json) {
  return ExperimentGroup()
    ..name = json['name'] as String
    ..groupType =
        _$enumDecodeNullable(_$GroupTypeEnumEnumMap, json['groupType'])
    ..customRendering = json['customRendering'] as bool
    ..customRenderingCode = json['customRenderingCode'] as String
    ..fixedDuration = json['fixedDuration'] as bool
    ..startDate = json['startDate'] as String
    ..endDate = json['endDate'] as String
    ..logActions = json['logActions'] as bool
    ..logShutdown = json['logShutdown'] as bool
    ..backgroundListen = json['backgroundListen'] as bool
    ..backgroundListenSourceIdentifier =
        json['backgroundListenSourceIdentifier'] as String
    ..accessibilityListen = json['accessibilityListen'] as bool
    ..actionTriggers = (json['actionTriggers'] as List)
        ?.map((e) => e == null
            ? null
            : ActionTrigger.fromJson(e as Map<String, dynamic>))
        ?.toList()
    ..inputs = (json['inputs'] as List)
        ?.map((e) =>
            e == null ? null : Input2.fromJson(e as Map<String, dynamic>))
        ?.toList()
    ..endOfDayGroup = json['endOfDayGroup'] as bool
    ..endOfDayReferredGroupName = json['endOfDayReferredGroupName'] as String
    ..feedback = json['feedback'] == null
        ? null
        : Feedback.fromJson(json['feedback'] as Map<String, dynamic>)
    ..feedbackType = json['feedbackType'] as int
    ..rawDataAccess = json['rawDataAccess'] as bool
    ..logNotificationEvents = json['logNotificationEvents'] as bool;
}

Map<String, dynamic> _$ExperimentGroupToJson(ExperimentGroup instance) =>
    <String, dynamic>{
      'name': instance.name,
      'groupType': _$GroupTypeEnumEnumMap[instance.groupType],
      'customRendering': instance.customRendering,
      'customRenderingCode': instance.customRenderingCode,
      'fixedDuration': instance.fixedDuration,
      'startDate': instance.startDate,
      'endDate': instance.endDate,
      'logActions': instance.logActions,
      'logShutdown': instance.logShutdown,
      'backgroundListen': instance.backgroundListen,
      'backgroundListenSourceIdentifier':
          instance.backgroundListenSourceIdentifier,
      'accessibilityListen': instance.accessibilityListen,
      'actionTriggers': instance.actionTriggers,
      'inputs': instance.inputs,
      'endOfDayGroup': instance.endOfDayGroup,
      'endOfDayReferredGroupName': instance.endOfDayReferredGroupName,
      'feedback': instance.feedback,
      'feedbackType': instance.feedbackType,
      'rawDataAccess': instance.rawDataAccess,
      'logNotificationEvents': instance.logNotificationEvents
    };

T _$enumDecode<T>(Map<T, dynamic> enumValues, dynamic source) {
  if (source == null) {
    throw ArgumentError('A value must be provided. Supported values: '
        '${enumValues.values.join(', ')}');
  }
  return enumValues.entries
      .singleWhere((e) => e.value == source,
          orElse: () => throw ArgumentError(
              '`$source` is not one of the supported values: '
              '${enumValues.values.join(', ')}'))
      .key;
}

T _$enumDecodeNullable<T>(Map<T, dynamic> enumValues, dynamic source) {
  if (source == null) {
    return null;
  }
  return _$enumDecode<T>(enumValues, source);
}

const _$GroupTypeEnumEnumMap = <GroupTypeEnum, dynamic>{
  GroupTypeEnum.SYSTEM: 'SYSTEM',
  GroupTypeEnum.SURVEY: 'SURVEY',
  GroupTypeEnum.APPUSAGE_ANDROID: 'APPUSAGE_ANDROID',
  GroupTypeEnum.NOTIFICATION: 'NOTIFICATION',
  GroupTypeEnum.ACCESSIBILITY: 'ACCESSIBILITY',
  GroupTypeEnum.PHONESTATUS: 'PHONESTATUS'
};
