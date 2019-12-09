import 'package:intl/intl.dart';
import 'package:taqo_client/model/schedule.dart';
import 'package:taqo_client/model/signal_time.dart';

const DAYS_SHORT_NAMES = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" ];
const ORDINAL_NUMBERS = ["", "1st", "2nd", "3rd", "4th", "5th" ];


String _getHourOffsetAsTimeString(int millisFromMidnight) {
  final hourFormatter = DateFormat('hh:mma');
  final now = DateTime.now();
  final endHour = DateTime(now.year, now.month, now.day)
      .add(Duration(milliseconds: millisFromMidnight));
  return hourFormatter.format(endHour);
}

void _appendDaysOfWeek(int weekDaysScheduled, StringBuffer sb) {
  var first = true;
  for (var i = 0; i < Schedule.DAYS_OF_WEEK.length; i++) {
    if (Schedule.DAYS_OF_WEEK[i] & weekDaysScheduled != 0) {
      if (first) {
        first = false;
      } else {
        sb.write(",");
      }
      sb.write(DAYS_SHORT_NAMES[i]);
    }
  }
}

void _appendTimesOfDay(List<SignalTime> signalTimes, StringBuffer sb) {
  if (signalTimes == null) return;
  var firstTime = true;
  for (var time in signalTimes) {
    if (firstTime) {
      firstTime = false;
    } else {
      sb.write(",");
    }
    if (time.label != null && time.label.isNotEmpty && time.label != "null") {
      sb.write("${time.label}: ");
    }
    sb.write(_getHourOffsetAsTimeString(time.fixedTimeMillisFromMidnight));
  }
}

String toPrettyString(Schedule schedule, [bool includeIds=false]) {
  final sb = new StringBuffer();
  if (includeIds) {
    sb.write("${schedule.id}:");
  }
  final repeatRate = schedule.repeatRate;
  switch (schedule.scheduleType) {
    case Schedule.DAILY:
    case Schedule.WEEKDAY:
      repeatRate > 1 ? sb.write("Every $repeatRate days at ") : sb.write("Daily at ");
      _appendTimesOfDay(schedule.signalTimes, sb);
      break;
    case Schedule.WEEKLY:
      repeatRate > 1 ? sb.write("Every $repeatRate weeks on ") : sb.write("Weekly on ");
      _appendDaysOfWeek(schedule.weekDaysScheduled, sb);
      sb.write(" at ");
      _appendTimesOfDay(schedule.signalTimes, sb);
      break;
    case Schedule.MONTHLY:
      repeatRate > 1 ? sb.write("Every $repeatRate months on ") : sb.write("Monthly on ");
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
      sb.write(Schedule.ESM_PERIODS_NAMES[schedule.esmPeriodInDays].toLowerCase());
      sb.write(" between ");
      sb.write(_getHourOffsetAsTimeString(schedule.esmStartHour));
      sb.write(" and ");
      sb.write(_getHourOffsetAsTimeString(schedule.esmEndHour));
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
