import 'dart:async';

import 'package:taqo_common/model/action_specification.dart';
import 'package:taqo_common/model/event.dart';
import 'package:taqo_common/model/experiment.dart';
import 'package:taqo_common/model/notification_holder.dart';

abstract class BaseDatabase {
  Future<void> insertEvent(Event event);

  Future<int> insertNotification(NotificationHolder notificationHolder);

  Future<NotificationHolder> getNotification(int id);

  Future<List<NotificationHolder>> getAllNotifications();

  Future<List<NotificationHolder>> getAllNotificationsForExperiment(Experiment experiment);

  Future<void> removeNotification(int id);

  Future<void> removeAllNotifications();

  Future<int> insertAlarm(ActionSpecification actionSpecification);

  Future<ActionSpecification> getAlarm(int id);

  Future<Map<int, ActionSpecification>> getAllAlarms();

  Future<void> removeAlarm(int id);

  Future<Iterable<Event>> getUnuploadedEvents();

  Future<void> markEventsAsUploaded(Iterable<Event> events);
}

typedef DatabaseFactoryFunction = FutureOr<BaseDatabase> Function();

class DatabaseFactory {
  static DatabaseFactoryFunction _factory;

  static void initialize(DatabaseFactoryFunction factory) {
    _factory = factory;
  }

  static FutureOr<BaseDatabase> makeDatabaseOrFuture() {
    return _factory();
  }
}