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

import 'flutter_intellij.dart';
import 'patches.dart';

final BuildSpec buildSpec = BuildSpec(
    flutter_intellij_commit: '5a6c0330d39bbbf86a658d4e40f6891447f03b2e',
    flutter_intellij_release: '72.0');

class BuildSpec {
  final String flutter_intellij_commit;
  final String flutter_intellij_release;

  BuildSpec(
      {required this.flutter_intellij_commit,
      required this.flutter_intellij_release});

  factory BuildSpec.fromFlutterIntellijRelease(String release) {
    var version_components = release.split('.');
    var major = version_components[0];

    // Patching the release string if it is in the format 'x' or 'x.y.z'
    // instead of 'x.y'
    if (version_components.length > 2) {
      release = version_components.sublist(0, 2).join('.');
    } else if (version_components.length == 1) {
      release = '$release.0';
    }
    return BuildSpec(
        flutter_intellij_commit: 'release_$major',
        flutter_intellij_release: release);
  }
}

Future<void> runGradleBuild({String? javaHome}) async {
  final args = ['buildPlugin'];
  final env = (javaHome == null) ? null : {'JAVA_HOME': javaHome};

  Process process;
  if (Platform.isWindows) {
    process = await Process.start('.\\gradlew.bat', args, environment: env);
  } else {
    process = await Process.start('./gradlew', args, environment: env);
  }
  await Future.wait(
      [stdout.addStream(process.stdout), stderr.addStream(process.stderr)]);
}

Future<void> buildPlugins(BuildSpec spec) async {
  await downloadProductMatrix(spec.flutter_intellij_commit);
  var flutter_intellij_specs = readFlutterIntellijSpecs();

  for (var i = 0; i < flutter_intellij_specs.length; i++) {
    var fi_spec = flutter_intellij_specs[i];
    await downloadArtifacts(fi_spec);
    await writeGradleProperties(fi_spec, spec.flutter_intellij_release, i + 1);
    await buildWithPatches(fi_spec, runGradleBuild, patches);
  }
}

Future<void> main(List<String> arguments) async {
  initGlobals();
  await buildPlugins(buildSpec);
}
