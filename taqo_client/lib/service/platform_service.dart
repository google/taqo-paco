import 'dart:async';
import 'dart:io';

import 'package:taqo_common/rpc/rpc_constants.dart';
import 'package:taqo_common/storage/base_database.dart';
import 'package:taqo_event_server_protocol/taqo_event_server_protocol.dart';

import '../storage/flutter_file_storage.dart';
import '../storage/local_database.dart';
import '../storage/remote_database.dart';

TespFullClient _tespClient;
Completer<TespFullClient> _completer;

/// Returns a global [TespFullClient] to use for RPC
Future<TespFullClient> get tespClient async {
  if (_completer != null && !_completer.isCompleted) {
    return _completer.future;
  }
  if (_tespClient != null) {
    return _tespClient;
  }
  _completer = Completer();
  _tespInit().then((_) {
    _completer.complete(_tespClient);
  });
  return _completer.future;
}

Future _tespInit() async {
  final completer = Completer();
  _tespClient = TespFullClient(localServerHost, localServerPort);
  _tespClient.connect().then((_) {
    completer.complete();
  }).catchError((e) {
    print('Failed to connect to the PAL event server. Is it running?');
    _tespClient = null;
  });
  return completer.future;
}

/// Desktop platforms use RPC for sqlite
bool get isTaqoDesktop => Platform.isLinux || Platform.isMacOS;

Future<BaseDatabase> get databaseImpl {
  if (isTaqoDesktop) {
    return RemoteDatabase.get();
  } else {
    return LocalDatabase.get(FlutterFileStorage(LocalDatabase.dbFilename));
  }
}
