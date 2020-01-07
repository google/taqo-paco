import 'dart:async';
import 'dart:math';

import 'package:taqo_client/model/experiment.dart';
import 'package:taqo_client/model/schedule.dart';
import 'package:taqo_client/storage/esm_signal_storage.dart';

class ESMScheduleGenerator {
  static const int _maxRandomAttempts = 1000;

  final DateTime startTime;
  final Experiment experiment;
  final String groupName;
  final int triggerId;
  final Schedule schedule;

  final Completer _lock;

  ESMScheduleGenerator(this.startTime, this.experiment, this.groupName, this.triggerId,
      this.schedule) : _lock = Completer() {
    _generate();
  }

  /// Get the next scheduled alarm time
  Future<DateTime> nextScheduleTime() async {
    await _lock.future;
    final periodStart = _getNextPeriodStart();
    return _lookupNextESMScheduleTime(periodStart) ??
        _lookupNextESMScheduleTime(_getNextPeriodStart(periodStart));
  }

  /// Generate ESM Schedules for the next two periods
  Future<void> _generate() async {
    final periodStart = _getNextPeriodStart();
    await _ensureESMScheduleGeneratedForPeriod(periodStart);

    final nextPeriodStart = _getNextPeriodStart(periodStart);
    await _ensureESMScheduleGeneratedForPeriod(nextPeriodStart);

    _lock.complete();
  }

  /// Skips over Saturday and Sunday
  DateTime _skipOverWeekend(DateTime dt) {
    while (dt.weekday > DateTime.friday) {
      dt = dt.add(Duration(days: 1));
    }
    return dt;
  }

  /// Gets the next period start after [from]
  DateTime _getNextPeriodStart([DateTime from]) {
    var base = from ?? startTime;

    // Find first day of ESM period
    var periodStart = DateTime(base.year, base.month, base.day);
    if (from != null) {
      periodStart = periodStart.add(Duration(days: schedule.convertEsmPeriodToDays()));
    }

    if (schedule.esmPeriodInDays == Schedule.ESM_PERIOD_WEEK) {
      periodStart = periodStart.subtract(Duration(days: periodStart.weekday - 1));
    } else if (schedule.esmPeriodInDays == Schedule.ESM_PERIOD_MONTH) {
      periodStart = periodStart.subtract(Duration(days: periodStart.day - 1));
    }

    if (!schedule.esmWeekends) {
      periodStart = _skipOverWeekend(periodStart);
    }

    return periodStart;
  }

  /// Retrieve the next scheduled alarm time for [periodStart] from storage
  Future<DateTime> _lookupNextESMScheduleTime(DateTime periodStart) async {
    final signals = await ESMSignalStorage()
        .getSignals(periodStart, experiment.id, groupName, triggerId, schedule.id);

    if (signals.isEmpty) {
      return null;
    }

    signals.sort();
    final now = DateTime.now();
    for (var s in signals) {
      if (s.isAtSameMomentAs(now) || s.isAfter(now)) {
        return s;
      }
    }

    return null;
  }

  /// Checks if ESM schedule for [periodStart] exists in storage and generates/stores it, if
  /// necessary
  Future<void> _ensureESMScheduleGeneratedForPeriod(DateTime periodStart) async {
    if (experiment.isOver(periodStart)) {
      return;
    }

    final signals = await ESMSignalStorage()
        .getSignals(periodStart, experiment.id, groupName, triggerId, schedule.id);

    if (signals.isNotEmpty) {
      // Signals are already generated -> done
      print('ESM signals already generated for period ${periodStart.toIso8601String()}');
      return;
    }

    final signalTimes = _generateESMTimesForSchedule(periodStart);
    for (var signal in signalTimes) {
      await ESMSignalStorage()
          .storeSignal(periodStart, experiment.id, signal, groupName, triggerId, schedule.id);
    }
  }

  List<DateTime> _generateESMTimesForSchedule(DateTime periodStart) {
    final signalTimes = <DateTime>[];
    if (schedule.esmFrequency == null || schedule.esmFrequency == 0) {
      return signalTimes;
    }

    var schedulableDays = 0;
    switch (schedule.esmPeriodInDays) {
      case Schedule.ESM_PERIOD_DAY:
        schedulableDays = 1;
        break;
      case Schedule.ESM_PERIOD_WEEK:
        schedulableDays = 5;
        if (schedule.esmWeekends) {
          schedulableDays += 2;
        }
        break;
      case Schedule.ESM_PERIOD_MONTH:
        var dt = DateTime.fromMillisecondsSinceEpoch(periodStart.millisecondsSinceEpoch);
        while (dt.month == periodStart.month) {
          if (dt.weekday < DateTime.saturday || schedule.esmWeekends) {
            schedulableDays += 1;
          }
          dt = dt.add(Duration(days: 1));
        }
        break;
    }

    final candidateBaseDt = DateTime(periodStart.year, periodStart.month, periodStart.day)
        .add(Duration(hours: schedule.esmStartHour ~/ 3600000));

    final minutesPerDay = ((schedule.esmEndHour - schedule.esmStartHour) ~/ 1000) ~/ 60;
    final minutesPerPeriod = schedulableDays * minutesPerDay;
    final minutesPerBlock = minutesPerPeriod ~/ schedule.esmFrequency;
    final minBuffer = schedule.minimumBuffer;
    final rand = Random();

    for (var signal = 0; signal < schedule.esmFrequency; signal++) {
      var candidateDt;
      bool okToAdd = false;

      for (var i = 0; i < _maxRandomAttempts; i++) {
        candidateDt = candidateBaseDt.add(Duration());
        var candidate = (signal * minutesPerBlock) + rand.nextInt(minutesPerBlock);
        while (candidate > minutesPerDay) {
          candidateDt = candidateDt.add(Duration(days: 1));
          if (!schedule.esmWeekends) {
            candidateDt = _skipOverWeekend(candidateDt);
          }
          candidate -= minutesPerDay;
        }

        candidateDt = candidateDt.add(Duration(minutes: candidate));

        // signalTimes is guaranteed to be sorted ascending
        okToAdd = signalTimes.isEmpty ||
            candidateDt.difference(signalTimes.last).inMinutes > minBuffer;
        if (okToAdd) {
          break;
        }
      }

      if (okToAdd) {
        signalTimes.add(candidateDt);
      }
    }

    return signalTimes;
  }
}
