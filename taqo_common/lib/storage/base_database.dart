// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// @dart=2.9

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

  Future<List<NotificationHolder>> getAllNotificationsForExperiment(
      Experiment experiment);

  Future<void> removeNotification(int id);

  Future<void> removeAllNotifications();

  Future<int> insertAlarm(ActionSpecification actionSpecification);

  Future<ActionSpecification> getAlarm(int id);

  Future<Map<int, ActionSpecification>> getAllAlarms();

  Future<void> removeAlarm(int id);

  Future<Iterable<Event>> getUnuploadedEvents();

  Future<void> markEventsAsUploaded(Iterable<Event> events);

  Future<void> saveJoinedExperiments(Iterable<Experiment> experiments);

  Future<List<Experiment>> getJoinedExperiments();

  Future<Experiment> getExperimentById(int experimentId);

  Future<Map<int, bool>> getExperimentsPausedStatus(
      Iterable<Experiment> experiments);

  Future<void> setExperimentPausedStatus(Experiment experiment, bool paused);
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
