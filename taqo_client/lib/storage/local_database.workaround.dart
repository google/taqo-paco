// This is only a temporary workaround

part of 'local_database.dart';

Future<Event> _createEventFromColumnValueMap(
    Database db, Map<String, dynamic> map) async {
  var event = Event()
    ..id = map['_id']
    ..experimentId = map['experiment_id']
    ..experimentName = map['experiment_name']
    ..experimentVersion = map['experiment_version']
    ..scheduleTime = (map['schedule_time'] == null
        ? null
        : ZonedDateTime.fromIso8601String(map['schedule_time']))
    ..responseTime = (map['response_time'] == null
        ? null
        : ZonedDateTime.fromIso8601String(map['response_time']))
    ..uploaded = (map['uploaded'] == 1)
    ..groupName = map['group_name']
    ..actionTriggerId = map['action_trigger_id']
    ..actionTriggerSpecId = map['action_trigger_spec_id']
    ..actionId = map['action_id'];
  var responsesColumnValueMaps = await db.query('outputs',
      columns: ['text', 'answer'], where: 'event_id=?', whereArgs: [event.id]);
  event.responses = Map.fromIterable(responsesColumnValueMaps,
      key: (columnValueMap) => columnValueMap['text'],
      value: (columnValueMap) => columnValueMap['answer']);

  return event;
}
