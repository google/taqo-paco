import 'package:intl/intl.dart';

import '../model/schedule.dart';
import '../util/zoned_date_time.dart';

const DAYS_SHORT_NAMES = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" ];
const ORDINAL_NUMBERS = ["", "1st", "2nd", "3rd", "4th", "5th" ];

DateTime getLater(DateTime dt1, DateTime dt2) {
  if (dt1 == null || dt2 == null) return dt1 ?? dt2;
  return dt1.isAfter(dt2) ? dt1 : dt2;
}

int getMillisFromMidnight(DateTime dt) {
  return 1000 * (60 * (60 * dt.hour + dt.minute) + dt.second) + dt.millisecond;
}

String getHourOffsetAsTimeString(int millisFromMidnight) {
  final hourFormatter = DateFormat('hh:mma');
  final endHour = getDateWithoutTime(DateTime.now()).add(Duration(milliseconds: millisFromMidnight));
  return hourFormatter.format(endHour);
}

/// Parses a string of YYYY/MM/DD into a [DateTime] object
DateTime parseYMDTime(String time) {
  if (time == null || time.isEmpty) {
    return null;
  }

  final pattern = RegExp(r'\d{4}\/\d{2}\/\d{2}');
  if (pattern.matchAsPrefix(time) == null) {
    return null;
  }

  try {
    final parse = time.split("/");
    return DateTime(int.parse(parse[0]), int.parse(parse[1]), int.parse(parse[2]));
  } catch (e) {
    print('Unexpected error parsing date string $time: $e');
    return null;
  }
}

/// Skips over Saturday and Sunday
DateTime skipOverWeekend(DateTime dt) {
  while (dt.weekday > DateTime.friday) {
    dt = dt.add(Duration(days: 1));
  }
  return dt;
}

/// Gets the Sunday at the start of the week containing [day]
DateTime getSunday(DateTime day) {
  final offset = Duration(days: day.weekday == DateTime.sunday ? 0 : day.weekday);
  return DateTime(day.year, day.month, day.day).subtract(offset);
}

/// Extract days of week for a [Schedule]
/// Implicitly converts from ISO 8601 weekday to 0-based weekday starting with Sunday
List<int> extractDaysOfWeek(int weekDaysScheduled, [bool convert=false]) {
  final daysOfWeek = <int>[];
  // Sunday = 0
  if (weekDaysScheduled & 0x1 != 0) {
    daysOfWeek.add(convert ? 0 : DateTime.sunday);
  }
  for (var day = 1; day < 7; day += 1) {
    if (weekDaysScheduled & (0x1 << day) != 0) {
      daysOfWeek.add(day);
    }
  }
  return daysOfWeek;
}

/// Set the day of the month without rolling over to next month
/// e.g. setting 31st day of February should return Feb 28 (or 29)
DateTime setDayOfMonth(DateTime from, int dayOfMonth) {
  DateTime dt = cloneDateTime(from, day: 1);
  final int month = dt.month;
  while (dt.month == month && dt.day != dayOfMonth) {
    dt = dt.add(Duration(days: 1));
  }
  return dt.subtract(Duration(days: dt.month == month ? 0 : 1));
}

int getLastDayOfMonth(DateTime month) => setDayOfMonth(month, 31).day;

/// Add [months] months to [base], rolling the year as necessary
DateTime addMonths(DateTime base, int months) {
  var newMonth = base.month + months;
  var newYear = base.year;
  while (newMonth > 12) {
    newMonth -= 12;
    newYear += 1;
  }
  return DateTime(newYear, newMonth, base.day, base.hour, base.minute, base.second,
      base.millisecond, base.microsecond);
}

DateTime cloneDateTime(DateTime src, {int year,
  int month,
  int day,
  int hour,
  int minute,
  int second,
  int millisecond,
  int microsecond}) =>
    DateTime(
      year ?? src.year,
      month ?? src.month,
      day ?? src.day,
      hour ?? src.hour,
      minute ?? src.minute,
      second ?? src.second,
      millisecond ?? src.millisecond,
      microsecond ?? src.microsecond);

DateTime getDateWithoutTime(DateTime src) => DateTime(src.year, src.month, src.day);

DateTime mixDateWithTime(DateTime date, DateTime time, {int year,
  int month,
  int day,
  int hour,
  int minute,
  int second,
  int millisecond,
  int microsecond}) =>
    DateTime(
        year ?? date.year,
        month ?? date.month,
        day ?? date.day,
        (hour ?? time?.hour) ?? 0,
        (minute ?? time?.minute) ?? 0,
        (second ?? time?.second) ?? 0,
        (millisecond ?? time?.millisecond) ?? 0,
        (microsecond ?? time?.microsecond) ?? 0);

/// Get a ZonedDateTime from [dt] using the current timezone
/// TODO Remove this when ZonedDateTime is used properly
ZonedDateTime getZonedDateTime(DateTime dt) {
  final tzOffset = DateTime.now().timeZoneOffset;
  final sign = tzOffset.isNegative ? '-' : '+';
  final hours = tzOffset.inMinutes.abs() ~/ 60;
  final minutes = tzOffset.inMinutes.abs() - 60 * hours;
  final format = NumberFormat('00');
  return ZonedDateTime.fromIso8601String(
      '${dt.toIso8601String()}'
      '${dt.microsecond == 0 ? "000" : ""}'
      '$sign${format.format(hours)}${format.format(minutes)}'
  );
}
