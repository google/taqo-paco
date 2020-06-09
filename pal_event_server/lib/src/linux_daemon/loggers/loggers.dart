import 'dart:async';

import 'package:taqo_common/model/event.dart';
import 'package:taqo_common/model/experiment.dart';

import '../../experiment_service_local.dart';

typedef CreateEventFunc = Future<Event> Function(
    Experiment experiment, String groupname, Map<String, dynamic> response);

Future<List<Event>> createLoggerPacoEvents(
    Map<String, dynamic> response, CreateEventFunc func) async {
  final events = <Event>[];

  final experimentService = await ExperimentServiceLocal.getInstance();
  final experiments = await experimentService.getJoinedExperiments();

  for (var e in experiments) {
    if (e.isOver() || (e.paused ?? false)) {
      continue;
    }

    for (var g in e.groups) {
      if (g.isAppUsageLoggingGroup) {
        events.add(await func(e, g.name, response));
      }
    }
  }

  return events;
}

Future<bool> shouldStartLoggers() async {
  final experimentService = await ExperimentServiceLocal.getInstance();
  final experiments = await experimentService.getJoinedExperiments();

  for (var e in experiments) {
    if (e.isOver() || (e.paused ?? false)) {
      continue;
    }

    for (var g in e.groups) {
      if (g.isAppUsageLoggingGroup) {
        return true;
      }
    }
  }

  return false;
}
