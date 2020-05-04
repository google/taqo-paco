// TODO Can delete when done wth json-rpc

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:stream_channel/stream_channel.dart';

/// A [StreamChannel] wrapper for a [Socket]. Basically just converts from List<int> to String.
class SocketChannel extends StreamChannelMixin<String> {
  final Socket _socket;

  SocketChannel(this._socket);

  @override
  StreamSink<String> get sink => SocketSink._(_socket);

  @override
  Stream<String> get stream => StreamView(Utf8Codec().decoder.bind(_socket));
}

/// A [StreamSink] wrapper for a [Socket]. Basically just converts from List<int> to String.
class SocketSink extends StreamSink<String> {
  final Socket _socket;

  SocketSink._(this._socket);

  @override
  void add(String event) {
    _socket.add(Utf8Codec().encoder.convert(event));
  }

  @override
  void addError(Object error, [StackTrace stackTrace]) {
    _socket.addError(error, stackTrace);
  }

  @override
  Future addStream(Stream<String> stream) => _socket.addStream(Utf8Codec().encoder.bind(stream));

  @override
  Future close() => _socket.close();

  @override
  Future get done => _socket.done;
}
