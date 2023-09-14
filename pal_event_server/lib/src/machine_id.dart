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

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:taqo_common/storage/local_file_storage.dart';
import 'package:uuid/uuid.dart';

final _logger = Logger('MachineId');

class MachineId {
  static String _machineId = "";

  static Future<void> initialize() async {
    final uuidFile = File(
        path.join(LocalFileStorageFactory.localStorageDirectory.path, 'uuid'));

    if (await uuidFile.exists()) {
      _machineId = (await uuidFile.readAsString()).trim();
    } else {
      final uuid = Uuid();
      _machineId = uuid.v4();
      await uuidFile.writeAsString(_machineId + '\n');
    }
    _logger.info('Machine ID: $_machineId');
  }

  static String get() => _machineId;
}
