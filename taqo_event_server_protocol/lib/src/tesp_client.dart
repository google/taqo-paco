import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:pedantic/pedantic.dart';
import 'package:taqo_event_server_protocol/src/tesp_codec.dart';

import 'tesp_message.dart';
import 'tesp_message_socket.dart';

class TespClient {
  final serverAddress;
  final int port;
  /// Maximum allowed time between two consecutive chunks belonging to the same response
  final Duration chunkTimeoutMillis;
  /// Maximum allowed time between
  /// (1) sending of one request is finished or previous request get responded, whichever happens later,
  /// and
  /// (2) a response is received
  final Duration responseTimeoutMillis;
  /// Timeout for connection to the server
  final Duration connectionTimeoutMillis;

  Socket _socket;
  TespMessageSocket<TespResponse, TespRequest> _tespSocket;
  // The response timeout is set based on the time needed for sending the request.
  // To measure the sending time, one need to buffer the requests so that the second request
  // is not added to the socket until sending the first request is finished.
  StreamController<TespRequestWrapper> _sendingBuffer;
  // The client can send the next request before the previous request get responded.
  // The following queue is to store the completers for un-responed requests.
  Queue<TimeoutCompleter<TespResponse>> _tespResponseCompleterQueue;
  final Completer _responseAllCompleter = Completer();
  // Timer for response timeout
  Timer _timer;

  TespClient(this.serverAddress, this.port,
      {this.chunkTimeoutMillis = const Duration(milliseconds: 500),
      this.responseTimeoutMillis = const Duration(milliseconds: 500),
      this.connectionTimeoutMillis = const Duration(milliseconds: 5000)});

  Future<void> connect() async {
    _socket = await Socket.connect(serverAddress, port,
        timeout: connectionTimeoutMillis);
    _tespSocket = TespMessageSocket(_socket, timeoutMillis: chunkTimeoutMillis);
    _sendingBuffer = StreamController();
    _tespResponseCompleterQueue = Queue();
    var stopwatch = Stopwatch();
    StreamSubscription sendingSubscription;
    StreamSubscription receivingSubscription;

    void closeWithError(TespResponseError error) {
      _tespResponseCompleterQueue.forEach((e) => e.completer.complete(error));
      sendingSubscription?.cancel();
      receivingSubscription?.cancel();
      close(force: true);
    }

    sendingSubscription = _sendingBuffer.stream.listen((tespRequestWrapper) {
      sendingSubscription.pause();
      stopwatch.start();
      _tespSocket.add(tespRequestWrapper.tespRequest);
      _socket.flush().then((_) {
        stopwatch.stop();
        tespRequestWrapper.timeoutCompleter.timeout =
            stopwatch.elapsed + responseTimeoutMillis;
        // The timer is started when current sending is finished or previous
        // request get responded (including the case of being the first request),
        // whichever happens later.
        // Below is the case when finishing sending happens later.
        if (_tespResponseCompleterQueue.first ==
            tespRequestWrapper.timeoutCompleter) {
          _timer = Timer(
              tespRequestWrapper.timeoutCompleter.timeout,
              () => closeWithError(TespResponseError(
                  TespResponseError.tespClientErrorResponseTimeout)));
        }
        sendingSubscription.resume();
      });
    });

    void onResponse(TespResponse tespResponse) {
      // Unexpected response, i.e. a response without request.
      if (_tespResponseCompleterQueue.isEmpty) {
        // TODO: log the event
        return;
      }
      _timer?.cancel();

      var timeoutCompleter = _tespResponseCompleterQueue.removeFirst();
      timeoutCompleter.completer.complete(tespResponse);

      // The timer is started when current sending is finished or previous
      // request get responded (including the case of being the first request),
      // whichever happens later.
      // Below is the case when previous request getting responded happens later.
      if (_tespResponseCompleterQueue.isNotEmpty &&
          _tespResponseCompleterQueue.first.timeout != null) {
        _timer = Timer(
            _tespResponseCompleterQueue.first.timeout,
            () => closeWithError(TespResponseError(
                TespResponseError.tespClientErrorResponseTimeout)));
      }
    }

    receivingSubscription = _tespSocket.listen(onResponse, onError: (e) {
      if (e is TimeoutException) {
        closeWithError(TespResponseError(
            TespResponseError.tespClientErrorChunkTimeout, '$e'));
      } else if (e is TespPayloadDecodingException) {
        onResponse(TespResponseError(
            TespResponseError.tespClientErrorPayloadDecoding, '$e'));
      } else if (e is TespDecodingException || e is CastError) {
        closeWithError(
            TespResponseError(TespResponseError.tespClientErrorDecoding, '$e'));
      } else {
        closeWithError(
            TespResponseError(TespResponseError.tespClientErrorUnknown, '$e'));
      }
    }, onDone: () {
      // The server closes early before sending out all the responses
      if (_tespResponseCompleterQueue.isNotEmpty) {
        closeWithError(TespResponseError(
            TespResponseError.tespClientErrorServerCloseEarly));
      }
      _responseAllCompleter.complete();
    });

    // Handle errors during sending
    unawaited(_tespSocket.done.catchError((e) {
      closeWithError(
          TespResponseError(TespResponseError.tespClientErrorLostConnection));
    }, test: (e) => e is SocketException));
  }

  Future<TespResponse> send(TespRequest tespRequest) async {
    if (_tespSocket == null) {
      await connect();
    }

    var completer = Completer<TespResponse>();
    var timeoutCompleter = TimeoutCompleter(completer);
    _tespResponseCompleterQueue.addLast(timeoutCompleter);
    _sendingBuffer.add(TespRequestWrapper(tespRequest, timeoutCompleter));
    return completer.future;
  }

  Future<void> close({bool force = false}) async {
    try {
      if (!force) {
        await _sendingBuffer?.close();
        await _tespSocket?.close();
        await _responseAllCompleter?.future;
      }
    } catch (e) {
      rethrow;
    } finally {
      _socket?.destroy();
      _tespResponseCompleterQueue?.clear();
      _socket = null;
      _tespSocket = null;
      _tespResponseCompleterQueue = null;
      _sendingBuffer = null;
    }
  }
}

class TimeoutCompleter<T> {
  final Completer<T> completer;
  Duration timeout;

  TimeoutCompleter(this.completer);
}

class TespRequestWrapper {
  final TespRequest tespRequest;
  final TimeoutCompleter<TespResponse> timeoutCompleter;

  TespRequestWrapper(this.tespRequest, this.timeoutCompleter);
}
