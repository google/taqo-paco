import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'tesp_codec.dart';
import 'tesp_message.dart';

// R for receiving type, S for sending type
class TespMessageSocket<R extends TespMessage, S extends TespMessage>
    extends Stream<R> implements Sink<S> {
  final Socket _socket;
  // The time limit to wait for next available data while reading one message.
  final Duration waitingTimeLimit;
  TespMessageSocket(this._socket,
      {this.waitingTimeLimit = const Duration(milliseconds: 500)});

  @override
  void add(S tespMessage) {
    _socket.add(tesp.encode(tespMessage));
  }

  @override
  Future<void> close() async {
    await _socket.flush();
    await _socket.close();
  }

  Future get done => _socket.done;

  @override
  StreamSubscription<R> listen(void Function(R event) onData,
      {Function onError, void Function() onDone, bool cancelOnError}) {
    StreamController<Uint8List> timeoutController;
    StreamController<Uint8List> outputController;
    StreamSubscription timeoutSubscription;
    StreamSubscription socketSubscription;

    timeoutController =
        StreamController(onCancel: () => socketSubscription.cancel());
    outputController =
        StreamController(onCancel: () => timeoutSubscription.cancel());

    timeoutSubscription = timeoutController.stream
        .timeout(waitingTimeLimit)
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

    void pauseTimer() {
      if (!timeoutSubscription.isPaused) {
        timeoutSubscription.pause();
      }
    }

    return outputController.stream
        .cast<List<int>>()
        .transform(tesp.decoderAddingEvent)
        .cast<R>()
        .listen((R event) {
      pauseTimer();
      if (!(event is TespEventMessageFound)) {
        onData(event);
      }
    }, onError: (e, st) {
      pauseTimer();
      onError(e, st);
    }, onDone: onDone, cancelOnError: cancelOnError);
  }
}
