import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:taqo_common/model/event.dart';
import 'package:taqo_common/storage/dart_file_storage.dart';

import 'loggers.dart';
import 'pal_event_helper.dart';
import 'shell_util.dart' as shell;

class CmdLineLogger extends PacoEventLogger {
  static CmdLineLogger _instance;

  CmdLineLogger._();

  factory CmdLineLogger() {
    if (_instance == null) {
      _instance = CmdLineLogger._();
    }
    return _instance;
  }

  @override
  void start() async {
    if (active) {
      return;
    }

    print('Starting CmdLineLogger');
    await shell.enableCmdLineLogging();
    active = true;
    Timer.periodic(sendInterval, (Timer t) async {
      final events = await _readLoggedCommands();
      sendToPal(events, t);
    });
  }

  @override
  void stop() async {
    print('Stopping CmdLineLogger');
    await shell.disableCmdLineLogging();
    active = false;
  }

  Future<List<Event>> _readLoggedCommands() async {
    final events = <Event>[];
    try {
      final file = await File('${DartFileStorage.getLocalStorageDir().path}/command.log');
      if (await file.exists()) {
        final lines = await file.readAsLines();
        // TODO race condition here
        await file.delete();
        for (var line in lines) {
          // TODO jsonDecode can fail with special characters in line, e.g. '{'
          events.addAll(await createLoggerPacoEvents(jsonDecode(line),
              pacoEventCreator: createCmdUsagePacoEvent));
        }
        return events;
      }
      print("command.log file does not exist or is corrupted");
    } catch (e) {
      print("Error loading command.log file: $e");
    }
    return events;
  }
}
