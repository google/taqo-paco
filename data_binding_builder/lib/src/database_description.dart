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
  DatabaseTableInfo(
      {@required this.name, this.objectName, this.parentObjectName});
}

class DatabaseColumnSpecification {
  final String name;
  final SqlLiteDatatype type;
  String fromObject;
  String toObject;
  final DatabaseTableInfo dbTableInfo;

  String get typeAsString => getEnumName(type);

  DatabaseColumnSpecification({
    @required this.name,
    @required this.type,
    @required TranslatorFromObject fromObject,
    @required Function toObject,
    @required this.dbTableInfo,
  }) {
    this.fromObject = fromObject(this);
    this.toObject = '';
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
  static const _SPEC_TO_OBJECT = 'toObject';

  DatabaseDescription({Map<String, dynamic> meta}) : super(meta: meta);

  Map<String, DatabaseTableInfo> dbTableInfos = {};

  void addTableSpec(
      {@required String name, // DB table name
      String objectName,
      String parentObjectName,
      TranslatorFromObject defaultFromObjectTranslator,
      Function defaultToObjectTranslator,
      @required List<List<dynamic>> specContent // content of the specification
      }) {
    dbTableInfos[name] = DatabaseTableInfo(
        name: name, objectName: objectName, parentObjectName: parentObjectName);

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
      _SPEC_TO_OBJECT: Table.columnProcessorIdentity
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
          toObject: row[_SPEC_TO_OBJECT],
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
