import 'dart:async';
import 'dart:io';
import 'tesp_io.dart';
import 'tesp_message.dart';

import 'tesp_codec.dart';

class TespServer {
  final TespCommandExecutor _tespCommandExecutor;
  ServerSocket _serverSocket;

  TespServer(this._tespCommandExecutor);

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
      var sink = TespMessageSink<TespResponse>(socket);
      StreamSubscription<TespMessage> subscription;

      subscription = socket.cast<List<int>>().transform(tesp.decoder).listen(
          (tespMessage) {
        TespRequest tespRequest;
        try {
          tespRequest = tespMessage as TespRequest;
        } catch (e) {
          sink.add(TespResponseInvalidRequest.withPayload(e.toString()));
          return;
        }

        FutureOr<TespResponse> tespResponse;
        try {
          tespResponse = tespRequest.executeCommand(_tespCommandExecutor);
        } catch (e) {
          sink.add(TespResponseError(
              TespResponseError.tespErrorUnknown, e.toString()));
          return;
        }

        if (tespResponse is Future<TespResponse>) {
          subscription.pause();
          tespResponse
              .then((value) => socket.add(tesp.encode(value)),
                  onError: (e) => sink.add(TespResponseError(
                      TespResponseError.tespErrorUnknown, e.toString())))
              .whenComplete(subscription.resume);
        } else {
          sink.add(tespResponse);
        }
      }, onError: (e) {
        sink.add(TespResponseInvalidRequest.withPayload(e.toString()));
        subscription.cancel();
        sink.close();
        socket.close();
      }, onDone: () {
        sink.close();
        socket.close();
      });
    });
  }

  Future<void> close() async {
    await _serverSocket.close();
    _serverSocket = null;
  }
}
