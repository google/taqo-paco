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

// @dart=2.9
import 'dart:io';

import 'package:test/test.dart';
import 'package:pal_event_server/src/loggers/cmd_line/shell_util.dart';
import 'package:path/path.dart' as path show join;
import 'package:taqo_common/storage/dart_file_storage.dart';

// TODO(#190) Remove tech debt
void main() {
  group('All', ()
  {
    test('creates a fish config file', () async {
      Directory tmp = Directory("/tmp");
      Directory tmpHome = tmp.createTempSync("testshellutil");
      File expectedFishFile = File(path.join(tmpHome.path, ".config/fish/config.fish"));
      expect(expectedFishFile.existsSync(), isFalse);
      try {
        bool result = await addCmdLoggingToFishShellConfigFile(tmpHome.path);
        expect(result, isTrue);
        expect(expectedFishFile.existsSync(), isTrue);
        String expectedFileContent = expectedFishFile.readAsStringSync();
        expect(expectedFileContent, equals("set taqologcmd /usr/lib/taqo/logcmd\n" +
                "source /usr/lib/taqo/scripts/logger.fish\n"));
      } finally {
        tmpHome.delete(recursive: true);
      }
    });
    test('modifies an existing fish config file', () async {
      Directory tmp = Directory("/tmp");
      Directory tmpHome = tmp.createTempSync("testshellutil");
      try {
        File expectedFishFile = File(path.join(tmpHome.path, ".config/fish/config.fish"));
        await expectedFishFile.create(recursive:true);
        expect(expectedFishFile.existsSync(), isTrue);
        var previousContent = '# previous line in file';
        await expectedFishFile.writeAsString(
            previousContent+"\n",
            mode: FileMode.append);
        bool result = await addCmdLoggingToFishShellConfigFile(tmpHome.path);
        expect(result, isTrue);
        expect(expectedFishFile.existsSync(), isTrue);
        String expectedFileContent = expectedFishFile.readAsStringSync();
        expect(expectedFileContent, equals("$previousContent\n"
            "set taqologcmd /usr/lib/taqo/logcmd\n" +
            "source /usr/lib/taqo/scripts/logger.fish\n"));
      } finally {
        tmpHome.delete(recursive: true);
      }
    });
    test('deletes a fish config file', () async {
      Directory tmp = Directory("/tmp");
      Directory tmpHome = tmp.createTempSync("testshellutil");
      File expectedFishFile = File(path.join(tmpHome.path, ".config/fish/config.fish"));
      expect(expectedFishFile.existsSync(), isFalse);
      try {
        bool result = await addCmdLoggingToFishShellConfigFile(tmpHome.path);
        expect(result, isTrue);
        expect(expectedFishFile.existsSync(), isTrue);
        String expectedFileContent = expectedFishFile.readAsStringSync();
        expect(expectedFileContent, equals("set taqologcmd /usr/lib/taqo/logcmd\n" +
            "source /usr/lib/taqo/scripts/logger.fish\n"));

        bool restored = await removeCmdLoggingFromFishShellConfigFile(tmpHome.path);
        expect(restored, isFalse, reason: "There should be no file since there was none before.");
        expect(expectedFishFile.existsSync(), isFalse);
      } finally {
        tmpHome.delete(recursive: true);
      }
    });
    test('restores a previous fish config file', () async {
      Directory tmp = Directory("/tmp");
      Directory tmpHome = tmp.createTempSync("testshellutil");
      try {
        File expectedFishFile = File(path.join(tmpHome.path, ".config/fish/config.fish"));
        await expectedFishFile.create(recursive:true);
        expect(expectedFishFile.existsSync(), isTrue);
        var previousContent = '# previous line in file';
        await expectedFishFile.writeAsString(
            previousContent+"\n",
            mode: FileMode.append);
        bool result = await addCmdLoggingToFishShellConfigFile(tmpHome.path);
        expect(result, isTrue);
        expect(expectedFishFile.existsSync(), isTrue);
        String expectedFileContent = expectedFishFile.readAsStringSync();
        expect(expectedFileContent, equals("$previousContent\n"
            "set taqologcmd /usr/lib/taqo/logcmd\n" +
            "source /usr/lib/taqo/scripts/logger.fish\n"));
        bool restored = await removeCmdLoggingFromFishShellConfigFile(tmpHome.path);
        expect(restored, isTrue);
        expect(expectedFishFile.existsSync(), isTrue);
        String expectedOldFileContent = expectedFishFile.readAsStringSync();
        expect(expectedOldFileContent, equals("$previousContent\n"));
      } finally {
        tmpHome.delete(recursive: true);
      }
    });
  });
}