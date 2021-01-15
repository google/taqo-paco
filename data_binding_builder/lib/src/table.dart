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

import 'dart:collection';
import 'dart:mirrors';

import 'package:meta/meta.dart';

/// A table in traditional meaning, with rows and columns.
/// Note the column and rows here has nothing to do with a SQL table.
class Table {
  /// Table column specifications (names and types)
  final LinkedHashMap<String, Function> columnSpecification;

  /// A list storing the column names.
  final List<String> _columnNames;

  /// A list storing the column processors.
  final List<Function> _columnProcessors;

  /// The content of the table stored in a list of lists.
  final List<List<dynamic>> content;

  /// The number of columns in the table
  final int columnCount;

  /// The number of rows in the table
  final int rowCount;

  /// A map from column name in the head to the column index (starting from 0)
  final Map<String, int> _columnNameToIndexMap;

  Table._(
      this.columnSpecification,
      this._columnNames,
      this._columnProcessors,
      this.content,
      this.columnCount,
      this.rowCount,
      this._columnNameToIndexMap);

  factory Table(
      {@required LinkedHashMap<String, Function> columnSpec,
      @required List<List<dynamic>> content}) {
    final List<String> columnNames = columnSpec.keys.toList();
    final List<Function> columnProcessors = columnSpec.values.toList();
    final int columnCount = columnNames.length;
    final int rowCount = content.length;
    List<List<dynamic>> processedContent =
        List.generate(rowCount, (_) => List(columnCount));

    for (var i = 0; i < rowCount; i++) {
      if (content[i]?.length != columnCount) {
        throw ArgumentError(
            'The ${i}-th row of the table content is invalid. The size of each row should be the number of columms.');
      }
      for (var j = 0; j < columnCount; j++) {
        try {
          processedContent[i][j] = columnProcessors[j](content[i][j]);
        } catch (e, s) {
          throw ArgumentError('The table content is invalid. '
              '${columnProcessors[j]} throws the following error while processing '
              'content[${i}][${j}]=${content[i][j]}:\n $e\n'
              'And the stack trace is:\n $s');
        }
      }
    }

    final Map<String, int> headToIndexMap =
        columnNames.asMap().map((k, v) => MapEntry(v, k));
    return Table._(columnSpec, columnNames, columnProcessors, processedContent,
        columnCount, rowCount, headToIndexMap);
  }

  /// Get a rows iterator, where each row is represented by a map with table
  /// column name as key and the actual table entry as value.
  Iterable<Map<String, dynamic>> get rowsAsMaps => content
      .map((row) => row.asMap().map((i, v) => MapEntry(_columnNames[i], v)));

  static T columnProcessorIdentity<T>(T entry) => entry;

  static dynamic Function(dynamic) columnProcessorTakeType(Type type) {
    return (entry) {
      if ((reflectType(entry.runtimeType).isSubtypeOf(reflectType(type)))) {
        return entry;
      } else {
        throw ArgumentError(
            '$entry should be of type $type, inseted of type ${entry.runtimeType}');
      }
    };
  }
}
