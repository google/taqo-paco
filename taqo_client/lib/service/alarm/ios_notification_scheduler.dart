import 'dart:async';

import 'package:taqo_common/model/notification_holder.dart';
import 'package:taqo_common/scheduling/action_schedule_generator.dart';
import 'package:taqo_common/storage/esm_signal_storage.dart';

import '../../service/platform_service.dart' as platform_service;
import '../../storage/flutter_file_storage.dart';
import '../experiment_service.dart';
import 'flutter_local_notifications.dart' as flutter_local_notifications;
import 'taqo_alarm.dart' as taqo_alarm;

const _maxNotifications = 64;

Future<int> _clearExpiredNotifications() async {
  final db = await platform_service.databaseImpl;
  final pendingNotifications = await db.getAllNotifications();
  var count = pendingNotifications.length;

  await Future.forEach(pendingNotifications, (NotificationHolder pn) async {
    if (!pn.isActive && !pn.isFuture) {
      await taqo_alarm.timeout(pn.id);
      count -= 1;
    }
  });

  return count;
}

Future schedule() async {
  final count = _maxNotifications - (await _clearExpiredNotifications());
  print('Scheduling $count notification(s)');

  // Find last already scheduled and start scheduling from there
  final db = await platform_service.databaseImpl;
  final pendingNotifications = await db.getAllNotifications();
  var max = DateTime.now().millisecondsSinceEpoch;
  pendingNotifications.forEach((element) {
    if (element.alarmTime > max) {
      max = element.alarmTime;
    }
  });
  final dt = DateTime.fromMillisecondsSinceEpoch(max);

  final service = await ExperimentService.getInstance();
  final experiments = service.getJoinedExperiments();
  final alarms = await getNextNAlarmTimes(FlutterFileStorage(ESMSignalStorage.filename),
      experiments, n: count, now: dt);
  for (var a in alarms) {
    await flutter_local_notifications.scheduleNotification(a, cancelPending: false);
  }
}
