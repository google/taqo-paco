import 'package:data_binding_builder/src/database_description.dart';
import 'package:data_binding_builder/src/local_database_builder.dart';
import 'package:data_binding_builder/src/map_literal.dart';
import 'package:test/test.dart';

void main() {
  group('buildQueryCreateTable()', () {
    test('buildQueryCreateTable() with prependIdColumn=true', () {
      var dbDescription = DatabaseDescription(meta: {"prependIdColumn": true});
      dbDescription.addTable(name: 'a_table', specification: [
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
      expect(buildSqlCreateTable(dbDescription, 'a_table'),
          equalsIgnoringWhitespace(results));
    });

    test('buildQueryCreateTable() with prependIdColumn=false', () {
      var dbDescription = DatabaseDescription(meta: {"prependIdColumn": false});
      dbDescription.addTable(name: 'a_table', specification: [
        'column_first', SqlLiteDatatype.INTEGER, //
        'column_second', SqlLiteDatatype.TEXT, //
      ]);
      var results = '''
    CREATE TABLE a_table (
    column_first INTEGER,
    column_second TEXT
    );
    ''';
      expect(buildSqlCreateTable(dbDescription, 'a_table'),
          equalsIgnoringWhitespace(results));
    });
  });

  group('buildDartFieldMap()', () {
    test('buildDartFieldsMap() with normal input', () {
      var dbDescription = DatabaseDescription(meta: {"prependIdColumn": true});
      dbDescription.addTable(name: 'a_table', specification: [
        'column_first', SqlLiteDatatype.INTEGER, //
        'column_second', SqlLiteDatatype.TEXT, //
      ]);
      var results = '''
    {
      'column_first': aTable.columnFirst,
      'column_second': aTable.columnSecond,
    }
    ''';

      expect(buildDartFieldsMap(dbDescription, 'a_table', 'aTable'),
          equalsIgnoringWhitespace(results));
    });

    test('buildQueryCreateTable() errors', () {
      var dbDescription = DatabaseDescription(meta: {"prependIdColumn": false});
      dbDescription.addTable(name: 'a_table', specification: [
        'column_first', SqlLiteDatatype.INTEGER, //
        'column_second', SqlLiteDatatype.TEXT, //
      ]);
      expect(() => buildDartFieldsMap(dbDescription, 'a_table', 'aTable'),
          throwsUnimplementedError);
      expect(() => buildDartFieldsMap(dbDescription, 'b_table', 'aTable'),
          throwsArgumentError);
    });
  });

  group('buildDartFieldMapWithTranslationTemplate()', () {
    test('buildDartFieldsMapWithTranslationTemplate() with normal input', () {
      var dbDescription = DatabaseDescription(meta: {"prependIdColumn": true});
      dbDescription.addTable(
          name: 'a_table',
          withCustomHead: MapLiteral({
            'columnName': String,
            'columnType': SqlLiteDatatype,
            'translation': String
          }),
          specification: [
            'column_first', SqlLiteDatatype.INTEGER, "{{object}}.first", //
            'column_second', SqlLiteDatatype.TEXT, "{{object}}.second", //
          ]);
      var results = '''
    {
      'column_first': aTable.first,
      'column_second': aTable.second,
    }
    ''';

      expect(
          buildDartFieldsMapWithTranslationTemplate(
              dbDescription, 'a_table', {'object': 'aTable'}),
          equalsIgnoringWhitespace(results));
    });

    test('buildQueryCreateTableWithTranslationTemplate() errors', () {
      var dbDescription = DatabaseDescription(meta: {"prependIdColumn": false});
      dbDescription.addTable(
          name: 'a_table',
          withCustomHead: MapLiteral({
            'columnName': String,
            'columnType': SqlLiteDatatype,
            'translation': String
          }),
          specification: [
            'column_first', SqlLiteDatatype.INTEGER, "{{object}}.first", //
            'column_second', SqlLiteDatatype.TEXT, "{{object}}.second", //
          ]);
      expect(
          () => buildDartFieldsMapWithTranslationTemplate(
              dbDescription, 'a_table', {'object': 'aTable'}),
          throwsUnimplementedError);
      expect(
          () => buildDartFieldsMapWithTranslationTemplate(
              dbDescription, 'b_table', {'object': 'aTable'}),
          throwsArgumentError);
    });
  });
}
