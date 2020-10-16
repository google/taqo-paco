import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:taqo_common/rpc/rpc_constants.dart';
import 'package:taqo_common/storage/base_database.dart';
import 'package:taqo_event_server_protocol/taqo_event_server_protocol.dart';

import '../storage/flutter_file_storage.dart';
import '../storage/local_database.dart';
import '../storage/remote_database.dart';

final _logger = Logger('PlatformService');

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

Future<bool> isTespConnected() async {
  if (_tespClient == null) return false;

  return _tespClient.ping().then((TespResponse r) {
    if (r is TespResponseError) return false;
    return true;
  });
}

Future<bool> _tryConnect(TespFullClient client) {
  return client.connect().then((_) {
    return true;
  }).catchError((e) {
    _logger
        .warning('Failed to connect to the PAL event server. Is it running?');
    return false;
  });
}

Future _tespInit({int maxRetry = 3}) async {
  _tespClient = TespFullClient(localServerHost, localServerPort);
  final isConnected = await _tryConnect(_tespClient);
  if (!isConnected) {
    _tespClient = null;
    if (maxRetry > 0) {
      await Future.delayed(Duration(seconds: 2));
      return _tespInit(maxRetry: maxRetry - 1);
    } else {
      throw Exception("Failed to connect to PAL event server.");
    }
  }
}

/// Desktop platforms use RPC for sqlite and sync service
bool get isTaqoDesktop => Platform.isLinux || Platform.isMacOS;

Future<BaseDatabase> get databaseImpl {
  if (isTaqoDesktop) {
    return RemoteDatabase.get();
  } else {
    return LocalDatabase.get(FlutterFileStorage(LocalDatabase.dbFilename));
  }
}
