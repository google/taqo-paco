import 'dart:convert';
import 'dart:typed_data';

abstract class TespMessage {
  /// The response/request code for the message, which must fit in an 8-bit
  /// unsigned integer (0x00-0xFF).
  int get code;

  static const tespCodeRequestAddEvent = 0x01;
  static const tespCodeRequestPause = 0x02;
  static const tespCodeRequestResume = 0x04;
  static const tespCodeRequestWhiteListDataOnly = 0x06;
  static const tespCodeRequestAllData = 0x08;
  static const tespCodeResponseSuccess = 0x80;
  static const tespCodeResponseError = 0x81;
  static const tespCodeResponsePaused = 0x82;
  static const tespCodeResponseInvalidRequest = 0x83;
  static const tespCodeResponseAnswer = 0x85;

  TespMessage();

  /// Create an instance of [TespMessage] with proper subtype corresponding to the
  /// message [code].
  factory TespMessage.fromCode(int code, [Uint8List encodedPayload]) {
    switch (code) {
      case tespCodeRequestAddEvent:
        return TespRequestAddEvent.withEncodedPayload(encodedPayload);
      case tespCodeRequestPause:
        return TespRequestPause();
      case tespCodeRequestResume:
        return TespRequestResume();
      case tespCodeRequestWhiteListDataOnly:
        return TespRequestWhiteListDataOnly();
      case tespCodeRequestAllData:
        return TespRequestAllData();
      case tespCodeResponseSuccess:
        return TespResponseSuccess();
      case tespCodeResponseError:
        return TespResponseError.withEncodedPayload(encodedPayload);
      case tespCodeResponsePaused:
        return TespResponsePaused();
      case tespCodeResponseInvalidRequest:
        return TespResponseInvalidRequest.withEncodedPayload(encodedPayload);
      case tespCodeResponseAnswer:
        return TespResponseAnswer.withEncodedPayload(encodedPayload);
      default:
        throw ArgumentError.value(code, null, 'Invalid message code');
    }
  }
}

abstract class TespRequest extends TespMessage {}

abstract class TespResponse extends TespMessage {}

abstract class TespMessageWithoutPayload extends TespMessage {}

abstract class TespMessageWithPayload<T> extends TespMessage {
  T get payload;
  Uint8List get encodedPayload;

  TespMessageWithPayload.withPayload(T payload);
  TespMessageWithPayload.withEncodedPayload(Uint8List encodedPayload);
}

abstract class TespMessageWithStringPayload
    implements TespMessageWithPayload<String> {
  Uint8List _encodedPayload;
  String _payload;

  @override
  String get payload => _payload;

  @override
  Uint8List get encodedPayload {
    _encodedPayload ??= utf8.encode(_payload);
    return _encodedPayload;
  }

  @override
  TespMessageWithStringPayload.withPayload(String payload) {
    if (payload == null) {
      throw ArgumentError('payload must not be null for $runtimeType');
    }
    _payload = payload;
  }

  @override
  TespMessageWithStringPayload.withEncodedPayload(Uint8List encodedPayload) {
    if (encodedPayload == null) {
      throw ArgumentError('encodedPayload must not be null for $runtimeType');
    }
    _encodedPayload = encodedPayload;
    _payload = utf8.decode(_encodedPayload);
  }
}

class TespRequestAddEvent extends TespMessageWithStringPayload
    implements TespRequest {
  @override
  final code = TespMessage.tespCodeRequestAddEvent;

  TespRequestAddEvent.withPayload(String payload) : super.withPayload(payload);
  TespRequestAddEvent.withEncodedPayload(Uint8List encodedPayload)
      : super.withEncodedPayload(encodedPayload);
}

class TespRequestPause extends TespMessageWithoutPayload
    implements TespRequest {
  @override
  final code = TespMessage.tespCodeRequestPause;
}

class TespRequestResume extends TespMessageWithoutPayload
    implements TespRequest {
  @override
  final code = TespMessage.tespCodeRequestResume;
}

class TespRequestWhiteListDataOnly extends TespMessageWithoutPayload
    implements TespRequest {
  @override
  final code = TespMessage.tespCodeRequestWhiteListDataOnly;
}

class TespRequestAllData extends TespMessageWithoutPayload
    implements TespRequest {
  @override
  final code = TespMessage.tespCodeRequestAllData;
}

class TespResponseSuccess extends TespMessageWithoutPayload
    implements TespResponse {
  @override
  final code = TespMessage.tespCodeResponseSuccess;
}

class TespResponseError extends TespMessageWithStringPayload
    implements TespResponse {
  @override
  final code = TespMessage.tespCodeResponseError;

  TespResponseError.withPayload(String payload) : super.withPayload(payload);
  TespResponseError.withEncodedPayload(Uint8List encodedPayload)
      : super.withEncodedPayload(encodedPayload);
}

class TespResponsePaused extends TespMessageWithoutPayload
    implements TespResponse {
  @override
  final code = TespMessage.tespCodeResponsePaused;
}

class TespResponseInvalidRequest extends TespMessageWithStringPayload
    implements TespResponse {
  @override
  final code = TespMessage.tespCodeResponseInvalidRequest;

  TespResponseInvalidRequest.withPayload(String payload)
      : super.withPayload(payload);
  TespResponseInvalidRequest.withEncodedPayload(Uint8List encodedPayload)
      : super.withEncodedPayload(encodedPayload);
}

class TespResponseAnswer extends TespMessageWithStringPayload
    implements TespResponse {
  @override
  final code = TespMessage.tespCodeResponseAnswer;

  TespResponseAnswer.withPayload(String payload) : super.withPayload(payload);
  TespResponseAnswer.withEncodedPayload(Uint8List encodedPayload)
      : super.withEncodedPayload(encodedPayload);
}
