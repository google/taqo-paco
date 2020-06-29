import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:taqo_common/model/event.dart';

import '../loggers/loggers.dart';
import '../loggers/app_usage/app_logger.dart';
import '../loggers/cmd_line/cmdline_logger.dart';
import '../sqlite_database/sqlite_database.dart';
import 'macos_alarm_manager.dart' as macos_alarm_manager;
import 'macos_notification_manager.dart' as macos_notification_manager;

final _logger = Logger('MacOSDaemon');

void openSurvey(int id) {
  // Note: this will only work if Taqo is installed
  print('openSurvey $id');
  Process.start('open', ['/Applications/taqo_client.app']).then((Process process) {
    //stdout.addStream(process.stdout);
    //stderr.addStream(process.stderr);
  });

  // TODO: If the app is running, just notify it to open a survey
}

void handleCreateMissedEvent(Event event) async {
  final database = await SqliteDatabase.get();
  database.insertEvent(event);
}

Future<bool> handleCheckActiveNotification() async {
  final database = await SqliteDatabase.get();
  final activeNotifications = (await database.getAllNotifications())
      .where((n) => n.isActive);
  return activeNotifications.isNotEmpty;
}

void handleCancelNotification(int id) {
  macos_notification_manager.cancelNotification(id);
}

void handleCancelExperimentNotification(int id) {
  macos_notification_manager.cancelForExperiment(id);
}

void handleCancelAlarm(int id) {
  macos_alarm_manager.cancel(id);
}

void handleScheduleAlarm() async {
  macos_alarm_manager.scheduleNextNotification();

  // 'schedule' is called when we join, pause, un-pause, and leave experiments,
  // the experiment schedule is edited, or the time zone changes.
  // Configure app loggers appropriately here
  final experimentsToLog = await getExperimentsToLog();
  if (experimentsToLog.isNotEmpty) {
    // Found a non-paused experiment
    AppLogger().start(experimentsToLog);
    CmdLineLogger().start(experimentsToLog);
  } else {
    AppLogger().stop(experimentsToLog);
    CmdLineLogger().stop(experimentsToLog);
  }
}

void start() async {
  _logger.info('Starting macos daemon');

  // Schedule
  handleScheduleAlarm();
}
