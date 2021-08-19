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

import 'dart:collection';

import 'package:test/test.dart';

import 'package:data_binding_builder/src/table.dart';

void main() {
  group('Table for normal use', () {
    var table = Table(
        columnSpec: LinkedHashMap.from({
          'column1': Table.columnProcessorTakeType(String),
          'column2': Table.columnProcessorTakeType(int)
        }),
        content: [
          ['row1', 1],
          ['row2', 2],
          ['row3', 3]
        ]);

    test('Table basics', () {
      expect(table.columnCount, equals(2));
      expect(table.rowCount, equals(3));
    });

    test('Table.rowsAsMaps', () {
      expect(
          table.rowsAsMaps,
          equals([
            {'column1': 'row1', 'column2': 1},
            {'column1': 'row2', 'column2': 2},
            {'column1': 'row3', 'column2': 3},
          ]));
    });
  });

  group('Table errors', () {
    test('ill-formed table content', () {
      expect(
          () => Table(
                  columnSpec: LinkedHashMap.from({
                    'column1': Table.columnProcessorTakeType(String),
                    'column2': Table.columnProcessorTakeType(int)
                  }),
                  content: [
                    ['row1', 1],
                    ['row2'],
                    ['row3', 3]
                  ]),
          throwsArgumentError);

      expect(
          () => Table(
                  columnSpec: LinkedHashMap.from({
                    'column1': Table.columnProcessorTakeType(String),
                    'column2': Table.columnProcessorTakeType(int)
                  }),
                  content: [
                    ['row1', 1],
                    ['row2', 2, 4],
                    ['row3', 3]
                  ]),
          throwsArgumentError);
    });

    test('Table content type errors', () {
      expect(
          () => Table(
                  columnSpec: LinkedHashMap.from({
                    'column1': Table.columnProcessorTakeType(String),
                    'column2': Table.columnProcessorTakeType(int)
                  }),
                  content: [
                    ['row1', 1],
                    ['row2', 'wrong type'],
                    ['row3', 3]
                  ]),
          throwsArgumentError);

      expect(
          () => Table(
                  columnSpec: LinkedHashMap.from({
                    'column1': Table.columnProcessorTakeType(String),
                    'column2': Table.columnProcessorTakeType(int)
                  }),
                  content: [
                    ['row1', 1],
                    [2, 2],
                    ['row3', 3]
                  ]),
          throwsArgumentError);
    });
  });
}
