import 'dart:io';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as path;

const intelliJAssetPath =
    '/Applications/taqo_client.app/Contents/Frameworks/App.framework/Resources/flutter_assets/assets/pal_intellij_plugin.zip';

void extractIntelliJPlugin(String directory) async {
  final zipFile = await File(intelliJAssetPath).readAsBytes();
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

void enableAndroidStudio() async {
  final idePath = RegExp(r'AndroidStudio\d+\.\d+');
  final homeDir = Directory(path.join(
      Platform.environment['HOME'], 'Library', 'Application Support'));

  await for (var dir in homeDir.list()) {
    final baseDir = path.basename(dir.path);

    if (idePath.hasMatch(baseDir)) {
      await extractIntelliJPlugin(dir.path);
    }
  }
}

void enableIntelliJ() async {
  final idePath = RegExp(r'IdeaIC\d{4}\.\d+');
  final jetbrainsDir = Directory(path.join(Platform.environment['HOME'],
      'Library', 'Application Support', 'JetBrains'));

  if (!(await jetbrainsDir.exists())) {
    return;
  }

  await for (var dir in jetbrainsDir.list()) {
    final baseDir = path.basename(dir.path);

    if (idePath.hasMatch(baseDir)) {
      await extractIntelliJPlugin(path.join(dir.path, 'plugins'));
    }
  }
}

void enableIntelliJPlugin() async {
  await enableAndroidStudio();
  await enableIntelliJ();
}

void disableAndroidStudio() async {
  final idePath = RegExp(r'AndroidStudio\d+\.\d+');
  final homeDir = Directory(path.join(
      Platform.environment['HOME'], 'Library', 'Application Support'));

  await for (var dir in homeDir.list()) {
    final baseDir = path.basename(dir.path);

    if (idePath.hasMatch(baseDir)) {
      final d = Directory(path.join(dir.path, 'pal_intellij_plugin'));
      if (await d.exists()) {
        await d.delete(recursive: true);
      }
    }
  }
}

void disableIntelliJ() async {
  final idePath = RegExp(r'IdeaIC\d{4}\.\d+');
  final jetbrainsDir = Directory(path.join(Platform.environment['HOME'],
      'Library', 'Application Support', 'JetBrains'));

  await for (var dir in jetbrainsDir.list()) {
    final baseDir = path.basename(dir.path);

    if (idePath.hasMatch(baseDir)) {
      final d =
          Directory(path.join(dir.path, 'plugins', 'pal_intellij_plugin'));
      if (await d.exists()) {
        await d.delete(recursive: true);
      }
    }
  }
}

void disableIntelliJPlugin() async {
  await disableAndroidStudio();
  await disableIntelliJ();
}
