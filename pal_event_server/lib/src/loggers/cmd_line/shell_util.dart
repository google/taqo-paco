import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path show join;

import 'package:taqo_common/storage/dart_file_storage.dart';

final _logger = Logger('ShellUtil');

const _beginTaqo = '# Begin Taqo';
const _endTaqo = '# End Taqo';

const _logfileName = 'command.log';

String getLogLastCommandFunction(String dirPath) {
  final filePath = path.join(dirPath, _logfileName).replaceAll(r" ", r"\ ");
  return r'''
log_last_command () {
  last_command_number=$(fc -l -1 | awk '{print $1}')
  if [[ -n "${last_command_number_old}" && \
        "${last_command_number_old}" != "${last_command_number}" ]]; then
    RETURN_VAL=$?
    echo "{\"pid\":$$,\"cmd_raw\":\"$(fc -l -1 | sed "s/^[ ]*[0-9]*[ ]*\(\[\([^]]*\)\]\)*[ ]*//")\",\"cmd_ret\":$RETURN_VAL}"'''
      ' >> $filePath\n'
      r'''
  fi
  last_command_number_old="$last_command_number"
}
''';
}

Future<bool> enableCmdLineLogging() async {
  await disableCmdLineLogging();

  bool ret = true;

  final existingCommand = Platform.environment['PROMPT_COMMAND'];
  final bashrc = File(path.join(Platform.environment['HOME'], '.bashrc'));

  try {
    // Create it in case the user doesn't have a .bashrc but may use bash anyway
    if (!(await bashrc.exists())) {
      await bashrc.create();
    }

    await bashrc.writeAsString('$_beginTaqo\n', mode: FileMode.append);
    await bashrc.writeAsString(
        getLogLastCommandFunction(DartFileStorage.getLocalStorageDir().path),
        mode: FileMode.append);
    if (existingCommand == null) {
      await bashrc.writeAsString("export PROMPT_COMMAND='log_last_command'\n",
          mode: FileMode.append);
    } else {
      await bashrc.writeAsString(
          "export PROMPT_COMMAND='${existingCommand.trim()};log_last_command'\n",
          mode: FileMode.append);
    }
    await bashrc.writeAsString('$_endTaqo\n', mode: FileMode.append);
  } on Exception catch (e) {
    _logger.warning(e);
    ret = false;
  }

  final zshrc = File(path.join(Platform.environment['HOME'], '.zshrc'));

  try {
    // Create it in case the user doesn't have a .zshrc but may use zsh anyway
    if (!(await zshrc.exists())) {
      await zshrc.create();
    }

    await zshrc.writeAsString('$_beginTaqo\n', mode: FileMode.append);
    await zshrc.writeAsString(
        getLogLastCommandFunction(DartFileStorage.getLocalStorageDir().path),
        mode: FileMode.append);
    await zshrc.writeAsString("precmd_functions+=(log_last_command)\n",
        mode: FileMode.append);
    await zshrc.writeAsString('$_endTaqo\n', mode: FileMode.append);
  } on Exception catch (e) {
    _logger.warning(e);
    ret = false;
  }

  return ret;
}

Future<bool> disableCmdLineLogging() async {
  Future<bool> disable(String shrc) async {
    final withTaqo = File(path.join(Platform.environment['HOME'], shrc));
    final withoutTaqo = File(path.join(Directory.systemTemp.path, shrc));

    try {
      if (await withoutTaqo.exists()) {
        await withoutTaqo.delete();
      }
    } on Exception catch (e) {
      _logger.warning(e);
    }

    var skip = false;
    try {
      final lines = await withTaqo.readAsLines();
      for (var line in lines) {
        if (line == _beginTaqo) {
          skip = true;
        } else if (line == _endTaqo) {
          skip = false;
        } else if (!skip) {
          await withoutTaqo.writeAsString('$line\n', mode: FileMode.append);
        }
      }
      await withTaqo.delete();
      await withoutTaqo.copy(path.join(Platform.environment['HOME'], shrc));
    } on Exception catch (e) {
      if (!(await withoutTaqo.exists())) {
        _logger.warning("Not writing $shrc; file would have been empty");
      } else {
        _logger.warning(e);
      }
      return false;
    }
    return true;
  }

  var ret1 = await disable('.bashrc');
  var ret2 = await disable('.zshrc');
  return ret1 && ret2;
}
