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
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';

import '../daemon.dart' as daemon;

import 'package:meta/meta.dart';

final _logger = Logger('DbusNotifications');

const _objectPath = '/org/freedesktop/Notifications';
const _dest = 'org.freedesktop.Notifications';
const _notifyMethod = 'org.freedesktop.Notifications.Notify';
const _cancelMethod = 'org.freedesktop.Notifications.CloseNotification';

const _actionInvoked = 'org.freedesktop.Notifications.ActionInvoked';
const _notificationClosed = 'org.freedesktop.Notifications.NotificationClosed';

final _actionPattern = RegExp(
    "$_objectPath:\\s+$_actionInvoked\\s+\\(uint32\\s+(\\d+),\\s+'([a-zA-Z]+)'");
final _closedPattern = RegExp(
    "$_objectPath:\\s+$_notificationClosed\\s+\\(uint32\\s+(\\d+),\\s+uint32\\s+(\\d+)");

const _defaultActions = <String>[
  'default',
  'Open Taqo',
  '',
];

// Map between Taqo database notification id and libnotify id
@visibleForTesting
var notifications = <int, int>{};

void openSurvey(id) {
  daemon.openSurvey(id);
}

@visibleForTesting
void listen(String event) {
  _logger.info('Event:${event}');
  final action = _actionPattern.matchAsPrefix(event);
  
  if (action != null && notifications.keys.isNotEmpty) {
    _logger.info('action: id: ${action[1]} action: ${action[2]}');
    if (action.groupCount >= 2 && _defaultActions.contains(action[2])) {
      final notifId = int.tryParse(action[1]);
      if (notifId != null) {
        // Not super efficient, but fine for now
        final id =
            notifications.keys.firstWhere((k) => notifications[k] == notifId, orElse: () => null);
	if (id != null) {
	  openSurvey(id);
	}
      }
    }
  }

  final closed = _closedPattern.matchAsPrefix(event);
  if (closed != null) {
    // TODO Handle?
    _logger.info('closed: id: ${closed[1]} reason: ${closed[2]}');
  }
}

Future<void> cancel(int id) async {
  final notifId = notifications[id];
  if (notifId == null) return;
  notifications.remove(id);

  await Process.run('gdbus', [
    'call', //
    '--session',
    '--dest', _dest,
    '--object-path', _objectPath,
    '--method', _cancelMethod,
    '$notifId',
  ]);
}

void monitor() {
  Process.start('gdbus', [
    'monitor', //
    '--session',
    '--dest', _dest,
    '--object-path', _objectPath,
  ]).then((Process process) {
    //stdout.addStream(process.stdout);
    //stderr.addStream(process.stderr);
    Utf8Codec().decoder.bind(process.stdout).listen(listen);
  });
}

enum Priority {
  low,
  normal,
  critical,
}

String _priorityToString(Priority p) => '<byte ${p.index}>';

String _parseActions(List<String> actions) =>
    '[' + actions.map((String a) => '"$a"').join(', ') + ']';

String _parseHints(Map<String, dynamic> hints) {
  final sb = StringBuffer();
  sb.write('{');
  for (var h in hints.entries) {
    sb.write('"${h.key}"');
    sb.write(': ');
    if (h.value is Priority) {
      sb.write(_priorityToString(h.value));
    } else {
      // TODO Support more types
      sb.write('"{h.value}"');
    }
  }
  sb.write('}');
  return sb.toString();
}

String _parseTimeout(int timeout) => 'int32 $timeout';

Future<int> notify(
    int id, String appName, int replaceId, String title, String body,
    {String iconPath = '',
    List<String> actions = _defaultActions,
    Map<String, dynamic> hints = const {'urgency': Priority.critical},
    int timeout = 0}) async {
  final processResult = await Process.run('gdbus', [
    'call', //
    '--session',
    '--dest', _dest,
    '--object-path', _objectPath,
    '--method', _notifyMethod,
    appName,
    '$replaceId',
    iconPath,
    title,
    body,
    _parseActions(actions),
    _parseHints(hints),
    _parseTimeout(timeout),
  ]);

  final idString = processResult.stdout;
  final notifId = int.tryParse(
      RegExp(r'\(uint32 (\d+),\)').matchAsPrefix(idString)?.group(1));
  notifications[id] = notifId;
  return notifId;
}
