import 'package:test/test.dart';

import 'package:data_binding_builder/src/database_description.dart';
import 'package:data_binding_builder/src/local_database_builder.dart';
import 'package:data_binding_builder/src/string_util.dart';

String _defaultFromObjectTranslator(DatabaseColumnSpecification dbColSpec) =>
    '${dbColSpec.dbTableInfo.objectName}.${snakeCaseToCamelCase(dbColSpec.name)}';

void main() {
  group('buildQueryCreateTable()', () {
    test('buildQueryCreateTable() with prependIdColumn=true', () {
      var dbDescription = DatabaseDescription(
          meta: {DatabaseDescription.META_PREPEND_ID_COLUMN: true});
      dbDescription.addTableSpec(
          name: 'a_table',
          defaultFromObjectTranslator: _defaultFromObjectTranslator,
          specContent: [
            ['column_first', SqlLiteDatatype.INTEGER],
            ['column_second', SqlLiteDatatype.TEXT],
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
      var dbDescription = DatabaseDescription(
          meta: {DatabaseDescription.META_PREPEND_ID_COLUMN: false});
      dbDescription.addTableSpec(
          name: 'a_table',
          defaultFromObjectTranslator: _defaultFromObjectTranslator,
          specContent: [
            ['column_first', SqlLiteDatatype.INTEGER],
            ['column_second', SqlLiteDatatype.TEXT],
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
      var dbDescription = DatabaseDescription(
          meta: {DatabaseDescription.META_PREPEND_ID_COLUMN: true});
      dbDescription.addTableSpec(
          name: 'a_table',
          objectName: 'aTable',
          defaultFromObjectTranslator: _defaultFromObjectTranslator,
          specContent: [
            ['column_first', SqlLiteDatatype.INTEGER],
            ['column_second', SqlLiteDatatype.TEXT],
          ]);
      var results = '''
    {
      'column_first': aTable.columnFirst,
      'column_second': aTable.columnSecond,
    }
    ''';

      expect(buildDartFieldsMap(dbDescription, 'a_table'),
          equalsIgnoringWhitespace(results));
    });

    test('buildDartFieldMap() errors with prependIdColumn=true', () {
      var dbDescription = DatabaseDescription(
          meta: {DatabaseDescription.META_PREPEND_ID_COLUMN: true});
      dbDescription.addTableSpec(
          name: 'a_table',
          objectName: 'aTable',
          defaultFromObjectTranslator: _defaultFromObjectTranslator,
          specContent: [
            ['column_first', SqlLiteDatatype.INTEGER],
            ['column_second', SqlLiteDatatype.TEXT],
          ]);
      expect(() => buildDartFieldsMap(dbDescription, 'b_table'),
          throwsArgumentError);
    });

    test('buildDartFieldMap() errors with prependIdColumn=false', () {
      var dbDescription = DatabaseDescription(
          meta: {DatabaseDescription.META_PREPEND_ID_COLUMN: false});
      dbDescription.addTableSpec(
          name: 'a_table',
          objectName: 'aTable',
          defaultFromObjectTranslator: _defaultFromObjectTranslator,
          specContent: [
            ['column_first', SqlLiteDatatype.INTEGER],
            ['column_second', SqlLiteDatatype.TEXT],
          ]);
      expect(() => buildDartFieldsMap(dbDescription, 'a_table'),
          throwsUnimplementedError);
      // Note: compare the following with the similar test above when
      // prependIdColumn=true, which throws ArgumentError instead of UnimplementedError.
      // The difference is caused by "lazy" evaluation of a sync* function.
      expect(() => buildDartFieldsMap(dbDescription, 'b_table'),
          throwsUnimplementedError);
    });
  });
}
