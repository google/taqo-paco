import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'pal_event_client.dart';

const _queryInterval = const Duration(seconds: 1);
const _xpropCommand = 'xprop';
const _xpropGetIdArgs = ['-root', '32x', '\t\$0', '_NET_ACTIVE_WINDOW', ];

const appNameField = 'WM_CLASS';
const windowNameField = '_NET_WM_NAME';
const _xpropNameFields = [appNameField, windowNameField, ];

List<String> _xpropGetAppArgs(int windowId) {
  return ['-id', '$windowId', ] + _xpropNameFields;
}

const _invalidWindowId = -1;
String _lastResult;

/// Query xprop for the active window
void _appLoggerIsolate(SendPort sendPort) {
  final idSplitRegExp = RegExp(r'\s+');
  final fieldSplitRegExp = RegExp(r'\s+=\s+|\n');
  final appSplitRegExp = RegExp(r',\s*');

  int parseWindowId(dynamic result) {
    if (result is String) {
      final windowId = result.split(idSplitRegExp);
      if (windowId.length > 1) {
        return int.tryParse(windowId[1]) ?? _invalidWindowId;
      }
    }
    return _invalidWindowId;
  }

  Map<String, String> buildResultMap(dynamic result) {
    if (result is! String) return null;
    final resultMap = <String, String>{};
    final fields = result.split(fieldSplitRegExp);
    int i = 1;
    for (var name in _xpropNameFields) {
      if (i >= fields.length) break;
      if (name == appNameField) {
        final split = fields[i].split(appSplitRegExp);
        if (split.length > 1) {
          resultMap[name] = split[1].trim().replaceAll('"', '');
        } else {
          resultMap[name] = fields[i].trim().replaceAll('"', '');
        }
      } else {
        resultMap[name] = fields[i].trim().replaceAll('"', '');
      }
      i += 2;
    }
    return resultMap;
  }

  Timer.periodic(_queryInterval, (Timer _) {
    // Gets the active window ID
    Process.run(_xpropCommand, _xpropGetIdArgs).then((result) {
      // Parse the window ID
      final windowId = parseWindowId(result.stdout);
      if (windowId != _invalidWindowId) {
        // Gets the active window name
        Process.run(_xpropCommand, _xpropGetAppArgs(windowId)).then((result) {
          final res = result.stdout;
          if (res != _lastResult) {
            _lastResult = res;
            final resultMap = buildResultMap(res);
            if (resultMap != null) {
              sendPort.send(resultMap);
            }
          }
        });
      }
    });
  });
}

class AppLogger {
  static const _sendDelay = const Duration(seconds: 9);
  static final _instance = AppLogger._();

  ReceivePort _receivePort;
  Isolate _isolate;

  final _eventsToSend = <Map<String, dynamic>>[];

  AppLogger._() {
    _start();
  }

  factory AppLogger() {
    return _instance;
  }

  void _start() async {
    // Port for the main Isolate to receive msg from AppLogger Isolate
    _receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_appLoggerIsolate, _receivePort.sendPort);
    _isolate.addOnExitListener(_receivePort.sendPort, response: null);
    _receivePort.listen(_listen);

    Timer.periodic(_sendDelay, _sendToPal);
  }

  void _listen(dynamic data) {
    // The Isolate died
    if (data == null) {
      _receivePort.close();
      _isolate.kill();
      _start();
      return;
    }

    if (data is Map && data.isNotEmpty) {
      createAppUsagePacoEvent(data).then((event) {
        _eventsToSend.add(event);
      });
    }
  }

  void _sendToPal(Timer _) {
    List<Map<String, dynamic>> events = List.of(_eventsToSend);
    _eventsToSend.clear();
    sendPacoEvent(events);
  }
}

//void main() {
//  AppLogger();
//}
