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

import 'package:test/test.dart';
import 'package:pal_event_server/src/loggers/intellij/intellij_plugin_helper.dart';

void main() {
  group('All', () {
    test('extractVersionRepFromPluginFile', () {
      expect(extractVersionRepFromPluginFile('paco256.png'), isNull);
      expect(extractVersionRepFromPluginFile('pal_intellij_plugin-203.6682.168.zip'), equals('203'));
    });

    test('extractVersionRepFromIdeSupportFolder', () {
      expect(extractVersionRepFromIdeSupportFolder('consentOptions'), isNull);
      expect(extractVersionRepFromIdeSupportFolder('CLion2020.1'), isNull);
      expect(extractVersionRepFromIdeSupportFolder('IdeaIC2020.1'), equals('201'));
      expect(extractVersionRepFromIdeSupportFolder('IdeaIU2021.2'), equals('212'));
      expect(extractVersionRepFromIdeSupportFolder('AndroidStudioPreview2021.1'), equals('211'));
      expect(extractVersionRepFromIdeSupportFolder('AndroidStudioWithBlaze2020.3'), equals('203'));
      expect(extractVersionRepFromIdeSupportFolder('AndroidStudio4.2'), equals('202'));
      expect(extractVersionRepFromIdeSupportFolder('AndroidStudio4.1'), isNull);
    });
  });
}
