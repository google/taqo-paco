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

void main() {
  group('All', ()
  {
    test('creates a fish config file', () async {
      Directory tmp = Directory("/tmp");
      Directory tmpHome = tmp.createTempSync("testshellutil");
      //expect(tmpHome.existsSync(), isFalse);

      File expectedFishFile = File(path.join(tmpHome.path, ".config/fish/config.fish"));
      expect(expectedFishFile.existsSync(), isFalse);
      try {
        bool result = await modifyFishShell(tmpHome.path);
        expect(result, isTrue);
        expect(expectedFishFile.existsSync(), isTrue);
        String expectedFileContent = expectedFishFile.readAsStringSync();
        expect(expectedFileContent, equals("source /usr/lib/taqo/scripts/logger.fish /usr/lib/taqo /usr/lib/taqo/logcmd\n"));
      } finally {
        tmpHome.delete();
      }
    });
  });
}