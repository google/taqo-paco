import 'dart:async';
import 'dart:io';

import 'tesp_codec.dart';
import 'tesp_message.dart';

class TespMessageSocket<S extends TespMessage, T extends TespMessage>
    extends Stream<S> implements Sink<T> {
  final Socket _socket;
  TespMessageSocket(this._socket);

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
    return _socket.cast<List<int>>().transform(tesp.decoder).cast<S>().listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError);
  }
}
