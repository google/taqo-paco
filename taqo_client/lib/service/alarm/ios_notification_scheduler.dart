import 'dart:async';

import '../../model/notification_holder.dart';
import '../../scheduling/action_schedule_generator.dart';
import '../../storage/local_database.dart';
import '../experiment_service.dart';
import 'flutter_local_notifications.dart' as flutter_local_notifications;
import 'taqo_alarm.dart' as taqo_alarm;

const _maxNotifications = 64;

Future<int> _clearExpiredNotifications() async {
  final pendingNotifications = await LocalDatabase().getAllNotifications();
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
  final pendingNotifications = await LocalDatabase().getAllNotifications();
  var max = DateTime.now().millisecondsSinceEpoch;
  pendingNotifications.forEach((element) {
    if (element.alarmTime > max) {
      max = element.alarmTime;
    }
  });
  final dt = DateTime.fromMillisecondsSinceEpoch(max);

  final alarms = await getNextNAlarmTimes(n: count, now: dt);
  for (var a in alarms) {
    await flutter_local_notifications.scheduleNotification(a, cancelPending: false);
  }
}
