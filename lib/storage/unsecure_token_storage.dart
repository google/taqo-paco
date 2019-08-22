import 'dart:io';

class UnsecureTokenStorage {

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/tokens.txt');
  }

  Future<List<String>> readTokens() async {
    try {
      final file = await _localFile;
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

  Future<File>  saveTokens(String refreshToken, String accessToken, DateTime expiry) async {
    // TODO for mobile platforms use secure storage apis
    // for desktop, use local secure storage apis, e.g., Macos use keychain..
    // for Fuchsia ...?

    final file = await _localFile;
    return file.writeAsString(refreshToken + "\n" + accessToken + "\n" + expiry.toIso8601String());
  }

  getApplicationDocumentsDirectory() {
    return Directory.systemTemp;
  }

  Future<void> clearTokens() async {
     final file = await _localFile;
     if (await file.exists()) {
       await file.delete();
     }
  }
}