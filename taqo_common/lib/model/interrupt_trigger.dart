import 'dart:math';

import 'package:json_annotation/json_annotation.dart';

import 'action_trigger.dart';
import 'interrupt_cue.dart';
import 'minimum_bufferable.dart';
import 'paco_action.dart';
import 'paco_notification_action.dart';
import 'validatable.dart';
import 'validator.dart';

part 'interrupt_trigger.g.dart';

@JsonSerializable()
class InterruptTrigger extends ActionTrigger implements Validatable,  MinimumBufferable  {

  List<InterruptCue> cues;
  int minimumBuffer = 0;
  bool timeWindow = false;
  int startTimeMillis = 0;
  int endTimeMillis = 0;
  bool weekends = true;


  InterruptTrigger() {
    this.type = ActionTrigger.INTERRUPT_TRIGGER_TYPE_SPECIFIER;
    cues = [];
  }

  factory InterruptTrigger.fromJson(Map<String, dynamic> json) => _$InterruptTriggerFromJson(json);

  Map<String, dynamic> toJson() => _$InterruptTriggerToJson(this);

  int getDefaultMinimumBuffer() {
    // TODO minimum buffer cannot be shorter than the longest timeout for any notification actions
    // that this actiontrigger contains.
    // we need to compute this by iterating all the actions we contain and returning the
    int longestMinimum = 0;
    for (PacoAction action in actions) {
      if (action is PacoNotificationAction) {
        longestMinimum = max(longestMinimum, action.timeout);
      }
    }
    if (longestMinimum == 0) {
      return MinimumBufferable.DEFAULT_MIN_BUFFER;
    } else {
      return longestMinimum;
    }
  }

  void validateWith(Validator validator) {
    super.validateWith(validator);
//    System.out.println("VALIDATING INTERRUPT");
    validator.isNotNull(minimumBuffer, "minimumBuffer is not properly initialized");
    validator.isNotNullAndNonEmptyCollection(cues, "InterruptTrigger needs at least one cue");

    for (InterruptCue cue in cues) {
      cue.validateWith(validator);
    }
  }

}
