import 'package:json_annotation/json_annotation.dart';

part 'experiment_core.g.dart';

@JsonSerializable()
class ExperimentCore {
  String title;
  String description;
  String creator;
  String organization;
  String contactEmail;
  String contactPhone;
  String publicKey;
  String joinDate;
  int id;
  String informedConsentForm;
  bool recordPhoneDetails = false;
  List<int> extraDataCollectionDeclarations;
  bool deleted = false;

  ExperimentCore();

//  ExperimentCore(this.title, this.description, this.creator, this.organization,
//      this.contactEmail, this.contactPhone, this.publicKey, this.joinDate,
//      this.id, this.informedConsentForm, this.recordPhoneDetails,
//      this.extraDataCollectionDeclarations, this.deleted);

  factory ExperimentCore.fromJson(Map<String, dynamic> json) => _$ExperimentCoreFromJson(json);

  Map<String, dynamic> toJson() => _$ExperimentCoreToJson(this);


}