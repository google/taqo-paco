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

import 'dart:io';

import 'package:path/path.dart' as path;

import '../storage/local_file_storage.dart';

class DartFileStorage implements ILocalFileStorage {
  final _localFileName;

  static String getHomePath() {
    if (Platform.isMacOS) {
      return '${Platform.environment['HOME']}/../../../..';
    } else {
      return '${Platform.environment['HOME']}';
    }
  }

  // These should match whatever Flutter path_provider returns
  // Is there a better way to keep them in sync?
  static Directory getLocalStorageDir() {
    if (Platform.isLinux) {
      return Directory('${getHomePath()}/.local/share/taqo')
        ..createSync(recursive: true);
    } else if (Platform.isMacOS) {
      // Process.run("logger", ['${Platform.environment['HOME']}']);
      return Directory(
          '${getHomePath()}/Library/Group Containers/com.taqo/Library/Application Support/com.taqo')
        ..createSync(recursive: true);
    }

    throw UnsupportedError('Only supported on desktop platforms');
  }

  Future<Directory> get localStorageDir async => getLocalStorageDir();

  Future<String> get localPath async => (await localStorageDir).path;

  Future<File> get localFile async {
    final f = File(path.join(await localPath, _localFileName));
    if (!(await f.exists())) {
      await f.create();
    }
    await Process.run('chmod', [
      '0600',
      f.path,
    ]);
    return f;
  }

  DartFileStorage(this._localFileName);

  Future clear() async {
    final file = await localFile;
    if (await file.exists()) {
      await file.delete();
    }
  }
}
