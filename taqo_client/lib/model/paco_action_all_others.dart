import 'package:taqo_client/model/paco_action.dart';
import 'package:taqo_client/model/validator.dart';
import 'package:json_annotation/json_annotation.dart';

part 'paco_action_all_others.g.dart';


@JsonSerializable()
class PacoActionAllOthers extends PacoAction {

  String customScript;

  PacoActionAllOthers() {
    type = "pacoActionAllOthers";
  }

  factory PacoActionAllOthers.fromJson(Map<String, dynamic> json) => _$PacoActionAllOthersFromJson(json);

  Map<String, dynamic> toJson() => _$PacoActionAllOthersToJson(this);
  
  void validateWith(Validator validator) {
    super.validateWith(validator);
//    System.out.println("VALIDATING PACOACTIONALLOTHES");
    if (actionCode != null && actionCode == PacoAction.EXECUTE_SCRIPT_ACTION_CODE) {
      validator.isValidJavascript(customScript, "custom script for action " + PacoAction.ACTION_NAMES[actionCode - 1] + "should be valid javascript");
    }

  }


}