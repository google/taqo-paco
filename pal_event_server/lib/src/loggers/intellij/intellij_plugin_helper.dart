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
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:taqo_common/platform/platform.dart';

final _logger = Logger('IntelliJPluginHelper');

const intelliJAssetDirs = {
  PlatformOs.linux: '/usr/lib/taqo/',
  PlatformOs.macos:
      '/Applications/Taqo.app/Contents/Frameworks/App.framework/Resources/flutter_assets/assets/'
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
  RegExp(r'\.?(AndroidStudio[A-Za-z]*)(\d+\.\d+)'),
  RegExp(r'\.?(IdeaI[CU])(\d{4}\.\d+)'),
];

String getPluginDir(Directory dir) {
  if (Platform.isLinux) {
    return dir.path;
  } else if (Platform.isMacOS) {
    return path.join(dir.path, 'plugins');
  }
}

String extractVersionRepFromPluginFile(String pluginPath) {
  final pluginRegExp = RegExp(r'pal_intellij_plugin-(\d+)\.\d+\.\d+\.zip');
  final pluginBase = path.basename(pluginPath);
  var pluginMatch = pluginRegExp.firstMatch(pluginBase);
  return pluginMatch?.group(1);
}

String extractVersionRepFromIdeSupportFolder(String ideSupportPath) {
  final ideSupportBase = path.basename(ideSupportPath);
  for (var idePath in intelliJPaths) {
    var ideMatch = idePath.firstMatch(ideSupportBase);
    if (ideMatch != null) {
      var ide = ideMatch.group(1);
      var version = ideMatch.group(2);
      _logger.info('Detected $ideSupportBase ($ide, version $version)');

      if (ide.startsWith('AndroidStudio') && version == '4.2') {
        return '202';
      } else if (RegExp(r'^\d{4}\.\d$').hasMatch(version)) {
        // e.g. '2020.3' => '203'
        return version.substring(2, 4) + version[5];
      } else {
        _logger.info('Does not support $ideSupportBase');
      }
    }
  }
  return null;
}

Future<Map<String, String>> loadSupportedVersions() async {
  final pluginRegExp = RegExp(r'(\d+)\.\d+\.\d+');
  final intelliJAssetDir =
      Directory(intelliJAssetDirs[Platform.operatingSystem]);
  var versionPathMap = <String, String>{};
  await for (var asset in intelliJAssetDir.list()) {
    var versionRep = extractVersionRepFromPluginFile(asset.path);
    if (versionRep != null) {
      _logger.info('Support IntelliJ version $versionRep at ${asset.path}');
      versionPathMap[versionRep] = asset.path;
    }
  }
  return versionPathMap;
}

void extractIntelliJPlugin(String directory, String pluginPath) async {
  final zipFile = await File(pluginPath).readAsBytes();
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
  final versionPathMap = await loadSupportedVersions();
  for (var toCheck in searchPaths[Platform.operatingSystem]) {
    await for (var dir in toCheck.list()) {
      final versionRep = extractVersionRepFromIdeSupportFolder(dir.path);
      if (versionRep != null) {
        final pluginPath = versionPathMap[versionRep];
        if (pluginPath != null) {
          await extractIntelliJPlugin(getPluginDir(dir), pluginPath);
        } else {
          _logger.info('IDE at ${dir.path} has no corresponding plugins.');
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
