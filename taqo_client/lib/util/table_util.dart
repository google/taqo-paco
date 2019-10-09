import 'dart:mirrors';

import 'package:meta/meta.dart';
import 'package:taqo_client/util/map_literal.dart';

/// A table in traditional meaning, with rows and columns.
class Table {
  /// Table head (column names and types)
  final MapLiteral<String, Type> head;

  /// A list storing the column names.
  final List<String> _headNames;

  /// A list storing the column types.
  final List<Type> _headTypes;

  /// The number of columns in the table
  int _columnCount;

  int get columnCount {
    _columnCount ??= _headNames.length;
    return _columnCount;
  }

  /// A map from column name in the head to the column index (starting from 0)
  Map<String, int> _headToIndexMap;

  Map<String, int> get headToIndexMap {
    _headToIndexMap ??= _headNames.asMap().map((k, v) => MapEntry(v, k));
    return _headToIndexMap;
  }

  /// The content of the table stored in a row major order, should be of size rowCount x columnCount.
  List<dynamic> body;

  Table({@required this.head, this.body})
      : _headNames = head.keys.toList(),
        _headTypes = head.values.toList();

  /// Validate the table body
  bool validateBody() {
    if (body.length % columnCount != 0) {
      throw StateError(
          'The table "body" is invalid. The size of "body" should be a multiple of the size of "head".');
    }
    var rowCount = body.length ~/ columnCount;
    for (var i = 0; i < rowCount; i++) {
      var rowBase = i * columnCount;
      for (var j = 0; j < columnCount; j++) {
        if (!(reflectType(body[rowBase + j].runtimeType)
            .isSubtypeOf(reflectType(_headTypes[j])))) {
          throw StateError('The table "body" is invalid. '
              'body[${rowBase + j}]=${body[rowBase + j]} should be of type $_headTypes[j], '
              'instead of type ${body[rowBase + j].runtimeType}');
        }
      }
    }
  }

  /// Get a row iterator, where each row is represented by a map with table
  /// head/column name as key and the actual table entry as value.
  Iterable<Map<String, dynamic>> get rowIterator sync* {
    validateBody();
    var rowCount = body.length ~/ columnCount;
    for (var i = 0; i < rowCount; i++) {
      Map<String, dynamic> map = {};
      var rowBase = i * columnCount;
      for (var j = 0; j < columnCount; j++) {
        map[_headNames[j]] = body[rowBase + j];
      }
      yield map;
    }
  }
}
