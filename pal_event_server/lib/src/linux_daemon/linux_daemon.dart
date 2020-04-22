import 'dart:async';
import 'dart:io';

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:taqo_common/model/event.dart';
import 'package:taqo_common/rpc/socket_channel.dart';
import 'package:taqo_common/rpc/rpc_constants.dart';

import '../sqlite_database/sqlite_database.dart';
import 'loggers/loggers.dart';
import 'loggers/app_logger.dart';
import 'loggers/cmdline_logger.dart';
import 'dbus_notifications.dart' as dbus;
import 'linux_alarm_manager.dart' as linux_alarm_manager;
import 'linux_notification_manager.dart' as linux_notification_manager;

json_rpc.Peer _peer;

void openSurvey(int id) {
  try {
    // If the app is running, just notify it to open a survey
    _peer.sendNotification(openSurveyMethod, {'id': id,});
  } catch (e) {
    // Else launch the app and it will automatically open the survey
    // Note: this will only work if Taqo is in the user's PATH
    // For debugging/testing, maybe create a symlink in /usr/local/bin pointing to
    // build/linux/debug/taqo_survey
    Process.run('taqo_survey', []);
  }
}

void _handleCreateMissedEvent(json_rpc.Parameters args) async {
  final event = (args.asMap)['event'];
  final database = await SqliteDatabase.get();
  database.insertEvent(Event.fromJson(event));
}

Future<bool> _handleCheckActiveNotification(json_rpc.Parameters args) async {
  final database = await SqliteDatabase.get();
  final activeNotifications = (await database.getAllNotifications())
      .where((n) => n.isActive);
  return activeNotifications.isNotEmpty;
}

void _handleCancelNotification(json_rpc.Parameters args) {
  final id = (args.asMap)['id'];
  linux_notification_manager.cancelNotification(id);
}

void _handleCancelExperimentNotification(json_rpc.Parameters args) {
  final id = (args.asMap)['id'];
  linux_notification_manager.cancelForExperiment(id);
}

void _handleCancelAlarm(json_rpc.Parameters args) {
  final id = (args.asMap)['id'];
  linux_alarm_manager.cancel(id);
}

void _handleScheduleAlarm(json_rpc.Parameters args) async {
  linux_alarm_manager.scheduleNextNotification();

  // 'schedule' is called when we join, pause, un-pause, and leave experiments,
  // the experiment schedule is edited, or the time zone changes.
  // Configure app loggers appropriately here
  if (await shouldStartLoggers()) {
    // Found a non-paused experiment
    AppLogger().start();
    CmdLineLogger().start();
  } else {
    AppLogger().stop();
    CmdLineLogger().stop();
  }
}

void start(Socket socket) async {
  print('Starting linux daemon');

  // Monitor DBus for notification actions
  dbus.monitor();

  _peer = json_rpc.Peer(SocketChannel(socket), onUnhandledError: (e, st) {
    print('linux_daemon socket error: $e');
  });

  _peer.registerMethod(scheduleAlarmMethod, _handleScheduleAlarm);
  _peer.registerMethod(cancelAlarmMethod, _handleCancelAlarm);
  _peer.registerMethod(cancelNotificationMethod, _handleCancelNotification);
  _peer.registerMethod(cancelExperimentNotificationMethod, _handleCancelExperimentNotification);
  _peer.registerMethod(checkActiveNotificationMethod, _handleCheckActiveNotification);

  _peer.registerMethod(createMissedEventMethod, _handleCreateMissedEvent);
  _peer.listen();

  _peer.done.then((_) {
    print('linux_daemon client socket closed');
    _peer = null;
  });
}

void stop() {
  _peer.close();
  _peer = null;
}
