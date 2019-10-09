import 'package:data_binding_builder/src/database_helper.dart';
import 'package:data_binding_builder/src/local_database_builder.dart';
import 'package:data_binding_builder/src/map_literal.dart';
import 'package:data_binding_builder/src/table.dart';
import 'package:test/test.dart';

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
        buildSqlCreateTable(
            'a_table',
            Table(
                head: MapLiteral(
                    {'columnName': String, 'columnType': SqlLiteDatatype}),
                body: [
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
        buildSqlCreateTable(
            'a_table',
            Table(
                head: MapLiteral(
                    {'columnName': String, 'columnType': SqlLiteDatatype}),
                body: [
                  'column_first', SqlLiteDatatype.INTEGER, //
                  'column_second', SqlLiteDatatype.TEXT, //
                ]),
            prependIdColumn: false),
        equalsIgnoringWhitespace(results));
  });
}
