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

import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:taqo_common/model/event.dart';

import '../loggers/loggers.dart';
import '../sqlite_database/sqlite_database.dart';
import 'alarm_manager.dart' as alarm_manager;
import 'notification_manager.dart' as notification_manager;
import 'linux/dbus_notifications.dart' as linux_notifications;

final _logger = Logger('Daemon');

void openSurvey(int id) {
  // TODO: If the app is running, just notify it to open a survey

  if (Platform.isLinux) {
    // Note: this will only work if Taqo is in the user's PATH
    // For debugging/testing, create a symlink in /usr/local/bin, e.g.
    // sudo ln -sf /path/to/taqo_survey/taqo_client/build/linux/debug/bundle/taqo /usr/local/bin/taqo
    Process.start('taqo', []).then((Process process) {
      //stdout.addStream(process.stdout);
      //stderr.addStream(process.stderr);
    });
  } else if (Platform.isMacOS) {
    // Note: this will only work if Taqo is installed in /Applications
    Process.start('open', ['/Applications/taqo_client.app'])
        .then((Process process) {
      //stdout.addStream(process.stdout);
      //stderr.addStream(process.stderr);
    });
  }
}

void handleCreateMissedEvent(Event event) async {
  final database = await SqliteDatabase.get();
  database.insertEvent(event);
}

Future<bool> handleCheckActiveNotification() async {
  final database = await SqliteDatabase.get();
  final activeNotifications =
      (await database.getAllNotifications()).where((n) => n.isActive);
  return activeNotifications.isNotEmpty;
}

void handleCancelNotification(int id) {
  notification_manager.cancelNotification(id);
}

void handleCancelExperimentNotification(int id) {
  notification_manager.cancelForExperiment(id);
}

void handleCancelAlarm(int id) {
  alarm_manager.cancel(id);
}

void handleScheduleAlarm() {
  alarm_manager.scheduleNextNotification();

  // 'schedule' is called when we join, pause, un-pause, and leave experiments,
  // the experiment schedule is edited, or the time zone changes.
  // Configure app loggers appropriately here
  startOrStopLoggers();
}

void start() async {
  _logger.info('Starting linux daemon');

  if (Platform.isLinux) {
    // Monitor DBus for notification actions
    linux_notifications.monitor();
  }

  // Schedule
  handleScheduleAlarm();
}
