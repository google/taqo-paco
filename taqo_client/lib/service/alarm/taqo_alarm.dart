import 'dart:async';
import 'dart:io';

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;

import '../../linux_daemon/rpc_constants.dart';
import '../../linux_daemon/socket_channel.dart';
import '../../main.dart';
import '../../model/event.dart';
import '../../model/notification_holder.dart';
import '../../pages/running_experiments_page.dart';
import '../../pages/survey/survey_page.dart';
import '../../storage/flutter_file_storage.dart';
import '../../storage/local_database.dart';
import '../../util/date_time_util.dart';
import '../experiment_service.dart';
import 'android_alarm_manager.dart' as android_alarm_manager;
import 'flutter_local_notifications.dart' as flutter_local_notifications;
import 'ios_notification_scheduler.dart' as ios_notification_scheduler;

// For Linux
json_rpc.Peer _peer;
json_rpc.Peer get linuxDaemonPeer => _peer;

Future _linuxInit() async {
  final completer = Completer();
  Socket.connect(localServerHost, localServerPort).then((socket) {
    _peer = json_rpc.Peer(SocketChannel(socket), onUnhandledError: (e, st) {
      print('linux_alarm_manager socket error: $e');
    });

    _peer.registerMethod(openSurveyMethod, _handleOpenSurvey);
    _peer.listen();

    completer.complete();

    _peer.done.then((_) {
      print('linux_alarm_manager socket closed');
      _peer = null;
    });
  }).catchError((e) {
    print('Failed to connect to the Linux daemon. Is it running?');
    _peer = null;
  });
  return completer.future;
}

Future init() {
  // Init the actual notification plugins
  if (Platform.isLinux) {
    return _linuxInit().then((_) => schedule(cancelAndReschedule: false));
  } else {
    return flutter_local_notifications.init().then((_) => schedule(cancelAndReschedule: false));
  }
}

Future schedule({bool cancelAndReschedule=true}) async {
  // TODO schedule alarms in background
  // TODO the calculate() API currently doesn't support using plugins
  if (Platform.isAndroid) {
    android_alarm_manager.scheduleNextNotification();
  } else if (Platform.isIOS || Platform.isMacOS) {
    if (cancelAndReschedule) {
      await flutter_local_notifications.cancelAllNotifications();
    }
    ios_notification_scheduler.schedule();
  } else if (Platform.isLinux) {
    try {
      _peer.sendNotification(scheduleAlarmMethod);
    } catch (e) {
      print(e);
    }
  }
}

Future cancel(int id) async {
  if (Platform.isAndroid) {
    flutter_local_notifications.cancelNotification(id);
  } else if (Platform.isIOS || Platform.isMacOS) {
    await flutter_local_notifications.cancelNotification(id);
    await schedule(cancelAndReschedule: false);
  } else if (Platform.isLinux) {
    try {
      _peer.sendNotification(cancelNotificationMethod, {'id': id,});
    } catch (e) {
      print(e);
    }
  }
}

Future timeout(int id) async {
  final storage = await LocalDatabase.get(FlutterFileStorage(LocalDatabase.dbFilename));
  _createMissedEvent(await storage.getNotification(id));
  if (Platform.isAndroid) {
    return flutter_local_notifications.cancelNotification(id);
  }
}

void _handleOpenSurvey(json_rpc.Parameters args)  {
  final id = (args.asMap)['id'];
  openSurvey('$id');
}

/// Open the survey that triggered the notification
Future<void> openSurvey(String payload) async {
  final id = int.tryParse(payload);
  final storage = await LocalDatabase.get(FlutterFileStorage(LocalDatabase.dbFilename));
  final notificationHolder = await storage.getNotification(id);

  if (notificationHolder == null) {
    print('No holder for payload: $payload');
    return;
  }

  // TODO Timezone could have changed?
  if (!notificationHolder.isActive && !notificationHolder.isFuture) {
    await timeout(id);
    MyApp.navigatorKey.currentState.pushReplacementNamed(
        RunningExperimentsPage.routeName, arguments: [true, ]);
    return;
  }

  try {
    final service = await ExperimentService.getInstance();
    final e = service
        .getJoinedExperiments()
        .firstWhere((e) => e.id == notificationHolder.experimentId);
    e.groups.firstWhere((g) => g.name == notificationHolder.experimentGroupName);
    MyApp.navigatorKey.currentState.pushReplacementNamed(SurveyPage.routeName,
        arguments: [e, notificationHolder.experimentGroupName]);
  } on StateError catch (e, stack) {
    print('StateError: $e');
    print(stack);
  }
}

void _createMissedEvent(NotificationHolder notification) async {
  if (notification == null) return;
  print('_createMissedEvent: ${notification.id}');
  final service = await ExperimentService.getInstance();
  final experiment = await service.getExperimentFromServerById(notification.experimentId);
  final event = Event();
  event.experimentId = experiment.id;
  event.experimentServerId = experiment.id;
  event.experimentName = experiment.title;
  event.groupName = notification.experimentGroupName;
  event.actionId = notification.actionId;
  event.actionTriggerId = notification.actionTriggerId;
  event.actionTriggerSpecId = notification.actionTriggerSpecId;
  event.experimentVersion = experiment.version;
  event.scheduleTime = getZonedDateTime(DateTime.fromMillisecondsSinceEpoch(notification.alarmTime));
  final storage = await LocalDatabase.get(FlutterFileStorage(LocalDatabase.dbFilename));
  storage.insertEvent(event);
}
