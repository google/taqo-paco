import 'dart:collection';
import 'dart:mirrors';

import 'package:meta/meta.dart';

import 'database_description_base.dart';
import 'table.dart';

typedef TranslatorFromObject = String Function(
    DatabaseColumnSpecification, String);
typedef TranslatorFromObject2 = String Function(
    DatabaseColumnSpecification, String, String);

class DatabaseColumnSpecification {
  final String name;
  final SqlLiteDatatype type;
  final int fromObjectLevel;
  Function fromObject;
  Function toObject;

  String get typeAsString => getEnumName(type);

  DatabaseColumnSpecification(
      {@required this.name,
      @required this.type,
      @required this.fromObjectLevel,
      @required Function fromObject,
      @required this.toObject}) {
    var fromObjectTranslator;
    if (fromObjectLevel == 1 && fromObject is TranslatorFromObject) {
      fromObjectTranslator = (String object) => fromObject(this, object);
    } else if (fromObjectLevel == 2 && fromObject is TranslatorFromObject2) {
      fromObjectTranslator = (String object1, String object2) =>
          fromObject(this, object1, object2);
    } else {
      throw ArgumentError(
          'Unsupported fromObjectLevel and/or fromObject function');
    }
    this.fromObject = fromObjectTranslator;
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

  Map<String, int> tableFromObjectLevel = {};

  void addTableSpec(
      {@required String name, // DB table name
      int fromObjectLevel,
      Function defaultFromObjectTranslator,
      Function defaultToObjectTranslator,
      @required List<List<dynamic>> specContent // content of the specification
      }) {
    // Checking and processing the parameters
    if (fromObjectLevel == null && defaultFromObjectTranslator == null) {
      fromObjectLevel = 1;
    } else if (fromObjectLevel == null) {
      fromObjectLevel = (reflect(defaultFromObjectTranslator) as ClosureMirror)
              .function
              .parameters
              .length -
          1;
    } else if (defaultFromObjectTranslator == null) {
      //Do nothing
    } else {
      // both non-null
      if (fromObjectLevel !=
          (reflect(defaultFromObjectTranslator) as ClosureMirror)
                  .function
                  .parameters
                  .length -
              1) {
        throw ArgumentError(
            'The defaultFromObjectTranslator is inconsistent with fromObjectLevel $fromObjectLevel.');
      }
    }
    if (fromObjectLevel < 1 || fromObjectLevel > 2) {
      throw ArgumentError('Unsupported fromObjectLevel: ${fromObjectLevel}');
    }
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

    var foo = _specColumnProcessorFromObjectLevel[fromObjectLevel];
    var bar = foo(defaultFromObjectTranslator);

    LinkedHashMap specColumnSpec = LinkedHashMap<String, Function>.from({
      _SPEC_COLUMN_NAME: Table.columnProcessorTakeType(String),
      _SPEC_COLUMN_TYPE: Table.columnProcessorTakeType(SqlLiteDatatype),
      _SPEC_FROM_OBJECT: _specColumnProcessorFromObjectLevel[fromObjectLevel](
          defaultFromObjectTranslator),
      _SPEC_TO_OBJECT: Table.columnProcessorIdentity
    });

    addTableSpecification(
        name: name,
        specification: Table(columnSpec: specColumnSpec, content: specContent));
    tableFromObjectLevel[name] = fromObjectLevel;
  }

  int getTableFromObjectLevel(String tableName) =>
      tableFromObjectLevel[tableName] ??
      (throw ArgumentError(
          'There is no specification for table $tableName in the database description.'));

  Iterable<DatabaseColumnSpecification> getDatabaseColumnSpecifications(
      String tableName) sync* {
    final fromObjectLevel = getTableFromObjectLevel(tableName);
    final tableSpec = getTableSpecification(tableName);

    for (var row in tableSpec.rowsAsMaps) {
      yield DatabaseColumnSpecification(
          fromObjectLevel: fromObjectLevel,
          name: row[_SPEC_COLUMN_NAME],
          type: row[_SPEC_COLUMN_TYPE],
          fromObject: row[_SPEC_FROM_OBJECT],
          toObject: row[_SPEC_TO_OBJECT]);
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
            '$entry should be of type String Function(DatabaseColumnSpecification, String), instead of ${entry.runtimeType}');
      }
    };
  }

  static _specColumnProcessorFromObject2(TranslatorFromObject2 defaultFunc) {
    return (entry) {
      if (entry == null) {
        return defaultFunc;
      } else if (reflectType(entry.runtimeType)
          .isSubtypeOf(reflectType(TranslatorFromObject2))) {
        return entry;
      } else {
        throw ArgumentError(
            '$entry should be of type String Function(DatabaseColumnSpecification, String, String), instead of ${entry.runtimeType}');
      }
    };
  }

  static const _specColumnProcessorFromObjectLevel = <int, Function>{
    1: _specColumnProcessorFromObject,
    2: _specColumnProcessorFromObject2
  };
}

enum SqlLiteDatatype { NULL, INTEGER, REAL, TEXT, BLOB }

/// Helper function to translate a enum value to string.
/// The built-in toString() of enum adds the type name as prefix. For example,
/// SqlLiteDatatype.TEXT.toString() gives you 'SqlLiteDatatype.TEXT' instead of
/// 'TEXT', which is what we want here.
String getEnumName(Object enumEntry) {
  return enumEntry?.toString()?.split('.')?.last;
}
