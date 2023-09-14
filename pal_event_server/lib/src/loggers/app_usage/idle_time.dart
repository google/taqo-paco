// Copyright 2023 Google LLC
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

import 'dart:io';

import 'package:logging/logging.dart';

final _logger = Logger('IdleTime');

RegExp pattern = RegExp(r'"HIDIdleTime" = (\d+)');

Future<double> getIdleSecondsMacOS() async {
  final result = await Process.run('ioreg', ['-rc' 'IOHIDSystem']);
  final match = pattern.firstMatch(result.stdout);
  if (match == null || match[1] == null) {
    _logger.warning('Cannot get idle time.');
    return 0;
  }
  return int.parse(match[1]!) / 1000000000;
}

Future<double> getIdleSecondsLinux() async {
  final result = await Process.run('xprintidle', []);
  final milliseconds = int.tryParse(result.stdout) ?? 0;
  return milliseconds / 1000;
}

Future<double> getIdleSeconds() async {
  if (Platform.isMacOS) {
    return await getIdleSecondsMacOS();
  } else if (Platform.isLinux) {
    return await getIdleSecondsLinux();
  } else {
    _logger.warning('Unsupported platform: ${Platform.operatingSystem}.');
    return 0;
  }
}

Future<bool> isIdle() async => (await getIdleSeconds()) > 300;
