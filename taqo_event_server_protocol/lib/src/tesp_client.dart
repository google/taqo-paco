import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:pedantic/pedantic.dart';

import 'tesp_message.dart';
import 'tesp_message_socket.dart';

class TespClient {
  final Duration timeoutMillis;
  final serverAddress;
  final int port;

  Socket _socket;
  TespMessageSocket<TespResponse, TespRequest> _tespSocket;
  Queue<Completer<TespResponse>> _tespResponseCompleterQueue;
  final Completer _responseAllCompleter = Completer();

  TespClient(this.serverAddress, this.port,
      {this.timeoutMillis = const Duration(milliseconds: 500)});

  Future<void> connect() async {
    _socket = await Socket.connect(serverAddress, port);
    _tespSocket = TespMessageSocket(_socket, timeoutMillis: timeoutMillis);
    _tespResponseCompleterQueue = Queue();
    _tespSocket.listen((tespResponse) {
      if (_tespResponseCompleterQueue.isEmpty) {
        throw TespExceptionUnexpectedResponse();
      }
      var completer = _tespResponseCompleterQueue.removeFirst();
      completer.complete(tespResponse);
    }, onError: (e) {
      throw TespExceptionResponseError(e);
    }, onDone: () {
      if (_tespResponseCompleterQueue.isNotEmpty) {
        throw TespExceptionServerClosedEarly();
      }
      _responseAllCompleter.complete();
    });
    unawaited(_tespSocket.done.catchError((e) {
      close(force: true);
      throw TespExceptionConnectionLost();
    }, test: (e) => e is SocketException));
  }

  Future<TespResponse> send(TespRequest tespRequest) async {
    if (_tespSocket == null) {
      await connect();
    }
    _tespSocket.add(tespRequest);
    var completer = Completer<TespResponse>();
    _tespResponseCompleterQueue.addLast(completer);
    return completer.future;
  }

  Future<void> close({bool force = false}) async {
    if (!force) {
      await _tespSocket?.close();
      await _responseAllCompleter?.future;
    }
    _socket?.destroy();
    _tespResponseCompleterQueue?.clear();
    _socket = null;
    _tespSocket = null;
    _tespResponseCompleterQueue = null;
  }
}

class TespException implements IOException {
  final String message;

  const TespException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

class TespExceptionUnexpectedResponse extends TespException {
  TespExceptionUnexpectedResponse()
      : super('Unexpected response (unsolicited response without request).');
}

class TespExceptionResponseError extends TespException {
  TespExceptionResponseError(e)
      : super('Error while processing the response: $e');
}

class TespExceptionServerClosedEarly extends TespException {
  TespExceptionServerClosedEarly()
      : super('Server closed before sending all the responses.');
}

class TespExceptionConnectionLost extends TespException {
  TespExceptionConnectionLost()
      : super(
            'Connection to server is lost before finishing sending a message.');
}
