import 'package:meta/meta.dart';
import 'package:taqo_survey/util/table_util.dart';

class DatabaseDescription {
  final Map<String, dynamic> meta;
  final List<String> defaultHead;
  Map<String, Table> tableDescriptions = {};

  DatabaseDescription(
      {this.defaultHead = const ['columnName', 'columnType'], this.meta});

  void addTable(
      {@required String name,
      List<String> withCustomHead,
      List<dynamic> description}) {
    withCustomHead ??= defaultHead;
    tableDescriptions[name] = Table(head: withCustomHead, body: description);
  }
}

enum SqlLiteDatatype { NULL, INTEGER, REAL, TEXT, BLOB }
