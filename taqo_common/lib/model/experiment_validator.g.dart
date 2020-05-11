// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'experiment_validator.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExperimentValidator _$ExperimentValidatorFromJson(Map<String, dynamic> json) {
  return ExperimentValidator()
    ..results = (json['results'] as List)
        ?.map((e) => e == null
            ? null
            : ValidationMessage.fromJson(e as Map<String, dynamic>))
        ?.toList();
}

Map<String, dynamic> _$ExperimentValidatorToJson(
        ExperimentValidator instance) =>
    <String, dynamic>{
      'results': instance.results,
    };
