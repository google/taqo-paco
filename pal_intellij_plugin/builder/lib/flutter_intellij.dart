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

import 'package:path/path.dart' as p;
import 'package:plugin_tool/globals.dart';
import 'package:plugin_tool/plugin.dart';
import 'package:plugin_tool/build_spec.dart';
import 'package:plugin_tool/util.dart';

void initGlobals() {
  rootPath = Directory.current.path;
}

Future<void> downloadProductMatrix(String commit) async {
  final url =
      'https://raw.githubusercontent.com/flutter/flutter-intellij/$commit/product-matrix.json';
  final path = p.join(rootPath, 'product-matrix.json');

  final request = await HttpClient().getUrl(Uri.parse(url));
  final response = await request.close();
  await response.pipe(File(path).openWrite());
}

List<BuildSpec> readFlutterIntellijSpecs() {
  var specs = <BuildSpec>[];
  var input = readProductMatrix();
  for (var json in input) {
    specs.add(BuildSpec.fromJson(json, /* release */ ''));
  }
  return specs;
}

class DownloadException implements Exception {}

Future<void> downloadArtifacts(BuildSpec spec) async {
  // Manually remove 'artifacts/dart' folder due to a combination of the following reasons:
  // 1. ArtifactManager.provision() will stuck on unzip if any target file exists
  // 2. ArtifactManager.provision() actually tries to delete existing targets before unzipping
  // 3. For Dart artifacts, ArtifactManager.provision() tries to delete 'Dart' folder
  // 4. However, for some versions of Dart artifacts, it was actually unzipped to 'dart' folder
  await removeAll('$rootPath/artifacts/dart');

  var result = await spec.artifacts.provision(rebuildCache: true);
  if (result != 0) {
    throw DownloadException();
  }
}

Future<void> writeGradleProperties(
    BuildSpec spec, String release, int pluginCount) async {
  var contents = '''ide = ${spec.ideaProduct}
dartPluginVersion = ${spec.dartPluginVersion}
flutterPluginVersion = $release.$pluginCount
buildVersion = ${spec.sinceBuild}
baseVersion = ${spec.baseVersion}
''';
  final propertiesFile = File('$rootPath/gradle.properties');
  await propertiesFile.writeAsString(contents);
}
