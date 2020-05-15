import 'dart:io';

abstract class ILocalFileStorage {
  Future<Directory> get localStorageDir;

  Future<String> get localPath;

  Future<File> get localFile;

  Future clear();
}

typedef LocalFileStorageFactoryFunction = ILocalFileStorage Function(String);

class LocalFileStorageFactory {
  static LocalFileStorageFactoryFunction _factory;
  static Directory _localStorageDirectory;

  static Directory get localStorageDirectory => _localStorageDirectory;

  static initialize(LocalFileStorageFactoryFunction factory, Directory localStorageDirectory) {
    _factory = factory;
    _localStorageDirectory = localStorageDirectory;
  }

  static makeLocalFileStorage(String filename) {
    return _factory(filename);
  }
}