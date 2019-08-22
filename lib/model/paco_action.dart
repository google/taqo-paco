import 'package:json_annotation/json_annotation.dart';
import 'package:taqo_survey/model/validator.dart';

part 'paco_action.g.dart';


@JsonSerializable()
class PacoAction {

  static const NOTIFICATION_TO_PARTICIPATE_ACTION_CODE = 1;
  static const NOTIFICATION_ACTION_CODE = 2;
  static const LOG_EVENT_ACTION_CODE = 3;
  static const EXECUTE_SCRIPT_ACTION_CODE = 4;

  static const ACTIONS = [NOTIFICATION_TO_PARTICIPATE_ACTION_CODE ,NOTIFICATION_ACTION_CODE, LOG_EVENT_ACTION_CODE,EXECUTE_SCRIPT_ACTION_CODE];
  static const ACTION_NAMES = ["Create notification to participate", "Create notification message", "Log data", "Execute script"];

  // This id should be unique within its group and stable across edits because the client
  // relies on the id to recognize a actionTrigger or action that started a
  // chain of events
  int id;
  String type;
  int actionCode = NOTIFICATION_TO_PARTICIPATE_ACTION_CODE;

  PacoAction();

  factory PacoAction.fromJson(Map<String, dynamic> json) => _$PacoActionFromJson(json);

  Map<String, dynamic> toJson() => _$PacoActionToJson(this);
  
  void validateWith(Validator validator) {
//    System.out.println("VALIDATING PacoAction");
    validator.isNotNull(actionCode, "action code is not properly initialized");
  }
}