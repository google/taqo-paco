import 'package:meta/meta.dart';

import 'database_description_base.dart';
import 'map_literal.dart';
import 'table.dart';

class DatabaseColumnSpecification {
  final String specFormat;
  final String name;
  final SqlLiteDatatype type;
  final String translation;

  String get typeAsString => getEnumName(type);

  DatabaseColumnSpecification(
      {@required this.specFormat,
      @required this.name,
      @required this.type,
      @required this.translation});
}

class DatabaseDescription extends DatabaseDescriptionBase {
  // Predefined meta keys
  static const META_VERSION = 'version';
  static const META_PREPEND_ID_COLUMN = 'prependIdColumn';

  // Predefined [Table] column names for DB table specifications
  static const _SPEC_COLUMN_NAME = 'columnName';
  static const _SPEC_COLUMN_TYPE = 'columnType';
  static const _SPEC_TRANSLATION = 'translation';

  DatabaseDescription({Map<String, dynamic> meta}) : super(meta: meta);

  // Specification formats
  static const SPEC_FMT_NT = 'columnName, columnType';
  static const SPEC_FMT_NTTr = 'columnName, columnType, translation';

  static const _SPEC_BY_FORMAT = {
    SPEC_FMT_NT: MapLiteral(
        {_SPEC_COLUMN_NAME: String, _SPEC_COLUMN_TYPE: SqlLiteDatatype}),
    SPEC_FMT_NTTr: MapLiteral({
      _SPEC_COLUMN_NAME: String,
      _SPEC_COLUMN_TYPE: SqlLiteDatatype,
      _SPEC_TRANSLATION: String
    })
  };

  Map<String, String> tableSpecFormat = {};

  void addTableSpecWithFormat(
      {@required String name, // DB table name
      @required String specFormat, // format of the specification
      @required List<List<dynamic>> specContent // content of the specification
      }) {
    if (!_SPEC_BY_FORMAT.containsKey(specFormat)) {
      throw ArgumentError('Unknow specFormat: ${specFormat}');
    }
    addTableSpecification(
        name: name,
        specification: Table(
            columnSpec: _SPEC_BY_FORMAT[specFormat], content: specContent));
    tableSpecFormat[name] = specFormat;
  }

  String getTableSpecFormat(String tableName) =>
      tableSpecFormat[tableName] ??
      (throw ArgumentError(
          'There is no specification for table $tableName in the database description.'));

  Iterable<DatabaseColumnSpecification> getDatabaseColumnSpecifications(
      String tableName) sync* {
    final specFormat = getTableSpecFormat(tableName);
    final tableSpec = getTableSpecification(tableName);

    for (var row in tableSpec.rowsAsMaps) {
      yield DatabaseColumnSpecification(
          specFormat: specFormat,
          name: row[_SPEC_COLUMN_NAME],
          type: row[_SPEC_COLUMN_TYPE],
          translation: row[_SPEC_TRANSLATION]);
    }
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
