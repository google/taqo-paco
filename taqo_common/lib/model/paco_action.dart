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

import 'paco_action_all_others.dart';
import 'paco_notification_action.dart';
import 'validator.dart';

part 'paco_action.g.dart';

@JsonSerializable()
class PacoAction {
  static const NOTIFICATION_TO_PARTICIPATE_ACTION_CODE = 1;
  static const NOTIFICATION_ACTION_CODE = 2;
  static const LOG_EVENT_ACTION_CODE = 3;
  static const EXECUTE_SCRIPT_ACTION_CODE = 4;

  static const ACTIONS = [
    NOTIFICATION_TO_PARTICIPATE_ACTION_CODE,
    NOTIFICATION_ACTION_CODE,
    LOG_EVENT_ACTION_CODE,
    EXECUTE_SCRIPT_ACTION_CODE
  ];
  static const ACTION_NAMES = [
    "Create notification to participate",
    "Create notification message",
    "Log data",
    "Execute script"
  ];

  // This id should be unique within its group and stable across edits because the client
  // relies on the id to recognize a actionTrigger or action that started a
  // chain of events
  int id;
  String type;
  int actionCode = NOTIFICATION_TO_PARTICIPATE_ACTION_CODE;

  PacoAction();

  factory PacoAction.fromJson(Map<String, dynamic> json) {
    switch (json['actionCode']) {
      case NOTIFICATION_TO_PARTICIPATE_ACTION_CODE:
        return PacoNotificationAction.fromJson(json);
      case NOTIFICATION_ACTION_CODE:
      case LOG_EVENT_ACTION_CODE:
      case EXECUTE_SCRIPT_ACTION_CODE:
        return PacoActionAllOthers.fromJson(json);
    }
    throw TypeError();
  }

  Map<String, dynamic> toJson() => _$PacoActionToJson(this);

  void validateWith(Validator validator) {
//    System.out.println("VALIDATING PacoAction");
    validator.isNotNull(actionCode, "action code is not properly initialized");
  }
}
