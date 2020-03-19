import 'dart:io';

import 'package:path/path.dart' as path;

import '../storage/local_file_storage.dart';

String get taqoDir {
  final env = Platform.environment;
  String home;
  if (Platform.isLinux) {
    home = env['HOME'];
  } else {
    throw UnsupportedError('Only supports Linux and MacOS');
  }
  return '$home/.taqo';
}

class DartFileStorage implements ILocalFileStorage {
  final _localFileName;

  Future<Directory> get localStorageDir async => Directory(taqoDir);

  Future<String> get localPath async => (await localStorageDir).path;

  Future<File> get localFile async => File(path.join(await localPath, _localFileName));

  DartFileStorage(this._localFileName);

  Future clear() async {
    final file = await localFile;
    if (await file.exists()) {
      await file.delete();
    }
  }
}
