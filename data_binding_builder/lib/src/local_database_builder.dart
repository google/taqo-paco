import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:data_binding_builder/src/util.dart';
import 'package:path/path.dart' as p;

import 'database_helper.dart';
import 'map_literal.dart';
import 'table.dart';

// Describe the database schema
/// Predefined meta information fields
class _Meta {
  static const VERSION = 'version';
  static const PREPEND_ID_COLUMN = 'prependIdColumn';
}

/// Predefined table head/column names
class _TableHead {
  static const COLUMN_NAME = 'columnName';
  static const COLUMN_TYPE = 'columnType';
  static const DEFAULT_HEAD =
      const MapLiteral({COLUMN_NAME: String, COLUMN_TYPE: SqlLiteDatatype});
}

//
DatabaseDescription buildDatabaseDescription() {
  var db = DatabaseDescription(
      defaultHead: _TableHead.DEFAULT_HEAD,
      meta: const {_Meta.PREPEND_ID_COLUMN: true, _Meta.VERSION: 1});
  // In the [db.addTable()] statements below we use an (probably empty) line comment to mark the end of a [Table] row, so that
  // (1) dartfmt won't auto split the rows into one item per line
  // (2) In the case one line is split due to its length, one can tell the difference from a line end and a [Table] row end.
  db.addTable(name: 'experiments', specification: [
    'server_id', SqlLiteDatatype.INTEGER, //
    'title', SqlLiteDatatype.TEXT, //
    'join_date', SqlLiteDatatype.TEXT, //
    'json', SqlLiteDatatype.TEXT, //
  ]);
  db.addTable(name: 'events', specification: [
    'experiment_id', SqlLiteDatatype.INTEGER, //
    'experiment_server_id', SqlLiteDatatype.INTEGER, //
    'experiment_name', SqlLiteDatatype.TEXT, //
    'experiment_version', SqlLiteDatatype.INTEGER, //
    'schedule_time', SqlLiteDatatype.INTEGER, //
    'response_time', SqlLiteDatatype.INTEGER, //
    'uploaded', SqlLiteDatatype.INTEGER, //
    'group_name', SqlLiteDatatype.TEXT, //
    'action_trigger_id', SqlLiteDatatype.INTEGER, //
    'action_trigger_spec_id', SqlLiteDatatype.INTEGER, //
    'action_id', SqlLiteDatatype.INTEGER, //
  ]);
  db.addTable(name: 'outputs', specification: [
    'event_id', SqlLiteDatatype.INTEGER, //
    'input_server_id', SqlLiteDatatype.INTEGER, //
    'text', SqlLiteDatatype.TEXT, //
    'answer', SqlLiteDatatype.TEXT, //
  ]);

  return db;
}

/// How-tos
///
/// How to create a table?
String buildSqlCreateTable(
    DatabaseDescription dbDescription, String tableName) {
  var tableSpecification = dbDescription.tableSpecifications[tableName];
  if (tableSpecification == null) {
    throw StateError(
        'There is no specification for table $tableName in the database description.');
  }
  var prependIdColumn = dbDescription.meta[_Meta.PREPEND_ID_COLUMN] ?? false;
  return '''
CREATE TABLE $tableName (
${prependIdColumn ? "_id INTEGER PRIMARY KEY AUTOINCREMENT,\n" : ""}'''
      '''
${tableSpecification.rows.map((item) => "${item[_TableHead.COLUMN_NAME]} ${getEnumName(item[_TableHead.COLUMN_TYPE])}").join(', \n')}
  );
  ''';
}

/// How to get all column fields (of a table) from an object?
/// The returned string is the representation of a map that can be used by Database.insert()
String buildDartFieldsMap(
    DatabaseDescription dbDescription, String tableName, String objectName) {
  var tableSpecification = dbDescription.tableSpecifications[tableName];
  if (tableSpecification == null) {
    throw StateError(
        'There is no specification for table $tableName in the database description.');
  }
  var prependIdColumn = dbDescription.meta[_Meta.PREPEND_ID_COLUMN] ?? false;
  if (prependIdColumn == false) {
    throw UnimplementedError();
  }

  return '''
{
  '_id': ${objectName}.id,
  ${tableSpecification.getColumn(_TableHead.COLUMN_NAME).map((columnName) => "'$columnName': ${objectName}.${snakeCaseToCamelCase(columnName)},").join('\n')}
}
  ''';
}

/// Dart code builder
class LocalDatabaseBuilder implements Builder {
  static const partOfFilename = 'local_database.dart';
  static const outputFilename = 'local_database.inc.dart';

  static AssetId _output(BuildStep buildStep) {
    return AssetId(
      buildStep.inputId.package,
      p.join('lib', 'storage', outputFilename),
    );
  }

  @override
  Map<String, List<String>> get buildExtensions {
    return const {
      r'$lib$': const ['storage/$outputFilename'],
    };
  }

  @override
  Future<void> build(BuildStep buildStep) async {
    var dbDescription = buildDatabaseDescription();
    var formatter = DartFormatter();
    final content = formatter.format('''
// GENERATED CODE - DO NOT MODIFY BY HAND

part of '$partOfFilename';

var _dbVersion = ${dbDescription.meta[_Meta.VERSION]};

Future<void> _onCreate(Database db, int version) async {
${dbDescription.tableNames.map((tableName) => 'await db.execute(\'\'\'${buildSqlCreateTable(dbDescription, tableName)}\'\'\');').join('\n')}
}

Future<void> _insertEvent(Database db, Event event) async {
  await db.insert(
  'events',
  ${buildDartFieldsMap(dbDescription, 'events', 'event')},
  conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

    ''');

    final output = _output(buildStep);
    await buildStep.writeAsString(output, content);
  }
}
