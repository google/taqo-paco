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

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:taqo_common/storage/dart_file_storage.dart';
import 'package:taqo_common/storage/local_file_storage.dart';

class FlutterFileStorage implements ILocalFileStorage {
  final _localFileName;

  static Future<Directory> getLocalStorageDir() async {
    if (Platform.isMacOS) {
      return DartFileStorage.getLocalStorageDir();
    }
    try {
      return await getApplicationSupportDirectory();
    } catch (e) {
      // Workaround to support file storage during tests
      return Directory.systemTemp;
    }
  }

  Future<Directory> get localStorageDir => getLocalStorageDir();

  Future<String> get localPath async => (await localStorageDir).path;

  Future<File> get localFile async =>
      File(path.join(await localPath, _localFileName));

  FlutterFileStorage(this._localFileName);

  Future clear() async {
    final file = await localFile;
    if (await file.exists()) {
      await file.delete();
    }
  }
}
