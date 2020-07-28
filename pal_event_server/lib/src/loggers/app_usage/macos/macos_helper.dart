import 'dart:async';
import 'dart:html';
import 'dart:io';
import 'dart:isolate';

import '../../pal_event_helper.dart';
import '../app_logger.dart';
import 'apple_script_util.dart' as apple_script;

String _prevAppAndWindowName;

// Isolate entry point must be a top-level function (or static?)
// Run Apple Script for the active window
void macOSAppLoggerIsolate(SendPort sendPort) {
  Timer.periodic(queryInterval, (Timer _) {
    Process.run(apple_script.command, apple_script.scriptArgs).then((result) {
      final currWindow = result.stdout.trim();
      final resultMap = apple_script.buildResultMap(currWindow);
      final currAppAndWindowName = resultMap[appNameField] + resultMap[windowNameField];

      if (currAppAndWindowName != _prevAppAndWindowName) {
        // Send APP_CLOSED
        if (_prevAppAndWindowName != null && _prevAppAndWindowName.isNotEmpty) {
          sendPort.send(_prevAppAndWindowName);
        }

        _prevAppAndWindowName = currAppAndWindowName;

        // Send PacoEvent && APP_USAGE
        if (resultMap != null) {
          sendPort.send(resultMap);
        }
      }
    });
  });
}
