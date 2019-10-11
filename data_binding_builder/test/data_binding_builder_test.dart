import 'package:data_binding_builder/src/database_helper.dart';
import 'package:data_binding_builder/src/local_database_builder.dart';
import 'package:test/test.dart';

void main() {
  group('buildQueryCreateTable()', () {
    test('buildQueryCreateTable() with prependIdColumn=true', () {
      var db = DatabaseDescription(meta: {"prependIdColumn": true});
      db.addTable(name: 'a_table', specification: [
        'column_first', SqlLiteDatatype.INTEGER, //
        'column_second', SqlLiteDatatype.TEXT, //
      ]);
      var results = '''
    CREATE TABLE a_table (
    _id INTEGER PRIMARY KEY AUTOINCREMENT,
    column_first INTEGER,
    column_second TEXT
    );
    ''';
      expect(buildSqlCreateTable(db, 'a_table'),
          equalsIgnoringWhitespace(results));
    });

    test('buildQueryCreateTable() with prependIdColumn=false', () {
      var db = DatabaseDescription(meta: {"prependIdColumn": false});
      db.addTable(name: 'a_table', specification: [
        'column_first', SqlLiteDatatype.INTEGER, //
        'column_second', SqlLiteDatatype.TEXT, //
      ]);
      var results = '''
    CREATE TABLE a_table (
    column_first INTEGER,
    column_second TEXT
    );
    ''';
      expect(buildSqlCreateTable(db, 'a_table'),
          equalsIgnoringWhitespace(results));
    });
  });

  group('buildDartFieldMap()', () {
    test('buildDartFieldsMap() with normal input', () {
      var db = DatabaseDescription(meta: {"prependIdColumn": true});
      db.addTable(name: 'a_table', specification: [
        'column_first', SqlLiteDatatype.INTEGER, //
        'column_second', SqlLiteDatatype.TEXT, //
      ]);
      var results = '''
    {
      '_id': aTable.id,
      'column_first': aTable.columnFirst,
      'column_second': aTable.columnSecond,
    }
    ''';

      expect(buildDartFieldsMap(db, 'a_table', 'aTable'),
          equalsIgnoringWhitespace(results));
    });

    test('buildQueryCreateTable() errors', () {
      var db = DatabaseDescription(meta: {"prependIdColumn": false});
      db.addTable(name: 'a_table', specification: [
        'column_first', SqlLiteDatatype.INTEGER, //
        'column_second', SqlLiteDatatype.TEXT, //
      ]);
      expect(() => buildDartFieldsMap(db, 'a_table', 'aTable'),
          throwsUnimplementedError);
      expect(
          () => buildDartFieldsMap(db, 'b_table', 'aTable'), throwsStateError);
    });
  });
}
