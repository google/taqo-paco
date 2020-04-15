import 'dart:async';
import 'dart:io';
import 'tesp_message_socket.dart';
import 'tesp_message.dart';

import 'tesp_codec.dart';

abstract class TespRequestHandler {
  FutureOr<TespResponse> handle(TespRequest tespRequest);
}

mixin TespRequestHandlerMixin implements TespRequestHandler {
  FutureOr<TespResponse> addEvent(String eventPayload);
  FutureOr<TespResponse> pause();
  FutureOr<TespResponse> resume();
  FutureOr<TespResponse> whiteListDataOnly();
  FutureOr<TespResponse> allData();

  TespResponse ping() {
    return TespResponseSuccess();
  }

  @override
  FutureOr<TespResponse> handle(TespRequest tespRequest) {
    switch (tespRequest.runtimeType) {
      case TespRequestAddEvent:
        return addEvent((tespRequest as TespRequestAddEvent).payload);
      case TespRequestPause:
        return pause();
      case TespRequestResume:
        return resume();
      case TespRequestWhiteListDataOnly:
        return whiteListDataOnly();
      case TespRequestAllData:
        return allData();
      case TespRequestPing:
        return ping();
    }
  }
}

class TespServer {
  final TespRequestHandler _tespRequestHandler;
  ServerSocket _serverSocket;

  TespServer(this._tespRequestHandler);

  int get port => _serverSocket?.port;

  Future<void> serve(
      {dynamic address: "127.0.0.1",
      int port: 0,
      int backlog: 0,
      bool v6Only: false,
      bool shared: false}) async {
    _serverSocket = await ServerSocket.bind(address, port,
        backlog: backlog, v6Only: v6Only, shared: shared);

    _serverSocket.listen((socket) {
      var tespSocket = TespMessageSocket<TespRequest, TespResponse>(socket);
      StreamSubscription<TespMessage> subscription;

      subscription = tespSocket.listen((tespRequest) {
        FutureOr<TespResponse> tespResponse;
        try {
          tespResponse = _tespRequestHandler.handle(tespRequest);
        } catch (e) {
          tespSocket.add(TespResponseError(
              TespResponseError.tespErrorUnknown, e.toString()));
          return;
        }

        if (tespResponse is Future<TespResponse>) {
          subscription.pause();
          tespResponse
              .then((value) => socket.add(tesp.encode(value)),
                  onError: (e) => tespSocket.add(TespResponseError(
                      TespResponseError.tespErrorUnknown, e.toString())))
              .whenComplete(subscription.resume);
        } else {
          tespSocket.add(tespResponse);
        }
      }, onError: (e) {
        tespSocket.add(TespResponseInvalidRequest.withPayload(e.toString()));
        if (!(e is CastError)) {
          subscription.cancel();
          tespSocket.close();
        }
      }, onDone: () {
        tespSocket.close();
      });
    });
  }

  Future<void> close() async {
    await _serverSocket.close();
    _serverSocket = null;
  }
}
