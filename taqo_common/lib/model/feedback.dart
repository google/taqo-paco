import 'package:json_annotation/json_annotation.dart';

import 'validator.dart';

part 'feedback.g.dart';

@JsonSerializable()
class Feedback {
  static const FEEDBACK_TYPE_STATIC_MESSAGE = 0;
  static const FEEDBACK_TYPE_RETROSPECTIVE = 1;
  static const FEEDBACK_TYPE_RESPONSIVE = 2;
  static const FEEDBACK_TYPE_CUSTOM = 3;
  static const FEEDBACK_TYPE_HIDE_FEEDBACK = 4;

  static const DEFAULT_FEEDBACK_MSG = "Thanks for Participating!";

  String text;
  var type = FEEDBACK_TYPE_STATIC_MESSAGE;

  Feedback({this.text = DEFAULT_FEEDBACK_MSG});

  factory Feedback.fromJson(Map<String, dynamic> json) =>
      _$FeedbackFromJson(json);

  Map<String, dynamic> toJson() => _$FeedbackToJson(this);

  void validateWith(Validator validator) {
//    System.out.println("VALIDATING Feedback");
    validator.isNotNull(type, "feedback type should be set");
    if (type != null &&
        type != FEEDBACK_TYPE_RETROSPECTIVE &&
        type != FEEDBACK_TYPE_HIDE_FEEDBACK) {
      //validator.isNotNullAndNonEmptyString(text, "feedback text should not be null or empty");
      if (text != null && text.isEmpty) {
        validator.isValidHtmlOrJavascript(
            text, "text should be valid html or javascript");
      }
    }
  }
}
