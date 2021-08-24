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

// @dart=2.9

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
