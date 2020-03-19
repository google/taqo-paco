import 'dart:io';

abstract class ILocalFileStorage {
  Future<Directory> get localStorageDir;

  Future<String> get localPath;

  Future<File> get localFile;

  Future clear();
}
