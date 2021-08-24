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

part 'validation_message.g.dart';

@JsonSerializable()
class ValidationMessage {
  int importance;
  String msg;

  ValidationMessage(String msg, int importance) {
    this.msg = msg;
    this.importance = importance;
  }

  factory ValidationMessage.fromJson(Map<String, dynamic> json) =>
      _$ValidationMessageFromJson(json);

  Map<String, dynamic> toJson() => _$ValidationMessageToJson(this);

  String toString() {
    return importanceString() + ": " + msg;
  }

  String importanceString() {
    switch (importance) {
      case Validator.MANDATORY:
        return "ERROR";
      //break;
      case Validator.OPTIONAL:
        return "WARNING";
      default:
        return "";
      //break;
    }
  }
}
