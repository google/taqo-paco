import 'dart:async';

import 'package:taqo_event_server_protocol/taqo_event_server_protocol.dart';

class ExampleEventServer implements TespCommandExecutor {
  TespServer _tespServer;

  ExampleEventServer() {
    _tespServer = TespServer(this);
  }

  int get port => _tespServer.port;

  Future<void> serve({dynamic address: "127.0.0.1", int port: 0}) async {
    await _tespServer.serve(address: address, port: port);
  }

  @override
  Future<TespResponse> addEvent(String eventPayload) {
    print('addEvent: $eventPayload');
    return Future.value(TespResponseSuccess());
  }

  @override
  TespResponse allData() {
    print('allData');
    return TespResponseSuccess();
  }

  @override
  FutureOr<TespResponse> pause() {
    print('pause');
    return TespResponseSuccess();
  }

  @override
  FutureOr<TespResponse> resume() {
    print('resume');
    return TespResponseSuccess();
  }

  @override
  FutureOr<TespResponse> whiteListDataOnly() {
    print('whiteListDataOnly');
    return TespResponseSuccess();
  }
}

void main() async {
  var server = ExampleEventServer();
  await server.serve(port: 4444);
  print('Waiting for request on port ${server.port}...');
}
