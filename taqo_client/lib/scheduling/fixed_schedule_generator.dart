import '../model/experiment.dart';
import '../model/schedule.dart';
import '../util/date_time_util.dart';

class FixedScheduleGenerator {
  final DateTime startTime;
  final Experiment experiment;
  final String groupName;
  final int triggerId;
  final Schedule schedule;

  FixedScheduleGenerator(this.startTime, this.experiment, this.groupName, this.triggerId,
      this.schedule);

  DateTime nextAlarmTimeFromNow({DateTime fromNow}) {
    if (schedule.signalTimes == null || schedule.signalTimes.isEmpty) {
      return null;
    }

    final now = fromNow ?? DateTime.now();
    switch (schedule.scheduleType) {
      case Schedule.DAILY:
        return _scheduleDaily(now);
      case Schedule.WEEKDAY:
        return _scheduleWeekday(now);
      case Schedule.WEEKLY:
        return _scheduleWeekly(now);
      case Schedule.MONTHLY:
        return _scheduleMonthly(now);
    }

    return null;
  }

  DateTime get _scheduleBeginDay =>
      getDateWithoutTime(DateTime.fromMillisecondsSinceEpoch(schedule.beginDate));

  DateTime _getNextTimeOnDay(DateTime day, DateTime fromNow) {
    // TODO (mike) investigate SignalTime.type (offset)
    final nowTimeOnDay = mixDateWithTime(day, fromNow);
    for (var time in schedule.signalTimes) {
      final dt = day.add(Duration(milliseconds: time.fixedTimeMillisFromMidnight));
      if (dt.isAfter(nowTimeOnDay)) {
        return dt;
      }
    }
    return null;
  }

  DateTime _getNextDailyScheduleDay(DateTime fromNow) {
    final fromDay = getDateWithoutTime(fromNow);
    if (schedule.repeatRate == 1) {
      return fromDay;
    }
    final offsetToNextDay = fromDay.difference(_scheduleBeginDay).inDays % schedule.repeatRate;
    if (offsetToNextDay == 0) {
      return fromDay;
    }
    return fromDay.add(Duration(days: schedule.repeatRate - offsetToNextDay));
  }

  DateTime _scheduleDaily(DateTime fromNow) {
    final day = _getNextDailyScheduleDay(fromNow);
    final time = _getNextTimeOnDay(day, fromNow);
    if (time != null) {
      return time;
    }
    return _getNextTimeOnDay(_getNextDailyScheduleDay(day), fromNow);
  }

  DateTime _scheduleWeekday(DateTime fromNow) {
    final day = skipOverWeekend(_getNextDailyScheduleDay(fromNow));
    final time = _getNextTimeOnDay(day, fromNow);
    if (time != null) {
      return time;
    }
    return _getNextTimeOnDay(skipOverWeekend(_getNextDailyScheduleDay(day)), fromNow);
  }

  DateTime _getNextWeeklyScheduleDay(DateTime fromNow) {
    final fromDay = getDateWithoutTime(fromNow);
    // The start (Sunday) of the week when the schedule began
    final scheduleBeginWeek = getSunday(_scheduleBeginDay);

    // Get the start (Sunday) of the next schedule week
    var nextScheduleWeek = fromDay;
    if (schedule.repeatRate > 1) {
      final weeksBetween = fromDay.difference(scheduleBeginWeek).inDays ~/ 7;
      final offsetToNextWeek = weeksBetween % schedule.repeatRate;
      if (offsetToNextWeek > 0) {
        final offsetDays = 7 * (schedule.repeatRate - offsetToNextWeek);
        nextScheduleWeek = fromDay.add(Duration(days: offsetDays));
      }
    }
    nextScheduleWeek = getSunday(nextScheduleWeek);

    // Weekdays for this schedule
    // Implicitly converts from ISO 8601 weekday to 0-based weekday starting with Sunday
    final daysOfWeek = extractDaysOfWeek(schedule.weekDaysScheduled, true);

    // Find the next schedule weekday of nextScheduleWeek
    for (var day in daysOfWeek) {
      final candidate = mixDateWithTime(nextScheduleWeek, fromNow, day: nextScheduleWeek.day + day);
      if (candidate.isAfter(fromNow) || candidate.isAtSameMomentAs(fromNow)) {
        return getDateWithoutTime(candidate);
      }
    }

    // If we didn't find one, [fromNow] was already past the last schedule day/time of the week
    // Therefore we should return the first schedule day of the next schedule week
    nextScheduleWeek = nextScheduleWeek.add(Duration(days: 7 * schedule.repeatRate));
    return mixDateWithTime(nextScheduleWeek, null, day: nextScheduleWeek.day + daysOfWeek.first);
  }

  DateTime _scheduleWeekly(DateTime fromNow) {
    final day = _getNextWeeklyScheduleDay(fromNow);
    // _getNextTimeOnDay() should never return null here because _getNextWeeklyScheduleDay()
    // handles time checking
    return _getNextTimeOnDay(day, fromNow);
  }

  DateTime _getNextMonthlyScheduleDay(DateTime fromNow) {
    final today = getDateWithoutTime(fromNow);

    if (schedule.byDayOfMonth) {
      DateTime nextMonth = cloneDateTime(today, day: 1);
      final check = setDayOfMonth(mixDateWithTime(today, fromNow), schedule.dayOfMonth);
      if (check.isBefore(fromNow)) {
        nextMonth = addMonths(nextMonth, 1);
      }

      if (schedule.repeatRate == 1) {
        // Either this month or next month if schedule.dayOfMonth has already past this month
        final candidate = setDayOfMonth(mixDateWithTime(nextMonth, fromNow), schedule.dayOfMonth);
        if (candidate.isAfter(fromNow) || candidate.isAtSameMomentAs(fromNow)) {
          return getDateWithoutTime(candidate);
        }
        return setDayOfMonth(addMonths(nextMonth, 1), schedule.dayOfMonth);
      }

      final monthsBetween = today.month - _scheduleBeginDay.month;
      final offsetToNextMonth = monthsBetween % schedule.repeatRate;
      nextMonth = mixDateWithTime(today, fromNow);
      if (offsetToNextMonth > 0) {
        nextMonth = addMonths(today, schedule.repeatRate - offsetToNextMonth);
      }
      final candidate = setDayOfMonth(nextMonth, schedule.dayOfMonth);
      if (candidate.isAfter(fromNow) || candidate.isAtSameMomentAs(fromNow)) {
        return getDateWithoutTime(candidate);
      }

      // schedule.dayOfMonth has already passed, so use next applicable month
      nextMonth = addMonths(nextMonth, schedule.repeatRate - offsetToNextMonth);
      return setDayOfMonth(nextMonth, schedule.dayOfMonth);
    } else /* use schedule.nthOfMonth */ {
      final daysOfWeek = extractDaysOfWeek(schedule.weekDaysScheduled);
      var nextMonth = cloneDateTime(today, day: 1);

      final monthsBetween = today.month - _scheduleBeginDay.month;
      final offsetToNextMonth = monthsBetween % schedule.repeatRate;
      if (offsetToNextMonth > 0) {
        nextMonth = addMonths(nextMonth, schedule.repeatRate - offsetToNextMonth);
      }

      DateTime doIt(DateTime candidateNextMonth) {
        // 1st applicable weekday of month
        while (!daysOfWeek.contains(candidateNextMonth.weekday)) {
          candidateNextMonth = candidateNextMonth.add(Duration(days: 1));
        }

        // First Nth applicable weekday of month
        final lastDayOfMonth = getLastDayOfMonth(candidateNextMonth);
        int offsetToDay = 7 * (schedule.nthOfMonth - 1);
        if (candidateNextMonth.day + offsetToDay > lastDayOfMonth) {
          offsetToDay = lastDayOfMonth - candidateNextMonth.day;
        }
        candidateNextMonth = candidateNextMonth.add(Duration(days: offsetToDay));

        if (candidateNextMonth.day > lastDayOfMonth - DateTime.daysPerWeek) {
          // Make sure at least one of every daysOfWeek exists in the current month starting from
          // candidateNextMonth.day
          final lastWeekdayOfMonth = cloneDateTime(candidateNextMonth, day: lastDayOfMonth).weekday;
          // Relies on daysOfWeek being sorted
          if (daysOfWeek.last > lastWeekdayOfMonth) {
            final sub = (DateTime.daysPerWeek + candidateNextMonth.weekday) - daysOfWeek.last;
            candidateNextMonth = candidateNextMonth.subtract(Duration(days: sub));
          } else if (daysOfWeek.first < lastWeekdayOfMonth) {
            final sub = candidateNextMonth.weekday - daysOfWeek.first;
            candidateNextMonth = candidateNextMonth.subtract(Duration(days: sub));
          }
        }

        // At this point every dayOfWeek will exist in current month starting from candidateNextMonth
        var start = daysOfWeek.indexOf(candidateNextMonth.weekday);
        for (var i = start; i < start+daysOfWeek.length; i++) {
          var add = daysOfWeek[i % daysOfWeek.length] - candidateNextMonth.weekday;
          add = add < 0 ? DateTime.daysPerWeek + add : add;
          final candidate = mixDateWithTime(candidateNextMonth, fromNow, day: candidateNextMonth.day + add);
          if (candidate.isAfter(fromNow) || candidate.isAtSameMomentAs(fromNow)) {
            return getDateWithoutTime(candidate);
          }
        }

        // Couldn't find one, will need to use the next applicable month
        return null;
      }

      return doIt(cloneDateTime(nextMonth)) ??
          doIt(addMonths(nextMonth, schedule.repeatRate - offsetToNextMonth));
    }
  }

  DateTime _scheduleMonthly(DateTime fromNow) {
    final day = _getNextMonthlyScheduleDay(fromNow);
    // _getNextTimeOnDay() should never return null here because _getNextMonthlyScheduleDay()
    // handles time checking
    return _getNextTimeOnDay(day, fromNow);
  }
}
