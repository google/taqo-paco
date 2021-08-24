// GENERATED CODE - DO NOT MODIFY BY HAND

// @dart=2.9

part of 'experiment_core.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExperimentCore _$ExperimentCoreFromJson(Map<String, dynamic> json) {
  return ExperimentCore()
    ..title = json['title'] as String
    ..description = json['description'] as String
    ..creator = json['creator'] as String
    ..organization = json['organization'] as String
    ..contactEmail = json['contactEmail'] as String
    ..contactPhone = json['contactPhone'] as String
    ..publicKey = json['publicKey'] as String
    ..joinDate = json['joinDate'] as String
    ..id = json['id'] as int
    ..informedConsentForm = json['informedConsentForm'] as String
    ..recordPhoneDetails = json['recordPhoneDetails'] as bool
    ..extraDataCollectionDeclarations =
        (json['extraDataCollectionDeclarations'] as List)
            ?.map((e) => e as int)
            ?.toList()
    ..deleted = json['deleted'] as bool;
}

Map<String, dynamic> _$ExperimentCoreToJson(ExperimentCore instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'creator': instance.creator,
      'organization': instance.organization,
      'contactEmail': instance.contactEmail,
      'contactPhone': instance.contactPhone,
      'publicKey': instance.publicKey,
      'joinDate': instance.joinDate,
      'id': instance.id,
      'informedConsentForm': instance.informedConsentForm,
      'recordPhoneDetails': instance.recordPhoneDetails,
      'extraDataCollectionDeclarations':
          instance.extraDataCollectionDeclarations,
      'deleted': instance.deleted,
    };
