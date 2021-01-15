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

import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';

import 'local_file_storage.dart';

final _logger = Logger('UnsecureTokenStorage');

class UnsecureTokenStorage {
  static const filename = 'tokens.txt';

  static Completer<UnsecureTokenStorage> _completer;
  static UnsecureTokenStorage _instance;

  ILocalFileStorage _storageImpl;

  UnsecureTokenStorage._();

  static Future<UnsecureTokenStorage> get(ILocalFileStorage storageImpl) {
    if (_completer != null && !_completer.isCompleted) {
      return _completer.future;
    }
    if (_instance == null) {
      _completer = Completer<UnsecureTokenStorage>();
      final temp = UnsecureTokenStorage._();
      temp._initialize(storageImpl).then((_) {
        _instance = temp;
        _completer.complete(_instance);
      });
      return _completer.future;
    }
    return Future.value(_instance);
  }

  Future _initialize(ILocalFileStorage storageImpl) async {
    _storageImpl = storageImpl;
  }

  Future<List<String>> readTokens() async {
    try {
      final file = await _storageImpl.localFile;
      if (await file.exists()) {
        String contents = await file.readAsString();
        var variables = contents.split("\n");
        if (variables.length == 3) {
          return variables;
        }
      }
      _logger.info("token file does not exist or is corrupted");
      return null;
    } catch (e) {
      _logger.warning("Error loading token: $e");
      return null;
    }
  }

  Future<File> saveTokens(
          String refreshToken, String accessToken, DateTime expiry) async =>
      (await _storageImpl.localFile).writeAsString(
          "$refreshToken\n$accessToken\n${expiry.toIso8601String()}");

  Future clear() => _storageImpl.clear();
}
