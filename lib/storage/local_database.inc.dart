// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_database.dart';

var _dbVersion = 1;

Future<void> _onCreate(Database db, int version) async {
  await db.execute('''CREATE TABLE experiments (
_id INTEGER PRIMARY KEY AUTOINCREMENT,
server_id INTEGER, 
title TEXT, 
join_date TEXT, 
json TEXT
  );
  ''');
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
input_server_id INTEGER, 
text TEXT, 
answer TEXT
  );
  ''');
}
