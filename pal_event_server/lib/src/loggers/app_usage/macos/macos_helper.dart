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
import 'dart:io';
import 'dart:isolate';

import '../idle_time.dart';

import '../../pal_event_helper.dart';
import '../app_logger.dart';
import 'apple_script_util.dart' as apple_script;

String _prevAppAndWindowName;
bool _prevIdleState;

// Isolate entry point must be a top-level function (or static?)
// Run Apple Script for the active window
void macOSAppLoggerIsolate(SendPort sendPort) {
  Timer.periodic(queryInterval, (Timer _) {
    try {
      Future.wait([
        Process.run(apple_script.command, apple_script.scriptArgs),
        isIdle()
      ]).then((result) {
        final currWindow = (result[0] as ProcessResult).stdout.trim();
        final idleState = result[1];
        if (currWindow != '') {
          final resultMap = apple_script.buildResultMap(currWindow);
          final currAppAndWindowName =
              resultMap[appNameField] + resultMap[windowNameField];

          if (currAppAndWindowName != _prevAppAndWindowName ||
              idleState != _prevIdleState) {
            // Send APP_CLOSED
            if (currAppAndWindowName != _prevAppAndWindowName &&
                _prevAppAndWindowName != null &&
                _prevAppAndWindowName.isNotEmpty) {
              sendPort.send(_prevAppAndWindowName);
            }

            _prevAppAndWindowName = currAppAndWindowName;
            _prevIdleState = idleState;

            // Send PacoEvent && APP_USAGE
            if (resultMap != null) {
              resultMap[isIdleField] = idleState;
              sendPort.send(resultMap);
            }
          }
        }
      }).catchError((e, s) {
        print('Exception details:\n $e');
        print('Stack trace:\n $s');
      });
    } catch (e, s) {
      print('Exception details:\n $e');
      print('Stack trace:\n $s');
    }
  });
}
