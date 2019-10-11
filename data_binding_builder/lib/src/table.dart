import 'dart:mirrors';

import 'package:meta/meta.dart';

import 'map_literal.dart';

/// A table in traditional meaning, with rows and columns.
class Table {
  /// Table head (column names and types)
  final MapLiteral<String, Type> head;

  /// A list storing the column names.
  final List<String> _headNames;

  /// A list storing the column types.
  final List<Type> _headTypes;

  /// The content of the table stored in a row major order, should be of size rowCount x columnCount.
  final List<dynamic> body;

  /// The number of columns in the table
  final int columnCount;

  /// The number of rows in the table
  final int rowCount;

  /// A map from column name in the head to the column index (starting from 0)
  final Map<String, int> _headToIndexMap;

  Table._(this.head, this._headNames, this._headTypes, this.body,
      this.columnCount, this.rowCount, this._headToIndexMap);

  factory Table(
      {@required MapLiteral<String, Type> head, @required List<dynamic> body}) {
    final List<String> headNames = head.keys.toList();
    final List<Type> headTypes = head.values.toList();
    final int columnCount = headNames.length;
    if (body.length % columnCount != 0) {
      throw StateError(
          'The table "body" is invalid. The size of "body" should be a multiple of the size of "head".');
    }
    final int rowCount = body.length ~/ columnCount;
    for (var i = 0; i < rowCount; i++) {
      var rowBase = i * columnCount;
      for (var j = 0; j < columnCount; j++) {
        if (!(reflectType(body[rowBase + j].runtimeType)
            .isSubtypeOf(reflectType(headTypes[j])))) {
          throw StateError('The table "body" is invalid. '
              'body[${rowBase + j}]=${body[rowBase + j]} should be of type $headTypes[j], '
              'instead of type ${body[rowBase + j].runtimeType}');
        }
      }
    }
    final Map<String, int> headToIndexMap =
        headNames.asMap().map((k, v) => MapEntry(v, k));
    return Table._(head, headNames, headTypes, body, columnCount, rowCount,
        headToIndexMap);
  }

  /// Get a rows iterator, where each row is represented by a map with table
  /// head/column name as key and the actual table entry as value.
  Iterable<Map<String, dynamic>> get rows sync* {
    for (var i = 0; i < rowCount; i++) {
      Map<String, dynamic> map = {};
      var rowBase = i * columnCount;
      for (var j = 0; j < columnCount; j++) {
        map[_headNames[j]] = body[rowBase + j];
      }
      yield map;
    }
  }

  /// Get an iterator for one column.
  Iterable<dynamic> getColumn(String headName) sync* {
    var j = _headToIndexMap[headName];
    for (var i = 0; i < rowCount; i++) {
      yield body[i * columnCount + j];
    }
  }
}
