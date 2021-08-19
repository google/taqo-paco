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

// @dart=2.9

import 'dart:convert';
import 'dart:typed_data';

import 'package:taqo_common/model/action_specification.dart';
import 'package:taqo_common/model/event.dart';
import 'package:taqo_common/model/experiment.dart';
import 'package:taqo_common/model/notification_holder.dart';
import 'package:taqo_event_server_protocol/src/json_utils.dart';

abstract class TespMessage {
  /// The response/request code for the message, which must fit in an 8-bit
  /// unsigned integer (0x00-0xFF).
  int get code;

  static const tespCodeRequestPalAddEvents = 0x01;
  static const tespCodeRequestPalPause = 0x02;
  static const tespCodeRequestPalResume = 0x04;
  static const tespCodeRequestPalAllowlistDataOnly = 0x06;
  static const tespCodeRequestPalAllData = 0x08;
  static const tespCodeRequestPing = 0x0A;

  static const tespCodeRequestAlarmSchedule = 0x10;
  static const tespCodeRequestAlarmCancel = 0x11;
  static const tespCodeRequestAlarmSelectAll = 0x12;
  static const tespCodeRequestAlarmSelectById = 0x13;
  static const tespCodeRequestAlarmAdd = 0x15;
  static const tespCodeRequestAlarmRemove = 0x17;

  static const tespCodeRequestNotificationCheckActive = 0x20;
  static const tespCodeRequestNotificationCancel = 0x21;
  static const tespCodeRequestNotificationCancelByExperiment = 0x23;
  static const tespCodeRequestNotificationSelectAll = 0x24;
  static const tespCodeRequestNotificationSelectById = 0x25;
  static const tespCodeRequestNotificationSelectByExperiment = 0x27;
  static const tespCodeRequestNotificationAdd = 0x29;
  static const tespCodeRequestNotificationRemove = 0x2b;
  static const tespCodeRequestNotificationRemoveAll = 0x2c;

  static const tespCodeRequestCreateMissedEvent = 0x31;

  static const tespCodeRequestExperimentSaveJoined = 0x41;
  static const tespCodeRequestExperimentSelectJoined = 0x42;
  static const tespCodeRequestExperimentSelectById = 0x43;
  static const tespCodeRequestExperimentGetPausedStatuses = 0x45;
  static const tespCodeRequestExperimentSetPausedStatus = 0x47;

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
      case tespCodeRequestPalAddEvents:
        return TespRequestPalAddEvents.withEncodedPayload(encodedPayload);
      case tespCodeRequestPalPause:
        return TespRequestPalPause();
      case tespCodeRequestPalResume:
        return TespRequestPalResume();
      case tespCodeRequestPalAllowlistDataOnly:
        return TespRequestPalAllowlistDataOnly();
      case tespCodeRequestPalAllData:
        return TespRequestPalAllData();
      case tespCodeRequestPing:
        return TespRequestPing();
      case tespCodeRequestAlarmSchedule:
        return TespRequestAlarmSchedule();
      case tespCodeRequestAlarmAdd:
        return TespRequestAlarmAdd.withEncodedPayload(encodedPayload);
      case tespCodeRequestAlarmCancel:
        return TespRequestAlarmCancel.withEncodedPayload(encodedPayload);
      case tespCodeRequestAlarmSelectAll:
        return TespRequestAlarmSelectAll();
      case tespCodeRequestAlarmSelectById:
        return TespRequestAlarmSelectById.withEncodedPayload(encodedPayload);
      case tespCodeRequestAlarmRemove:
        return TespRequestAlarmRemove.withEncodedPayload(encodedPayload);
      case tespCodeRequestNotificationCheckActive:
        return TespRequestNotificationCheckActive();
      case tespCodeRequestNotificationAdd:
        return TespRequestNotificationAdd.withEncodedPayload(encodedPayload);
      case tespCodeRequestNotificationCancel:
        return TespRequestNotificationCancel.withEncodedPayload(encodedPayload);
      case tespCodeRequestNotificationCancelByExperiment:
        return TespRequestNotificationCancelByExperiment.withEncodedPayload(
            encodedPayload);
      case tespCodeRequestNotificationSelectAll:
        return TespRequestNotificationSelectAll();
      case tespCodeRequestNotificationSelectById:
        return TespRequestNotificationSelectById.withEncodedPayload(
            encodedPayload);
      case tespCodeRequestNotificationSelectByExperiment:
        return TespRequestNotificationSelectByExperiment.withEncodedPayload(
            encodedPayload);
      case tespCodeRequestNotificationRemove:
        return TespRequestNotificationRemove.withEncodedPayload(encodedPayload);
      case tespCodeRequestNotificationRemoveAll:
        return TespRequestNotificationRemoveAll();
      case tespCodeRequestCreateMissedEvent:
        return TespRequestCreateMissedEvent.withEncodedPayload(encodedPayload);
      case tespCodeRequestExperimentSaveJoined:
        return TespRequestExperimentSaveJoined.withEncodedPayload(
            encodedPayload);
      case tespCodeRequestExperimentSelectJoined:
        return TespRequestExperimentSelectJoined();
      case tespCodeRequestExperimentSelectById:
        return TespRequestExperimentSelectById.withEncodedPayload(
            encodedPayload);
      case tespCodeRequestExperimentGetPausedStatuses:
        return TespRequestExperimentGetPausedStatuses.withEncodedPayload(
            encodedPayload);
      case tespCodeRequestExperimentSetPausedStatus:
        return TespRequestExperimentSetPausedStatus.withEncodedPayload(
            encodedPayload);
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
  final _codec = (T == String ? utf8 : json.fuse(utf8));

  T createObjectFromJson(jsonObject) => jsonObject as T;

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
    try {
      setPayload(createObjectFromJson(_codec.decode(encodedPayload)));
    } catch (e) {
      throw FormatException('encodedPayload is not valid for $runtimeType');
    }
    _encodedPayload = encodedPayload;
  }
}

mixin EventsDeserializer on Payload<List<Event>> {
  @override
  List<Event> createObjectFromJson(jsonObject) {
    return (jsonObject as List).map((e) => Event.fromJson(e)).toList();
  }
}

mixin EventDeserializer on Payload<Event> {
  @override
  Event createObjectFromJson(jsonObject) {
    return Event.fromJson(jsonObject);
  }
}

mixin ExperimentsDeserializer on Payload<List<Experiment>> {
  @override
  List<Experiment> createObjectFromJson(jsonObject) {
    return (jsonObject as List).map((e) => Experiment.fromJson(e)).toList();
  }
}

mixin AlarmDeserializer on Payload<ActionSpecification> {
  @override
  ActionSpecification createObjectFromJson(jsonObject) {
    return ActionSpecification.fromJson(jsonObject);
  }
}

mixin NotificationDeserializer on Payload<NotificationHolder> {
  @override
  NotificationHolder createObjectFromJson(jsonObject) {
    return NotificationHolder.fromJson(jsonObject);
  }
}

mixin IntegersDeserializer on Payload<List<int>> {
  @override
  List<int> createObjectFromJson(jsonObject) {
    return (jsonObject as List).cast<int>();
  }
}

class TespRequestPalAddEvents extends TespRequest
    with Payload<List<Event>>, EventsDeserializer {
  @override
  final code = TespMessage.tespCodeRequestPalAddEvents;

  List<Event> get events => payload;

  TespRequestPalAddEvents(List<Event> events) {
    setPayload(events);
  }
  TespRequestPalAddEvents.withEventsJson(json) {
    setPayload(createObjectFromJson(json));
  }
  TespRequestPalAddEvents.withEncodedPayload(Uint8List encodedPayload) {
    setPayloadWithEncoded(encodedPayload);
  }
}

class TespRequestPalPause extends TespRequest {
  @override
  final code = TespMessage.tespCodeRequestPalPause;
}

class TespRequestPalResume extends TespRequest {
  @override
  final code = TespMessage.tespCodeRequestPalResume;
}

class TespRequestPalAllowlistDataOnly extends TespRequest {
  @override
  final code = TespMessage.tespCodeRequestPalAllowlistDataOnly;
}

class TespRequestPalAllData extends TespRequest {
  @override
  final code = TespMessage.tespCodeRequestPalAllData;
}

class TespRequestPing extends TespRequest {
  @override
  final code = TespMessage.tespCodeRequestPing;
}

class TespRequestAlarmSchedule extends TespRequest {
  @override
  final code = TespMessage.tespCodeRequestAlarmSchedule;
}

class TespRequestAlarmAdd extends TespRequest
    with Payload<ActionSpecification>, AlarmDeserializer {
  @override
  final code = TespMessage.tespCodeRequestAlarmAdd;

  ActionSpecification get alarm => payload;

  TespRequestAlarmAdd(alarm) {
    setPayload(alarm);
  }
  TespRequestAlarmAdd.withAlarmJson(json) {
    setPayload(createObjectFromJson(json));
  }
  TespRequestAlarmAdd.withEncodedPayload(Uint8List encodedPayload) {
    setPayloadWithEncoded(encodedPayload);
  }
}

class TespRequestAlarmCancel extends TespRequest with Payload<int> {
  @override
  final code = TespMessage.tespCodeRequestAlarmCancel;

  int get alarmId => payload;

  TespRequestAlarmCancel(int alarmId) {
    setPayload(alarmId);
  }

  TespRequestAlarmCancel.withEncodedPayload(Uint8List encodedPayload) {
    setPayloadWithEncoded(encodedPayload);
  }
}

class TespRequestAlarmSelectAll extends TespRequest {
  @override
  final code = TespMessage.tespCodeRequestAlarmSelectAll;
}

class TespRequestAlarmSelectById extends TespRequest with Payload<int> {
  @override
  final code = TespMessage.tespCodeRequestAlarmSelectById;

  int get alarmId => payload;

  TespRequestAlarmSelectById(int alarmId) {
    setPayload(alarmId);
  }

  TespRequestAlarmSelectById.withEncodedPayload(Uint8List encodedPayload) {
    setPayloadWithEncoded(encodedPayload);
  }
}

class TespRequestAlarmRemove extends TespRequest with Payload<int> {
  @override
  final code = TespMessage.tespCodeRequestAlarmRemove;

  int get alarmId => payload;

  TespRequestAlarmRemove(int alarmId) {
    setPayload(alarmId);
  }

  TespRequestAlarmRemove.withEncodedPayload(Uint8List encodedPayload) {
    setPayloadWithEncoded(encodedPayload);
  }
}

class TespRequestNotificationCheckActive extends TespRequest {
  @override
  final code = TespMessage.tespCodeRequestNotificationCheckActive;
}

class TespRequestNotificationAdd extends TespRequest
    with Payload<NotificationHolder>, NotificationDeserializer {
  @override
  final code = TespMessage.tespCodeRequestNotificationAdd;

  NotificationHolder get notification => payload;

  TespRequestNotificationAdd(notification) {
    setPayload(notification);
  }
  TespRequestNotificationAdd.withNotificationJson(json) {
    setPayload(createObjectFromJson(json));
  }
  TespRequestNotificationAdd.withEncodedPayload(Uint8List encodedPayload) {
    setPayloadWithEncoded(encodedPayload);
  }
}

class TespRequestNotificationCancel extends TespRequest with Payload<int> {
  @override
  final code = TespMessage.tespCodeRequestNotificationCancel;

  int get notificationId => payload;

  TespRequestNotificationCancel(int notificationId) {
    setPayload(notificationId);
  }

  TespRequestNotificationCancel.withEncodedPayload(Uint8List encodedPayload) {
    setPayloadWithEncoded(encodedPayload);
  }
}

class TespRequestNotificationCancelByExperiment extends TespRequest
    with Payload<int> {
  @override
  final code = TespMessage.tespCodeRequestNotificationCancelByExperiment;

  int get experimentId => payload;

  TespRequestNotificationCancelByExperiment(int experimentId) {
    setPayload(experimentId);
  }

  TespRequestNotificationCancelByExperiment.withEncodedPayload(
      Uint8List encodedPayload) {
    setPayloadWithEncoded(encodedPayload);
  }
}

class TespRequestNotificationSelectAll extends TespRequest {
  @override
  final code = TespMessage.tespCodeRequestNotificationSelectAll;
}

class TespRequestNotificationSelectById extends TespRequest with Payload<int> {
  @override
  final code = TespMessage.tespCodeRequestNotificationSelectById;

  int get notificationId => payload;

  TespRequestNotificationSelectById(int notificationId) {
    setPayload(notificationId);
  }

  TespRequestNotificationSelectById.withEncodedPayload(
      Uint8List encodedPayload) {
    setPayloadWithEncoded(encodedPayload);
  }
}

class TespRequestNotificationSelectByExperiment extends TespRequest
    with Payload<int> {
  @override
  final code = TespMessage.tespCodeRequestNotificationSelectByExperiment;

  int get experimentId => payload;

  TespRequestNotificationSelectByExperiment(int experimentId) {
    setPayload(experimentId);
  }

  TespRequestNotificationSelectByExperiment.withEncodedPayload(
      Uint8List encodedPayload) {
    setPayloadWithEncoded(encodedPayload);
  }
}

class TespRequestNotificationRemove extends TespRequest with Payload<int> {
  @override
  final code = TespMessage.tespCodeRequestNotificationRemove;

  int get notificationId => payload;

  TespRequestNotificationRemove(int notificationId) {
    setPayload(notificationId);
  }

  TespRequestNotificationRemove.withEncodedPayload(Uint8List encodedPayload) {
    setPayloadWithEncoded(encodedPayload);
  }
}

class TespRequestNotificationRemoveAll extends TespRequest {
  @override
  final code = TespMessage.tespCodeRequestNotificationRemoveAll;
}

class TespRequestCreateMissedEvent extends TespRequest
    with Payload<Event>, EventDeserializer {
  @override
  final code = TespMessage.tespCodeRequestCreateMissedEvent;

  Event get event => payload;

  TespRequestCreateMissedEvent(Event event) {
    setPayload(event);
  }
  TespRequestCreateMissedEvent.withEventJson(json) {
    setPayload(Event.fromJson(json));
  }
  TespRequestCreateMissedEvent.withEncodedPayload(Uint8List encodedPayload) {
    setPayloadWithEncoded(encodedPayload);
  }
}

class TespRequestExperimentSaveJoined extends TespRequest
    with Payload<List<Experiment>>, ExperimentsDeserializer {
  @override
  final code = TespMessage.tespCodeRequestExperimentSaveJoined;

  List<Experiment> get experiments => payload;

  TespRequestExperimentSaveJoined(List<Experiment> experiments) {
    setPayload(experiments);
  }
  TespRequestExperimentSaveJoined.withExperimentsJson(json) {
    setPayload(createObjectFromJson(json));
  }
  TespRequestExperimentSaveJoined.withEncodedPayload(Uint8List encodedPayload) {
    setPayloadWithEncoded(encodedPayload);
  }
}

class TespRequestExperimentSelectJoined extends TespRequest {
  @override
  final code = TespMessage.tespCodeRequestExperimentSelectJoined;
}

class TespRequestExperimentSelectById extends TespRequest with Payload<int> {
  @override
  final code = TespMessage.tespCodeRequestExperimentSelectById;

  int get experimentId => payload;

  TespRequestExperimentSelectById(int experimentId) {
    setPayload(experimentId);
  }

  TespRequestExperimentSelectById.withEncodedPayload(Uint8List encodedPayload) {
    setPayloadWithEncoded(encodedPayload);
  }
}

class TespRequestExperimentGetPausedStatuses extends TespRequest
    with Payload<List<int>>, IntegersDeserializer {
  @override
  final code = TespMessage.tespCodeRequestExperimentGetPausedStatuses;

  List<int> get experimentIds => payload;

  TespRequestExperimentGetPausedStatuses(Iterable<Experiment> experiments) {
    setPayload([for (var experiment in experiments) experiment.id]);
  }

  TespRequestExperimentGetPausedStatuses.withEncodedPayload(
      Uint8List encodedPayload) {
    setPayloadWithEncoded(encodedPayload);
  }
}

class TespRequestExperimentSetPausedStatus extends TespRequest
    with Payload<List> {
  @override
  final code = TespMessage.tespCodeRequestExperimentSetPausedStatus;

  int get experimentId => payload[0];
  bool get paused => payload[1];

  TespRequestExperimentSetPausedStatus(Experiment experiment, bool paused) {
    setPayload([experiment.id, paused]);
  }

  TespRequestExperimentSetPausedStatus.withEncodedPayload(
      Uint8List encodedPayload) {
    setPayloadWithEncoded(encodedPayload);
    if (payload.length != 2 || payload[0] is! int || payload[1] is! bool) {
      throw FormatException('encodedPayload is invalid for $runtimeType');
    }
  }
}

class TespResponseSuccess extends TespResponse {
  @override
  final code = TespMessage.tespCodeResponseSuccess;
}

class TespResponseError extends TespResponse with Payload<String> {
  @override
  final code = TespMessage.tespCodeResponseError;

  static const tespServerErrorDatabase = 'server-database';
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

  @override
  String toString() {
    return 'TespResponseError-$errorCode: $errorMessage';
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

class TespResponseAnswer extends TespResponse with Payload<Object> {
  @override
  final code = TespMessage.tespCodeResponseAnswer;

  TespResponseAnswer(dynamic object) : this.withJson(toJsonObject(object));

  TespResponseAnswer.withJson(Object json) {
    setPayload(json);
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
