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

  CmdLineLogger._() {
    _start();
  }

  factory CmdLineLogger() {
    return _instance;
  }

  void _start() async {
    Timer.periodic(_sendDelay, _sendToPal);
  }

  Future<List<Map<String, dynamic>>> _readLoggedCommands() async {
    final events = <Map<String, dynamic>>[];
    try {
      final file = await File('$taqoDir/command.log');
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

  void _sendToPal(Timer _) {
    _readLoggedCommands().then((events) {
      if (events != null && events.isNotEmpty) {
        sendPacoEvent(events);
      }
    });
  }
}

//void main() {
//  CmdLineLogger();
//}
