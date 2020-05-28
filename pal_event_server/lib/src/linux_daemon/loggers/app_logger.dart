import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:taqo_common/model/event.dart';

import 'loggers.dart';
import 'pal_event_helper.dart';
import 'xprop_util.dart' as xprop;

const _queryInterval = const Duration(seconds: 1);

String _lastResult;

// Isolate entry point must be a top-level function (or static?)
// Query xprop for the active window
void _appLoggerIsolate(SendPort sendPort) {
  Timer.periodic(_queryInterval, (Timer _) {
    // Gets the active window ID
    Process.run(xprop.command, xprop.getIdArgs).then((result) {
      // Parse the window ID
      final windowId = xprop.parseWindowId(result.stdout);
      if (windowId != xprop.invalidWindowId) {
        // Gets the active window name
        Process.run(xprop.command, xprop.getAppArgs(windowId)).then((result) {
          final res = result.stdout;
          if (res != _lastResult) {
            _lastResult = res;
            final resultMap = xprop.buildResultMap(res);
            if (resultMap != null) {
              sendPort.send(resultMap);
            }
          }
        });
      }
    });
  });
}

class AppLogger extends PacoEventLogger {
  static const Object _isolateDiedObj = Object();
  static AppLogger _instance;

  // Port for the main Isolate to receive msg from AppLogger Isolate
  ReceivePort _receivePort;
  // Background Isolate that will poll for the active window
  Isolate _isolate;

  // List of Events that should be sent to PAL
  final _eventsToSend = <Event>[];

  AppLogger._();

  factory AppLogger() {
    if (_instance == null) {
      _instance = AppLogger._();
    }
    return _instance;
  }

  @override
  void start() async {
    if (active) {
      return;
    }

    print('Starting AppLogger');
    _receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_appLoggerIsolate, _receivePort.sendPort);
    _isolate.addOnExitListener(_receivePort.sendPort, response: _isolateDiedObj);
    _receivePort.listen(_listen);
    active = true;

    Timer.periodic(sendInterval, (Timer t) {
      final events = List.of(_eventsToSend);
      _eventsToSend.clear();
      sendToPal(events, t);
    });
  }

  @override
  void stop() {
    print('Stopping AppLogger');
    active = false;
    _isolate?.kill();
    _receivePort?.close();
  }

  void _listen(dynamic data) async {
    if (data == _isolateDiedObj) {
      // The Isolate died
      _isolate?.kill();
      _receivePort?.close();
      if (active) {
        start();
      }
      return;
    }

    if (data is Map && data.isNotEmpty) {
      _eventsToSend.addAll(
          await createLoggerPacoEvents(data, pacoEventCreator: createAppUsagePacoEvent));
    }
  }
}
