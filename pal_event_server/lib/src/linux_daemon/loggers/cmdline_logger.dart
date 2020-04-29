import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:taqo_common/storage/dart_file_storage.dart';

import '../pal_event_client.dart';
import 'loggers.dart';

const _beginTaqo = '# Begin Taqo\n';
const _endTaqo = '# End Taqo\n';
const _bashPromptCommand = r"""
RETURN_VAL=$?;echo "{\"uid\":\"$(whoami)\",\"pid\":$$,\"cmd_raw\":\"$(history 1 | sed "s/^[ ]*[0-9]*[ ]*\[\([^]]*\)\][ ]*//")\",\"cmd_ret\":$RETURN_VAL}" >> ~/.taqo/command.log""";
const _zshPreCmd = r"""
precmd() { eval 'RETURN_VAL=$?;echo "{\"uid\":\"$(whoami)\",\"pid\":$$,\"cmd_raw\":$(history | tail -1 | sed "s/^[ ]*[0-9]*[ ]*//"),\"cmd_ret\":$RETURN_VAL}" >> /tmp/log' }""" + '\n';

Future<bool> _enableCmdLineLogging() async {
  bool ret = true;

  final existingCommand = Platform.environment['PROMPT_COMMAND'];
  final bashrc = File(join(Platform.environment['HOME'], '.bashrc'));
  try {
    await bashrc.writeAsString(_beginTaqo, mode: FileMode.append);
    if (existingCommand == null) {
      await bashrc.writeAsString("export PROMPT_COMMAND='$_bashPromptCommand'\n",
          mode: FileMode.append);
    } else {
      await bashrc.writeAsString("export PROMPT_COMMAND='${existingCommand.trim()};$_bashPromptCommand'\n",
          mode: FileMode.append);
    }
    await bashrc.writeAsString(_endTaqo, mode: FileMode.append);
  } on Exception catch (e) {
    print(e);
    ret = false;
  }

  final zshrc = File(join(Platform.environment['HOME'], '.zshrc'));
  try {
    // TODO Could we check for an existing function definition?
    await zshrc.writeAsString(_beginTaqo, mode: FileMode.append);
    await zshrc.writeAsString(_zshPreCmd, mode: FileMode.append);
    await zshrc.writeAsString(_endTaqo, mode: FileMode.append);
  } on Exception catch (e) {
    print(e);
    ret = false;
  }

  return ret;
}

Future<bool> _disableCmdLineLogging() async {
  Future<bool> disable(String shFile) async {
    final withTaqo = File(join(Platform.environment['HOME'], shFile));
    final withoutTaqo = File(join(Directory.systemTemp.path, shFile));
    if (await withoutTaqo.exists()) {
      await withoutTaqo.delete();
    }

    var skip = false;
    try {
      final lines = await withTaqo.readAsLines();
      for (var line in lines) {
        if (line == _beginTaqo.trim()) {
          skip = true;
        } else if (line == _endTaqo.trim()) {
          skip = false;
        } else if (!skip) {
          await withoutTaqo.writeAsString('$line\n', mode: FileMode.append);
        }
      }
      await withTaqo.delete();
      await withoutTaqo.copy(join(Platform.environment['HOME'], shFile));
    } on Exception catch (e) {
      print(e);
      return false;
    }
    return true;
  }

  var ret = await disable('.bashrc');
  ret = ret && await disable('.zshrc');
  return ret;
}

class CmdLineLogger {
  static const _sendDelay = const Duration(seconds: 11);
  static final _instance = CmdLineLogger._();

  bool _active = false;

  CmdLineLogger._();

  factory CmdLineLogger() {
    return _instance;
  }

  void start() async {
    if (_active) return;
    print('Starting CmdLineLogger');
    await _enableCmdLineLogging();
    _active = true;
    Timer.periodic(_sendDelay, _sendToPal);
  }

  void stop() async {
    print('Stopping CmdLineLogger');
    await _disableCmdLineLogging();
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
          // TODO Handle special characters in line
          events.addAll(await createLoggerPacoEvents(jsonDecode(line), createCmdUsagePacoEvent));
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
