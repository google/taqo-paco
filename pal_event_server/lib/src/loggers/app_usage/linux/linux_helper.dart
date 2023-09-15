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

import '../../pal_event_helper.dart';
import '../app_logger.dart';
import '../idle_time.dart';
import 'xprop_util.dart' as xprop;

String _prevAppAndWindowName;
bool _prevIdleState = false;

// Isolate entry point must be a top-level function (or static?)
// Query xprop for the active window
void linuxAppLoggerIsolate(SendPort sendPort) {
  Timer.periodic(queryInterval, (Timer _) {
    try {
      // Gets the active window ID
      Process.run(xprop.command, xprop.getIdArgs).then((result) {
        // Parse the window ID
        final windowId = xprop.parseWindowId(result.stdout);
        if (windowId != xprop.invalidWindowId) {
          // Gets the active window name and idle state
          Future.wait([
            Process.run(xprop.command, xprop.getAppArgs(windowId)),
            isIdle()
          ]).then((result) {
            final currWindow = (result[0] as ProcessResult).stdout;
            final idleState = result[1];
            final resultMap = xprop.buildResultMap(currWindow);
            String currApp = resultMap[appNameField];
            String currWindowName = resultMap[windowNameField];
            if (currApp == null) {
              currApp = "UNKNOWN";
            }
            if (currWindowName == null) {
              currWindowName = "UNKNOWN";
            }
            final currAppAndWindowName = currApp + currWindowName;

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
          }).catchError((e, s) {
            print('Exception details:\n $e');
            print('Stack trace:\n $s');
          });
        }
      });
    } catch (e, s) {
      print('Exception details:\n $e');
      print('Stack trace:\n $s');
    }
  });
}
