import 'dart:convert';

import 'package:taqo_event_server_protocol/taqo_event_server_protocol.dart';

import '../sqlite_database/sqlite_database.dart';
import '../whitelist.dart';
import 'pal_command.dart';

class PALTespServer with TespRequestHandlerMixin {
  TespServer _tespServer;
  final _whitelist = Whitelist();

  ExampleEventServer() {
    _tespServer = TespServer(this);
  }

  int get port => _tespServer.port;

  Future<void> serve({dynamic address = '127.0.0.1', int port = 0}) async {
    await _tespServer.serve(address: address, port: port);
  }

  @override
  Future<TespResponse> addEvent(String eventPayload) async {
    print('addEvent: $eventPayload');
    final List eventJson = jsonDecode(eventPayload);
    if (await isWhitelistedDataOnly()) {
      await _storeEvent(_whitelist.blackOutData(eventJson));
    } else {
      await _storeEvent(eventJson);
    }
    TespResponseSuccess();
  }

  @override
  Future<TespResponse> allData() async {
    print('allData');
    await setAllDataOnly();
    return TespResponseSuccess();
  }

  @override
  Future<TespResponse> pause() async {
    print('pause');
    await pauseDataUpload();
    return TespResponseSuccess();
  }

  @override
  Future<TespResponse> resume() async {
    print('resume');
    await resumeDataUpload();
    return TespResponseSuccess();
  }

  @override
  Future<TespResponse> whiteListDataOnly() async {
    print('whiteListDataOnly');
    setWhitelistedDataOnly();
    return TespResponseSuccess();
  }

  Future _storeEvent(List events) async {
    final database = await SqliteDatabase.get();
    for (var e in events) {
      print('storeEvent: $e');
      await database.insertEvent(e);
    }
  }
}
