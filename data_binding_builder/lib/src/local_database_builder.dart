import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
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
String buildSqlCreateTable(String name, Table tableDescription,
    {bool prependIdColumn = false}) {
  return '''
CREATE TABLE $name (
${prependIdColumn ? "_id INTEGER PRIMARY KEY AUTOINCREMENT,\n" : ""}'''
      '''
${tableDescription.rowIterator.map((item) => "${item[_TableHead.COLUMN_NAME]} ${getEnumName(item[_TableHead.COLUMN_TYPE])}").join(', \n')}
  );
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
${dbDescription.tableSpecifications.entries.map((entry) => 'await db.execute(\'\'\'${buildSqlCreateTable(entry.key, entry.value, prependIdColumn: dbDescription.meta[_Meta.PREPEND_ID_COLUMN])}\'\'\');').join('\n')}
}
    ''');

    final output = _output(buildStep);
    await buildStep.writeAsString(output, content);
  }
}


