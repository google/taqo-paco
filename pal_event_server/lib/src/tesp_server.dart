import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:pal_event_server/src/experiment_cache.dart';
import 'package:pal_event_server/src/loggers/loggers.dart' as loggers;

import 'package:pedantic/pedantic.dart';
import 'package:taqo_common/model/action_specification.dart';
import 'package:taqo_common/model/event.dart';
import 'package:taqo_common/model/experiment.dart';
import 'package:taqo_common/model/experiment_group.dart';
import 'package:taqo_common/model/notification_holder.dart';
import 'package:taqo_common/service/experiment_service_lite.dart';
import 'package:taqo_common/service/sync_service.dart';
import 'package:taqo_event_server_protocol/taqo_event_server_protocol.dart';

import 'daemon/daemon.dart' as daemon;
import 'pal_server/pal_commands.dart' as pal_commands;
import 'sqlite_database/sqlite_database.dart';
import 'allowlist.dart';

class PALTespServer with TespRequestHandlerMixin {
  TespServer _tespServer;
  final _allowlist = Allowlist();

  PALTespServer() {
    _tespServer = TespServer(this);
  }

  int get port => _tespServer.port;

  Future<void> serve({dynamic address = '127.0.0.1', int port = 0}) async {
    await _tespServer.serve(address: address, port: port);
  }

  Future _storeEvent(List events) async {
    final database = await SqliteDatabase.get();
    for (var e in events) {
      await database.insertEvent(e, notifySyncService: false);
    }
    unawaited(SyncService.syncData());
  }

  /**
   * If there are any events generated from the IDE logger,
   * find each experiment that is interested in these events
   * and record a copy of the vent for that experiment with
   * the experiment fields properly recorded.
   *
   */
  void createEventsPerExperimentOrDeleteIntelliJLoggerEvents(List<Event> events) async {
// the where call is async but there seems no way to add the async keyword
// so it fails.
//    List<Event> ideaLoggerEvents = await events.where((event) =>
//      event.groupName == "**IntelliJLoggerProcess");

// This version works.
    List<Event> ideaLoggerEvents = [];
    events.forEach((event) {
        if (event.groupName == "**IntelliJLoggerProcess") {
          ideaLoggerEvents.add(event);
        }});

    if (ideaLoggerEvents.isEmpty) {
      //print("no logger events. Keeping all");
      return;
    }
    var experimentsWithIdeaLogging = await loggers.getExperimentsToLogForType(GroupTypeEnum.IDE_IDEA_USAGE);
    if (experimentsWithIdeaLogging == null || experimentsWithIdeaLogging.isEmpty) {
      //print("deleting all logger events");
      deleteAllIdeaLoggerEvents(events, ideaLoggerEvents);
      return;
    }

    createEventForEachExperiment(ideaLoggerEvents, experimentsWithIdeaLogging, events);
  }

  void createEventForEachExperiment(List<Event> ideaLoggerEvents,
      List<loggers.ExperimentLoggerInfo> experimentsWithIdeaLogging,
      List<Event> events) {
    //print("creating events for each experiment");
    ideaLoggerEvents.forEach((event) {
        bool firstExperimentNeedingEvent = true;
        experimentsWithIdeaLogging.forEach((experiment) {
          if (firstExperimentNeedingEvent) {
            populateExperimentInfoOnEvent(event, experiment);
            firstExperimentNeedingEvent = false;
          } else {
            var dupevent = event.copy();
            populateExperimentInfoOnEvent(dupevent, experiment);
            events.add(dupevent);
          }
        });
    });
    //print("done with creating Events");
  }

  void deleteAllIdeaLoggerEvents(List<Event> events, List<Event> ideaLoggerEvents) {
    events.removeWhere((event) => ideaLoggerEvents.indexOf(event) != -1);
  }

  void populateExperimentInfoOnEvent(Event event, loggers.ExperimentLoggerInfo experimentInfo) {
    event.experimentId = experimentInfo.experiment.id;
    event.experimentName = experimentInfo.experiment.title;
    event.experimentVersion = experimentInfo.experiment.version;
    event.groupName = experimentInfo.groups.first.name;
  }
  // PAL Commands

  @override
  FutureOr<TespResponse> palAddEvents(List<Event> events) async {
    await createEventsPerExperimentOrDeleteIntelliJLoggerEvents(events);
    if (await pal_commands.isAllowlistedDataOnly()) {
      await _storeEvent(_allowlist.filterData(events));
    } else {
      await _storeEvent(events);
    }
    return TespResponseSuccess();
  }

  @override
  FutureOr<TespResponse> palPause() async {
    await pal_commands.pauseDataUpload();
    return TespResponseSuccess();
  }

  @override
  FutureOr<TespResponse> palResume() async {
    await pal_commands.resumeDataUpload();
    return TespResponseSuccess();
  }

  @override
  FutureOr<TespResponse> palAllowlistDataOnly() async {
    await pal_commands.setAllowlistedDataOnly();
    return TespResponseSuccess();
  }

  @override
  FutureOr<TespResponse> palAllData() async {
    await pal_commands.setAllDataOnly();
    return TespResponseSuccess();
  }

  // Alarm/Notification RPC

  @override
  FutureOr<TespResponse> alarmSchedule() async {
    await daemon.handleScheduleAlarm();
    return TespResponseSuccess();
  }

  @override
  FutureOr<TespResponse> alarmAdd(ActionSpecification actionSpecification) async {
    // On Linux and MacOS, alarms and notifications are handled entirely
    // in the daemon
    return TespResponseError('Unsupported platform for alarmAdd: ${Platform.operatingSystem}');
  }

  @override
  FutureOr<TespResponse> alarmCancel(int alarmId) async {
    await daemon.handleCancelAlarm(alarmId);
    return TespResponseSuccess();
  }

  @override
  FutureOr<TespResponse> alarmRemove(int alarmId) async {
    // On Linux and MacOS, alarms and notifications are handled entirely
    // in the daemon
    return TespResponseError('Unsupported platform for alarmRemove: ${Platform.operatingSystem}');
  }

  @override
  FutureOr<TespResponse> notificationCheckActive() async {
    await daemon.handleScheduleAlarm();
    return TespResponseSuccess();
  }

  @override
  FutureOr<TespResponse> notificationAdd(NotificationHolder notification) async {
    // On Linux and MacOS, alarms and notifications are handled entirely
    // in the daemon
    return TespResponseError('Unsupported platform for notificationAdd: '
        '${Platform.operatingSystem}');
  }

  @override
  FutureOr<TespResponse> notificationCancel(int notificationId) async {
    await daemon.handleCancelNotification(notificationId);
    return TespResponseSuccess();
  }

  @override
  FutureOr<TespResponse> notificationCancelByExperiment(int experimentId) async {
    await daemon.handleCancelExperimentNotification(experimentId);
    return TespResponseSuccess();
  }

  @override
  FutureOr<TespResponse> notificationRemove(int notificationId) async {
    // On Linux and MacOS, alarms and notifications are handled entirely
    // in the daemon
    return TespResponseError('Unsupported platform for notificationRemove: ${Platform.operatingSystem}');
  }

  @override
  FutureOr<TespResponse> notificationRemoveAll() async {
    // On Linux and MacOS, alarms and notifications are handled entirely
    // in the daemon
    return TespResponseError('Unsupported platform for notificationRemoveAll: ${Platform.operatingSystem}');
  }

  @override
  FutureOr<TespResponse> createMissedEvent(Event event) async {
    await daemon.handleCreateMissedEvent(event);
    return TespResponseSuccess();
  }

  // SQL Commands

  @override
  FutureOr<TespResponse> alarmSelectAll() async {
    final database = await SqliteDatabase.get();
    final alarms = await database.getAllAlarms();
    // JSON keys must be String
    final json = Map<String, dynamic>.fromIterable(alarms.entries,
        key: (entry) => '${entry.key}',
        value: (entry) => entry.value);
    return TespResponseAnswer(jsonEncode(json));
  }

  @override
  FutureOr<TespResponse> alarmSelectById(int alarmId) async {
    final database = await SqliteDatabase.get();
    final alarm = await database.getAlarm(alarmId);
    return TespResponseAnswer(jsonEncode(alarm));
  }

  @override
  FutureOr<TespResponse> notificationSelectAll() async {
    final database = await SqliteDatabase.get();
    final notifications = await database.getAllNotifications();
    return TespResponseAnswer(jsonEncode(notifications));
  }

  @override
  FutureOr<TespResponse> notificationSelectById(int notificationId) async {
    final database = await SqliteDatabase.get();
    final notification = await database.getNotification(notificationId);
    return TespResponseAnswer(jsonEncode(notification));
  }

  @override
  FutureOr<TespResponse> notificationSelectByExperiment(int experimentId) async {
    final database = await SqliteDatabase.get();
    final experimentServiceLite = await ExperimentServiceLiteFactory.makeExperimentServiceLiteOrFuture();
    final notifications = await database.getAllNotificationsForExperiment(await experimentServiceLite.getExperimentById(experimentId));
    return TespResponseAnswer(jsonEncode(notifications));
  }

  @override
  Future<TespResponse> experimentSaveJoined(List<Experiment> experiments) async {
   final database = await SqliteDatabase.get();
   try {
     await database.saveJoinedExperiments(experiments);
   } catch (e) {
     return TespResponseError(TespResponseError.tespServerErrorDatabase, '$e');
   }
   var experimentCache = await ExperimentCache.getInstance();
   experimentCache.updateCacheWithJoinedExperiment(experiments);
   return TespResponseSuccess();
  }

  @override
  Future<TespResponse> experimentSelectById(int experimentId) async {
    final database = await SqliteDatabase.get();
    var experiment;
    try {
      experiment = await database.getExperimentById(experimentId);
    } catch (e) {
      return TespResponseError(TespResponseError.tespServerErrorDatabase, '$e');
    }
    return TespResponseAnswer(experiment);
  }

  @override
  Future<TespResponse> experimentSelectJoined() async {
    final database = await SqliteDatabase.get();
    var experiments;
    try {
      experiments = await database.getJoinedExperiments();
    } catch (e) {
      return TespResponseError(TespResponseError.tespServerErrorDatabase, '$e');
    }
    return TespResponseAnswer(experiments);
  }

  @override
  Future<TespResponse> experimentGetPausedStatuses(List<int> experimentIds) async {
    final database = await SqliteDatabase.get();
    final experimentCache = await ExperimentCache.getInstance();
    Map<int, bool> statuses;
    try {
      statuses = await database.getExperimentsPausedStatus(
          [for (var experimentId in experimentIds)
            await experimentCache.getExperimentById(experimentId)]);
    } catch (e) {
      return TespResponseError(TespResponseError.tespServerErrorDatabase, '$e');
    }
    // JSON only supports strings as keys.
    return TespResponseAnswer(statuses.map((key, value) => MapEntry(key.toString(), value)));
  }

  @override
  Future<TespResponse> experimentSetPausedStatus(int experimentId, bool paused) async {
    final database = await SqliteDatabase.get();
    final experimentCache = await ExperimentCache.getInstance();
    final Experiment experiment = await experimentCache.getExperimentById(experimentId);
    try {
      await database.setExperimentPausedStatus(experiment, paused);
    } catch (e) {
      return TespResponseError(TespResponseError.tespServerErrorDatabase, '$e');
    }
    experiment.paused = paused;
    return TespResponseSuccess();

  }
}
