// GENERATED CODE - DO NOT MODIFY BY HAND
// @dart=2.9

part of 'experiment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Experiment _$ExperimentFromJson(Map<String, dynamic> json) {
  return Experiment()
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
    ..deleted = json['deleted'] as bool
    ..modifyDate = json['modifyDate'] as String
    ..published = json['published'] as bool
    ..admins = (json['admins'] as List)?.map((e) => e as String)?.toList()
    ..publishedUsers =
        (json['publishedUsers'] as List)?.map((e) => e as String)?.toList()
    ..version = json['version'] as int
    ..groups = (json['groups'] as List)
        ?.map((e) => e == null
            ? null
            : ExperimentGroup.fromJson(e as Map<String, dynamic>))
        ?.toList()
    ..ringtoneUri = json['ringtoneUri'] as String
    ..postInstallInstructions = json['postInstallInstructions'] as String
    ..anonymousPublic = json['anonymousPublic'] as bool ?? false
    ..participantId = json['participantId'] as int
    ..visualizations = (json['visualizations'] as List)
        ?.map((e) => e == null
            ? null
            : Visualization.fromJson(e as Map<String, dynamic>))
        ?.toList();
}

Map<String, dynamic> _$ExperimentToJson(Experiment instance) =>
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
      'modifyDate': instance.modifyDate,
      'published': instance.published,
      'admins': instance.admins,
      'publishedUsers': instance.publishedUsers,
      'version': instance.version,
      'groups': instance.groups,
      'ringtoneUri': instance.ringtoneUri,
      'postInstallInstructions': instance.postInstallInstructions,
      'anonymousPublic': instance.anonymousPublic,
      'participantId': instance.participantId,
      'visualizations': instance.visualizations,
    };
