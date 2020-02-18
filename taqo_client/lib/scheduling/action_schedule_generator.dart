import 'dart:math';

import 'package:taqo_client/model/action_specification.dart';
import 'package:taqo_client/model/experiment.dart';
import 'package:taqo_client/model/experiment_group.dart';
import 'package:taqo_client/model/paco_notification_action.dart';
import 'package:taqo_client/model/schedule.dart';
import 'package:taqo_client/model/schedule_trigger.dart';
import 'package:taqo_client/scheduling/esm_schedule_generator.dart';
import 'package:taqo_client/scheduling/fixed_schedule_generator.dart';
import 'package:taqo_client/service/experiment_service.dart';
import 'package:taqo_client/util/date_time_util.dart';

Future<List<ActionSpecification>> _getAllAlarmTimesForExperiment(
    Experiment experiment, DateTime start, DateTime end) async {
  if (experiment.isOver() || experiment.paused) {
    return null;
  }

  final allAlarmTimes = <ActionSpecification>[];
  for (var group in experiment.groups) {
    if (group.groupType == GroupTypeEnum.SYSTEM || group.isOver(start)) {
      continue;
    }

    final startTime = group.isStarted(start) ? start : parseYMDTime(group.startDate);

    for (ScheduleTrigger trigger in group.actionTriggers.where((t) => t is ScheduleTrigger)) {
      for (var schedule in trigger.schedules) {
        List<DateTime> scheduleTimes;
        if (schedule.scheduleType == Schedule.ESM) {
          scheduleTimes = await ESMScheduleGenerator(
              startTime, experiment, group.name, trigger.id, schedule).allScheduleTimes();
        } else {
          scheduleTimes =
              FixedScheduleGenerator(startTime, experiment, group.name, trigger.id, schedule)
                  .allAlarmTimesFromUntil(start, end);
        }

        for (var time in scheduleTimes) {
          if (time == null) continue;
          PacoNotificationAction notificationAction;
          for (var action in trigger.actions) {
            if (action != null && action is PacoNotificationAction) {
              notificationAction = action;
              break;
            }
          }

          allAlarmTimes.add(ActionSpecification(time, experiment, group, trigger,
              notificationAction, schedule.id));
        }
      }
    }
  }

  return allAlarmTimes;
}

Future<ActionSpecification> _getNextAlarmTimeForExperiment(Experiment experiment, DateTime now) async {
  if (experiment.isOver() || experiment.paused) {
    return null;
  }

  ActionSpecification nextAlarmTime;
  DateTime currNextTime;
  for (var group in experiment.groups) {
    if (group.groupType == GroupTypeEnum.SYSTEM || group.isOver(now)) {
      continue;
    }

    final startTime = group.isStarted(now) ? now : parseYMDTime(group.startDate);

    for (ScheduleTrigger trigger in group.actionTriggers.where((t) => t is ScheduleTrigger)) {
      for (var schedule in trigger.schedules) {
        DateTime nextScheduleTime;
        if (schedule.scheduleType == Schedule.ESM) {
          nextScheduleTime =
              await ESMScheduleGenerator(startTime, experiment, group.name, trigger.id, schedule)
                  .nextScheduleTime();
          print('Next ESM $nextScheduleTime');
        } else {
          nextScheduleTime =
              FixedScheduleGenerator(startTime, experiment, group.name, trigger.id, schedule)
                  .nextAlarmTimeFromNow(fromNow: startTime);
          print('Next fixed $nextScheduleTime');
        }

        if (nextScheduleTime != null &&
            (currNextTime == null || nextScheduleTime.isBefore(currNextTime))) {
          currNextTime = nextScheduleTime;
          PacoNotificationAction notificationAction;
          for (var action in trigger.actions) {
            if (action != null && action is PacoNotificationAction) {
              notificationAction = action;
              break;
            }
          }

          nextAlarmTime = ActionSpecification(currNextTime, experiment, group, trigger,
              notificationAction, schedule.id);
        }
      }
    }
  }

  return nextAlarmTime;
}

Future<List<ActionSpecification>> getAllAlarmTimesOrdered(
    {List<Experiment> experiments, DateTime start, DateTime end}) async {
  final service = await ExperimentService.getInstance();

  // Default args
  experiments ??= service.getJoinedExperiments();
  start ??= DateTime.now();
  // TODO establish a default for end time

  final alarmTimes = <ActionSpecification>[];
  for (var e in experiments) {
    final times = await _getAllAlarmTimesForExperiment(e, start, end);
    if (times != null) {
      alarmTimes.addAll(times);
    }
  }
  alarmTimes.sort();
  return alarmTimes;
}

Future<List<ActionSpecification>> getNextAlarmTimesOrdered(
    {List<Experiment> experiments, DateTime now}) async {
  final service = await ExperimentService.getInstance();

  // Default args
  experiments ??= service.getJoinedExperiments();
  now ??= DateTime.now();

  final alarmTimes = <ActionSpecification>[];
  for (var e in experiments) {
    final time = await _getNextAlarmTimeForExperiment(e, now);
    if (time != null) {
      alarmTimes.add(time);
    }
  }
  alarmTimes.sort();
  return alarmTimes;
}

Future<List<ActionSpecification>> getAllAlarmsWithinRange(
    {List<Experiment> experiments, DateTime start, Duration duration}) async {
  final service = await ExperimentService.getInstance();

  // Default args
  experiments ??= service.getJoinedExperiments();
  start ??= DateTime.now().subtract(Duration(minutes: 1));
  duration ??= Duration(minutes: 2);
  final end = start.add(duration);

  final alarms = await getAllAlarmTimesOrdered(experiments: experiments, start: start, end: end);
  return alarms
      .where((a) =>
        (a.time.isAtSameMomentAs(start) || a.time.isAfter(start)) &&
        (a.time.isAtSameMomentAs(end) || a.time.isBefore(end)))
      .toList();
}

Future<ActionSpecification> getNextAlarmTime({List<Experiment> experiments, DateTime now}) async {
  final service = await ExperimentService.getInstance();

  // Default args
  experiments ??= service.getJoinedExperiments();
  now ??= DateTime.now();

  final alarms = await getNextAlarmTimesOrdered(experiments: experiments, now: now);
  print('Next alarm is ${alarms.isEmpty ? null : alarms.first}');
  return alarms.isEmpty ? null : alarms.first;
}

Future<List<ActionSpecification>> getNextNAlarmTimes(
    {int n, List<Experiment> experiments, DateTime now}) async {
  final service = await ExperimentService.getInstance();

  // Default args
  experiments ??= service.getJoinedExperiments();
  now ??= DateTime.now();
  n ??= 64;

  final alarms = <ActionSpecification>[];
  var count = 0;
  var loopNow = now;
  while (alarms.length < n) {
    final next = await getNextAlarmTime(
        experiments: experiments, now: loopNow);
    if (next == null) {
      break;
    }
    alarms.add(next);
    loopNow = alarms.last.time.add(Duration(seconds: 1));
    count = alarms.length;
  }

  count = min(n, alarms.length);
  return alarms.isEmpty ? <ActionSpecification>[] : alarms.sublist(0, count);
}
