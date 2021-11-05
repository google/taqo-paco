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
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:taqo_common/model/action_specification.dart';
import 'package:taqo_common/model/notification_holder.dart';
import 'package:taqo_common/service/experiment_service_lite.dart';

import '../sqlite_database/sqlite_database.dart';
import 'alarm_manager.dart' show timeout;
import 'linux/dbus_notifications.dart' as linux_notifications;
import 'macos/alerter_notifications.dart' as macos_notifications;

final _logger = Logger('TaqoNotificationManager');

const _appName = 'Taqo';

/// Shows or schedules a notification with the plugin
Future<int> _notify(ActionSpecification actionSpec,
    {DateTime when, bool cancelPending = true}) async {
  final notificationHolder = NotificationHolder(
    -1, // placeholder, the real ID will be assigned by sqlite
    actionSpec.time.millisecondsSinceEpoch,
    actionSpec.experiment.id,
    0,
    1000 * 60 * actionSpec.action.timeout,
    actionSpec.experimentGroup.name,
    actionSpec.actionTrigger.id,
    actionSpec.action?.id,
    null,
    actionSpec.action == null
        ? "Time to participate"
        : actionSpec.action.msgText,
    actionSpec.actionTriggerSpecId,
  );

  // Cancel existing (pending) notifications for the same survey
  // On Linux, we create the notification at the time of the alarm
  // Therefore we should timeout any pending notifications for the same survey
  // We don't want to do this on iOS where we are aggressively pre-scheduling
  // notifications
  if (cancelPending) {
    final database = await SqliteDatabase.get();
    final pendingNotifications =
        await database.getAllNotificationsForExperiment(actionSpec.experiment);
    await Future.forEach(pendingNotifications, (pn) async {
      if (notificationHolder.sameGroupAs(pn)) {
        timeout(pn.id);
      }
    });
  }

  final database = await SqliteDatabase.get();
  final id = await database.insertNotification(notificationHolder);

  if (Platform.isLinux) {
    await linux_notifications.notify(id, _appName, 0,
        actionSpec.experiment.title, notificationHolder.message);
  } else if (Platform.isMacOS) {
    await macos_notifications.notify(
        id, actionSpec.experiment.title, notificationHolder.message);
  }

  return id;
}

/// Show a notification now
Future<int> showNotification(ActionSpecification actionSpec) async {
  final id = await _notify(actionSpec);
  _logger.info('Showing notification id: $id @ ${actionSpec.time}');
  return id;
}

/// Cancel notification with [id]
Future cancelNotification(int id) async {
  if (Platform.isLinux) {
    await linux_notifications.cancel(id);
  } else if (Platform.isMacOS) {
    await macos_notifications.cancel(id);
  }

  final database = await SqliteDatabase.get();
  return database.removeNotification(id);
}

/// Cancel all notifications for [experiment]
Future cancelForExperiment(int experimentId) async {
  final database = await SqliteDatabase.get();
  final experimentServiceLite =
      await ExperimentServiceLiteFactory.makeExperimentServiceLiteOrFuture();
  return database
      .getAllNotificationsForExperiment(
          await experimentServiceLite.getExperimentById(experimentId))
      .then((List<NotificationHolder> notifications) =>
          notifications.forEach((n) => cancelNotification(n.id)))
      .catchError((e, st) => "Error canceling notifications: $e");
}

/// Cancel all notifications, except ones that fired and are still pending
Future cancelAllNotifications() async {
  final database = await SqliteDatabase.get();
  return database
      .getAllNotifications()
      .then(((List<NotificationHolder> notifications) {
    for (var n in notifications) {
      final dt = DateTime.fromMillisecondsSinceEpoch(n.alarmTime);
      if (dt.isBefore(DateTime.now())) {
        continue;
      }
      cancelNotification(n.id);
    }
  })).catchError((e, st) => "Error canceling notifications: $e");
}
