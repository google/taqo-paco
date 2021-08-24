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

import 'package:taqo_common/model/event.dart';
import 'package:test/test.dart';
import 'package:taqo_event_server_protocol/src/json_utils.dart';

void main() {
  group('toJsonObject()', () {
    test('primitive types', () {
      expect(toJsonObject(null), equals(null));
      expect(toJsonObject(1), equals(1));
      expect(toJsonObject('string'), equals('string'));
      expect(toJsonObject(true), equals(true));
    });
    final event1 = Event()
      ..experimentName = 'test1'
      ..experimentId = 1
      ..responses = {'Q1': 'A1', 'Q2': 'A2'};
    final event2 = Event()
      ..experimentName = 'test2'
      ..experimentId = 2
      ..responses = {'Q3': 'A3', 'Q4': 'A4'};
    final event3 = Event()
      ..experimentName = 'test3'
      ..experimentId = 3
      ..responses = {'Q5': 'A5', 'Q6': 'A6'};
    test('list and map', () {
      expect(toJsonObject([1, 2, 3, 4, 5]), equals([1, 2, 3, 4, 5]));
      expect(toJsonObject([1, '2', 3, '4', 5, true, null]),
          equals([1, '2', 3, '4', 5, true, null]));
      expect(
          toJsonObject([
            event1,
            2,
            [event2, '5', event3],
            {'1': event1, '4': 4}
          ]),
          equals([
            event1.toJson(),
            2,
            [event2.toJson(), '5', event3.toJson()],
            {'1': event1.toJson(), '4': 4}
          ]));
      expect(
          toJsonObject({
            '1': '1',
            '2': 2,
            '3': false,
            '4': null,
            '5': event1,
            '6': [1, '2', event2, event3]
          }),
          equals({
            '1': '1',
            '2': 2,
            '3': false,
            '4': null,
            '5': event1.toJson(),
            '6': [1, '2', event2.toJson(), event3.toJson()]
          }));
    });

    test('unsupported objects', () {
      expect(() => toJsonObject({1: 1}),
          throwsA(isA<JsonUnsupportedObjectError>()));
      expect(() => toJsonObject(String),
          throwsA(isA<JsonUnsupportedObjectError>()));
    });
  });
}
