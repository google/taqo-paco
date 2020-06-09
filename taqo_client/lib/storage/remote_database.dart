import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';

import 'package:taqo_common/model/experiment.dart';
import 'package:taqo_common/storage/base_database.dart';
import 'package:taqo_common/model/action_specification.dart';
import 'package:taqo_common/model/event.dart';
import 'package:taqo_common/model/notification_holder.dart';
import 'package:taqo_event_server_protocol/taqo_event_server_protocol.dart';

import '../service/platform_service.dart' as global;

final logger = Logger('RemoteDatabase');

/// Desktop clients use the PAL event server for all database functions over IPC
class RemoteDatabase extends BaseDatabase {
  static Completer<RemoteDatabase> _completer;
  static RemoteDatabase _instance;

  RemoteDatabase._();

  static Future<RemoteDatabase> get() async {
    if (_completer != null && !_completer.isCompleted) {
      return _completer.future;
    }
    if (_instance == null) {
      _completer = Completer<RemoteDatabase>();
      final temp = RemoteDatabase._();
      await temp._initialize().then((_) {
        _instance = temp;
        _completer.complete(_instance);
      });
      return _completer.future;
    }
    return Future.value(_instance);
  }

  Future _initialize() async {}

  @override
  Future<void> insertEvent(Event event) {
    return global.tespClient.then((tespClient) async {
      tespClient.palAddEventJson(event.toJson());
    });
  }

  @override
  Future<int> insertAlarm(ActionSpecification actionSpecification) {
    // On Linux, alarms and notifications are handled entirely in the
    // linux_daemon. On MacOS (for now), taqo_client handles it
    if (Platform.isMacOS) {
      return global.tespClient.then((tespClient) async {
        final TespResponseAnswer response =
            await tespClient.alarmAdd(actionSpecification);
        return response.payload;
      });
    }
    return Future.value(-1);
  }

  @override
  Future<int> insertNotification(NotificationHolder notificationHolder) {
    // On Linux, alarms and notifications are handled entirely in the
    // linux_daemon. On MacOS (for now), taqo_client handles it
    if (Platform.isMacOS) {
      return global.tespClient.then((tespClient) async {
        final TespResponseAnswer response =
            await tespClient.notificationAdd(notificationHolder);
        return response.payload;
      });
    }
    return Future.value(-1);
  }

  @override
  Future<ActionSpecification> getAlarm(int id) {
    return global.tespClient.then((tespClient) async {
      final TespResponseAnswer response =
      await tespClient.alarmSelectById(id);
      return ActionSpecification.fromJson(jsonDecode(response.payload));
    });
  }

  @override
  Future<Map<int, ActionSpecification>> getAllAlarms() {
    return global.tespClient.then((tespClient) async {
      final TespResponseAnswer response =
      await tespClient.alarmSelectAll();
      final Map map = jsonDecode(response.payload);
      return Map.fromIterable(map.entries,
          key: (entry) => int.parse(entry.key),
          value: (entry) => ActionSpecification.fromJson(entry.value));
    });
  }

  @override
  Future<NotificationHolder> getNotification(int id) {
    return global.tespClient.then((tespClient) async {
      final TespResponseAnswer response =
          await tespClient.notificationSelectById(id);
      return NotificationHolder.fromJson(jsonDecode(response.payload));
    });
  }

  @override
  Future<List<NotificationHolder>> getAllNotifications() {
    return global.tespClient.then((tespClient) async {
      final TespResponseAnswer response =
          await tespClient.notificationSelectAll();
      final List list = jsonDecode(response.payload);
      return list.map((n) => NotificationHolder.fromJson(n)).toList();
    });
  }

  @override
  Future<List<NotificationHolder>> getAllNotificationsForExperiment(
      Experiment experiment) {
    return global.tespClient.then((tespClient) async {
      final TespResponseAnswer response =
          await tespClient.notificationSelectByExperiment(experiment.id);
      final List list = jsonDecode(response.payload);
      return list.map((n) => NotificationHolder.fromJson(n)).toList();
    });
  }

  @override
  Future<void> removeAlarm(int id) {
    // no-op on desktop
  }

  @override
  Future<void> removeNotification(int id) {
    // no-op on desktop
  }

  @override
  Future<void> removeAllNotifications() {
    // no-op on desktop
  }

  @override
  Future<Iterable<Event>> getUnuploadedEvents() {
    // no-op on desktop
  }

  @override
  Future<void> markEventsAsUploaded(Iterable<Event> events) {
    // no-op on desktop
  }

  @override
  Future<void> saveJoinedExperiments(Iterable<Experiment> experiments) async {
    await global.tespClient.then((tespClient) async {
      final TespResponse response = await tespClient.experimentSaveJoined(experiments);
      if (response is TespResponseError) {
        logger.warning('$response');
      }
    });
  }

  @override
  Future<Experiment> getExperimentById(int experimentId) {
    return global.tespClient.then((tespClient) async {
      final TespResponse response = await tespClient.experimentSelectById(experimentId);
      if (response is TespResponseError) {
        logger.warning('$response');
        return null;
      } else {
        return Experiment.fromJson(jsonDecode((response as TespResponseAnswer).payload));
      }
    });
  }

  @override
  Future<List<Experiment>> getJoinedExperiments() {
    return global.tespClient.then((tespClient) async {
      final TespResponse response = await tespClient.experimentSelectJoined();
      if (response is TespResponseError) {
        logger.warning('$response');
        return <Experiment>[];
      } else {
        return (jsonDecode((response as TespResponseAnswer).payload) as List)
            .map((e) => Experiment.fromJson(e)).toList();
      }
    });
  }
}
