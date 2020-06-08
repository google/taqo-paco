import 'dart:async';
import 'dart:convert';

import 'package:pal_event_server/src/experiment_cache.dart';
import 'package:pedantic/pedantic.dart';
import 'package:taqo_common/model/event.dart';
import 'package:taqo_common/model/experiment.dart';
import 'package:taqo_common/service/experiment_service_lite.dart';
import 'package:taqo_common/service/sync_service.dart';
import 'package:taqo_event_server_protocol/taqo_event_server_protocol.dart';

import 'linux_daemon/linux_daemon.dart' as linux_daemon;
import 'pal_server/pal_commands.dart' as pal_commands;
import 'sqlite_database/sqlite_database.dart';
import 'whitelist.dart';

class PALTespServer with TespRequestHandlerMixin {
  TespServer _tespServer;
  final _whitelist = Whitelist();

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
      print('storeEvent: $e');
      await database.insertEvent(e);
    }
  }

  // PAL Commands

  @override
  FutureOr<TespResponse> palAddEvents(List<Event> events) async {
    print('palAddEvents: $events');
    if (await pal_commands.isWhitelistedDataOnly()) {
      await _storeEvent(_whitelist.blackOutData(events));
    } else {
      await _storeEvent(events);
    }
    unawaited(SyncService.syncData());
    return TespResponseSuccess();
  }

  @override
  FutureOr<TespResponse> palPause() async {
    print('pause');
    await pal_commands.pauseDataUpload();
    return TespResponseSuccess();
  }

  @override
  FutureOr<TespResponse> palResume() async {
    print('resume');
    await pal_commands.resumeDataUpload();
    return TespResponseSuccess();
  }

  @override
  FutureOr<TespResponse> palWhiteListDataOnly() async {
    print('whiteListDataOnly');
    await pal_commands.setWhitelistedDataOnly();
    return TespResponseSuccess();
  }

  @override
  FutureOr<TespResponse> palAllData() async {
    print('allData');
    await pal_commands.setAllDataOnly();
    return TespResponseSuccess();
  }

  // Alarm/Notification RPC

  @override
  FutureOr<TespResponse> alarmSchedule() async {
    await linux_daemon.handleScheduleAlarm();
    return TespResponseSuccess();
  }

  @override
  FutureOr<TespResponse> alarmCancel(int alarmId) async {
    await linux_daemon.handleCancelAlarm(alarmId);
    return TespResponseSuccess();
  }

  @override
  FutureOr<TespResponse> notificationCheckActive() async {
    await linux_daemon.handleScheduleAlarm();
    return TespResponseSuccess();
  }

  @override
  FutureOr<TespResponse> notificationCancel(int notificationId) async {
    await linux_daemon.handleCancelNotification(notificationId);
    return TespResponseSuccess();
  }

  @override
  FutureOr<TespResponse> notificationCancelByExperiment(int experimentId) async {
    await linux_daemon.handleCancelExperimentNotification(experimentId);
    return TespResponseSuccess();
  }

  @override
  FutureOr<TespResponse> createMissedEvent(Event event) async {
    await linux_daemon.handleCreateMissedEvent(event);
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
    return TespResponseAnswer(jsonEncode(experiment));
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
    return TespResponseAnswer(jsonEncode(experiments));
  }
}
