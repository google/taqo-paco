import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as p;
import 'package:taqo_survey/model/database_helper.dart';
import 'package:taqo_survey/util/table_util.dart';

/// Describe the database schema

DatabaseDescription buildDatabaseDescription() {
  var db = DatabaseDescription(
      defaultHead: const ['columnName', 'columnType'],
      meta: const {'prependIdColumn': true, 'version': 1});
  // In the [db.addTable()] statements below we use an (probably empty) line comment to mark the end of a [Table] row, so that
  // (1) dartfmt won't auto split the rows into one item per line
  // (2) In the case one line is split due to its length, one can tell the difference from a line end and a [Table] row end.
  db.addTable(name: 'experiments', description: [
    'server_id', SqlLiteDatatype.INTEGER, //
    'title', SqlLiteDatatype.TEXT, //
    'join_date', SqlLiteDatatype.TEXT, //
    'json', SqlLiteDatatype.TEXT, //
  ]);
  db.addTable(name: 'events', description: [
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
  db.addTable(name: 'outputs', description: [
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
String buildQueryCreateTable(String name, Table tableDescription,
    {bool prependIdColumn = false}) {
  return '''
CREATE TABLE $name (
${prependIdColumn ? "_id INTEGER PRIMARY KEY AUTOINCREMENT,\n" : ""}'''
      '''
${tableDescription.rowIterator.map((item) => "${item['columnName']} ${item['columnType'].toString().split('.').last}").join(', \n')}
  );
  ''';
}

/// Dart code builder
class LocalDatabaseBuilder implements Builder {
  static const partOfFilename = 'local_database.dart';
  static const outputFilename = 'local_database.inc.dart';

  static AssetId _output(BuildStep buildStep) {
    return new AssetId(
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

var _dbVersion = ${dbDescription.meta['version']};
Future<void> _onCreate(Database db, int version) async {
${dbDescription.tableDescriptions.entries.map((entry) => 'await db.execute(\'\'\'${buildQueryCreateTable(entry.key, entry.value, prependIdColumn: dbDescription.meta['prependIdColumn'])}\'\'\');').join('\n')}
}
    ''');

    final output = _output(buildStep);
    await buildStep.writeAsString(output, content);
  }
}

/// Builder factory
Builder localDatabaseBuilder(BuilderOptions options) => LocalDatabaseBuilder();
