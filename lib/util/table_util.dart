import 'package:meta/meta.dart';

/// A table in traditional meaning, with rows and columns.
class Table {
  /// Table head (column names)
  List<String> head;

  /// The content of the table stored in a row major order, should be of size rowCount x columnCount.
  List<dynamic> body;

  /// The number of columns in the table
  int columnCount;

  /// A map from column name in the head to the column index (starting from 0)
  Map<String, int> headToIndexMap = {};

  Table({@required this.head, this.body}) {
    columnCount = head.length;
    for (var i = 0; i < columnCount; i++) {
      headToIndexMap[head[i]] = i;
    }
  }

  /// Get a row iterator, where each row is represented by a map with table
  /// head/column name as key and the actual table entry as value.
  Iterable<Map<String, dynamic>> get rowIterator sync* {
    var rowCount = body.length ~/
        columnCount; // Incomplete last row, if existing, will be ignored
    for (var i = 0; i < rowCount; i++) {
      Map<String, dynamic> map = {};
      for (var j = 0; j < columnCount; j++) {
        map[head[j]] = body[i * columnCount + j];
      }
      yield map;
    }
  }
}
