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

Future<void> main(List<String> arguments) async {
  final tespClient = TespEventClient(localServerHost, localServerPort);
  try {
    tespClient.connect();
  } catch (e) {
    exit(1);
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
    stderr.write('''Usage:
$executable start <command> <shell-pid> fg|bg
or
$executable end <shell-pid> <exit-code>
    ''');
    exit(2);
  }
  await tespClient.palLogCmd(cmdLog);
  exit(0);
}
