// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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
