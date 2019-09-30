import 'package:meta/meta.dart';

/// A table in traditional meaning, with rows and columns.
class Table {
  List<String> head;
  List<dynamic> body;
  int columnCount;
  Map<String, int> headToIndexMap = {};

  Table({@required this.head, this.body}) {
    columnCount = head.length;
    for (var i = 0; i < columnCount; i++) {
      headToIndexMap[head[i]] = i;
    }
  }

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
