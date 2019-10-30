import 'package:test/test.dart';

import 'package:data_binding_builder/src/database_description.dart';
import 'package:data_binding_builder/src/local_database_builder.dart';

void main() {
  group('buildQueryCreateTable()', () {
    test('buildQueryCreateTable() with prependIdColumn=true', () {
      var dbDescription = DatabaseDescription(
          meta: {DatabaseDescription.META_PREPEND_ID_COLUMN: true});
      dbDescription.addTableSpecWithFormat(
          name: 'a_table',
          specFormat: DatabaseDescription.SPEC_FMT_NT,
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
      dbDescription.addTableSpecWithFormat(
          name: 'a_table',
          specFormat: DatabaseDescription.SPEC_FMT_NT,
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
      dbDescription.addTableSpecWithFormat(
          name: 'a_table',
          specFormat: DatabaseDescription.SPEC_FMT_NT,
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

      expect(buildDartFieldsMap(dbDescription, 'a_table', 'aTable'),
          equalsIgnoringWhitespace(results));
    });

    test('buildQueryCreateTable() errors with prependIdColumn=true', () {
      var dbDescription = DatabaseDescription(
          meta: {DatabaseDescription.META_PREPEND_ID_COLUMN: true});
      dbDescription.addTableSpecWithFormat(
          name: 'a_table',
          specFormat: DatabaseDescription.SPEC_FMT_NT,
          specContent: [
            ['column_first', SqlLiteDatatype.INTEGER],
            ['column_second', SqlLiteDatatype.TEXT],
          ]);
      expect(() => buildDartFieldsMap(dbDescription, 'b_table', 'aTable'),
          throwsArgumentError);
    });

    test('buildQueryCreateTable() errors with prependIdColumn=false', () {
      var dbDescription = DatabaseDescription(
          meta: {DatabaseDescription.META_PREPEND_ID_COLUMN: false});
      dbDescription.addTableSpecWithFormat(
          name: 'a_table',
          specFormat: DatabaseDescription.SPEC_FMT_NT,
          specContent: [
            ['column_first', SqlLiteDatatype.INTEGER],
            ['column_second', SqlLiteDatatype.TEXT],
          ]);
      expect(() => buildDartFieldsMap(dbDescription, 'a_table', 'aTable'),
          throwsUnimplementedError);
      // Note: compare the following with the similar test above when
      // prependIdColumn=true, which throws ArgumentError instead of UnimplementedError.
      // The difference is caused by "lazy" evaluation of a sync* function.
      expect(() => buildDartFieldsMap(dbDescription, 'b_table', 'aTable'),
          throwsUnimplementedError);
    });
  });

  group('buildDartFieldMapWithTranslationTemplate()', () {
    test('buildDartFieldsMapWithTranslationTemplate() with normal input', () {
      var dbDescription = DatabaseDescription(
          meta: {DatabaseDescription.META_PREPEND_ID_COLUMN: true});
      dbDescription.addTableSpecWithFormat(
          name: 'a_table',
          specFormat: DatabaseDescription.SPEC_FMT_NTTr,
          specContent: [
            ['column_first', SqlLiteDatatype.INTEGER, '{{object}}.first'],
            ['column_second', SqlLiteDatatype.TEXT, '{{object}}.second'],
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

    test(
        'buildQueryCreateTableWithTranslationTemplate() errors with prependIdColumn=true',
        () {
      var dbDescription = DatabaseDescription(
          meta: {DatabaseDescription.META_PREPEND_ID_COLUMN: true});
      dbDescription.addTableSpecWithFormat(
          name: 'a_table',
          specFormat: DatabaseDescription.SPEC_FMT_NTTr,
          specContent: [
            ['column_first', SqlLiteDatatype.INTEGER, '{{object}}.first'],
            ['column_second', SqlLiteDatatype.TEXT, '{{object}}.second'],
          ]);
      expect(
          () => buildDartFieldsMapWithTranslationTemplate(
              dbDescription, 'b_table', {'object': 'aTable'}),
          throwsArgumentError);
    });

    test(
        'buildQueryCreateTableWithTranslationTemplate() errors with prependIdColumn=false',
        () {
      var dbDescription = DatabaseDescription(
          meta: {DatabaseDescription.META_PREPEND_ID_COLUMN: false});
      dbDescription.addTableSpecWithFormat(
          name: 'a_table',
          specFormat: DatabaseDescription.SPEC_FMT_NTTr,
          specContent: [
            ['column_first', SqlLiteDatatype.INTEGER, '{{object}}.first'],
            ['column_second', SqlLiteDatatype.TEXT, '{{object}}.second'],
          ]);
      expect(
          () => buildDartFieldsMapWithTranslationTemplate(
              dbDescription, 'a_table', {'object': 'aTable'}),
          throwsUnimplementedError);
      expect(
          () => buildDartFieldsMapWithTranslationTemplate(
              dbDescription, 'b_table', {'object': 'aTable'}),
          throwsUnimplementedError);
    });
  });
}
