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

// @dart=2.9

import 'package:json_annotation/json_annotation.dart';

import 'validator.dart';

part 'input2.g.dart';

@JsonSerializable()
class Input2 {
  static const LIKERT = "likert";
  static const LIKERT_SMILEYS = "likert_smileys";
  static const OPEN_TEXT = "open text";
  static const LIST = "list";
  static const NUMBER = "number";
  static const LOCATION = "location";
  static const PHOTO = "photo";
  static const SOUND = "sound";
  static const ACTIVITY = "activity";
  static const AUDIO = "audio";
  static const TEXTBLOB = "textblob";

  static const RESPONSE_TYPES = [
    LIKERT_SMILEYS,
    LIKERT,
    OPEN_TEXT,
    LIST,
    NUMBER,
    LOCATION,
    PHOTO,
    SOUND,
    ACTIVITY,
    AUDIO,
    TEXTBLOB
  ];

  String name;
  bool required = false;
  bool conditional = false;
  String conditionExpression;
  String responseType = LIKERT;

  String text;

  int likertSteps;
  String leftSideLabel;
  String rightSideLabel;

  List<String> listChoices;
  bool multiselect = false;

  static const int DEFAULT_LIKERT_STEPS = 5;

  Input2(
      String name,
      String responseType,
      String text,
      bool required,
      int likertSteps,
      bool conditional,
      String conditionExpression,
      String leftSideLabel,
      String rightSideLabel,
      List<String> listChoices,
      bool multiselect) {
    this.text = text;
    this.required = required != null ? required : false;
    this.responseType = responseType;
    this.likertSteps = likertSteps;
    this.name = name;
    this.conditional = conditional;
    this.conditionExpression = conditionExpression;
    this.leftSideLabel = leftSideLabel;
    this.rightSideLabel = rightSideLabel;
    this.listChoices = listChoices;
    this.multiselect = multiselect != null ? multiselect : false;
  }

  Input2.newLikert(String name, String text) {
    Input2(
        name, LIKERT, text, false, null, false, null, null, null, null, null);
  }

  factory Input2.fromJson(Map<String, dynamic> json) => _$Input2FromJson(json);

  Map<String, dynamic> toJson() => _$Input2ToJson(this);

  void validateWith(Validator validator) {
//    System.out.println("VALIDATING Input");
    validator.isNonEmptyString(name, "input name is not properly initialized");
    //validator.isNotNullAndNonEmptyString(text, "input question text is not properly initialized");
    if (text != null && text.length > 0) {
      validator.isTrue(text.length <= 500,
          "input question text is too long. 500 char limit.");
    }
    validator.isNotNull(
        responseType, "responseType is not properly initialized");
    validator.isNotNull(required, "required is not properly initialized");
    if (responseType != null) {
      if (responseType == LIKERT) {
        validator.isNotNull(
            likertSteps, "scales need a number of steps specified");
        validator.isTrue(likertSteps >= 2, "scales need at least 2 steps");
        validator.isTrue(likertSteps <= 9, "scales need 9 or less steps");
        //validator.isNotNull(leftSideLabel, "no left label is specified for scale");
        //validator.isNotNull(rightSideLabel, "no right label is specified for scale");
      } else if (responseType == LIST) {
        validator.isNotNullAndNonEmptyCollection(
            listChoices, "lists must have a non-empty set of choices");
        for (String choice in listChoices) {
          validator.isNonEmptyString(
              choice, "list choice text must all be non-empty");
          if (choice != null && choice.length > 0) {
            validator.isTrue(choice.length <= 500,
                "list choice text is too long. 500 char limit.");
          }
        }
        validator.isNotNull(
            multiselect, "multiselect is not initialized properly");
      } else if (responseType == LIKERT_SMILEYS) {
        //validator.isNotNull(likertSteps, "likert steps is not initialized properly");
//        if (likertSteps != null) {
//          validator.isTrue(likertSteps == 5, "likert smiley only allows 5 steps");
//        }
      }
    }
    validator.isNotNull(conditional, "conditional is not initialized properly");
    if (conditional != null && conditional) {
      validator.isValidConditionalExpression(conditionExpression,
          "conditionalExpression is not properly specified");
    }
  }

  bool isInvisible() {
    return responseType == LOCATION || responseType == PHOTO;
  }

  bool isNumeric() {
    return responseType == LIKERT ||
        responseType ==
            LIST || // TODO (bobevans): LIST shoudl be a categorical, not a numeric.
        responseType == NUMBER;
  }
}
