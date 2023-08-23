// Copyright 2023 Google LLC
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

import 'dart:io';

import 'package:taqo_common/model/shell_command_log.dart';
import 'package:taqo_common/rpc/rpc_constants.dart';
import 'package:taqo_common/util/zoned_date_time.dart';
import 'package:taqo_event_server_protocol/taqo_event_server_protocol.dart';

// This program should always exit with code 0, since it will be invoked in
// pre_cmd and pre_exec hooks, where a non-zero exit code will basically disable
// the user's terminal.
Future<void> main(List<String> arguments) async {
  final tespClient = TespEventClient(localServerHost, localServerPort);
  try {
    await tespClient.connect();
  } catch (e, st) {
    displayError(e, st);
    exit(0);
  }
  ShellCommandLog cmdLog;
  if (arguments.length == 4 && arguments[0] == 'start') {
    cmdLog = ShellCommandStart(
        timestamp: ZonedDateTime.now(),
        command: arguments[1],
        shellPid: int.parse(arguments[2]),
        isBackground: arguments[3] == 'bg');
  } else if (arguments.length == 3 && arguments[0] == 'end') {
    cmdLog = ShellCommandEnd(
        timestamp: ZonedDateTime.now(),
        shellPid: int.parse(arguments[1]),
        exitCode: int.parse(arguments[2]));
  } else {
    final executable = Platform.script.pathSegments.last;
    stderr.write('''This message is for debug/test only. 
If you see it as a user, please file a bug at
https://github.com/google/taqo-paco/issues
or contact the Taqo authors.

Usage:
$executable start <command> <shell-pid> fg|bg
or
$executable end <shell-pid> <exit-code>
''');
    exit(0);
  }
  try {
    await tespClient.palLogCmd(cmdLog);
  } catch (e, st) {
    displayError(e, st);
  }
  exit(0);
}

const _start_server_linux = '/usr/bin/taqo_daemon restart';
const _start_server_mac =
    'killall taqo_daemon; open /Applications/Taqo.app/Contents/Library/LoginItems/TaqoLauncher.app';

String getStartServerCmd() {
  if (Platform.isMacOS) {
    return _start_server_mac;
  }
  return _start_server_linux;
}

void displayError(e, st) {
  stderr.write('$e\n');
  stderr.write('$st\n');
  stderr.write(
      '''Taqo's shell tracer cannot connect to the Taqo server. To restart the Taqo server, please run
  ${getStartServerCmd()}
To manually disable Taqo's shell tracer, remove the line that sources 
  <taqo-lib-dir>/scripts/logger.bash or <taqo-lib-dir>/scripts/logger.zsh
in ~/.bashrc or ~/.zshrc, respectively, and restart the shell.
Please contact the Taqo authors if you have any questions.
''');
}
