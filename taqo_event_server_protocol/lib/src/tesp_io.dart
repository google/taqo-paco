import 'dart:io';

import 'tesp_codec.dart';
import 'tesp_message.dart';

class TespMessageSink<T extends TespMessage> implements Sink<T> {
  Socket _socket;

  TespMessageSink(this._socket);

  @override
  void add(T tespMessage) {
    _socket?.add(tesp.encode(tespMessage));
  }

  @override
  void close() {
    _socket = null;
  }
}

