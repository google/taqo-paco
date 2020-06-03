const beginTransactionCommand = 'begin transaction;';

const commitCommand = 'commit;';

const createAlarmsTable = '''
create table alarms (
  _id integer primary key autoincrement,
  json text
);''';

const createNotificationsTable = '''
create table notifications (
  _id integer primary key autoincrement,
  alarm_time integer, 
  experiment_id integer, 
  notice_count integer, 
  timeout_millis integer, 
  notification_source text, 
  message text, 
  experiment_group_name text, 
  action_trigger_id integer, 
  action_id integer, 
  action_trigger_spec_id integer, 
  snooze_time integer, 
  snooze_count integer
);''';

const createEventsTable = '''
create table events (
  _id integer primary key autoincrement,
  experiment_id integer, 
  experiment_name text, 
  experiment_version integer, 
  schedule_time text, 
  response_time text, 
  uploaded integer, 
  group_name text, 
  action_trigger_id integer, 
  action_trigger_spec_id integer, 
  action_id integer
);''';

const createOutputsTable = '''
create table outputs (
  _id integer primary key autoincrement,
  event_id integer,
  text text,
  answer text
);''';

const createExperimentsTable = '''
create table experiments (
  id integer primary key, 
  json text, 
  joined integer, 
  paused integer
);
''';

const insertAlarmCommand = '''
insert into alarms (
  json
) values (
  ?
);''';

const insertNotificationCommand = '''
insert into notifications (
  alarm_time,
  experiment_id,
  notice_count,
  timeout_millis,
  notification_source,
  message,
  experiment_group_name,
  action_trigger_id,
  action_id,
  action_trigger_spec_id,
  snooze_time,
  snooze_count
) values (
  ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
);''';

const insertEventCommand = '''
insert into events (
  experiment_id,
  experiment_name,
  experiment_version,
  schedule_time,
  response_time,
  uploaded,
  group_name,
  action_trigger_id,
  action_trigger_spec_id,
  action_id
) values (
  ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
)''';

const insertOutputCommand = '''
insert into outputs (
  event_id,
  text,
  answer
) values (
  ?, ?, ?
);''';

const selectAlarmByIdCommand = 'select * from alarms where _id = ?';

const selectAllAlarmsCommand = 'select * from alarms';

const deleteAlarmByIdCommand = 'delete from alarms where _id = ?;';

const selectNotificationByIdCommand = 'select * from notifications where _id = ?';

const selectNotificationByExperimentCommand = 'select * from notifications where experiment_id = ?';

const selectAllNotificationsCommand = 'select * from notifications';

const deleteNotificationByIdCommand = 'delete from notifications where _id = ?;';

const deleteAllNotificationsCommand = 'delete from notifications;';

const selectUnuploadedEventsCommand = 'select * from events where uploaded = 0;';

const selectOutputsCommand = 'select text, answer from outputs where event_id=?;';

const markEventAsUploadedCommand = 'update events set uploaded = 1 where _id = ?;';

const quitAllExperimentsCommand = 'update experiments set joined = 0 where joined = 1;';

const insertOrUpdateJoinedExperimentsCommand = '''
insert into experiments(id, json, joined, paused) values (?, ?, 1, 0)
  on conflict(id) do update set json=excluded.json, joined=1,
  paused=case joined when 0 then 0 else paused end;
''';

const selectExperimentByIdCommand = 'select json from experiments where id = ?;';
const selectJoindExperimentsCommand = 'select json from experiments where joined = 1;';