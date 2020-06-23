import 'dart:io';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as path;

const intelliJAssetPath = '/usr/share/taqo/pal_intellij_plugin.zip';
final intelliJPaths = [
  RegExp(r'AndroidStudio\d+\.\d+'),
  RegExp(r'IdeaIC\d{4}\.\d+'),
];

void extractIntelliJPlugin(String directory) async {
  final zipFile = await File(intelliJAssetPath).readAsBytes();
  final pluginPkg = ZipDecoder().decodeBytes(zipFile);

  for (var item in pluginPkg) {
    final output = path.join(directory, 'config', 'plugins', item.name);
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
  final homeDir = Directory(Platform.environment['HOME']);

  await for (var dir in homeDir.list()) {
    final baseDir = path.basename(dir.path);

    for (var idePath in intelliJPaths) {
      if (idePath.hasMatch(baseDir)) {
        await extractIntelliJPlugin(dir.path);
      }
    }
  }
}

void disableIntelliJPlugin() async {
  final homeDir = Directory(Platform.environment['HOME']);

  await for (var dir in homeDir.list()) {
    final baseDir = path.basename(dir.path);

    for (var idePath in intelliJPaths) {
      if (idePath.hasMatch(baseDir)) {
        final d = Directory(path.join(dir.path, 'config', 'plugins', 'pal_intellij_plugin'));
        if (await d.exists()) {
          await d.delete(recursive: true);
        }
      }
    }
  }
}
