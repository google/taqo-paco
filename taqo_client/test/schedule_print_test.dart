import 'package:flutter_test/flutter_test.dart';
import 'package:taqo_client/model/schedule.dart';
import 'package:taqo_client/model/signal_time.dart';
import 'package:taqo_client/util/schedule_printer.dart' as schedule_printer;

/// Constructs a [SignalTime] object (with default values)
SignalTime _getSignalTime(int type, int fixedTimeMillisFromMidnight,
    {int basis = SignalTime.OFFSET_BASIS_SCHEDULED_TIME,
      int missedBasisBehavior = SignalTime.MISSED_BEHAVIOR_SKIP,
      int offsetTimeMillis = SignalTime.OFFSET_TIME_DEFAULT,
      String label = ''}) {
  return SignalTime(type, basis, fixedTimeMillisFromMidnight,
      missedBasisBehavior, offsetTimeMillis, label);
}

/// Constructs a [Schedule] object (with default values)
Schedule _getSchedule(int scheduleType, List<SignalTime> signalTimes,
    {bool byDayOfMonth = false, int dayOfMonth = 1, int esmEndHour = 61200000 /*5PM*/,
      int esmFrequency = 8, int esmPeriodInDays = 0, int esmStartHour = 32400000 /*9AM*/,
      int nthOfMonth = 1, int repeatRate = 1, int weekDaysScheduled = 0, bool esmWeekends = false,
      int minimumBuffer = 59}) {
  return Schedule(scheduleType, byDayOfMonth, dayOfMonth, esmEndHour,
      esmFrequency, esmPeriodInDays, esmStartHour, nthOfMonth, repeatRate,
      signalTimes, weekDaysScheduled, esmWeekends, minimumBuffer);
}

/// Calculate milliseconds since midnight on [dateTime]
int _getFixedTimeMillisFromMidnight(DateTime dateTime) {
  final midnight = DateTime(dateTime.year, dateTime.month, dateTime.day);
  return dateTime.difference(midnight).inMilliseconds;
}

// Test constants
final _testNow = DateTime(2001, 2, 3);
final _12AM = DateTime(_testNow.year, _testNow.month, _testNow.day);
final _1AM = DateTime(_testNow.year, _testNow.month, _testNow.day, 1);
final _230AM = DateTime(_testNow.year, _testNow.month, _testNow.day, 2, 30);
final _12PM = DateTime(_testNow.year, _testNow.month, _testNow.day, 12);
final _315PM = DateTime(_testNow.year, _testNow.month, _testNow.day, 15, 15);
final _445PM = DateTime(_testNow.year, _testNow.month, _testNow.day, 16, 45);

void main() {
  test('Daily', () {
    expect(schedule_printer.toPrettyString(_getSchedule(Schedule.DAILY,
        [_getSignalTime(SignalTime.FIXED_TIME, _getFixedTimeMillisFromMidnight(_12AM))])),
        'Daily at 12:00AM');
    expect(schedule_printer.toPrettyString(_getSchedule(Schedule.DAILY,
        [_getSignalTime(SignalTime.FIXED_TIME, _getFixedTimeMillisFromMidnight(_230AM)),
        _getSignalTime(SignalTime.FIXED_TIME, _getFixedTimeMillisFromMidnight(_315PM))])),
        'Daily at 02:30AM,03:15PM');
    expect(schedule_printer.toPrettyString(_getSchedule(Schedule.DAILY,
        [_getSignalTime(SignalTime.FIXED_TIME, _getFixedTimeMillisFromMidnight(_12PM)),
          _getSignalTime(SignalTime.FIXED_TIME, _getFixedTimeMillisFromMidnight(_445PM))],
    repeatRate: 3)), 'Every 3 days at 12:00PM,04:45PM');
  });

  test('Weekday', () {
    expect(schedule_printer.toPrettyString(_getSchedule(Schedule.WEEKDAY,
        [_getSignalTime(SignalTime.FIXED_TIME, _getFixedTimeMillisFromMidnight(_12AM))])),
        'Daily at 12:00AM');
    expect(schedule_printer.toPrettyString(_getSchedule(Schedule.WEEKDAY,
        [_getSignalTime(SignalTime.FIXED_TIME, _getFixedTimeMillisFromMidnight(_230AM)),
          _getSignalTime(SignalTime.FIXED_TIME, _getFixedTimeMillisFromMidnight(_315PM))])),
        'Daily at 02:30AM,03:15PM');
    expect(schedule_printer.toPrettyString(_getSchedule(Schedule.WEEKDAY,
        [_getSignalTime(SignalTime.FIXED_TIME, _getFixedTimeMillisFromMidnight(_12PM)),
          _getSignalTime(SignalTime.FIXED_TIME, _getFixedTimeMillisFromMidnight(_445PM))],
        repeatRate: 3)), 'Every 3 days at 12:00PM,04:45PM');
  });

  test('Weekly', () {
    expect(schedule_printer.toPrettyString(_getSchedule(Schedule.WEEKLY,
        [_getSignalTime(SignalTime.FIXED_TIME, _getFixedTimeMillisFromMidnight(_12AM))],
        weekDaysScheduled: 1)), 'Weekly on Sun at 12:00AM');
    expect(schedule_printer.toPrettyString(_getSchedule(Schedule.WEEKLY,
        [_getSignalTime(SignalTime.FIXED_TIME, _getFixedTimeMillisFromMidnight(_230AM)),
        _getSignalTime(SignalTime.FIXED_TIME, _getFixedTimeMillisFromMidnight(_315PM))],
        weekDaysScheduled: 9)), 'Weekly on Sun,Wed at 02:30AM,03:15PM');
    expect(schedule_printer.toPrettyString(_getSchedule(Schedule.WEEKLY,
        [_getSignalTime(SignalTime.FIXED_TIME, _getFixedTimeMillisFromMidnight(_12PM)),
          _getSignalTime(SignalTime.FIXED_TIME, _getFixedTimeMillisFromMidnight(_445PM))],
        weekDaysScheduled: 34, repeatRate: 2)), 'Every 2 weeks on Mon,Fri at 12:00PM,04:45PM');
  });

  test('Monthly dayOfMonth', () {
    expect(schedule_printer.toPrettyString(_getSchedule(Schedule.MONTHLY,
        [_getSignalTime(SignalTime.FIXED_TIME, _getFixedTimeMillisFromMidnight(_12AM))],
        byDayOfMonth: true, dayOfMonth: 20)), 'Monthly on 20 at 12:00AM');
    expect(schedule_printer.toPrettyString(_getSchedule(Schedule.MONTHLY,
        [_getSignalTime(SignalTime.FIXED_TIME, _getFixedTimeMillisFromMidnight(_230AM)),
          _getSignalTime(SignalTime.FIXED_TIME, _getFixedTimeMillisFromMidnight(_315PM))],
        byDayOfMonth: true, dayOfMonth: 20)), 'Monthly on 20 at 02:30AM,03:15PM');
    expect(schedule_printer.toPrettyString(_getSchedule(Schedule.MONTHLY,
        [_getSignalTime(SignalTime.FIXED_TIME, _getFixedTimeMillisFromMidnight(_12PM)),
          _getSignalTime(SignalTime.FIXED_TIME, _getFixedTimeMillisFromMidnight(_445PM))],
        byDayOfMonth: true, dayOfMonth: 20, repeatRate: 4)),
        'Every 4 months on 20 at 12:00PM,04:45PM');
  });

  test('Monthly nthOfMonth', () {
    expect(schedule_printer.toPrettyString(_getSchedule(Schedule.MONTHLY,
        [_getSignalTime(SignalTime.FIXED_TIME, _getFixedTimeMillisFromMidnight(_12AM))],
        weekDaysScheduled: 2, nthOfMonth: 1)), 'Monthly on 1st Mon at 12:00AM');
    expect(schedule_printer.toPrettyString(_getSchedule(Schedule.MONTHLY,
        [_getSignalTime(SignalTime.FIXED_TIME, _getFixedTimeMillisFromMidnight(_230AM)),
          _getSignalTime(SignalTime.FIXED_TIME, _getFixedTimeMillisFromMidnight(_315PM))],
        weekDaysScheduled: 20, nthOfMonth: 3)), 'Monthly on 3rd Tue,Thu at 02:30AM,03:15PM');
    expect(schedule_printer.toPrettyString(_getSchedule(Schedule.MONTHLY,
        [_getSignalTime(SignalTime.FIXED_TIME, _getFixedTimeMillisFromMidnight(_12PM)),
          _getSignalTime(SignalTime.FIXED_TIME, _getFixedTimeMillisFromMidnight(_445PM))],
        weekDaysScheduled: 65, nthOfMonth: 5, repeatRate: 6)),
        'Every 6 months on 5th Sun,Sat at 12:00PM,04:45PM');
  });


  test('ESM', () {
    expect(schedule_printer.toPrettyString(_getSchedule(Schedule.ESM, [])),
        'Randomly 8 times per day between 09:00AM and 05:00PM');
    expect(schedule_printer.toPrettyString(_getSchedule(Schedule.ESM, [], esmWeekends: true)),
        'Randomly 8 times per day between 09:00AM and 05:00PM incl weekends');
  });
}
