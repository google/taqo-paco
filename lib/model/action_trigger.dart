import 'package:json_annotation/json_annotation.dart';
import 'package:taqo_survey/model/validatable.dart';
import 'paco_action.dart';
import 'package:taqo_survey/model/validator.dart';
import 'package:taqo_survey/model/experiment_validator.dart';
import 'dart:collection';

part 'action_trigger.g.dart';

@JsonSerializable()
class ActionTrigger implements Validatable {

  static const INTERRUPT_TRIGGER_TYPE_SPECIFIER = "interruptTrigger";
  static const SCHEDULE_TRIGGER_TYPE_SPECIFIER = "scheduleTrigger";

  String type;
  List<PacoAction> actions;

  // This id should be unique within its group and stable across edits because the client
  // relies on the id to recognize a actionTrigger and action that started a
  // chain of events
  int id;

  ActionTrigger() {
    actions = new List<PacoAction>();
  }

  factory ActionTrigger.fromJson(Map<String, dynamic> json) => _$ActionTriggerFromJson(json);
  Map<String, dynamic> toJson() => _$ActionTriggerToJson(this);

  set setActions(List<PacoAction> triggerActions) {
    this.actions = triggerActions;
    ExperimentValidator validator = new ExperimentValidator();
    validateActions(validator);
    if (validator.results.isNotEmpty) {
      throw validator.stringifyResults();
    }
  }

  PacoAction getActionById(int id) {
    for (PacoAction at in actions) {
      if (at.id == id) {
        return at;
      }
    }
    return null;
  }

  void validateWith(Validator validator) {
//    System.out.println("VALIDATING ACTION TRIGGER");
    validator.isNonEmptyString(type, "ActionTrigger"
        + " type field is not properly initialized");
    validateActions(validator);
  }

  void validateActions(Validator validator) {
//    System.out.println("VALIDATING Actions");
    validator.isNotNullAndNonEmptyCollection(actions, "ActionTrigger actions should contain at least one action");

    HashSet<int> ids = HashSet();

    bool hasNotificationToParticipateAction = false;
    bool hasNotificationMessageAction = false;

    for (PacoAction pacoAction in actions) {
      if (!ids.add(pacoAction.id)) {
        validator.addError("action id: " + pacoAction.id.toString() + " is not unique. Each action needs a unique id that is stable across edits.");
      }
      final int actionCode = pacoAction.actionCode;
      validator.isNotNull(actionCode, "actionCode is not properly initialized");
      if (actionCode != null && actionCode == PacoAction.NOTIFICATION_TO_PARTICIPATE_ACTION_CODE && hasNotificationToParticipateAction) {
        validator.addError("Should only have one notification to participate action");
      } else {
        hasNotificationToParticipateAction = true;
      }
      if (actionCode != null && actionCode == PacoAction.NOTIFICATION_ACTION_CODE && hasNotificationMessageAction) {
        validator.addError("Should only have one notification message action");
      } else {
        hasNotificationMessageAction = true;
      }
      pacoAction.validateWith(validator);
    }
  }

}


