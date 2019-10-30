import 'dart:mirrors';

import 'package:meta/meta.dart';

import 'map_literal.dart';

/// A table in traditional meaning, with rows and columns.
/// Note the column and rows here has nothing to do with a SQL table.
class Table {
  /// Table column specifications (names and types)
  final MapLiteral<String, Type> columnSpecification;

  /// A list storing the column names.
  final List<String> _columnNames;

  /// A list storing the column types.
  final List<Type> _columnTypes;

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
      this._columnTypes,
      this.content,
      this.columnCount,
      this.rowCount,
      this._columnNameToIndexMap);

  factory Table(
      {@required MapLiteral<String, Type> columnSpec,
      @required List<List<dynamic>> content}) {
    final List<String> columnNames = columnSpec.keys.toList();
    final List<Type> columnTypes = columnSpec.values.toList();
    final int columnCount = columnNames.length;
    final int rowCount = content.length;

    for (var i = 0; i < rowCount; i++) {
      if (content[i]?.length != columnCount) {
        throw ArgumentError(
            'The ${i}-th row of the table content is invalid. The size of each row should be the number of columms.');
      }
      for (var j = 0; j < columnCount; j++) {
        if (!(reflectType(content[i][j].runtimeType)
            .isSubtypeOf(reflectType(columnTypes[j])))) {
          throw ArgumentError('The table content is invalid. '
              'content[${i}][${j}]=${content[i][j]} should be of type ${columnTypes[j]}, '
              'instead of type ${content[i][j].runtimeType}');
        }
      }
    }
    final Map<String, int> headToIndexMap =
        columnNames.asMap().map((k, v) => MapEntry(v, k));
    return Table._(columnSpec, columnNames, columnTypes, content, columnCount,
        rowCount, headToIndexMap);
  }

  /// Get a rows iterator, where each row is represented by a map with table
  /// column name as key and the actual table entry as value.
  Iterable<Map<String, dynamic>> get rowsAsMaps => content
      .map((row) => row.asMap().map((i, v) => MapEntry(_columnNames[i], v)));
}
