import 'dart:async';

import '../../model/notification_holder.dart';
import '../../scheduling/action_schedule_generator.dart';
import '../../storage/local_database.dart';
import 'flutter_local_notifications.dart' as flutter_local_notifications;
import 'taqo_alarm.dart' as taqo_alarm;

const _maxNotifications = 64;

Future<int> _clearExpiredNotifications() async {
  final pendingNotifications = await LocalDatabase().getAllNotifications();
  var count = pendingNotifications.length;

  await Future.forEach(pendingNotifications, (NotificationHolder pn) async {
    if (!pn.isActive) {
      await taqo_alarm.timeout(pn.id);
      count -= 1;
    }
  });

  return count;
}

Future schedule() async {
  final count = await _clearExpiredNotifications();
  print('Scheduling $count notification(s)');

  final alarms = await getNextNAlarmTimes(n: _maxNotifications - count);
  for (var a in alarms) {
    await flutter_local_notifications.scheduleNotification(a, cancelPending: false);
  }
}
