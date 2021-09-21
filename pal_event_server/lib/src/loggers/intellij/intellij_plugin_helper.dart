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

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as path;
import 'package:taqo_common/platform/platform.dart';

const intelliJAssetPaths = {
  PlatformOs.linux: '/usr/lib/taqo/pal_intellij_plugin.zip',
  PlatformOs.macos:
      '/Applications/Taqo.app/Contents/Frameworks/App.framework/Resources/flutter_assets/assets/pal_intellij_plugin.zip'
};
final homeDir = Directory(Platform.environment['HOME']);

final searchPaths = {
  PlatformOs.linux: [
    Directory(path.join(homeDir.path, '.local', 'share')),
    Directory(path.join(homeDir.path, '.local', 'share', 'JetBrains')),
    Directory(path.join(homeDir.path, '.local', 'share', 'Google'))
  ],
  PlatformOs.macos: [
    Directory(path.join(homeDir.path, 'Library', 'Application Support')),
    Directory(
        path.join(homeDir.path, 'Library', 'Application Support', 'JetBrains')),
    Directory(
        path.join(homeDir.path, 'Library', 'Application Support', 'Google')),
  ]
};

final intelliJPaths = [
  //RegExp(r'\.?AndroidStudio(?:WithBlaze)?\d+\.\d+'),
  RegExp(r'\.?IdeaIC\d{4}\.\d+'),
];

String getPluginDir(Directory dir) {
  if (Platform.isLinux) {
    return dir.path;
  } else if (Platform.isMacOS) {
    return path.join(dir.path, 'plugins');
  }
}

void extractIntelliJPlugin(String directory) async {
  final zipFile =
      await File(intelliJAssetPaths[Platform.operatingSystem]).readAsBytes();
  final pluginPkg = ZipDecoder().decodeBytes(zipFile);

  for (var item in pluginPkg) {
    final output = path.join(directory, item.name);
    if (item.isFile) {
      final itemBytes = item.content as List<int>;
      final f = File(output);
      await f.create(recursive: true);
      await f.writeAsBytes(itemBytes);
    } else {
      final d = Directory(output);
      await d.create(recursive: true);
    }
  }
}

void enableIntelliJPlugin() async {
  for (var toCheck in searchPaths[Platform.operatingSystem]) {
    await for (var dir in toCheck.list()) {
      final baseDir = path.basename(dir.path);

      for (var idePath in intelliJPaths) {
        if (idePath.hasMatch(baseDir)) {
          await extractIntelliJPlugin(getPluginDir(dir));
        }
      }
    }
  }
}

void disableIntelliJPlugin() async {
  for (var toCheck in searchPaths[Platform.operatingSystem]) {
    await for (var dir in toCheck.list()) {
      final baseDir = path.basename(dir.path);

      for (var idePath in intelliJPaths) {
        if (idePath.hasMatch(baseDir)) {
          var d =
              Directory(path.join(getPluginDir(dir), 'pal_intellij_plugin'));
          if (await d.exists()) {
            await d.delete(recursive: true);
          }
        }
      }
    }
  }
}
