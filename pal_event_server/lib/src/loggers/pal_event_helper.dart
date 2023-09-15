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

import 'dart:async';

import 'package:logging/logging.dart';
import 'package:pedantic/pedantic.dart';
import 'package:taqo_common/model/event.dart';
import 'package:taqo_common/model/experiment.dart';
import 'package:taqo_common/model/experiment_group.dart';
import 'package:taqo_common/service/sync_service.dart';
import 'package:taqo_common/storage/dart_file_storage.dart';
import 'package:taqo_common/util/zoned_date_time.dart';
import 'package:taqo_shared_prefs/taqo_shared_prefs.dart';

import '../sqlite_database/sqlite_database.dart';
import '../utils.dart';
import 'loggers.dart';

const appNameField = 'WM_CLASS';
const windowNameField = '_NET_WM_NAME';
const urlNameField = '_NET_URL_NAME';
const isIdleField = 'isIdle';

final _logger = Logger('PalEventHelper');

typedef CreateEventFunc = Future<Event> Function(
    Experiment experiment, String groupname, Map<String, dynamic> response);

Future<List<Event>> createLoggerPacoEvents(
    Map<String, dynamic> response,
    List<ExperimentLoggerInfo> info,
    CreateEventFunc pacoEventCreator,
    GroupTypeEnum groupType) async {
  final events = <Event>[];

  final storageDir = DartFileStorage.getLocalStorageDir().path;
  final sharedPrefs = TaqoSharedPrefs(storageDir);

  for (var info in info) {
    final e = info.experiment;
    final paused =
        await sharedPrefs.getBool("${sharedPrefsExperimentPauseKey}_${e.id}");
    if (e.isOver() || (paused ?? false)) {
      continue;
    }

    for (var g in e.groups) {
      if (g.groupType == groupType) {
        events.add(await pacoEventCreator(e, g.name, response));
      }
    }
  }

  return events;
}

const _participantId = 'participantId';
const _responseName = 'name';
const _responseAnswer = 'answer';

Event createPacoEvent(Experiment experiment, String groupName) {
  var group;
  try {
    group = experiment.groups.firstWhere((g) => g.name == groupName);
  } catch (e) {
    _logger
        .warning('Failed to get experiment group $groupName for $experiment');
  }

  final event = Event.of(experiment, group);
  event.responseTime = ZonedDateTime.now();

  event.responses = <String, dynamic>{
    _responseName: _participantId,
    _responseAnswer: '${experiment.participantId}',
  };

  return event;
}

const _loggerStarted = 'started';
const _loggerStopped = 'stopped';

Future<Event> createLoggerStatusPacoEvent(Experiment experiment,
    String groupName, String loggerName, bool status) async {
  final event = await createPacoEvent(experiment, groupName);
  final responses = <String, dynamic>{
    loggerName: status ? _loggerStarted : _loggerStopped,
  };
  event.responses.addAll(responses);
  return event;
}

const appsUsedKey = 'apps_used';
const appContentKey = 'app_content';
const appsUsedRawKey = 'apps_used_raw';
const _isIdleKey ='isIdle';


Future<Event> createAppUsagePacoEvent(Experiment experiment, String groupName,
    Map<String, dynamic> response) async {
  final event = await createPacoEvent(experiment, groupName);
  final responses = <String, dynamic>{
    appsUsedKey: response[appNameField],
    appContentKey: response[windowNameField],
    appsUsedRawKey: '${response[appNameField]}:${response[windowNameField]}',
    _isIdleKey: response[isIdleField],
  };
  event.responses.addAll(responses);
  return event;
}

// TODO(https://github.com/google/taqo-paco/issues/56):
// Remove createCmdUsagePacoEvent and use createShellUsagePacoEvent below instead, after
// we migrate to the new shell usage tracer.
//const _uidKey = 'uid';
const pidKey = 'pid';
const cmdRawKey = 'cmd_raw';
const cmdRetKey = 'cmd_ret';

Future<Event> createCmdUsagePacoEvent(Experiment experiment, String groupName,
    Map<String, dynamic> response) async {
  final event = await createPacoEvent(experiment, groupName);
  final responses = <String, String>{
    //_uidKey: response[_uidKey],
    pidKey: '${response[pidKey]}',
    cmdRetKey: '${response[cmdRetKey]}',
    cmdRawKey: response[cmdRawKey].trim(),
  };
  event.responses.addAll(responses);
  return event;
}

Future<Event> createShellUsagePacoEvent(Experiment experiment, String groupName,
    Map<String, dynamic> response) async {
  final event = await createPacoEvent(experiment, groupName);
  event.responses.addAll(response);
  return event;
}

void storePacoEvent(List<Event> events) async {
  final database = await SqliteDatabase.get();
  for (var e in events) {
    await database.insertEvent(e, notifySyncService: false);
  }
  unawaited(SyncService.syncData());
}
