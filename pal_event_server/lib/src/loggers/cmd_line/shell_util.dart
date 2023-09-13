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

String getTaqoLibPath() {
  if (Platform.isLinux) {
    return '/usr/lib/taqo';
  } else if (Platform.isMacOS) {
    return '/Applications/Taqo.app/Contents/Resources';
  } else {
    throw UnsupportedError(
        'Desktop platform other than Linux and macOS is not supported');
  }
}

final _source_taqo = 'source ${getTaqoLibPath()}/scripts/logger';
final _source_taqo_bash = '${_source_taqo}.bash';
final _source_taqo_zsh = '${_source_taqo}.zsh';
final _source_taqo_fish = '${_source_taqo}.fish';
final _taqo_log_cmd = getLogCmdPath();
final _taqo_lib_dir = getTaqoLibPath();

Future<bool> modifyFishShell(String homeDir) async {
  final fish_config = File(
      path.join(homeDir, '.config/fish/config.fish'));
  print("$homeDir, $fish_config.toString()");
  try {
    if (await fish_config.exists()) {
      await fish_config
          .copy(path.join(
          homeDir, '.config/fish/config.fish.taqo_bak'));
    } else {
      print("creating $fish_config");
      print("creating fish_config $fish_config");
      await fish_config.create(recursive: true);
    }

    await fish_config.writeAsString(
        '$_source_taqo_fish $_taqo_lib_dir $_taqo_log_cmd\n',
        mode: FileMode.append);
  } on Exception catch (e) {
    print("exception $e");
    _logger.warning(e);
    return false;
  }
  return true;
}

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

    await bashrc.writeAsString(
        '$_source_taqo_bash $_taqo_lib_dir $_taqo_log_cmd\n',
        mode: FileMode.append);
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

    await zshrc.writeAsString(
        '$_source_taqo_zsh $_taqo_lib_dir $_taqo_log_cmd\n',
        mode: FileMode.append);
  } on Exception catch (e) {
    _logger.warning(e);
    ret = false;
  }

  ret = await modifyFishShell(DartFileStorage.getHomePath());

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

    try {
      final lines = await withTaqo.readAsLines();
      for (var line in lines) {
        if (!line.startsWith(_source_taqo)) {
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
  var ret3 = await disable('/.config/fish/config.fish');
  return ret1 && ret2 && ret3;
}
