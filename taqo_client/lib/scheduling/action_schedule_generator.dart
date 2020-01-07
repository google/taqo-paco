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

Future<ActionSpecification> _getNextAlarmTimeForExperiment(Experiment experiment, DateTime now) async {
  if (experiment.isOver()) {
    return null;
  }

  ActionSpecification nextAlarmTime;
  DateTime currNextTime;
  for (var group in experiment.groups) {
    if (group.groupType == GroupTypeEnum.SYSTEM || group.isOver(now)) {
      continue;
    }

    final startTime =
        group.isStarted(now) ? now : parseYMDTime(group.startDate);

    for (ScheduleTrigger trigger in group.actionTriggers.where((t) => t is ScheduleTrigger)) {
      for (var schedule in trigger.schedules) {
        DateTime nextScheduleTime;
        if (schedule.scheduleType == Schedule.ESM) {
          nextScheduleTime =
              await ESMScheduleGenerator(startTime, experiment, group.name, trigger.id, schedule)
                  .nextScheduleTime();
        } else {
          nextScheduleTime =
              await FixedScheduleGenerator(startTime, experiment, group.name, trigger.id, schedule)
                  .nextAlarmTimeFromNow();
        }

        if (nextScheduleTime != null &&
            (currNextTime == null || nextScheduleTime.isBefore(currNextTime))) {
          currNextTime = nextScheduleTime;
          PacoNotificationAction notificationAction;
          for (var action in trigger.actions) {
            if (action != null && action is PacoNotificationAction) {
              notificationAction = action;
              // Should we break here or something?
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
    {List<Experiment> experiments, DateTime now}) async {
  // Default args
  experiments ??= ExperimentService().getJoinedExperiments();
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

Future<List<ActionSpecification>> getAllAlarmsFromNowToWhen(
    {List<Experiment> experiments, DateTime now, Duration when}) async {
  // Default args
  experiments ??= ExperimentService().getJoinedExperiments();
  now ??= DateTime.now();
  when ??= Duration(minutes: 1);

  final alarms = await getAllAlarmTimesOrdered(experiments: experiments, now: now);
  return alarms.where((a) => a.time.isAfter(now) && a.time.isBefore(now.add(when)));
}

Future<ActionSpecification> getNextAlarmTime({List<Experiment> experiments, DateTime now}) async {
  // Default args
  experiments ??= ExperimentService().getJoinedExperiments();
  now ??= DateTime.now();

  final alarms = await getAllAlarmTimesOrdered(experiments: experiments, now: now);
  return alarms.isEmpty ? null : alarms.first;
}
