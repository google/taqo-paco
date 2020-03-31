import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../storage/dart_file_storage.dart';
import 'pal_event_client.dart';

// To start:
// bash: export PROMPT_COMMAND='RETURN_VAL=$?;echo "{\"uid\":\"$(whoami)\",\"pid\":$$,\"cmd_raw\":\"$(history 1 | sed "s/^[ ]*[0-9]*[ ]*\[\([^]]*\)\][ ]*//")\",\"ret\":$RETURN_VAL}" >> ~/.taqo/command.log'
// zsh: precmd() { eval 'RETURN_VAL=$?;echo "{\"uid\":\"$(whoami)\",\"pid\":$$,\"cmd_raw\":$(history | tail -1 | sed "s/^[ ]*[0-9]*[ ]*//"),\"ret\":$RETURN_VAL}" >> /tmp/log' }

class CmdLineLogger {
  static const _sendDelay = const Duration(seconds: 11);
  static final _instance = CmdLineLogger._();

  bool _active = false;

  CmdLineLogger._();

  factory CmdLineLogger() {
    return _instance;
  }

  void start() {
    if (_active) return;
    print('Starting CmdLineLogger');
    _active = true;
    Timer.periodic(_sendDelay, _sendToPal);
  }

  void stop() {
    print('Stopping CmdLineLogger');
    _active = false;
  }

  Future<List<Map<String, dynamic>>> _readLoggedCommands() async {
    final events = <Map<String, dynamic>>[];
    try {
      final file = await File('${DartFileStorage.getLocalStorageDir().path}/command.log');
      if (await file.exists()) {
        final lines = await file.readAsLines();
        // TODO race condition here
        await file.delete();
        for (var line in lines) {
          events.add(await createCmdUsagePacoEvent(jsonDecode(line)));
        }
        return events;
      }
      print("command.log file does not exist or is corrupted");
    } catch (e) {
      print("Error loading command.log file: $e");
    }
    return [];
  }

  void _sendToPal(Timer timer) {
    _readLoggedCommands().then((events) {
      if (events != null && events.isNotEmpty) {
        sendPacoEvent(events);
      }
      if (!_active) {
        timer.cancel();
      }
    });
  }
}

//void main() {
//  CmdLineLogger();
//}
