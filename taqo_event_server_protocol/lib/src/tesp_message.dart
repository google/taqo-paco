import 'dart:convert';
import 'dart:typed_data';

import 'package:taqo_common/model/event.dart';

abstract class TespMessage {
  /// The response/request code for the message, which must fit in an 8-bit
  /// unsigned integer (0x00-0xFF).
  int get code;

  static const tespCodeRequestAddEvent = 0x01;
  static const tespCodeRequestPause = 0x02;
  static const tespCodeRequestResume = 0x04;
  static const tespCodeRequestWhiteListDataOnly = 0x06;
  static const tespCodeRequestAllData = 0x08;
  static const tespCodeRequestPing = 0x0A;
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
      case tespCodeRequestPing:
        return TespRequestPing();
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

mixin Payload<T> on TespMessage {
  static S identity<S>(S x) => x;
  static final jsonFactories = <Type, Function>{
    String: identity,
    Event: (json) => Event.fromJson(json)
  };
  final _codec = (T == String ? utf8 : json.fuse(utf8));

  Uint8List _encodedPayload;
  T _payload;

  T get payload => _payload;

  Uint8List get encodedPayload {
    _encodedPayload ??= _codec.encode(_payload);
    return _encodedPayload;
  }

  void setPayload(T payload) {
    if (payload == null) {
      throw ArgumentError('payload must not be null for $runtimeType');
    }
    if (_payload == null) {
      _payload = payload;
    } else {
      throw StateError('payload cannot be set twice');
    }
  }

  void setPayloadWithEncoded(Uint8List encodedPayload) {
    if (encodedPayload == null) {
      throw ArgumentError('encodedPayload must not be null for $runtimeType');
    }
    setPayload(jsonFactories[T](_codec.decode(encodedPayload)));
    _encodedPayload = encodedPayload;
  }
}

class TespRequestAddEvent extends TespRequest with Payload<Event> {
  @override
  final code = TespMessage.tespCodeRequestAddEvent;

  TespRequestAddEvent(Event event) {
    setPayload(event);
  }
  TespRequestAddEvent.withEventJson(json) {
    setPayload(Event.fromJson(json));
  }
  TespRequestAddEvent.withEncodedPayload(Uint8List encodedPayload) {
    setPayloadWithEncoded(encodedPayload);
  }
}

class TespRequestPause extends TespRequest {
  @override
  final code = TespMessage.tespCodeRequestPause;
}

class TespRequestResume extends TespRequest {
  @override
  final code = TespMessage.tespCodeRequestResume;
}

class TespRequestWhiteListDataOnly extends TespRequest {
  @override
  final code = TespMessage.tespCodeRequestWhiteListDataOnly;
}

class TespRequestAllData extends TespRequest {
  @override
  final code = TespMessage.tespCodeRequestAllData;
}

class TespRequestPing extends TespRequest {
  @override
  final code = TespMessage.tespCodeRequestPing;
}

class TespResponseSuccess extends TespResponse {
  @override
  final code = TespMessage.tespCodeResponseSuccess;
}

class TespResponseError extends TespResponse with Payload<String> {
  @override
  final code = TespMessage.tespCodeResponseError;

  static const tespServerErrorUnknown = 'server-unknown';
  static const tespClientErrorResponseTimeout = 'client-response-timeout';
  static const tespClientErrorServerCloseEarly = 'client-server-close-early';
  static const tespClientErrorLostConnection = 'client-lost-connection';
  static const tespClientErrorChunkTimeout = 'client-chunk-timeout';
  static const tespClientErrorDecoding = 'client-decoding-error';
  static const tespClientErrorPayloadDecoding = 'client-payload-decoding-error';
  static const tespClientErrorUnknown = 'client-unknown';

  static const _jsonKeyCode = 'code';
  static const _jsonKeyMessage = 'message';
  static const _jsonKeyDetails = 'details';

  String _errorCode;
  String _errorMessage;
  String _errorDetails;

  String get errorCode => _errorCode;
  String get errorMessage => _errorMessage;
  String get errorDetails => _errorDetails;

  TespResponseError.withEncodedPayload(Uint8List encodedPayload) {
    setPayloadWithEncoded(encodedPayload);
    var error = json.decode(payload);
    _errorCode = error[_jsonKeyCode];
    _errorMessage = error[_jsonKeyMessage];
    _errorDetails = error[_jsonKeyDetails];
  }

  TespResponseError(this._errorCode, [this._errorMessage, this._errorDetails]) {
    var payload = json.encode({
      _jsonKeyCode: errorCode,
      _jsonKeyMessage: errorMessage,
      _jsonKeyDetails: errorDetails
    });
    setPayload(payload);
  }
}

class TespResponsePaused extends TespResponse {
  @override
  final code = TespMessage.tespCodeResponsePaused;
}

class TespResponseInvalidRequest extends TespResponse with Payload<String> {
  @override
  final code = TespMessage.tespCodeResponseInvalidRequest;

  TespResponseInvalidRequest.withPayload(String payload) {
    setPayload(payload);
  }
  TespResponseInvalidRequest.withEncodedPayload(Uint8List encodedPayload) {
    setPayloadWithEncoded(encodedPayload);
  }
}

class TespResponseAnswer extends TespResponse with Payload<String> {
  @override
  final code = TespMessage.tespCodeResponseAnswer;

  TespResponseAnswer.withPayload(String payload) {
    setPayload(payload);
  }
  TespResponseAnswer.withEncodedPayload(Uint8List encodedPayload) {
    setPayloadWithEncoded(encodedPayload);
  }
}

/// This type of message should never be encoded or transported. It can be added
/// to a stream of TespMessage as an event to be processed.
abstract class TespEvent implements TespResponse, TespRequest {
  @override
  final code = null;
}

/// [TespEventMessageArrived] can be fired when the TESP decoder receives the last
/// byte of the encoded message, but may not have processed it.
class TespEventMessageArrived extends TespEvent {}

/// [TespEventMessageExpected] can be fired when the TESP decoder receives the
/// header of a message, but the rest of the message may be yet to arrive.
class TespEventMessageExpected extends TespEvent {}
