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

// This file contains version specific information. The IntelliJ API
// changes over time. In order to support multiple versions of IntelliJ IDEs
// (e.g. IntelliJ IDEA and Android Studio), we patch some source files for
// specific versions to match their API definitions.

import 'dart:io' show Platform;

import 'package:plugin_tool/build_spec.dart';
import 'package:plugin_tool/edit.dart';

final patches = <EditCommand>[
  Subst(
      path: 'src/main/java/com/pacoapp/intellij/PacoProjectComponent.java',
      initial:
          'public void changesRemoved(Collection<Change> collection, ChangeList changeList) {',
      replacement:
          'public void changesRemoved(Collection<? extends Change> collection, ChangeList changeList) {',
      version: '2023.1'),
  Subst(
      path: 'src/main/java/com/pacoapp/intellij/PacoProjectComponent.java',
      initial:
          'public void changesAdded(Collection<Change> collection, ChangeList changeList) {',
      replacement:
          'public void changesAdded(Collection<? extends Change> collection, ChangeList changeList) {',
      version: '2023.1'),
  Subst(
      path: 'src/main/java/com/pacoapp/intellij/PacoProjectComponent.java',
      initial:
          'public void changesMoved(Collection<Change> collection, ChangeList changeList, ChangeList changeList1) {',
      replacement:
          'public void changesMoved(Collection<? extends Change> collection, ChangeList changeList, ChangeList changeList1) {',
      version: '2023.1'),
];

String? getJavaHome(BuildSpec spec) {
  final needJava17 = spec.ideaVersion.compareTo('2022.z') > 0;
  if (needJava17) {
    return Platform.environment['JAVA_HOME_17'];
  } else {
    return Platform.environment['JAVA_HOME_11'];
  }
}

Future<void> buildWithPatches(
    BuildSpec spec, Function buildFn, List<EditCommand> patches) async {
  var patched = <EditCommand, String>{};
  try {
    for (var patch in patches) {
      var source = patch.convert(spec);
      if (source != null) {
        patched[patch] = source;
      }
    }
    await buildFn.call(javaHome: getJavaHome(spec));
  } finally {
    // Restore sources.
    patched.forEach((edit, source) {
      edit.restore(source);
    });
  }
}
