// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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
  Future addStream(Stream<String> stream) =>
      _socket.addStream(Utf8Codec().encoder.bind(stream));

  @override
  Future close() => _socket.close();

  @override
  Future get done => _socket.done;
}
