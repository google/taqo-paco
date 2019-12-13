import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

abstract class LocalFileStorage {
  // TODO for mobile platforms use secure storage apis
  // TODO for desktop, use local secure storage apis, e.g., MacOS use keychain
  // TODO for Fuchsia ...?
  Future<Directory> get _localStorageDir async {
    WidgetsFlutterBinding.ensureInitialized();
    return await getApplicationDocumentsDirectory();
  }

  Future<String> get _localPath async => (await _localStorageDir).path;

  final String _fileName;

  @protected
  Future<File> get localFile async => File(path.join(await _localPath, _fileName));

  LocalFileStorage(this._fileName);

  Future<void> clear() async {
    final file = await localFile;
    if (await file.exists()) {
      await file.delete();
    }
  }
}
