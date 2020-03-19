import 'dart:async';
import 'dart:io';

import 'local_file_storage.dart';

class UnsecureTokenStorage {
  static const filename = 'tokens.txt';

  static Completer<UnsecureTokenStorage> _completer;
  static UnsecureTokenStorage _instance;

  ILocalFileStorage _storageImpl;

  UnsecureTokenStorage._();

  static Future<UnsecureTokenStorage> get(ILocalFileStorage storageImpl) {
    if (_completer != null && !_completer.isCompleted) {
      return _completer.future;
    }
    if (_instance == null) {
      _completer = Completer<UnsecureTokenStorage>();
      final temp = UnsecureTokenStorage._();
      temp._initialize(storageImpl).then((_) {
        _instance = temp;
        _completer.complete(_instance);
      });
      return _completer.future;
    }
    return Future.value(_instance);
  }

  Future _initialize(ILocalFileStorage storageImpl) async {
    _storageImpl = storageImpl;
  }

  Future<List<String>> readTokens() async {
    try {
      final file = await _storageImpl.localFile;
      if (await file.exists()) {
        String contents = await file.readAsString();
        var variables = contents.split("\n");
        if (variables.length == 3) {
          return variables;
        }
      }
      print("token file does not exist or is corrupted");
      return null;
    } catch (e) {
      print("Error loading token: $e");
      return null;
    }
  }

  Future<File> saveTokens(String refreshToken, String accessToken, DateTime expiry) async =>
      (await _storageImpl.localFile)
          .writeAsString("$refreshToken\n$accessToken\n${expiry.toIso8601String()}");

  Future clear() => _storageImpl.clear();
}
