import 'dart:async';
import 'dart:convert';

import 'package:taqo_client/storage/base_database.dart';
import 'package:taqo_common/model/action_specification.dart';
import 'package:taqo_common/model/event.dart';
import 'package:taqo_common/model/experiment.dart';
import 'package:taqo_common/model/notification_holder.dart';
import 'package:taqo_event_server_protocol/taqo_event_server_protocol.dart';

import '../service/platform_service.dart' as global;

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
  }

  @override
  Future<int> insertNotification(NotificationHolder notificationHolder) {
  }

  @override
  Future<NotificationHolder> getNotification(int id) {
    return global.tespClient.then((tespClient) async {
      final TespResponseAnswer response =
          await tespClient.notificationSelectById(id);
      return NotificationHolder.fromJson(response.payload);
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
  Future<void> removeNotification(int id) {
  }

  @override
  Future<void> removeAllNotifications() {
  }

  @override
  Future<int> insertAlarm(ActionSpecification actionSpecification) {
  }

  @override
  Future<ActionSpecification> getAlarm(int id) {
    return global.tespClient.then((tespClient) async {
      final TespResponseAnswer response =
          await tespClient.alarmSelectById(id);
      return ActionSpecification.fromJson(response.payload);
    });
  }

  @override
  Future<Map<int, ActionSpecification>> getAllAlarms() {
    return global.tespClient.then((tespClient) async {
      final TespResponseAnswer response =
          await tespClient.alarmSelectAll();
      final Map map = jsonDecode(response.payload);
      return Map.fromIterable(map.entries,
          key: (entry) => entry.key,
          value: (entry) => ActionSpecification.fromJson(entry.value));
    });
  }

  @override
  Future<void> removeAlarm(int id) {
  }

  @override
  Future<Iterable<Event>> getUnuploadedEvents() {
  }

  @override
  Future<void> markEventsAsUploaded(Iterable<Event> events) {
  }
}
