import 'package:taqo_client/model/action_trigger.dart';
import 'package:taqo_client/model/validatable.dart';
import 'package:taqo_client/model/validator.dart';
import 'package:taqo_client/model/paco_action.dart';

import 'package:taqo_client/model/schedule.dart';
import 'package:json_annotation/json_annotation.dart';

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

  factory ScheduleTrigger.fromJson(Map<String, dynamic> json) => _$ScheduleTriggerFromJson(json);

  Map<String, dynamic> toJson() => _$ScheduleTriggerToJson(this);
  
  void validateWith(Validator validator) {
    super.validateWith(validator);
//    System.out.println("VALIDATING SCHEDULETRIGGER");
    validator.isNotNullAndNonEmptyCollection(schedules, "ScheduleTrigger needs at least one schedule");
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