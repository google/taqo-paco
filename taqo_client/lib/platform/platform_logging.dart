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

import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

final _logger = Logger('MethodChannel.Logging');

const _platform = MethodChannel('com.taqo.survey.taqosurvey/logging');

void setupLoggingMethodChannel() {
  _platform.setMethodCallHandler((MethodCall call) async {
    switch (call.method) {
      case 'log':
        var arguments = call.arguments as Map;
        _log(arguments['level'], arguments['message']);
        break;
      default:
        throw MissingPluginException();
    }
  });
}

final stringLevelMap =
    Map.fromIterable(Level.LEVELS, key: (e) => e.name, value: (e) => e);
void _log(String level, String message) {
  _logger.log(stringLevelMap[level], message);
}
