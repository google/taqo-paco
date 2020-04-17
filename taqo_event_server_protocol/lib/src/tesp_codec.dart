import 'dart:convert';
import 'dart:typed_data';

import 'tesp_message.dart';

/// An instance of the default implementation of the [TespCodec].
///
/// This instance provides a convenient access to the most common TESP
/// use cases.
///
/// Examples:
///
///     var encoded = tesp.encode(TespRequestPause());
///     var decoded = tesp.decode([0x01, 0x02]);
const TespCodec tesp = TespCodec();

/// A [TespCodec] encodes TESP messages ([TespMessage]) to bytes and decodes
/// bytes to TESP messages.
class TespCodec extends Codec<TespMessage, List<int>> {
  const TespCodec();

  /// The TESP protocol version. It needs to fit in an 8-bit unsigned integer
  /// (0-255).
  static const protocolVersion = 1;

  // constants associated with the protocol specification
  static const headerLength = 2;
  static const payloadSizeLength = 4;
  static const headerWithPayloadSizeLength = headerLength + payloadSizeLength;
  static const versionOffset = 0;
  static const codeOffset = 1;
  static const payloadSizeOffset = headerLength;
  static const payloadOffset = payloadSizeOffset + payloadSizeLength;

  @override
  Converter<List<int>, TespMessage> get decoder => const TespDecoder();

  Converter<List<int>, TespMessage> get decoderAddingEvent =>
      const TespDecoder(addingEvent: true);

  @override
  Converter<TespMessage, List<int>> get encoder => const TespEncoder();
}

/// This class converts a TESP message to bytes (a list of unsigned 8-bit
/// integers).
class TespEncoder extends Converter<TespMessage, List<int>> {
  const TespEncoder();
  static const int UINT32_MAX = 0xFFFFFFFF;

  @override
  Uint8List convert(TespMessage message) {
    var header = Uint8List.fromList([TespCodec.protocolVersion, message.code]);
    if (message is StringPayload) {
      if (message.encodedPayload.length > UINT32_MAX) {
        throw TespLengthException(
            'TESP cannot encode messages with payload larger than UINT32_MAX bytes.',
            message);
      }
      var encoded =
          Uint8List(TespCodec.payloadOffset + message.encodedPayload.length);
      encoded.setRange(0, TespCodec.headerLength, header);

      // encode payload size using big-endian byte order
      var bdata = ByteData.view(encoded.buffer, TespCodec.payloadSizeOffset,
          TespCodec.payloadSizeLength);
      bdata.setUint32(0, message.encodedPayload.length, Endian.big);

      encoded.setRange(
          TespCodec.payloadOffset, encoded.length, message.encodedPayload);
      return encoded;
    } else {
      return header;
    }
  }

  @override
  Stream<List<int>> bind(Stream<TespMessage> stream) {
    return stream.map(convert);
  }
}

/// This class converts UTF-8 code units (lists of unsigned 8-bit integers)
/// to a TESP message.
class TespDecoder extends Converter<List<int>, TespMessage> {
  final bool addingEvent;
  const TespDecoder({this.addingEvent = false});

  static bool isCodeForTespMessageWithPayload(int code) {
    return (code & 0x01 == 0x01);
  }

  static bool isCodeForTespMessageWithoutPayload(int code) {
    return (code & 0x01 == 0x00);
  }

  static bool isCodeForTespRequest(int code) {
    return (code & 0x80 == 0x00);
  }

  static bool isCodeForTespResponse(int code) {
    return (code & 0x80 == 0x80);
  }

  static void checkProtocolVersion(int version, [source, int offset]) {
    // Currently we only support one version of the protocol
    if (version != TespCodec.protocolVersion) {
      throw TespVersionException(version, source, offset);
    }
  }

  @override
  TespMessage convert(List<int> bytes) {
    if (bytes.isEmpty) {
      throw TespLengthException('Cannot decode an empty message.', bytes);
    }

    checkProtocolVersion(
        bytes[TespCodec.versionOffset], bytes, TespCodec.versionOffset);

    if (bytes.length < TespCodec.headerLength) {
      throw TespLengthException(
          'An encoded message should have at least ${TespCodec.headerLength} bytes.',
          bytes);
    }

    var code = bytes[TespCodec.codeOffset];
    if (isCodeForTespMessageWithoutPayload(code)) {
      if (bytes.length > TespCodec.headerLength) {
        throw TespLengthException(
            'An encoded message without payload should have exact ${TespCodec.headerLength} bytes.',
            bytes);
      }
      try {
        return TespMessage.fromCode(code);
      } on ArgumentError {
        throw TespUndefinedCodeException(code, bytes, TespCodec.codeOffset);
      }
    } else {
      // the [code] is for TespMessageWithPayload

      if (bytes.length < TespCodec.headerWithPayloadSizeLength) {
        throw TespLengthException(
            'An encoded message with payload should have at least ${TespCodec.headerWithPayloadSizeLength} bytes.',
            bytes);
      }

      // decode the payload size using big-endian byte order
      var bdata;
      if (bytes is Uint8List) {
        bdata = ByteData.view(bytes.buffer, TespCodec.payloadSizeOffset,
            TespCodec.payloadSizeLength);
      } else {
        bdata = ByteData.view(Uint8List.fromList(bytes.sublist(
                TespCodec.payloadSizeOffset, TespCodec.payloadOffset))
            .buffer);
      }
      var payloadSize = bdata.getUint32(0, Endian.big);

      var actualPayloadSize = bytes.length - TespCodec.payloadOffset;
      if (actualPayloadSize != payloadSize) {
        throw TespLengthException(
            'The encoded message indicates it has a payload of $payloadSize ${payloadSize == 1 ? 'byte' : 'bytes'}. Only $actualPayloadSize ${actualPayloadSize == 1 ? 'byte is' : 'bytes are'} found.',
            bytes);
      }

      var encodedPayload;
      if (bytes is Uint8List) {
        encodedPayload =
            Uint8List.view(bytes.buffer, TespCodec.payloadOffset, payloadSize);
      } else {
        encodedPayload = Uint8List.view(Uint8List.fromList(bytes).buffer,
            TespCodec.payloadOffset, payloadSize);
      }

      try {
        return TespMessage.fromCode(code, encodedPayload);
      } on ArgumentError {
        throw TespUndefinedCodeException(code, bytes, TespCodec.codeOffset);
      } on FormatException catch (e) {
        throw TespPayloadDecodingException(
            e, bytes, TespCodec.payloadOffset + e.offset);
      }
    }
  }

  @override
  ByteConversionSink startChunkedConversion(Sink<TespMessage> sink) {
    return _TespDecoderSink(sink, addingEvent: addingEvent);
  }

  // Override the base-classes bind, to provide a better type.
  @override
  Stream<TespMessage> bind(Stream<List<int>> stream) => super.bind(stream);
}

class _TespDecoderSink extends ByteConversionSinkBase {
  final Sink<TespMessage> _outputSink;
  final bool addingEvent;
  _TespDecoderSink(this._outputSink, {this.addingEvent = false});

  final Uint8List _headerWithPayloadSize = Uint8List(TespCodec.payloadOffset);
  int _headerIndex = 0;
  int _code;
  bool _hasPayload;
  int _payloadSize;
  Uint8List _encodedPayload;
  int _payloadIndex;

  @override
  void add(List<int> chunk) {
    addSlice(chunk, 0, chunk.length, false);
  }

  @override
  void addSlice(List<int> chunk, int start, int end, bool isLast) {
    for (var i = start; i < end; i++) {
      if (_headerIndex < TespCodec.payloadOffset) {
        // still reading the header (possibly with payload size)

        _headerWithPayloadSize[_headerIndex] = chunk[i];

        if (_headerIndex == TespCodec.versionOffset) {
          TespDecoder.checkProtocolVersion(chunk[i]);
        } else if (_headerIndex == TespCodec.codeOffset) {
          _code = chunk[i];
          _hasPayload = TespDecoder.isCodeForTespMessageWithPayload(_code);
          if (!_hasPayload) {
            _foundTespMessage();
            continue;
          }
        } else if (_headerIndex == TespCodec.payloadOffset - 1) {
          var bdata = ByteData.view(_headerWithPayloadSize.buffer,
              TespCodec.payloadSizeOffset, TespCodec.payloadSizeLength);
          _payloadSize = bdata.getUint32(0, Endian.big);
          _encodedPayload = Uint8List(_payloadSize);
          _payloadIndex = 0;
          if (_payloadSize == 0) {
            _foundTespMessage();
            continue;
          }
        }
        _headerIndex++;
      } else if (_payloadIndex < _payloadSize - 1) {
        // reading the payload
        _encodedPayload[_payloadIndex] = chunk[i];
        _payloadIndex++;
      } else {
        // finishes reading the payload
        _encodedPayload[_payloadIndex] = chunk[i];
        _foundTespMessage();
        continue;
      }
    }
    if (isLast) close();
  }

  @override
  void close() {
    if (_headerIndex > 0) {
      _reset();
      _outputSink.close();
      throw TespIncompleteMessageException();
    }
    _outputSink.close();
  }

  void _reset() {
    _headerIndex = 0;
    _encodedPayload = null;
  }

  void _foundTespMessage() {
    var tespMessage;

    // sending out an event before the payload get decoded, so that the stream
    // consumer can know that a message is received as soon as possible
    if (addingEvent && _hasPayload) {
      _outputSink.add(TespEventMessageFound());
    }
    try {
      tespMessage =
          TespMessage.fromCode(_code, _hasPayload ? _encodedPayload : null);
    } on ArgumentError {
      throw TespUndefinedCodeException(_code);
    } on FormatException catch (e) {
      throw TespPayloadDecodingException(e);
    } finally {
      _reset();
    }
    _outputSink.add(tespMessage);
  }
}

// Exceptions
const _errorHeader = 'TESP v${TespCodec.protocolVersion}: ';

class TespDecodingException extends FormatException {
  TespDecodingException(String message, [source, int offset])
      : super(_errorHeader + message, source, offset);
}

class TespUndefinedCodeException extends TespDecodingException {
  TespUndefinedCodeException(int code, [source, int offset])
      : super('undefined message code: $code.}', source, offset);
}

class TespPayloadDecodingException extends TespDecodingException {
  TespPayloadDecodingException(FormatException e, [source, int offset])
      : super('unable to decode the payload: ${e.message}', source, offset);
}

class TespLengthException extends TespDecodingException {
  TespLengthException(String message, [source]) : super(message, source);
}

class TespVersionException extends TespDecodingException {
  TespVersionException(int unsupportedVersion, [source, int offset])
      : super('unsupported protocol version: ${unsupportedVersion}.', source,
            offset);
}

class TespIncompleteMessageException extends TespDecodingException {
  TespIncompleteMessageException()
      : super('stream is closed before a message is finished.');
}
