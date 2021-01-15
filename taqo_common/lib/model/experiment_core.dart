// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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

  factory ExperimentCore.fromJson(Map<String, dynamic> json) =>
      _$ExperimentCoreFromJson(json);

  Map<String, dynamic> toJson() => _$ExperimentCoreToJson(this);
}
