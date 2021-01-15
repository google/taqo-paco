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

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:taqo_common/model/action_specification.dart';
import 'package:taqo_common/model/event.dart';
import 'package:taqo_common/model/experiment.dart';
import 'package:taqo_common/model/notification_holder.dart';
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
    final experiment1 = Experiment.fromJson(jsonDecode(
        '{"title":"test experiment 1","description":"test","creator":"tester","organization":"test org","contactEmail":"test@email.com","contactPhone":null,"publicKey":null,"joinDate":null,"id":12345,"informedConsentForm":"test","recordPhoneDetails":false,"extraDataCollectionDeclarations":[],"deleted":false,"modifyDate":"2020/05/19","published":true,"admins":["test@email.com"],"publishedUsers":[],"version":3,"groups":[{"name":"SYSTEM","groupType":"SYSTEM","customRendering":false,"customRenderingCode":null,"fixedDuration":false,"startDate":null,"endDate":null,"logActions":false,"logShutdown":false,"backgroundListen":false,"backgroundListenSourceIdentifier":null,"accessibilityListen":false,"actionTriggers":[],"inputs":[{"name":"joined","required":false,"conditional":false,"conditionExpression":null,"responseType":"open text","text":"joined","likertSteps":5,"leftSideLabel":null,"rightSideLabel":null,"listChoices":null,"multiselect":false},{"name":"schedule","required":false,"conditional":false,"conditionExpression":null,"responseType":"open text","text":"schedule","likertSteps":5,"leftSideLabel":null,"rightSideLabel":null,"listChoices":null,"multiselect":false}],"endOfDayGroup":false,"endOfDayReferredGroupName":null,"feedback":{"text":"Thanks for Participating!","type":0},"feedbackType":0,"rawDataAccess":true,"logNotificationEvents":false},{"name":"Quick survey","groupType":"SURVEY","customRendering":false,"customRenderingCode":null,"fixedDuration":false,"startDate":null,"endDate":null,"logActions":false,"logShutdown":false,"backgroundListen":false,"backgroundListenSourceIdentifier":null,"accessibilityListen":false,"actionTriggers":[],"inputs":[{"name":"input1","required":false,"conditional":false,"conditionExpression":null,"responseType":"likert_smileys","text":"Pick one","likertSteps":5,"leftSideLabel":null,"rightSideLabel":null,"listChoices":null,"multiselect":false}],"endOfDayGroup":false,"endOfDayReferredGroupName":null,"feedback":{"text":"Thanks for Participating!","type":0},"feedbackType":0,"rawDataAccess":true,"logNotificationEvents":false}],"ringtoneUri":"/assets/ringtone/Paco Bark","postInstallInstructions":"<b>You have successfully joined the experiment!</b><br/><br/>\\nNo need to do anything else for now.<br/><br/>\\nPaco will send you a notification when it is time to participate.<br/><br/>\\nBe sure your ringer/buzzer is on so you will hear the notification.","anonymousPublic":true,"visualizations":[]}'));
    final experiment2 = Experiment.fromJson(jsonDecode(
        '{"title":"test experiment 2","description":"test","creator":"tester","organization":"test org","contactEmail":"test@email.com","contactPhone":null,"publicKey":null,"joinDate":null,"id":67890,"informedConsentForm":"test","recordPhoneDetails":false,"extraDataCollectionDeclarations":[],"deleted":false,"modifyDate":"2020/05/19","published":true,"admins":["test@email.com"],"publishedUsers":[],"version":3,"groups":[{"name":"SYSTEM","groupType":"SYSTEM","customRendering":false,"customRenderingCode":null,"fixedDuration":false,"startDate":null,"endDate":null,"logActions":false,"logShutdown":false,"backgroundListen":false,"backgroundListenSourceIdentifier":null,"accessibilityListen":false,"actionTriggers":[],"inputs":[{"name":"joined","required":false,"conditional":false,"conditionExpression":null,"responseType":"open text","text":"joined","likertSteps":5,"leftSideLabel":null,"rightSideLabel":null,"listChoices":null,"multiselect":false},{"name":"schedule","required":false,"conditional":false,"conditionExpression":null,"responseType":"open text","text":"schedule","likertSteps":5,"leftSideLabel":null,"rightSideLabel":null,"listChoices":null,"multiselect":false}],"endOfDayGroup":false,"endOfDayReferredGroupName":null,"feedback":{"text":"Thanks for Participating!","type":0},"feedbackType":0,"rawDataAccess":true,"logNotificationEvents":false},{"name":"Quick survey","groupType":"SURVEY","customRendering":false,"customRenderingCode":null,"fixedDuration":false,"startDate":null,"endDate":null,"logActions":false,"logShutdown":false,"backgroundListen":false,"backgroundListenSourceIdentifier":null,"accessibilityListen":false,"actionTriggers":[],"inputs":[{"name":"input1","required":false,"conditional":false,"conditionExpression":null,"responseType":"likert_smileys","text":"Pick one","likertSteps":5,"leftSideLabel":null,"rightSideLabel":null,"listChoices":null,"multiselect":false}],"endOfDayGroup":false,"endOfDayReferredGroupName":null,"feedback":{"text":"Thanks for Participating!","type":0},"feedbackType":0,"rawDataAccess":true,"logNotificationEvents":false}],"ringtoneUri":"/assets/ringtone/Paco Bark","postInstallInstructions":"<b>You have successfully joined the experiment!</b><br/><br/>\\nNo need to do anything else for now.<br/><br/>\\nPaco will send you a notification when it is time to participate.<br/><br/>\\nBe sure your ringer/buzzer is on so you will hear the notification.","anonymousPublic":false,"visualizations":[]}'));
    final alarm1 = ActionSpecification.fromJson(jsonDecode(
        '{"time":"2020-06-05T10:52:19.440595","timeUTC":"2020-06-05T17:52:19.440595Z","experiment":{"title":"Schedule Test","description":"Desc","creator":"maksymowych.test@gmail.com","organization":"Org","contactEmail":"steve@steve.com","contactPhone":"911","publicKey":null,"joinDate":null,"id":4514766238777344,"informedConsentForm":"Consent","recordPhoneDetails":false,"extraDataCollectionDeclarations":[],"deleted":false,"modifyDate":"2020/06/01","published":true,"admins":["maksymowych.test@gmail.com"],"publishedUsers":[],"version":107,"groups":[{"name":"Question 1","groupType":"APPUSAGE_ANDROID","customRendering":false,"customRenderingCode":null,"fixedDuration":true,"startDate":"2020/5/28","endDate":"2020/6/6","logActions":true,"logShutdown":false,"backgroundListen":false,"backgroundListenSourceIdentifier":null,"accessibilityListen":false,"actionTriggers":[{"type":"interruptTrigger","actions":[{"id":1590599443730,"type":"pacoNotificationAction","actionCode":1,"snoozeCount":0,"timeout":15,"delay":0,"color":0,"dismissible":true,"msgText":"Time to participate"}],"id":1590599443729,"cues":[{"cueCode":4,"cueSource":"Xfce4-terminal","cueAEClassName":null,"cueAEEventType":1,"cueAEContentDescription":null,"id":1590599443731}],"minimumBuffer":1,"timeWindow":true,"startTimeMillis":32400000,"endTimeMillis":61200000,"weekends":false}],"inputs":[{"name":"input1","required":false,"conditional":false,"conditionExpression":"input2 > 3","responseType":"likert_smileys","text":"Hows it going?","likertSteps":5,"leftSideLabel":null,"rightSideLabel":null,"listChoices":null,"multiselect":false}],"endOfDayGroup":false,"endOfDayReferredGroupName":null,"feedback":{"text":"Thanks for Participating!","type":0},"feedbackType":0,"rawDataAccess":false,"logNotificationEvents":false}],"ringtoneUri":"/assets/ringtone/Paco Bark","postInstallInstructions":"Instructions","anonymousPublic":false,"visualizations":[]},"experimentGroup":{"name":"Question 1","groupType":"APPUSAGE_ANDROID","customRendering":false,"customRenderingCode":null,"fixedDuration":true,"startDate":"2020/5/28","endDate":"2020/6/6","logActions":true,"logShutdown":false,"backgroundListen":false,"backgroundListenSourceIdentifier":null,"accessibilityListen":false,"actionTriggers":[{"type":"interruptTrigger","actions":[{"id":1590599443730,"type":"pacoNotificationAction","actionCode":1,"snoozeCount":0,"timeout":15,"delay":0,"color":0,"dismissible":true,"msgText":"Time to participate"}],"id":1590599443729,"cues":[{"cueCode":4,"cueSource":"Xfce4-terminal","cueAEClassName":null,"cueAEEventType":1,"cueAEContentDescription":null,"id":1590599443731}],"minimumBuffer":1,"timeWindow":true,"startTimeMillis":32400000,"endTimeMillis":61200000,"weekends":false}],"inputs":[{"name":"input1","required":false,"conditional":false,"conditionExpression":"input2 > 3","responseType":"likert_smileys","text":"Hows it going?","likertSteps":5,"leftSideLabel":null,"rightSideLabel":null,"listChoices":null,"multiselect":false}],"endOfDayGroup":false,"endOfDayReferredGroupName":null,"feedback":{"text":"Thanks for Participating!","type":0},"feedbackType":0,"rawDataAccess":false,"logNotificationEvents":false},"actionTrigger":{"type":"interruptTrigger","actions":[{"id":1590599443730,"type":"pacoNotificationAction","actionCode":1,"snoozeCount":0,"timeout":15,"delay":0,"color":0,"dismissible":true,"msgText":"Time to participate"}],"id":1590599443729,"cues":[{"cueCode":4,"cueSource":"Xfce4-terminal","cueAEClassName":null,"cueAEEventType":1,"cueAEContentDescription":null,"id":1590599443731}],"minimumBuffer":1,"timeWindow":true,"startTimeMillis":32400000,"endTimeMillis":61200000,"weekends":false},"action":{"id":1590599443730,"type":"pacoNotificationAction","actionCode":1,"snoozeCount":0,"timeout":15,"delay":0,"color":0,"dismissible":true,"msgText":"Time to participate"},"actionTriggerSpecId":1590599443731}'));
    final notification1 = NotificationHolder(666, 1234567890, 1337, 1, 5000,
        'group1', 1, 2, '', 'time to participate', 3);

    final msgRequestAddEvent = TespRequestPalAddEvents([event1, event2]);
    final msgResponseError = TespResponseError('error', 'message', 'details');
    final msgResponseInvalidRequest =
        TespResponseInvalidRequest.withPayload(''); // Empty payload on purpose
    final msgResponseAnswer = TespResponseAnswer(event1);

    final msgRequestPause = TespRequestPalPause();
    final msgRequestResume = TespRequestPalResume();
    final msgRequestAllowlistDataOnly = TespRequestPalAllowlistDataOnly();
    final msgRequestAllData = TespRequestPalAllData();
    final msgRequestPing = TespRequestPing();
    final msgResponseSuccess = TespResponseSuccess();
    final msgResponsePaused = TespResponsePaused();

    final msgRequestAlarmSchedule = TespRequestAlarmSchedule();
    final msgRequestAlarmAdd = TespRequestAlarmAdd(alarm1);
    final msgRequestAlarmCancel = TespRequestAlarmCancel(1);
    final msgRequestAlarmSelectAll = TespRequestAlarmSelectAll();
    final msgRequestAlarmSelectById = TespRequestAlarmSelectById(2);
    final msgRequestAlarmRemove = TespRequestAlarmRemove(8);
    final msgRequestNotificationCheckActive =
        TespRequestNotificationCheckActive();
    final msgRequestNotificationAdd = TespRequestNotificationAdd(notification1);
    final msgRequestNotificationCancel = TespRequestNotificationCancel(3);
    final msgRequestNotificationCancelByExperiment =
        TespRequestNotificationCancelByExperiment(4);
    final msgRequestNotificationSelectAll = TespRequestNotificationSelectAll();
    final msgRequestNotificationSelectById =
        TespRequestNotificationSelectById(5);
    final msgRequestNotificationSelectByExperiment =
        TespRequestNotificationSelectByExperiment(6);
    final msgRequestNotificationRemove = TespRequestNotificationRemove(9);
    final msgRequestNotificationRemoveAll = TespRequestNotificationRemoveAll();
    final msgRequestCreateMissedEvent = TespRequestCreateMissedEvent(event1);
    final msgRequestExperimentSaveJoined =
        TespRequestExperimentSaveJoined([experiment1, experiment2]);
    final msgRequestExperimentSelectJoined =
        TespRequestExperimentSelectJoined();
    final msgRequestExperimentSelectById = TespRequestExperimentSelectById(7);
    final msgRequestExperimentGetPausedStatuses =
        TespRequestExperimentGetPausedStatuses([experiment1, experiment2]);
    final msgRequestExperimentSetPausedStatus =
        TespRequestExperimentSetPausedStatus(experiment1, true);

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
      expect(tesp.decode(tesp.encode(msgRequestAllowlistDataOnly)),
          equalsTespMessage(msgRequestAllowlistDataOnly));
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
      expect(tesp.decode(tesp.encode(msgRequestAlarmAdd)),
          equalsTespMessage(msgRequestAlarmAdd));
      expect(tesp.decode(tesp.encode(msgRequestAlarmCancel)),
          equalsTespMessage(msgRequestAlarmCancel));
      expect(tesp.decode(tesp.encode(msgRequestAlarmSelectAll)),
          equalsTespMessage(msgRequestAlarmSelectAll));
      expect(tesp.decode(tesp.encode(msgRequestAlarmSelectById)),
          equalsTespMessage(msgRequestAlarmSelectById));
      expect(tesp.decode(tesp.encode(msgRequestAlarmRemove)),
          equalsTespMessage(msgRequestAlarmRemove));
      expect(tesp.decode(tesp.encode(msgRequestNotificationCheckActive)),
          equalsTespMessage(msgRequestNotificationCheckActive));
      expect(tesp.decode(tesp.encode(msgRequestNotificationAdd)),
          equalsTespMessage(msgRequestNotificationAdd));
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
      expect(tesp.decode(tesp.encode(msgRequestNotificationRemove)),
          equalsTespMessage(msgRequestNotificationRemove));
      expect(tesp.decode(tesp.encode(msgRequestNotificationRemoveAll)),
          equalsTespMessage(msgRequestNotificationRemoveAll));

      expect(tesp.decode(tesp.encode(msgRequestExperimentSaveJoined)),
          equalsTespMessage(msgRequestExperimentSaveJoined));
      expect(tesp.decode(tesp.encode(msgRequestExperimentSelectJoined)),
          equalsTespMessage(msgRequestExperimentSelectJoined));
      expect(tesp.decode(tesp.encode(msgRequestExperimentSelectById)),
          equalsTespMessage(msgRequestExperimentSelectById));
      expect(tesp.decode(tesp.encode(msgRequestExperimentGetPausedStatuses)),
          equalsTespMessage(msgRequestExperimentGetPausedStatuses));
      expect(tesp.decode(tesp.encode(msgRequestExperimentSetPausedStatus)),
          equalsTespMessage(msgRequestExperimentSetPausedStatus));
    });

    test('encode/decode (chunked)', () {
      final messages = <TespMessage>[
        msgRequestAddEvent, msgRequestAddEvent, msgRequestPause, //
        msgRequestAddEvent, msgRequestResume, msgRequestAddEvent, //
        msgRequestAllowlistDataOnly, msgRequestAllData, msgResponseSuccess, //
        msgResponseSuccess, msgResponseSuccess, msgResponsePaused, //
        msgResponseSuccess, msgResponseSuccess, msgResponseSuccess, //
        msgResponseInvalidRequest, msgResponseError, msgResponseAnswer, //
        msgRequestPing, msgResponseSuccess, msgRequestAlarmSchedule, //
        msgRequestAlarmAdd, msgRequestAlarmCancel, msgRequestAlarmSelectAll, //
        msgRequestAlarmSelectById, msgRequestAlarmRemove, //
        msgRequestNotificationCheckActive, //
        msgRequestNotificationAdd, msgRequestNotificationCancel, //
        msgRequestNotificationCancelByExperiment, //
        msgRequestNotificationSelectAll, msgRequestNotificationSelectById, //
        msgRequestNotificationSelectByExperiment, //
        msgRequestNotificationRemove, msgRequestNotificationRemoveAll, //
        msgRequestCreateMissedEvent, msgRequestExperimentSaveJoined, //
        msgRequestExperimentSelectJoined, msgRequestExperimentSelectJoined, //
        msgRequestExperimentGetPausedStatuses, //
        msgRequestExperimentSetPausedStatus, //
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
