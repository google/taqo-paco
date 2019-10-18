// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_database.dart';

var _dbVersion = 1;

Future<void> _onCreate(Database db, int version) async {
  await db.execute('''CREATE TABLE events (
_id INTEGER PRIMARY KEY AUTOINCREMENT,
experiment_id INTEGER, 
experiment_server_id INTEGER, 
experiment_name TEXT, 
experiment_version INTEGER, 
schedule_time INTEGER, 
response_time INTEGER, 
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
}

Future<void> _insertEvent(Database db, Event event) async {
  try {
    db.transaction((txn) async {
      event.id = await txn.insert(
        'events',
        {
          'experiment_id': event.experimentId,
          'experiment_server_id': event.experimentServerId,
          'experiment_name': event.experimentName,
          'experiment_version': event.experimentVersion,
          'schedule_time': event.scheduleTime,
          'response_time': event.responseTime,
          'uploaded': event.uploaded,
          'group_name': event.groupName,
          'action_trigger_id': event.actionTriggerId,
          'action_trigger_spec_id': event.actionTriggerSpecId,
          'action_id': event.actionId,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      var batch = txn.batch();
      for (var entry in event.responses.entries) {
        batch.insert(
          'outputs',
          {
            'event_id': event.id,
            'text': entry.key,
            'answer': entry.value,
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
