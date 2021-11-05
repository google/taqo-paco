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

const _alerterBinary = '/Applications/Taqo.app/Contents/MacOS/alerter';
const _bundleId = '/com.taqo.survey.taqoClient';

final _logger = Logger('AlerterNotifications');

// On-going notification ids
final _notifications = <int>[];

void _listen(int id, List<int> event) {
  final json = jsonDecode(String.fromCharCodes(event));
  switch (json['activationType']) {
    case 'closed':
      // noop
      break;
    case 'actionClicked':
    case 'contentsClicked':
      daemon.openSurvey(id);
      break;
  }
}

Future<void> cancel(int id) async {
  if (!_notifications.contains(id)) {
    return;
  }

  _notifications.remove(id);
  await Process.start(_alerterBinary, ['-remove', '$id'],
      mode: ProcessStartMode.inheritStdio);
}

Future<int> notify(int id, String title, String body, {int timeout = 0}) async {
  _logger.info("Launching alerter for ${id}");
  await Process.start(_alerterBinary, [
    '-title', title, //
    '-message', body,
    '-timeout', '$timeout',
    '-sender', _bundleId,
    '-group', '$id',
    '-json',
  ]).then((Process p) {
    p.stdout.listen((List<int> event) {
      _listen(id, event);
    });
    p.stderr.listen((List<int> err) {
      _logger
          .warning('Error posting notification: ${String.fromCharCodes(err)}');
    });
  });

  _notifications.add(id);
  return id;
}
