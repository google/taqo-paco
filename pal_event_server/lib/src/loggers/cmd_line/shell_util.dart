import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart';

final _logger = Logger('ShellUtil');

const _beginTaqo = '# Begin Taqo\n';
const _endTaqo = '# End Taqo\n';
const _bashPromptCommand = r"""
RETURN_VAL=$?;echo "{\"pid\":$$,\"cmd_raw\":\"$(history 1 | sed "s/^[ ]*[0-9]*[ ]*\(\[\([^]]*\)\]\)*[ ]*//")\",\"cmd_ret\":$RETURN_VAL}" >> ~/.taqo/command.log""";
const _zshPreCmd = r"""
precmd() { eval 'RETURN_VAL=$?;echo "{\"pid\":$$,\"cmd_raw\":$(history | tail -1 | sed "s/^[ ]*[0-9]*[ ]*//"),\"cmd_ret\":$RETURN_VAL}" >> /tmp/log' }""" + '\n';

Future<bool> enableCmdLineLogging() async {
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
    _logger.warning(e);
    ret = false;
  }

  final zshrc = File(join(Platform.environment['HOME'], '.zshrc'));
  try {
    // TODO Could we check for an existing function definition?
    await zshrc.writeAsString(_beginTaqo, mode: FileMode.append);
    await zshrc.writeAsString(_zshPreCmd, mode: FileMode.append);
    await zshrc.writeAsString(_endTaqo, mode: FileMode.append);
  } on Exception catch (e) {
    _logger.warning(e);
    ret = false;
  }

  return ret;
}

Future<bool> disableCmdLineLogging() async {
  Future<bool> disable(String shrc) async {
    final withTaqo = File(join(Platform.environment['HOME'], shrc));
    final withoutTaqo = File(join(Directory.systemTemp.path, shrc));
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
      await withoutTaqo.copy(join(Platform.environment['HOME'], shrc));
    } on Exception catch (e) {
      _logger.warning(e);
      return false;
    }
    return true;
  }

  var ret = await disable('.bashrc');
  ret = ret && await disable('.zshrc');
  return ret;
}
