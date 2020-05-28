import 'dart:async';

import 'package:taqo_common/model/event.dart';
import 'package:taqo_common/model/experiment.dart';
import 'package:taqo_common/storage/dart_file_storage.dart';
import 'package:taqo_common/util/zoned_date_time.dart';
import 'package:taqo_shared_prefs/taqo_shared_prefs.dart';

import '../../sqlite_database/sqlite_database.dart';
import '../../utils.dart';
import 'xprop_util.dart' as xprop;

typedef CreateEventFunc = Future<Event> Function(
    Experiment experiment, String groupname, Map<String, dynamic> response);

Future<List<Event>> createLoggerPacoEvents(Map<String, dynamic> response,
    {CreateEventFunc pacoEventCreator}) async {
  final events = <Event>[];

  final storageDir = DartFileStorage.getLocalStorageDir().path;
  final sharedPrefs = TaqoSharedPrefs(storageDir);
  final experiments = await readJoinedExperiments();

  for (var e in experiments) {
    final paused = await sharedPrefs.getBool("${sharedPrefsExperimentPauseKey}_${e.id}");
    if (e.isOver() || (paused ?? false)) {
      continue;
    }

    for (var g in e.groups) {
      if (g.isAppUsageLoggingGroup) {
        events.add(await pacoEventCreator(e, g.name, response));
      }
    }
  }

  return events;
}

const _participantId = 'participantId';

const _responseName = 'name';
const _responseAnswer = 'answer';

Event _createPacoEvent(Experiment experiment, String groupName) {
  var group;
  try {
    group = experiment.groups.firstWhere((g) => g.name == groupName);
  } catch (e) {
    print('Failed to get experiment group $groupName for $experiment');
  }

  final event = Event.of(experiment, group);
  event.responseTime = ZonedDateTime.now();

  event.responses = <String, dynamic>{
      _responseName: _participantId,
      _responseAnswer: 'TODO:participantId',
  };

  return event;
}

const _appsUsedKey = 'apps_used';
const _appContentKey = 'app_content';
const _appsUsedRawKey = 'apps_used_raw';

Future<Event> createAppUsagePacoEvent(Experiment experiment, String groupName,
    Map<String, dynamic> response) async {
  final event = await _createPacoEvent(experiment, groupName);
  final responses = <String, dynamic>{
      _appsUsedKey: response[xprop.appNameField],
      _appContentKey: response[xprop.windowNameField],
      _appsUsedRawKey: '${response[xprop.appNameField]}:${response[xprop.windowNameField]}',
  };
  event.responses.addAll(responses);
  return event;
}

const _uidKey = 'uid';
const _pidKey = 'pid';
const _cmdRawKey = 'cmd_raw';
const _cmdRetKey = 'cmd_ret';

Future<Event> createCmdUsagePacoEvent(Experiment experiment, String groupName,
    Map<String, dynamic> response) async {
  final event = await _createPacoEvent(experiment, groupName);
  final responses = <String, String>{
      _uidKey: response[_uidKey],
      _pidKey: '${response[_pidKey]}',
      _cmdRetKey: '${response[_cmdRetKey]}',
      _cmdRawKey: response[_cmdRawKey].trim(),
  };
  event.responses.addAll(responses);
  return event;
}

void storePacoEvent(List<Event> events) async {
  final database = await SqliteDatabase.get();
  for (var e in events) {
    print('storeEvent: $e');
    await database.insertEvent(e);
  }
}
