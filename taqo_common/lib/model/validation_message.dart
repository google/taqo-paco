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
