import 'dart:collection';

import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:taqo_client/model/action_trigger.dart';
import 'package:taqo_client/model/feedback.dart';
import 'package:taqo_client/model/input2.dart';
import 'package:taqo_client/model/validator.dart';
import 'package:taqo_client/util/date_time_util.dart';

part 'experiment_group.g.dart';

enum GroupTypeEnum {
  SYSTEM,
  SURVEY,
  APPUSAGE_ANDROID,
  NOTIFICATION,
  ACCESSIBILITY,
  PHONESTATUS

}

@JsonSerializable()
class ExperimentGroup {

  static const MAX_DURATION_DAYS_FOR_LARGE_DATA_LOGGERS = 14;

  String name;
  GroupTypeEnum groupType;

  bool customRendering = false;
  String customRenderingCode;

  bool fixedDuration = false;
  String startDate;
  String endDate;

  bool logActions = false;
  bool logShutdown = false;

  bool backgroundListen = false;
  String backgroundListenSourceIdentifier;

  bool accessibilityListen = false;

  List<ActionTrigger> actionTriggers;
  List<Input2> inputs;
  bool endOfDayGroup = false;
  String endOfDayReferredGroupName;

  Feedback feedback;

  // Need to keep this for the interim experiments on staging
  // this will allow us to copy it on to the Feedback object for those
  // experiments
  int feedbackType;

  bool rawDataAccess = true;

  bool logNotificationEvents = false;

  ExperimentGroup() {
    actionTriggers = new List<ActionTrigger>();
    inputs = new List<Input2>();
    feedbackType = Feedback.FEEDBACK_TYPE_STATIC_MESSAGE;
  }

  factory ExperimentGroup.fromJson(Map<String, dynamic> json) => _$ExperimentGroupFromJson(json);

  Map<String, dynamic> toJson() => _$ExperimentGroupToJson(this);


//  factory ExperimentGroup newWithName(String name) {
//    this();
//    name = name;
//  }

  List<ActionTrigger> getActionTriggers() {
    return actionTriggers;
  }

  void setActionTriggers(List<ActionTrigger> actionTriggers) {
    this.actionTriggers = actionTriggers;
    // TODO comment this for now because upon json deserialization it throws and breaks protocol (we should always check later).
//    ExperimentValidator validator = new ExperimentValidator();
//    validateActionTriggers(validator);
//    if (!validator.getResults().isEmpty()) {
//      throw new IllegalArgumentException(validator.stringifyResults());
//    }
  }

  ActionTrigger getActionTriggerById(int actionTriggerId) {
    for (ActionTrigger at in actionTriggers) {
      if (at.id ==actionTriggerId) {
        return at;
      }
    }
    return null;
  }


  void setInputs(List<Input2> inputs) {
    this.inputs = inputs;
//    ExperimentValidator validator = new ExperimentValidator();
//    validateInputs(validator);
//    if (!validator.getResults().isEmpty()) {
//      throw new IllegalArgumentException(validator.stringifyResults());
//    }
  }

  void validateWith(Validator validator) {
//    System.out.println("VALIDATING GROUP");
    validator.isNonEmptyString(name, "name is not properly initialized");

    validateActionTriggers(validator);

    validator.isNotNull(backgroundListen, "backgroundListen not initialized");
    validator.isNotNull(accessibilityListen, "accessibilityListen not initialized");
    validator.isNotNull(logActions, "logActions not initialized");
    validator.isNotNull(logNotificationEvents, "logNotificationEvents not initialized");
    validator.isNotNull(logShutdown, "logShutdown not initialized");
    if (backgroundListen != null && backgroundListen) {
      validator.isNonEmptyString(backgroundListenSourceIdentifier,
          "background listening requires a source identifier");
    }
    validator.isNotNull(customRendering, "customRendering not initialized properly");
    if (customRendering != null && customRendering) {
      validator.isValidJavascript(customRenderingCode, "custom rendering code is not properly formed");
    }
    validator.isNotNull(fixedDuration, "fixed duration not properly initialized");
    if (fixedDuration != null && fixedDuration) {
      validator.isValidDateString(startDate, "start date must be a valid string");
      validator.isValidDateString(endDate, "end date must be a valid string");
    }
    if (isPresentAndTrue(logActions) || isPresentAndTrue(accessibilityListen) || isPresentAndTrue(logNotificationEvents)) {
      if (fixedDuration == null || !fixedDuration || !isDurationLessThanTwoWeeks()) {
        validator.addError("logActions, logAccessibilityEvents and logNotificationEvents are only "
            + "allowed on Fixed Duration experiments that run less than 2 weeks due to large data volumes.");
      }
    }
    validator.isNotNull(feedbackType, "feedbacktype is not properly initialized");
    validator.isNotNull(feedback, "feedback is not properly initialized");

    validateInputs(validator);

    validator.isNotNull(endOfDayGroup, "endOfDayGroup is not properly initialized");
    if (endOfDayGroup != null && endOfDayGroup) {
      validator.isNonEmptyString(endOfDayReferredGroupName, "endOfDayGroups need to specify the name of the group to which they refer");
    }
    feedback.validateWith(validator);
  }

  bool isDurationLessThanTwoWeeks() {
    try {
      if (startDate == null || endDate == null) {
        return false;
      }

      var startDateCandidate = toMidnight(parseYMDTime(startDate));
      var endDateCandidate = toMidnight(parseYMDTime(endDate));
      Duration daysDuration = endDateCandidate.difference(startDateCandidate);
      if (daysDuration.inDays > MAX_DURATION_DAYS_FOR_LARGE_DATA_LOGGERS) {
        return false;
      } else {
        return true;
      }
    } catch (e) {
    // fall through to return false
    }
    return false;
  }

  bool isOver(DateTime now) {
    return fixedDuration && DateFormat.yMd().parse(endDate).isBefore(now);
  }

  bool isStarted(DateTime now) {
    if (!fixedDuration) {
      return true;
    }
    final start = parseYMDTime(startDate);
    return now.isAtSameMomentAs(start) || now.isAfter(start);
  }

  bool isRunning(DateTime now) {
    if (groupType != GroupTypeEnum.SYSTEM && !fixedDuration) {
      return true;
    }
    return now.isBefore(parseYMDTime(startDate)) ? false : !isOver(now);
  }

  DateTime toMidnight(startDateCandidate) {
    return DateTime(startDateCandidate.year, startDateCandidate.month, startDateCandidate.day);
  }

  bool isPresentAndTrue(bool fieldToValidate) {
    return fieldToValidate != null && logActions;
  }

  void validateInputs(Validator validator) {
//    System.out.println("VALIDATING INPUTS");
    validator.isNotNullCollection(inputs, "inputs not properly initialized");
    Set<String> inputNames = new HashSet();
    if (inputs == null) {
      return;
    }
    for (Input2 input in inputs) {
      if (!inputNames.add(input.name)) {
        validator.addError("Input name: " + input.name + " is duplicate. All input names within a group must be unique");
      }
      input.validateWith(validator);
    }
  }

  void validateActionTriggers(Validator validator) {
//    System.out.println("VALIDATING ACTION TRIGGERS");
    validator.isNotNullCollection(actionTriggers, "action triggers not properly initialized");
    Set<int> ids = new HashSet();
    if (actionTriggers  != null) {
      for (ActionTrigger actionTrigger in actionTriggers) {
        actionTrigger.validateWith(validator);
        if (!ids.add(actionTrigger.id)) {
          validator.addError("action trigger id: " + actionTrigger.id.toString() + " is not unique. Ids must be unique and stable across edits.");
        }
      }
    }
  }
}
