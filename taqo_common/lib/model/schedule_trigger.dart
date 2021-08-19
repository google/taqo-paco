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

import 'action_trigger.dart';
import 'paco_action.dart';
import 'schedule.dart';
import 'validatable.dart';
import 'validator.dart';

part 'schedule_trigger.g.dart';

@JsonSerializable()
class ScheduleTrigger extends ActionTrigger implements Validatable {
  List<Schedule> schedules;

  ScheduleTrigger() {
    this.type = ActionTrigger.SCHEDULE_TRIGGER_TYPE_SPECIFIER;
    this.schedules = [];
  }

  ScheduleTrigger.withSchedules(List<Schedule> schedules) {
    this.type = ActionTrigger.SCHEDULE_TRIGGER_TYPE_SPECIFIER;
    if (schedules != null) {
      this.schedules = schedules;
    } else {
      this.schedules = [];
    }
  }

  factory ScheduleTrigger.fromJson(Map<String, dynamic> json) =>
      _$ScheduleTriggerFromJson(json);

  Map<String, dynamic> toJson() => _$ScheduleTriggerToJson(this);

  void validateWith(Validator validator) {
    super.validateWith(validator);
//    System.out.println("VALIDATING SCHEDULETRIGGER");
    validator.isNotNullAndNonEmptyCollection(
        schedules, "ScheduleTrigger needs at least one schedule");
    for (Schedule schedule in schedules) {
      schedule.validateWith(validator);
    }
  }

  Schedule getSchedulesById(int scheduleId) {
    for (Schedule schedule in schedules) {
      if (schedule.id == scheduleId) {
        return schedule;
      }
    }
    return null;
  }
}
