import 'package:taqo_client/model/paco_notification_action.dart';
import 'package:taqo_client/model/signal_time.dart';
import 'package:taqo_client/model/validatable.dart';
import 'package:taqo_client/model/validator.dart';
import 'minimum_bufferable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'schedule.g.dart';


@JsonSerializable()
class Schedule implements Validatable, MinimumBufferable {

  static const SATURDAY = 64;
  static const FRIDAY = 32;
  static const THURSDAY = 16;
  static const WEDNESDAY = 8;
  static const TUESDAY = 4;
  static const MONDAY = 2;
  static const SUNDAY = 1;

  static const DAILY = 0;
  static const WEEKDAY = 1;
  static const WEEKLY = 2;
  static const MONTHLY = 3;
  static const ESM = 4;
  static const SELF_REPORT = 5;
  static const ADVANCED = 6;
  static const SCHEDULE_TYPES = [DAILY, WEEKDAY, WEEKLY, MONTHLY, ESM, SELF_REPORT, ADVANCED ];

  static const SCHEDULE_TYPES_NAMES = ["Daily", "Weekdays", "Weekly", "Monthly",
    "Random sampling (ESM)", "Self report only",
    "Advanced" ];

  static const ESM_PERIOD_DAY = 0;
  static const ESM_PERIOD_WEEK = 1;
  static const ESM_PERIOD_MONTH = 2;

  static const DEFAULT_ESM_PERIOD = ESM_PERIOD_DAY;
  static const ESM_PERIODS_NAMES = ["Day", "Week", "Month" ];
  static const DEFAULT_REPEAT_RATE = 1;
  static const DAYS_OF_WEEK = [1, 2, 4, 8, 16, 32, 64 ];
  static const ESM_PERIODS = [ESM_PERIOD_DAY, ESM_PERIOD_WEEK, ESM_PERIOD_MONTH];

  int scheduleType = DAILY;
  int esmFrequency = 3;
  int esmPeriodInDays = ESM_PERIOD_DAY;
  int esmStartHour = 9 * 60 * 60 * 1000;
  int esmEndHour = 17 * 60 * 60 * 1000;

  List<SignalTime> signalTimes;
  int repeatRate = 1;
  int weekDaysScheduled = 0;
  int nthOfMonth = 1;
  bool byDayOfMonth = true;
  int dayOfMonth = 1;
  bool esmWeekends = false;
  int minimumBuffer = int.parse(PacoNotificationAction.ESM_SIGNAL_TIMEOUT);

  int joinDateMillis;
  int beginDate;
  int id;
  bool onlyEditableOnJoin = false;
  bool userEditable = true;

  Schedule(int scheduleType, bool byDayOfMonth, int dayOfMonth, int esmEndHour,
      int esmFrequency, int esmPeriodInDays, int esmStartHour, int nthOfMonth,
      int repeatRate, List<SignalTime> signalTimes, int weekDaysScheduled, bool esmWeekends,
      int minimumBuffer) {
    this.scheduleType = scheduleType;
    this.byDayOfMonth = byDayOfMonth;
    this.dayOfMonth = dayOfMonth;
    this.esmEndHour = esmEndHour;
    this.esmFrequency = esmFrequency;
    this.esmPeriodInDays = esmPeriodInDays;
    this.esmStartHour = esmStartHour;
    this.esmWeekends = esmWeekends;
    this.nthOfMonth = nthOfMonth;
    this.repeatRate = repeatRate;
    this.signalTimes = signalTimes;
    this.minimumBuffer = minimumBuffer;
    this.weekDaysScheduled = weekDaysScheduled;
  }

  factory Schedule.fromJson(Map<String, dynamic> json) => _$ScheduleFromJson(json);

  Map<String, dynamic> toJson() => _$ScheduleToJson(this);

  int getRepeatRate() {
    return repeatRate == null ? DEFAULT_REPEAT_RATE : repeatRate;
  }
  void validateWith(Validator validator) {
//    System.out.println("VALIDATING SCHEDULE");
    validator.isNotNull(scheduleType, "scheduleType is not properly initialized");
    validator.isNotNull(onlyEditableOnJoin, "onlyEditableOnJoin is not properly initialized");
    validator.isNotNull(userEditable, "userEditable is not properly initialized");

    switch (scheduleType) {
      case DAILY:
      case WEEKDAY:
        break;
      case WEEKLY:
        validator.isNotNull(weekDaysScheduled, "weekdaysSchedule is not properly initialized");
        break;
      case MONTHLY:
        validator.isNotNull(byDayOfMonth, "byDayOfMonth is not properly initialized");
        if (byDayOfMonth) {
          validator.isNotNull(dayOfMonth, "dayOfMonth is not properly initialized");
        } else {
          validator.isNotNull(nthOfMonth, "nthOfMonth is not properly initialized");
          validator.isNotNull(weekDaysScheduled, "weekdaysSchedule is not properly initialized");
        }
        break;
      case ESM:
        validator.isNotNull(esmFrequency, "esm frequency is not properly initialized");
        validator.isNotNull(esmPeriodInDays, "esm period is not properly initialized");
        validator.isNotNull(esmWeekends, "esm weekends is not properly initialized");
        validator.isNotNull(esmStartHour, "esm startHour is not properly initialized");
        validator.isNotNull(esmEndHour, "esm endHour is not properly initialized");
        validator.isNotNull(minimumBuffer, "minimumBuffer for esm signals is not properly initialized");
        validator.isTrue(validateESMSchedule(), "esm parameters are invalid");
        break;
      default:
      // do nothing;

    }
    if (scheduleType != null && scheduleType != ESM && scheduleType != SELF_REPORT &&
        scheduleType != ADVANCED) {
      validator.isNotNull(repeatRate, "repeatRate is not properly initialized");
      validator.isNotNullAndNonEmptyCollection(signalTimes,
          "For the schedule type, there must be at least one signal Time");
      int lastTime = 0;
      for (SignalTime signalTime in signalTimes) {
        signalTime.validateWith(validator);
        if (signalTime.basis == null || signalTime.basis == SignalTime.FIXED_TIME) {
          if (signalTime.fixedTimeMillisFromMidnight <= lastTime) {
            validator.addError("Signal Times must be in chronological order");
          }
          lastTime = signalTime.fixedTimeMillisFromMidnight;
        }
      }

    }

  }

  int getJoinDateMillis() {
    return joinDateMillis;
  }

  void setJoinDateMillis(int joinDateMillis) {
    this.joinDateMillis = joinDateMillis;
  }

  int convertEsmPeriodToDays() {
    switch (esmPeriodInDays) {
      case ESM_PERIOD_DAY:
        return 1;
      case ESM_PERIOD_WEEK:
        return 7;
      case ESM_PERIOD_MONTH:
        return 30;
      default:
        return 1;
    }

  }

  void addWeekDayToSchedule(int day) {
    weekDaysScheduled |= day;
  }

  void removeWeekDayFromSchedule(int day) {
    weekDaysScheduled &= (~day);
  }

  // Visible for testing
  void removeAllWeekDaysScheduled() {
    this.weekDaysScheduled = 0;
  }


  bool isWeekDayScheduled(int day) {
    return (weekDaysScheduled & day) != 0;
  }

  bool validateESMSchedule({int startHour, int endHour, int frequency, int minBuffer, int period}) {
    // Use default instance values (default parameter values must be const)
    startHour ??= esmStartHour;
    endHour ??= esmEndHour;
    frequency ??= esmFrequency;
    minBuffer ??= minimumBuffer;
    period ??= esmPeriodInDays;

    int periodDays = 1;
    // TODO consider period
//    switch (period) {
//      case Schedule.ESM_PERIOD_WEEK:
//        periodDays = 7;
//        break;
//      case Schedule.ESM_PERIOD_MONTH:
//        periodDays = 28;
//        break;
//    }

    // 1. start time is before end time
    // 2. enough minutes per period for all of the samples, with buffer
    return startHour < endHour &&
        ((endHour - startHour) / (1000 * 60)) >= periodDays * ((frequency - 1) * minBuffer);
  }


}
