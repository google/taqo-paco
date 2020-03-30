import 'dart:io';

import 'package:path/path.dart' as path;

import '../storage/local_file_storage.dart';

class DartFileStorage implements ILocalFileStorage {
  final _localFileName;

  static Directory getLocalStorageDir() {
    if (Platform.isLinux) {
      return Directory('${Platform.environment['HOME']}/.taqo');
    }
    throw UnsupportedError('Only supported on Linux');
  }

  Future<Directory> get localStorageDir async => getLocalStorageDir();

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
