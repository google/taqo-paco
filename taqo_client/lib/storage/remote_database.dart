import 'dart:async';

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
  Future<void> insertEvent(Event event) async {
  }

  @override
  Future<int> insertNotification(NotificationHolder notificationHolder) async {
  }

  @override
  Future<NotificationHolder> getNotification(int id) async {
  }

  @override
  Future<List<NotificationHolder>> getAllNotifications() async {
  }

  @override
  Future<List<NotificationHolder>> getAllNotificationsForExperiment(
      Experiment experiment) async {
  }

  @override
  Future<void> removeNotification(int id) async {
  }

  @override
  Future<void> removeAllNotifications() async {
  }

  @override
  Future<int> insertAlarm(ActionSpecification actionSpecification) async {
  }

  @override
  Future<ActionSpecification> getAlarm(int id) async {
  }

  @override
  Future<Map<int, ActionSpecification>> getAllAlarms() async {
  }

  @override
  Future<void> removeAlarm(int id) async {
  }

  @override
  Future<Iterable<Event>> getUnuploadedEvents() async {
  }

  @override
  Future<void> markEventsAsUploaded(Iterable<Event> events) async {
  }
}
