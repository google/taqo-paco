// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated by package:data_binding_builder|database_inc
// Code template can be found at package:data_binding_builder/src/local_database_builder.dart

part of 'local_database.dart';

var _dbVersion = 1;

Future<void> _onCreate(Database db, int version) async {
  await db.execute('''CREATE TABLE events (
_id INTEGER PRIMARY KEY AUTOINCREMENT,
experiment_id INTEGER, 
experiment_name TEXT, 
experiment_version INTEGER, 
schedule_time TEXT, 
response_time TEXT, 
uploaded INTEGER, 
group_name TEXT, 
action_trigger_id INTEGER, 
action_trigger_spec_id INTEGER, 
action_id INTEGER
  );
  ''');
  await db.execute('''CREATE TABLE outputs (
_id INTEGER PRIMARY KEY AUTOINCREMENT,
event_id INTEGER, 
text TEXT, 
answer TEXT
  );
  ''');
  await db.execute('''CREATE TABLE notifications (
_id INTEGER PRIMARY KEY AUTOINCREMENT,
alarm_time INTEGER, 
experiment_id INTEGER, 
notice_count INTEGER, 
timeout_millis INTEGER, 
notification_source TEXT, 
message TEXT, 
experiment_group_name TEXT, 
action_trigger_id INTEGER, 
action_id INTEGER, 
action_trigger_spec_id INTEGER, 
snooze_time INTEGER, 
snooze_count INTEGER
  );
  ''');
  await db.execute('''CREATE TABLE alarms (
_id INTEGER PRIMARY KEY AUTOINCREMENT,
json TEXT
  );
  ''');
}

Future<void> _insertEvent(Database db, Event event) async {
  try {
    db.transaction((txn) async {
      event.id = await txn.insert(
        'events',
        {
          'experiment_id': event.experimentId,
          'experiment_name': event.experimentName,
          'experiment_version': event.experimentVersion,
          'schedule_time': event.scheduleTime?.toIso8601String(withColon: true),
          'response_time': event.responseTime?.toIso8601String(withColon: true),
          'uploaded': event.uploaded,
          'group_name': event.groupName,
          'action_trigger_id': event.actionTriggerId,
          'action_trigger_spec_id': event.actionTriggerSpecId,
          'action_id': event.actionId,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      var batch = txn.batch();
      for (var responseEntry in event.responses.entries) {
        batch.insert(
          'outputs',
          {
            'event_id': event.id,
            'text': responseEntry.key,
            'answer': responseEntry.value,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  } catch (e) {
    event.id = null;
    rethrow;
  }
}

Future<int> _insertNotification(
    Database db, NotificationHolder notificationHolder) async {
  try {
    return db.transaction((txn) {
      return txn.insert(
        'notifications',
        {
          'alarm_time': notificationHolder.alarmTime,
          'experiment_id': notificationHolder.experimentId,
          'notice_count': notificationHolder.noticeCount,
          'timeout_millis': notificationHolder.timeoutMillis,
          'notification_source': notificationHolder.notificationSource,
          'message': notificationHolder.message,
          'experiment_group_name': notificationHolder.experimentGroupName,
          'action_trigger_id': notificationHolder.actionTriggerId,
          'action_id': notificationHolder.actionId,
          'action_trigger_spec_id': notificationHolder.actionTriggerSpecId,
          'snooze_time': notificationHolder.snoozeTime,
          'snooze_count': notificationHolder.snoozeCount,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  } catch (_) {
    rethrow;
  }
}

Future<int> _removeNotification(Database db, int id) async {
  return db.transaction((txn) {
    return txn.delete('notifications', where: '_id = $id');
  }).catchError((e, st) => null);
}

Future<int> _removeAllNotifications(Database db) async {
  return db.transaction((txn) {
    return txn.delete('notifications');
  }).catchError((e, st) => null);
}

List<NotificationHolder> _buildNotificationHolder(
        List<Map<String, dynamic>> res) =>
    res
        .map((json) => NotificationHolder.fromJson({
              'id': json['_id'],
              'alarmTime': json['alarm_time'],
              'experimentId': json['experiment_id'],
              'noticeCount': json['notice_count'],
              'timeoutMillis': json['timeout_millis'],
              'notificationSource': json['notification_source'],
              'message': json['message'],
              'experimentGroupName': json['experiment_group_name'],
              'actionTriggerId': json['action_trigger_id'],
              'actionId': json['action_id'],
              'actionTriggerSpecId': json['action_trigger_spec_id'],
              'snoozeTime': json['snooze_time'],
              'snoozeCount': json['snooze_count'],
            }))
        .toList(growable: false);

Future<NotificationHolder> _getNotification(Database db, int id) {
  return db.transaction((txn) async {
    List<Map<String, dynamic>> res =
        await txn.query('notifications', where: '_id = $id');
    if (res == null || res.isEmpty) return null;
    return _buildNotificationHolder(res).first;
  }).catchError((e, st) => null);
}

Future<List<NotificationHolder>> _getAllNotifications(Database db) {
  return db.transaction((txn) async {
    List<Map<String, dynamic>> res = await txn.query('notifications');
    if (res == null || res.isEmpty) return <NotificationHolder>[];
    return _buildNotificationHolder(res);
  }).catchError((e, st) => <NotificationHolder>[]);
}

Future<List<NotificationHolder>> _getAllNotificationsForExperiment(
    Database db, int expId) {
  return db.transaction((txn) async {
    List<Map<String, dynamic>> res =
        await txn.query('notifications', where: 'experiment_id = $expId');
    if (res == null || res.isEmpty) return <NotificationHolder>[];
    return _buildNotificationHolder(res);
  }).catchError((e, st) => <NotificationHolder>[]);
}

Future<int> _insertAlarm(
    Database db, ActionSpecification actionSpecification) async {
  try {
    return db.transaction((txn) {
      return txn.insert(
        'alarms',
        {
          'json': jsonEncode(actionSpecification),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  } catch (_) {
    rethrow;
  }
}

Future<ActionSpecification> _getAlarm(Database db, int id) {
  return db.transaction((txn) async {
    List<Map<String, dynamic>> res =
        await txn.query('alarms', where: '_id = $id');
    if (res == null || res.isEmpty) return null;
    return ActionSpecification.fromJson(jsonDecode(res.first['json']));
  }).catchError((e, st) => null);
}

Future<int> _removeAlarm(Database db, int id) async {
  return db.transaction((txn) {
    return txn.delete('alarms', where: '_id = $id');
  }).catchError((e, st) => null);
}

Future<Map<int, ActionSpecification>> _getAllAlarms(Database db) {
  return db.transaction((txn) async {
    List<Map<String, dynamic>> res = await txn.query('alarms');
    if (res == null || res.isEmpty) return <int, ActionSpecification>{};
    int key(as) => as['_id'];
    ActionSpecification value(as) =>
        ActionSpecification.fromJson(jsonDecode(as['json']));
    return Map.fromEntries(res.map((as) => MapEntry(key(as), value(as))));
  }).catchError((e, st) => <int, ActionSpecification>{});
}
