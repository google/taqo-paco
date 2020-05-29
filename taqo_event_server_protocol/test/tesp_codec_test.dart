import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:taqo_common/model/event.dart';
import 'package:taqo_common/util/zoned_date_time.dart';
import 'package:taqo_event_server_protocol/src/tesp_codec.dart';
import 'package:taqo_event_server_protocol/taqo_event_server_protocol.dart';
import 'package:test/test.dart';

import 'tesp_matchers.dart';

void main() {
  group('ChunkedTransformer', () {
    final chunks = [
      [2, 3, 5], [7], [11, 13, 17, 19], [23], //
      [29, 31, 37, 41, 43], [47, 53, 59, 61, 67, 71, 73, 79, 83], [89, 97]
    ];
    test(
        'ChunkedTransformer transform chunked bytes into predefined length pattern',
        () {
      expect(Stream.fromIterable(chunks).transform(ChunkedTransformer(<int>[])),
          emitsInOrder(chunks.cast() + [emitsDone]));
      expect(
          Stream.fromIterable(chunks).transform(ChunkedTransformer([1])),
          emitsInOrder([
            [2], [3], [5], [7], [11], [13], [17], [19], [23], [29], [31], //
            [37], [41], [43], [47], [53], [59], [61], [67], [71], [73], [79], //
            [83], [89], [97], emitsDone
          ]));
      expect(
          Stream.fromIterable(chunks).transform(ChunkedTransformer([2, 3])),
          emitsInOrder([
            [2, 3], [5, 7, 11], [13, 17], [19, 23, 29], [31, 37], //
            [41, 43, 47], [53, 59], [61, 67, 71], [73, 79], [83, 89, 97], //
            emitsDone
          ]));
      expect(
          Stream.fromIterable(chunks).transform(ChunkedTransformer([100, 97])),
          emitsInOrder([
            [
              2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, //
              61, 67, 71, 73, 79, 83, 89, 97
            ],
            emitsDone
          ]));
    });
  });
  group('TespCodec', () {
    final payload =
        '{"a": "b", "c": 1, "d": [1, 2, 3, "e"], "f": "Îñţérñåţîöñåļîžåţîờñ" }';
    final event1 = Event()
      ..responses = json.decode(payload)
      ..experimentName = 'TestExperiment'
      ..experimentId = 12345
      ..responseTime =
          ZonedDateTime.fromIso8601String('2020-05-04T16:21:31.415926-0700')
      ..experimentVersion = 1;
    final event2 = Event()
      ..responses = json.decode(payload)
      ..experimentName = 'TestExperiment'
      ..experimentId = 67890
      ..responseTime =
          ZonedDateTime.fromIso8601String('2020-05-05T16:21:31.415926-0700')
      ..experimentVersion = 2;
    final msgRequestAddEvent = TespRequestPalAddEvents([event1, event2]);
    final msgResponseError = TespResponseError('error', 'message', 'details');
    final msgResponseInvalidRequest =
        TespResponseInvalidRequest.withPayload(''); // Empty payload on purpose
    final msgResponseAnswer = TespResponseAnswer(event1);

    final msgRequestPause = TespRequestPalPause();
    final msgRequestResume = TespRequestPalResume();
    final msgRequestWhiteListDataOnly = TespRequestPalWhiteListDataOnly();
    final msgRequestAllData = TespRequestPalAllData();
    final msgRequestPing = TespRequestPing();
    final msgResponseSuccess = TespResponseSuccess();
    final msgResponsePaused = TespResponsePaused();

    final msgRequestAlarmSchedule = TespRequestAlarmSchedule();
    final msgRequestAlarmCancel = TespRequestAlarmCancel(1);
    final msgRequestAlarmSelectAll = TespRequestAlarmSelectAll();
    final msgRequestAlarmSelectById = TespRequestAlarmSelectById(2);
    final msgRequestNotificationCheckActive =
        TespRequestNotificationCheckActive();
    final msgRequestNotificationCancel = TespRequestNotificationCancel(3);
    final msgRequestNotificationCancelByExperiment =
        TespRequestNotificationCancelByExperiment(4);
    final msgRequestNotificationSelectAll = TespRequestNotificationSelectAll();
    final msgRequestNotificationSelectById =
        TespRequestNotificationSelectById(5);
    final msgRequestNotificationSelectByExperiment =
        TespRequestNotificationSelectByExperiment(6);
    final msgRequestCreateMissedEvent = TespRequestCreateMissedEvent(event1);

    test('encode/decode (non-chunked)', () {
      // Briefly verify that the codec actually converts between [TespMessage] and List<int>.
      expect(tesp.encode((msgRequestPause)), equals([0x01, 0x02]));
      expect(tesp.decode([0x01, 0x02]), equalsTespMessage(msgRequestPause));

      // Now we test by converting back and forth.
      expect(tesp.decode(tesp.encode(msgRequestAddEvent)),
          equalsTespMessage(msgRequestAddEvent));
      expect(tesp.decode(tesp.encode(msgResponseError)),
          equalsTespMessage(msgResponseError));
      expect(tesp.decode(tesp.encode(msgResponseInvalidRequest)),
          equalsTespMessage(msgResponseInvalidRequest));
      expect(tesp.decode(tesp.encode(msgResponseAnswer)),
          equalsTespMessage(msgResponseAnswer));
      expect(tesp.decode(tesp.encode(msgRequestPause)),
          equalsTespMessage(msgRequestPause));
      expect(tesp.decode(tesp.encode(msgRequestResume)),
          equalsTespMessage(msgRequestResume));
      expect(tesp.decode(tesp.encode(msgRequestWhiteListDataOnly)),
          equalsTespMessage(msgRequestWhiteListDataOnly));
      expect(tesp.decode(tesp.encode(msgRequestAllData)),
          equalsTespMessage(msgRequestAllData));
      expect(tesp.decode(tesp.encode(msgRequestPing)),
          equalsTespMessage(msgRequestPing));
      expect(tesp.decode(tesp.encode(msgResponseSuccess)),
          equalsTespMessage(msgResponseSuccess));
      expect(tesp.decode(tesp.encode(msgResponsePaused)),
          equalsTespMessage(msgResponsePaused));

      expect(tesp.decode(tesp.encode(msgRequestAlarmSchedule)),
          equalsTespMessage(msgRequestAlarmSchedule));
      expect(tesp.decode(tesp.encode(msgRequestAlarmCancel)),
          equalsTespMessage(msgRequestAlarmCancel));
      expect(tesp.decode(tesp.encode(msgRequestAlarmSelectAll)),
          equalsTespMessage(msgRequestAlarmSelectAll));
      expect(tesp.decode(tesp.encode(msgRequestAlarmSelectById)),
          equalsTespMessage(msgRequestAlarmSelectById));
      expect(tesp.decode(tesp.encode(msgRequestNotificationCheckActive)),
          equalsTespMessage(msgRequestNotificationCheckActive));
      expect(tesp.decode(tesp.encode(msgRequestNotificationCancel)),
          equalsTespMessage(msgRequestNotificationCancel));
      expect(tesp.decode(tesp.encode(msgRequestNotificationCancelByExperiment)),
          equalsTespMessage(msgRequestNotificationCancelByExperiment));
      expect(tesp.decode(tesp.encode(msgRequestNotificationSelectAll)),
          equalsTespMessage(msgRequestNotificationSelectAll));
      expect(tesp.decode(tesp.encode(msgRequestNotificationSelectById)),
          equalsTespMessage(msgRequestNotificationSelectById));
      expect(tesp.decode(tesp.encode(msgRequestNotificationSelectByExperiment)),
          equalsTespMessage(msgRequestNotificationSelectByExperiment));
      expect(tesp.decode(tesp.encode(msgRequestCreateMissedEvent)),
          equalsTespMessage(msgRequestCreateMissedEvent));
    });

    test('encode/decode (chunked)', () {
      final messages = <TespMessage>[
        msgRequestAddEvent, msgRequestAddEvent, msgRequestPause, //
        msgRequestAddEvent, msgRequestResume, msgRequestAddEvent, //
        msgRequestWhiteListDataOnly, msgRequestAllData, msgResponseSuccess, //
        msgResponseSuccess, msgResponseSuccess, msgResponsePaused, //
        msgResponseSuccess, msgResponseSuccess, msgResponseSuccess, //
        msgResponseInvalidRequest, msgResponseError, msgResponseAnswer, //
        msgRequestPing, msgResponseSuccess, msgRequestAlarmSchedule, //
        msgRequestAlarmCancel, msgRequestAlarmSelectAll, //
        msgRequestAlarmSelectById, msgRequestNotificationCheckActive, //
        msgRequestNotificationCancel,
        msgRequestNotificationCancelByExperiment, //
        msgRequestNotificationSelectAll, msgRequestNotificationSelectById, //
        msgRequestNotificationSelectByExperiment,
        msgRequestCreateMissedEvent, //
        msgRequestPing, msgResponseSuccess
      ];
      final matcher = emitsInOrder(
          messages.map((e) => equalsTespMessage(e)).toList() + [emitsDone]);
      expect(
          Stream.fromIterable(messages)
              .transform(tesp.encoder)
              .transform(tesp.decoder),
          matcher);
      expect(
          Stream.fromIterable(messages)
              .transform(tesp.encoder)
              .transform(ChunkedTransformer([1]))
              .transform(tesp.decoder),
          matcher);
      expect(
          Stream.fromIterable(messages)
              .transform(tesp.encoder)
              .transform(ChunkedTransformer(
                  [3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5, 8, 9, 7, 9]))
              .transform(tesp.decoder),
          matcher);
      expect(
          Stream.fromIterable(messages)
              .transform(tesp.encoder)
              .transform(ChunkedTransformer([10000]))
              .transform(tesp.decoder),
          matcher);
    });
  });
}

class ChunkedTransformer extends StreamTransformerBase<List<int>, List<int>> {
  final pattern;
  ChunkedTransformer(this.pattern);

  @override
  Stream<List<int>> bind(Stream<List<int>> stream) {
    return Stream.eventTransformed(
        stream, (sink) => ChunkedTransformSink(sink, pattern));
  }
}

class ChunkedTransformSink implements EventSink<List<int>> {
  final EventSink<List<int>> _outputSink;
  final List<int> _pattern;
  int _patternIndex = 0;
  Uint8List _currentBuffer;
  int _currentBufferSize = 0;
  int _currentBufferIndex = 0;

  ChunkedTransformSink(this._outputSink, this._pattern) {
    _pattern.retainWhere((element) => element > 0);
    if (_pattern.isNotEmpty) {
      _currentBufferSize = _pattern[_patternIndex];
      _currentBuffer = Uint8List(_currentBufferSize);
    }
  }

  @override
  void add(List<int> event) {
    if (_pattern.isEmpty) {
      if (event is Uint8List) {
        _outputSink.add(event);
      } else {
        _outputSink.add(Uint8List.fromList(event));
      }
    } else {
      for (var data in event) {
        if (_currentBufferIndex < _currentBufferSize) {
          _currentBuffer[_currentBufferIndex] = data;
          _currentBufferIndex++;
        } else {
          _outputSink.add(_currentBuffer);
          _patternIndex = (_patternIndex + 1) % _pattern.length;
          _currentBufferSize = _pattern[_patternIndex];
          _currentBuffer = Uint8List(_currentBufferSize);
          _currentBufferIndex = 0;
          _currentBuffer[_currentBufferIndex] = data;
          _currentBufferIndex++;
        }
      }
    }
  }

  @override
  void addError(e, [StackTrace stackTrace]) {
    _outputSink.addError(e, stackTrace);
  }

  @override
  void close() {
    if (_pattern.isNotEmpty) {
      if (_currentBufferIndex < _currentBufferSize) {
        _outputSink
            .add(Uint8List.view(_currentBuffer.buffer, 0, _currentBufferIndex));
      } else {
        _outputSink.add(_currentBuffer);
      }
    }
    _outputSink.close();
  }
}
