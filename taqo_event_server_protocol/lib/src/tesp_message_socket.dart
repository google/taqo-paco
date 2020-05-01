import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'tesp_codec.dart';
import 'tesp_message.dart';

// R for receiving type, S for sending type
class TespMessageSocket<R extends TespMessage, S extends TespMessage>
    implements Sink<S> {
  final Socket _socket;
  // The time limit to wait for next available data while reading one message.
  final Duration timeoutMillis;
  // Whether the stream can generate Future<R>
  final bool isAsync;
  Completer<R> _messageCompleter;

  TespMessageSocket(this._socket,
      {this.timeoutMillis = const Duration(milliseconds: 500),
      this.isAsync = false});

  @override
  void add(S tespMessage) {
    _socket.add(tesp.encode(tespMessage));
  }

  @override
  Future<void> close() async {
    try {
      await _socket.flush();
    } catch (_) {
      // flush() may fail if the client closes early, in which case we just give up
    } finally {
      await _socket.close();
    }
  }

  // Dart may have issues when there are uncompleted completers,
  // see https://github.com/dart-lang/sdk/issues/23797
  void cleanUp() {
    if (isAsync && _messageCompleter != null) {
      _messageCompleter
          .completeError(StateError('message receiving is not finished.'));
    }
  }

  Future get done => _socket.done;

  Stream<FutureOr<R>> get stream {
    StreamController<Uint8List> timeoutController;
    StreamController<Uint8List> outputController;
    StreamController<FutureOr<R>> tespMessageStreamController;
    StreamSubscription timeoutSubscription;
    StreamSubscription socketSubscription;
    StreamSubscription outputSubscription;

    timeoutController =
        StreamController(onCancel: () => socketSubscription.cancel());
    outputController =
        StreamController(onCancel: () => timeoutSubscription.cancel());

    void pauseTimer() {
      if (!timeoutSubscription.isPaused) {
        timeoutSubscription.pause();
      }
    }

    void onListen() {
      timeoutSubscription = timeoutController.stream
          .timeout(timeoutMillis)
          .listen((event) => outputController.add(event),
              onError: (e, st) => outputController.addError(e, st),
              onDone: outputController.close);

      // There should be no timeout until data comes in
      timeoutSubscription.pause();

      socketSubscription = _socket.listen((event) {
        timeoutSubscription.resume();
        timeoutController.add(event);
      }, onError: (e, st) {
        timeoutSubscription.resume();
        timeoutController.addError(e, st);
      }, onDone: () {
        timeoutSubscription.resume();
        timeoutController.close();
      });

      outputSubscription = outputController.stream
          .cast<List<int>>()
          .transform(tesp.decoderAddingEvent)
          .cast<R>()
          .listen((R event) {
            if (!(event is TespEventMessageExpected)) {
              pauseTimer();
            }
        if (isAsync) {
          if (event is TespEventMessageExpected || event is TespEventMessageArrived) {
            if (_messageCompleter == null) {
              _messageCompleter = Completer();
              tespMessageStreamController.add(_messageCompleter.future);
            } else {
              assert (event is TespEventMessageArrived);
              // The completer is already assigned in a previous TespEventMessageExpected event
            }
          } else if (_messageCompleter != null) {
            _messageCompleter.complete(event);
            _messageCompleter = null;
          } else {
            tespMessageStreamController.add(event);
          }
        } else {
          if (!(event is TespEvent)) {
            tespMessageStreamController.add(event);
          }
        }
      }, onError: (e, st) {
        pauseTimer();
        if (isAsync) {
          if (_messageCompleter != null) {
            _messageCompleter.completeError(e, st);
            _messageCompleter = null;
          } else {
            tespMessageStreamController.addError(e, st);
          }
        } else {
          tespMessageStreamController.addError(e, st);
        }
      }, onDone: () => tespMessageStreamController.close());
    }

    if (isAsync) {
      tespMessageStreamController = StreamController(
          onListen: onListen, onCancel: () => outputSubscription.cancel());
    } else {
      tespMessageStreamController = StreamController<R>(
          onListen: onListen, onCancel: () => outputSubscription.cancel());
    }

    return tespMessageStreamController.stream;
  }
}
