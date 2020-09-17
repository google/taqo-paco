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
  static bool _isInitialized = false;

  static Directory get localStorageDirectory => _localStorageDirectory;
  static bool get isInitialized => _isInitialized;

  static void initialize(LocalFileStorageFactoryFunction factory,
      Directory localStorageDirectory) {
    _factory = factory;
    _localStorageDirectory = localStorageDirectory;
    _isInitialized = true;
  }

  static ILocalFileStorage makeLocalFileStorage(String filename) {
    return _factory(filename);
  }
}
