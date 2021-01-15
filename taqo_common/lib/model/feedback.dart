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

import 'validator.dart';

part 'feedback.g.dart';

@JsonSerializable()
class Feedback {
  static const FEEDBACK_TYPE_STATIC_MESSAGE = 0;
  static const FEEDBACK_TYPE_RETROSPECTIVE = 1;
  static const FEEDBACK_TYPE_RESPONSIVE = 2;
  static const FEEDBACK_TYPE_CUSTOM = 3;
  static const FEEDBACK_TYPE_HIDE_FEEDBACK = 4;

  static const DEFAULT_FEEDBACK_MSG = "Thanks for Participating!";

  String text;
  var type = FEEDBACK_TYPE_STATIC_MESSAGE;

  Feedback({this.text = DEFAULT_FEEDBACK_MSG});

  factory Feedback.fromJson(Map<String, dynamic> json) =>
      _$FeedbackFromJson(json);

  Map<String, dynamic> toJson() => _$FeedbackToJson(this);

  void validateWith(Validator validator) {
//    System.out.println("VALIDATING Feedback");
    validator.isNotNull(type, "feedback type should be set");
    if (type != null &&
        type != FEEDBACK_TYPE_RETROSPECTIVE &&
        type != FEEDBACK_TYPE_HIDE_FEEDBACK) {
      //validator.isNotNullAndNonEmptyString(text, "feedback text should not be null or empty");
      if (text != null && text.isEmpty) {
        validator.isValidHtmlOrJavascript(
            text, "text should be valid html or javascript");
      }
    }
  }
}
