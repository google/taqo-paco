// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// @dart=2.9

import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path show join;

import 'package:taqo_common/storage/dart_file_storage.dart';

final _logger = Logger('ShellUtil');

const _beginTaqo = '# Begin Taqo';
const _endTaqo = '# End Taqo';

const _logfileName = 'command.log';

String getLogCmdPath() {
  if (Platform.isLinux) {
    return '/usr/lib/taqo/logcmd';
  } else if (Platform.isMacOS) {
    return '/Applications/Taqo.app/Contents/MacOS/logcmd';
  } else {
    throw UnsupportedError(
        'Desktop platform other than Linux and macOS is not supported');
  }
}

String getBashPreexecPath() {
  if (Platform.isLinux) {
    return '/usr/lib/taqo/third_party/bash-preexec/bash-preexec.sh';
  } else if (Platform.isMacOS) {
    return '/Applications/Taqo.app/Contents/Resources/third_party/bash-preexec/bash-preexec.sh';
  } else {
    throw UnsupportedError(
        'Desktop platform other than Linux and macOS is not supported');
  }
}

final scripts = '__taqo_log_cmd="${getLogCmdPath()}"\n'
    r'''
preexec_log_command() {
  if [[ "$1" == *\& ]]; then
    __taqo_bfg=bg
    unset __taqo_need_log_precmd
  else
    __taqo_bfg=fg
    __taqo_need_log_precmd=1
  fi
  $__taqo_log_cmd start "$1" "$$" "$__taqo_bfg"
}

precmd_log_status() {
  __taqo_last_ret="$?"
  if [[ "$__taqo_need_log_precmd" == 1 ]]; then
    $__taqo_log_cmd end "$$" "$__taqo_last_ret"
    unset __taqo_need_log_precmd
  fi
}

preexec_functions+=(preexec_log_command)
precmd_functions+=(precmd_log_status)
''';

Future<bool> enableCmdLineLogging() async {
  await disableCmdLineLogging();

  bool ret = true;

  final bashrc = File(path.join(DartFileStorage.getHomePath(), '.bashrc'));

  try {
    if (await bashrc.exists()) {
      await bashrc
          .copy(path.join(DartFileStorage.getHomePath(), '.bashrc.taqo_bak'));
    } else {
      await bashrc.create();
    }

    await bashrc.writeAsString('$_beginTaqo\n', mode: FileMode.append);
    await bashrc.writeAsString(
        r'if [[ -z "${bash_preexec_imported:-}" ]] && [[ -z "${__bp_imported}" ]]; then'
        '\n  source ${getBashPreexecPath()}\n'
        'fi\n',
        mode: FileMode.append);
    await bashrc.writeAsString(scripts, mode: FileMode.append);

    await bashrc.writeAsString('export PS1="🔴\$PS1"\n', mode: FileMode.append);
    await bashrc.writeAsString('$_endTaqo\n', mode: FileMode.append);
  } on Exception catch (e) {
    _logger.warning(e);
    ret = false;
  }

  final zshrc = File(path.join(DartFileStorage.getHomePath(), '.zshrc'));

  try {
    if (await zshrc.exists()) {
      await zshrc
          .copy(path.join(DartFileStorage.getHomePath(), '.zshrc.taqo_bak'));
    } else {
      await zshrc.create();
    }

    await zshrc.writeAsString('$_beginTaqo\n', mode: FileMode.append);
    await zshrc.writeAsString(scripts, mode: FileMode.append);
    await zshrc.writeAsString('export PROMPT="🔴\$PROMPT"\n',
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
    final withTaqo = File(path.join(DartFileStorage.getHomePath(), shrc));
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
      await withoutTaqo.copy(path.join(DartFileStorage.getHomePath(), shrc));
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
