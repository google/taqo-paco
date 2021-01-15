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

import 'dart:collection';
import 'dart:mirrors';

import 'package:meta/meta.dart';

import 'database_description_base.dart';
import 'table.dart';

typedef TranslatorFromObject = String Function(DatabaseColumnSpecification);

class DatabaseTableInfo {
  final String name;
  final String objectName;
  final String parentObjectName;
  final bool prependIdColumn;
  DatabaseTableInfo(
      {@required this.name,
      this.objectName,
      this.parentObjectName,
      this.prependIdColumn = false});
}

class DatabaseColumnSpecification {
  final String name;
  final SqlLiteDatatype type;
  String fromObject;
  final String constraints;
  final DatabaseTableInfo dbTableInfo;

  String get typeAsString => getEnumName(type);

  DatabaseColumnSpecification({
    @required this.name,
    @required this.type,
    @required TranslatorFromObject fromObject,
    @required this.constraints,
    @required this.dbTableInfo,
  }) {
    this.fromObject = fromObject(this);
  }
}

class DatabaseDescription extends DatabaseDescriptionBase {
  // Predefined meta keys
  static const META_VERSION = 'version';
  static const META_PREPEND_ID_COLUMN = 'prependIdColumn';

  // Predefined [Table] column names for DB table specifications
  static const _SPEC_COLUMN_NAME = 'columnName';
  static const _SPEC_COLUMN_TYPE = 'columnType';
  static const _SPEC_FROM_OBJECT = 'fromObject';
  static const _SPEC_CONSTRAINTS = 'constraints';

  DatabaseDescription({Map<String, dynamic> meta}) : super(meta: meta);

  Map<String, DatabaseTableInfo> dbTableInfos = {};

  void addTableSpec(
      {@required String name, // DB table name
      String objectName,
      String parentObjectName,
      TranslatorFromObject defaultFromObjectTranslator,
      Function defaultToObjectTranslator,
      bool prependIdColumnOverride,
      @required List<List<dynamic>> specContent // content of the specification
      }) {
    dbTableInfos[name] = DatabaseTableInfo(
        name: name,
        objectName: objectName,
        parentObjectName: parentObjectName,
        prependIdColumn:
            prependIdColumnOverride ?? meta[META_PREPEND_ID_COLUMN] ?? false);

    if (specContent == null || specContent.isEmpty) {
      throw ArgumentError('Empty or null specContent');
    }

    // Complete the specContent
    for (var i = 0; i < specContent.length; i++) {
      var specRow = specContent[i];
      if (specRow.length == 2) {
        specRow.addAll([null, null]);
      } else if (specRow.length == 3) {
        specRow.add(null);
      } else if (specRow.length == 4) {
        // Good, do nothing
      } else {
        throw ArgumentError(
            'The $i-th row of specContent has unsupported number of elements');
      }
    }

    LinkedHashMap specColumnSpec = LinkedHashMap<String, Function>.from({
      _SPEC_COLUMN_NAME: Table.columnProcessorTakeType(String),
      _SPEC_COLUMN_TYPE: Table.columnProcessorTakeType(SqlLiteDatatype),
      _SPEC_FROM_OBJECT:
          _specColumnProcessorFromObject(defaultFromObjectTranslator),
      _SPEC_CONSTRAINTS: Table.columnProcessorTakeType(String)
    });

    addTableSpecification(
        name: name,
        specification: Table(columnSpec: specColumnSpec, content: specContent));
  }

  DatabaseTableInfo getDbTableInfo(String tableName) =>
      dbTableInfos[tableName] ??
      (throw ArgumentError(
          'There is no specification for table $tableName in the database description.'));

  Iterable<DatabaseColumnSpecification> getDatabaseColumnSpecifications(
      String tableName) sync* {
    final tableSpec = getTableSpecification(tableName);
    final dbTableInfo = getDbTableInfo(tableName);

    for (var row in tableSpec.rowsAsMaps) {
      yield DatabaseColumnSpecification(
          name: row[_SPEC_COLUMN_NAME],
          type: row[_SPEC_COLUMN_TYPE],
          fromObject: row[_SPEC_FROM_OBJECT],
          constraints: row[_SPEC_CONSTRAINTS],
          dbTableInfo: dbTableInfo);
    }
  }

  static _specColumnProcessorFromObject(TranslatorFromObject defaultFunc) {
    return (entry) {
      if (entry == null) {
        return defaultFunc;
      } else if (reflectType(entry.runtimeType)
          .isSubtypeOf(reflectType(TranslatorFromObject))) {
        return entry;
      } else {
        throw ArgumentError(
            '$entry should be of type String Function(DatabaseColumnSpecification), instead of ${entry.runtimeType}');
      }
    };
  }
}

enum SqlLiteDatatype { NULL, INTEGER, REAL, TEXT, BLOB }

/// Helper function to translate a enum value to string.
/// The built-in toString() of enum adds the type name as prefix. For example,
/// SqlLiteDatatype.TEXT.toString() gives you 'SqlLiteDatatype.TEXT' instead of
/// 'TEXT', which is what we want here.
String getEnumName(Object enumEntry) {
  return enumEntry?.toString()?.split('.')?.last;
}
