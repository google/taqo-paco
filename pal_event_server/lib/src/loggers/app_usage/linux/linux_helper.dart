import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import '../../pal_event_helper.dart';
import '../app_logger.dart';
import 'xprop_util.dart' as xprop;

String _prevWindowName;

// Isolate entry point must be a top-level function (or static?)
// Query xprop for the active window
void linuxAppLoggerIsolate(SendPort sendPort) {
  Timer.periodic(queryInterval, (Timer _) {
    // Gets the active window ID
    Process.run(xprop.command, xprop.getIdArgs).then((result) {
      // Parse the window ID
      final windowId = xprop.parseWindowId(result.stdout);
      if (windowId != xprop.invalidWindowId) {
        // Gets the active window name
        Process.run(xprop.command, xprop.getAppArgs(windowId)).then((result) {
          final currWindow = result.stdout;
          final resultMap = xprop.buildResultMap(currWindow);
          final currWindowName = resultMap[appNameField];

          if (currWindowName != _prevWindowName) {
            // Send APP_CLOSED
            if (_prevWindowName != null && _prevWindowName.isNotEmpty) {
              sendPort.send(_prevWindowName);
            }

            _prevWindowName = currWindowName;

            // Send PacoEvent && APP_USAGE
            if (resultMap != null) {
              sendPort.send(resultMap);
            }
          }
        });
      }
    });
  });
}
