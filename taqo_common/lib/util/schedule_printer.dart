import '../model/experiment.dart';
import '../model/schedule.dart';
import '../model/schedule_trigger.dart';
import '../model/signal_time.dart';
import 'date_time_util.dart';

void _appendDaysOfWeek(int weekDaysScheduled, StringBuffer sb) {
  final daysScheduled = [];
  for (var i = 0; i < Schedule.DAYS_OF_WEEK.length; i++) {
    if (Schedule.DAYS_OF_WEEK[i] & weekDaysScheduled != 0) {
      daysScheduled.add(DAYS_SHORT_NAMES[i]);
    }
  }
  sb.write(daysScheduled.join(","));
}

void _appendTimesOfDay(List<SignalTime> signalTimes, StringBuffer sb) {
  if (signalTimes == null) return;
  sb.write(List.generate(signalTimes.length, (i) {
    final time = signalTimes[i];
    if (time.label != null && time.label.isNotEmpty && time.label != "null") {
      return "${time.label}: ${getHourOffsetAsTimeString(time.fixedTimeMillisFromMidnight)}";
    } else {
      return "${getHourOffsetAsTimeString(time.fixedTimeMillisFromMidnight)}";
    }
  }).join(","));
}

String toPrettyString(Schedule schedule, [bool includeIds = false]) {
  final sb = StringBuffer();
  if (includeIds) {
    sb.write("${schedule.id}:");
  }
  final repeatRate = schedule.repeatRate;
  switch (schedule.scheduleType) {
    case Schedule.DAILY:
    case Schedule.WEEKDAY:
      repeatRate > 1
          ? sb.write("Every $repeatRate days at ")
          : sb.write("Daily at ");
      _appendTimesOfDay(schedule.signalTimes, sb);
      break;
    case Schedule.WEEKLY:
      repeatRate > 1
          ? sb.write("Every $repeatRate weeks on ")
          : sb.write("Weekly on ");
      _appendDaysOfWeek(schedule.weekDaysScheduled, sb);
      sb.write(" at ");
      _appendTimesOfDay(schedule.signalTimes, sb);
      break;
    case Schedule.MONTHLY:
      repeatRate > 1
          ? sb.write("Every $repeatRate months on ")
          : sb.write("Monthly on ");
      if (schedule.byDayOfMonth) {
        sb.write(schedule.dayOfMonth);
      } else {
        sb.write("${ORDINAL_NUMBERS[schedule.nthOfMonth]} ");
        _appendDaysOfWeek(schedule.weekDaysScheduled, sb);
      }
      sb.write(" at ");
      _appendTimesOfDay(schedule.signalTimes, sb);
      break;
    case Schedule.ESM:
      sb.write("Randomly ");
      sb.write(schedule.esmFrequency);
      sb.write(" times per ");
      sb.write(
          Schedule.ESM_PERIODS_NAMES[schedule.esmPeriodInDays].toLowerCase());
      sb.write(" between ");
      sb.write(getHourOffsetAsTimeString(schedule.esmStartHour));
      sb.write(" and ");
      sb.write(getHourOffsetAsTimeString(schedule.esmEndHour));
      // TODO "excl weekends" is a better ux?
      if (schedule.esmWeekends) {
        sb.write(" incl weekends");
      }
      break;
    default:
      return sb.toString();
  }
  return sb.toString();
}

String createStringOfAllSchedules(Experiment experiment) {
  final groupStrings = <String>[];
  for (var group in experiment.groups) {
    final triggerStrings = <String>[];
    for (var trigger in group.actionTriggers) {
      if (trigger is ScheduleTrigger) {
        final scheduleStrings = <String>[];
        for (var schedule in trigger.schedules) {
          scheduleStrings.add(toPrettyString(schedule));
        }
        triggerStrings.add("${trigger.id}:(${scheduleStrings.join(", ")})");
      }
    }
    groupStrings.add("${group.name}:[${triggerStrings.join(" | ")}]");
  }
  return groupStrings.join(", ");
}
