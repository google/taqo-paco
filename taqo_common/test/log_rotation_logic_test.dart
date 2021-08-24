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

import 'package:test/test.dart';
import 'package:taqo_common/service/logging_service.dart';

void main() {
  group('Filtering old logs based on sorting filenames', () {
    const _MAX_LOG_FILES_COUNT = 3;
    test('Number of log files exceed limit', () {
      expect(
          LoggingService.filterOldLogFileNames([
            'fcc4d8/server-2020-01-11.log',
            'fcc4d8/server-2020-01-10.log',
            'fcc4d8/server-2020-01-14.log',
            'fcc4d8/server-2020-01-12.log',
            'fcc4d8/server-2020-01-09.log',
            'fcc4d8/server-2020-01-13.log'
          ], maxLogFilesCount: _MAX_LOG_FILES_COUNT),
          equals([
            'fcc4d8/server-2020-01-09.log',
            'fcc4d8/server-2020-01-10.log',
            'fcc4d8/server-2020-01-11.log'
          ]));
    });
    test('Number of log files within limit', () {
      expect(
          LoggingService.filterOldLogFileNames([
            'fcc4d8/server-2020-01-14.log',
            'fcc4d8/server-2020-01-12.log',
            'fcc4d8/server-2020-01-13.log'
          ], maxLogFilesCount: _MAX_LOG_FILES_COUNT),
          equals([]));
      expect(
          LoggingService.filterOldLogFileNames(
              ['fcc4d8/server-2020-01-14.log', 'fcc4d8/server-2020-01-13.log'],
              maxLogFilesCount: _MAX_LOG_FILES_COUNT),
          equals([]));
    });
  });
}
