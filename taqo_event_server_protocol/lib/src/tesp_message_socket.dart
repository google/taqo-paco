import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'tesp_codec.dart';
import 'tesp_message.dart';

typedef _TimerCallback = void Function();

class TespMessageSocket<S extends TespMessage, T extends TespMessage>
    extends Stream<S> implements Sink<T> {
  final Socket _socket;
  // The time limit to wait for next available data while reading one message.
  final Duration waitingTimeLimit;
  TespMessageSocket(this._socket,
      {this.waitingTimeLimit = const Duration(milliseconds: 500)});

  @override
  void add(T tespMessage) {
    _socket.add(tesp.encode(tespMessage));
  }

  @override
  void close() {
    _socket.flush().then((_) => _socket.close());
  }

  @override
  StreamSubscription<S> listen(void Function(S event) onData,
      {Function onError, void Function() onDone, bool cancelOnError}) {
    // The following code managing timeout is based on the source code for Stream.timeout() method.
    StreamController<Uint8List> controller;
    Timer timer;
    // The following variables are set in _onListen().
    StreamSubscription<Uint8List> subscription;
    Zone zone;
    _TimerCallback timeout;

    void _onData(Uint8List event) {
      timer?.cancel();
      timer = zone.createTimer(waitingTimeLimit, timeout);
      controller.add(event);
    }

    void _onError(error, StackTrace stackTrace) {
      timer?.cancel();
      controller.addError(error, stackTrace); // Avoid Zone error replacement.
      timer = zone.createTimer(waitingTimeLimit, timeout);
    }

    void _onDone() {
      timer?.cancel();
      controller.close();
    }

    void _onListen() {
      // This is the onListen callback for of controller.
      // It runs in the same zone that the subscription was created in.
      // Use that zone for creating timers and running the onTimeout
      // callback.
      zone = Zone.current;
      timeout = () {
        controller.addError(
            TimeoutException(
                'more data expected or wrong message format', waitingTimeLimit),
            null);
      };

      subscription =
          _socket.listen(_onData, onError: _onError, onDone: _onDone);
    }

    Future _onCancel() {
      timer.cancel();
      var result = subscription.cancel();
      subscription = null;
      return result;
    }

    controller = StreamController(
        onListen: _onListen,
        onPause: () {
          // Don't null the timer, onCancel may call cancel again.
          timer?.cancel();
          subscription.pause();
        },
        onResume: () {
          subscription.resume();
          timer = zone.createTimer(waitingTimeLimit, timeout);
        },
        onCancel: _onCancel,
        sync: true);

    return controller.stream
        .cast<List<int>>()
        .transform(tesp.decoder)
        .cast<S>()
        .listen((S event) {
      timer?.cancel();
      if (!(event is TespEventMessageFound)) {
        onData(event);
      }
    }, onError: (e, st) {
      timer?.cancel();
      onError(e, st);
    }, onDone: onDone, cancelOnError: cancelOnError);
  }
}
