import 'package:taqo_survey/model/validatable.dart';
import 'package:taqo_survey/model/validator.dart';
import 'package:json_annotation/json_annotation.dart';

part 'signal_time.g.dart';


@JsonSerializable()
class SignalTime implements Validatable {
  static const FIXED_TIME = 0;
  static const OFFSET_TIME = 1;

  static const OFFSET_BASIS_SCHEDULED_TIME = 0;
  static const OFFSET_BASIS_RESPONSE_TIME = 1;


  static const MISSED_BEHAVIOR_SKIP = 0;
  static const MISSED_BEHAVIOR_USE_SCHEDULED_TIME = 1;

  static const OFFSET_TIME_DEFAULT = 30 * 60 * 1000; // 30 minutes

  int type = FIXED_TIME;
  int fixedTimeMillisFromMidnight;
  int basis; // from previous scheduledTime, from previous responseTime
  int offsetTimeMillis;
  int missedBasisBehavior = MISSED_BEHAVIOR_USE_SCHEDULED_TIME; // skip this time, use previousScheduledTime
  String label;

  SignalTime(int type, int basis, int fixedTimeMillisFromMidnight,
      int missedBasisBehavior,
      int offsetTimeMillis, String label) {
    this.type = type;
    this.basis = basis;
    this.fixedTimeMillisFromMidnight = fixedTimeMillisFromMidnight;
    this.missedBasisBehavior = missedBasisBehavior;
    this.offsetTimeMillis = offsetTimeMillis;
    this.label = label;
  }

  factory SignalTime.fromJson(Map<String, dynamic> json) => _$SignalTimeFromJson(json);

  Map<String, dynamic> toJson() => _$SignalTimeToJson(this);
  
  
  void validateWith(Validator validator) {
//    System.out.println("VALIDATING SIGNALTIME");
    validator.isNotNull(type, "signal time type is not properly initialized");
    if (type != null && type == FIXED_TIME) {
      validator.isNotNull(fixedTimeMillisFromMidnight, "fixed type signal times must have fixedTimeMillisFromMidnight");
    } else {
      validator.isNotNull(offsetTimeMillis, "offset type signalTimes must have offsetMillis specified");
      validator.isNotNull(missedBasisBehavior, "offset type signalTimes must have missedBasisBehavior specified");
      validator.isNotNull(basis, "offset type signalTimes must have basis specified");

    }

  }

}
