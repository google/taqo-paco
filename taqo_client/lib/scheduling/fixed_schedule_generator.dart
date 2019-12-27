import 'package:taqo_client/model/experiment.dart';
import 'package:taqo_client/model/schedule.dart';

class FixedScheduleGenerator {
  static final maxRandomScheduleAttempts = 1000;

  final DateTime startTime;
  final Experiment experiment;
  final String groupName;
  final int triggerId;
  final Schedule schedule;

  FixedScheduleGenerator(this.startTime, this.experiment, this.groupName, this.triggerId,
      this.schedule);

  Future<DateTime> nextAlarmTimeFromNow() async {
    if (schedule.signalTimes == null || schedule.signalTimes.isEmpty) {
      return null;
    }

    switch (schedule.scheduleType) {
      case Schedule.DAILY:
        return _scheduleDaily();
      case Schedule.WEEKDAY:
        return _scheduleWeekday();
      case Schedule.WEEKLY:
        return _scheduleWeekly();
      case Schedule.MONTHLY:
        return _scheduleMonthly();
    }

    return null;
  }

  Future<DateTime> _scheduleDaily() async {}

  Future<DateTime> _scheduleWeekday() async {}

  Future<DateTime> _scheduleWeekly() async {}

  Future<DateTime> _scheduleMonthly() async {}
}
