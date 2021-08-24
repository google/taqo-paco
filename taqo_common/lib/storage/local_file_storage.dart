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

abstract class ILocalFileStorage {
  Future<Directory> get localStorageDir;

  Future<String> get localPath;

  Future<File> get localFile;

  Future clear();
}

typedef LocalFileStorageFactoryFunction = ILocalFileStorage Function(String);

class LocalFileStorageFactory {
  static LocalFileStorageFactoryFunction _factory;
  static Directory _localStorageDirectory;
  static bool _isInitialized = false;

  static Directory get localStorageDirectory => _localStorageDirectory;
  static bool get isInitialized => _isInitialized;

  static void initialize(LocalFileStorageFactoryFunction factory,
      Directory localStorageDirectory) {
    _factory = factory;
    _localStorageDirectory = localStorageDirectory;
    _isInitialized = true;
  }

  static ILocalFileStorage makeLocalFileStorage(String filename) {
    return _factory(filename);
  }
}
