import 'package:flutter_test/flutter_test.dart';
import 'package:taqo_survey/model/database_helper.dart';
import 'package:taqo_survey/storage/local_database_builder.dart';
import 'package:taqo_survey/util/table_util.dart';

void main() {
  test('buildQueryCreateTable() with prependIdColumn=true', () {
    var results = '''
    CREATE TABLE a_table (
    _id INTEGER PRIMARY KEY AUTOINCREMENT,
    column_first INTEGER,
    column_second TEXT
    );
    ''';
    expect(
        buildQueryCreateTable(
            'a_table',
            Table(head: [
              'columnName',
              'columnType'
            ], body: [
              'column_first', SqlLiteDatatype.INTEGER, //
              'column_second', SqlLiteDatatype.TEXT, //
            ]),
            prependIdColumn: true),
        equalsIgnoringWhitespace(results));
  });
  test('buildQueryCreateTable() with prependIdColumn=false', () {
    var results = '''
    CREATE TABLE a_table (
    column_first INTEGER,
    column_second TEXT
    );
    ''';
    expect(
        buildQueryCreateTable(
            'a_table',
            Table(head: [
              'columnName',
              'columnType'
            ], body: [
              'column_first', SqlLiteDatatype.INTEGER, //
              'column_second', SqlLiteDatatype.TEXT, //
            ]),
            prependIdColumn: false),
        equalsIgnoringWhitespace(results));
  });
}
