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

part 'paco_notification_action.g.dart';

@JsonSerializable()
class PacoNotificationAction extends PacoAction {
  static const String DEFAULT_NOTIFICATION_MSG = "Time to participate";
  static const int SNOOZE_TIME_DEFAULT =
      600000; // 10 minutes (10min * 60sec * 1000ms)
  static const int SNOOZE_COUNT_DEFAULT = 0;
  static const String TRIGGER_SIGNAL_TIMEOUT = "59";
  static const String ESM_SIGNAL_TIMEOUT = "59";
  static const String FIXED_SCHEDULE_TIMEOUT = "479";
  static const int DEFAULT_NOTIFICATION_DELAY = 5000;
  static const int DEFAULT_COLOR = 0;
  static const bool DEFAULT_DISMISSIBLE = true;

  int snoozeCount = SNOOZE_COUNT_DEFAULT;
  int _snoozeTime =
      SNOOZE_TIME_DEFAULT; // XXX it really is more of a data object but need to make it private to override setter
  int timeout; //min? TODO findout
  int delay = DEFAULT_NOTIFICATION_DELAY; // ms
  int color = DEFAULT_COLOR;
  bool dismissible = DEFAULT_DISMISSIBLE;

  String msgText;

  PacoNotificationAction.fullSpecified(int snoozeCount, int snoozeTime,
      int timeout, int delay, String msgText, int color, bool dismissible) {
    this.type = "pacoNotificationAction";
    this.timeout = timeout ?? ESM_SIGNAL_TIMEOUT;
    this.delay = delay;
    this.snoozeCount = snoozeCount ?? SNOOZE_COUNT_DEFAULT;
    this.snoozeTime = snoozeTime ?? SNOOZE_TIME_DEFAULT;
    this.msgText = msgText;
    this.color = color;
    this.dismissible = dismissible;
  }

  PacoNotificationAction() {
    PacoNotificationAction.fullSpecified(
        SNOOZE_COUNT_DEFAULT,
        SNOOZE_TIME_DEFAULT,
        int.parse(ESM_SIGNAL_TIMEOUT),
        DEFAULT_NOTIFICATION_DELAY,
        DEFAULT_NOTIFICATION_MSG,
        DEFAULT_COLOR,
        DEFAULT_DISMISSIBLE);
  }

  factory PacoNotificationAction.fromJson(Map<String, dynamic> json) =>
      _$PacoNotificationActionFromJson(json);

  Map<String, dynamic> toJson() => _$PacoNotificationActionToJson(this);

  void setSnoozeCount(int snoozeCount) {
    this.snoozeCount = snoozeCount != null
        ? snoozeCount
        : PacoNotificationAction.SNOOZE_COUNT_DEFAULT;
  }

  set snoozeTime(int snoozeTime2) {
    _snoozeTime = snoozeTime2 != null
        ? snoozeTime2
        : PacoNotificationAction.SNOOZE_TIME_DEFAULT;
  }

  int getSnoozeTimeInMinutes() {
    return (_snoozeTime / 1000 / 60) as int;
  }

  void setSnoozeTimeInMinutes(int minutes) {
    _snoozeTime = minutes * 60 * 1000;
  }

  void validateWith(Validator validator) {
    super.validateWith(validator);
//    System.out.println("VALIDATING PACONOTIFICATIONACTION");
    // need to detect if we are an action for InterruptTrigger
    validator.isNotNull(delay,
        "delay is not properly initialized for PacoNotificationActions for InterruptTriggers");
    validator.isNotNull(msgText, "msgText is not properly initialized");
    validator.isNotNull(snoozeCount, "snoozeCount is not properly initialized");
    if (snoozeCount > 0) {
      validator.isNotNull(_snoozeTime,
          "snoozeTime must be properly initialized when snoozeCount is  > 0");
    }
  }
}
