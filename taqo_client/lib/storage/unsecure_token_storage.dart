import 'dart:io';

import 'package:taqo_client/storage/local_storage.dart';

class UnsecureTokenStorage extends LocalFileStorage {
  static const filename = 'tokens.txt';
  static final _instance = UnsecureTokenStorage._();

  UnsecureTokenStorage._() : super(filename);

  factory UnsecureTokenStorage() {
    return _instance;
  }

  Future<List<String>> readTokens() async {
    try {
      final file = await localFile;
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
      (await localFile).writeAsString("$refreshToken\n$accessToken\n${expiry.toIso8601String()}");
}
