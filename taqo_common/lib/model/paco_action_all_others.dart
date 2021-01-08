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

import 'paco_action.dart';
import 'validator.dart';

part 'paco_action_all_others.g.dart';

@JsonSerializable()
class PacoActionAllOthers extends PacoAction {
  String customScript;

  PacoActionAllOthers() {
    type = "pacoActionAllOthers";
  }

  factory PacoActionAllOthers.fromJson(Map<String, dynamic> json) =>
      _$PacoActionAllOthersFromJson(json);

  Map<String, dynamic> toJson() => _$PacoActionAllOthersToJson(this);

  void validateWith(Validator validator) {
    super.validateWith(validator);
//    System.out.println("VALIDATING PACOACTIONALLOTHES");
    if (actionCode != null &&
        actionCode == PacoAction.EXECUTE_SCRIPT_ACTION_CODE) {
      validator.isValidJavascript(
          customScript,
          "custom script for action " +
              PacoAction.ACTION_NAMES[actionCode - 1] +
              "should be valid javascript");
    }
  }
}
