import 'package:meta/meta.dart';
import 'package:taqo_survey/util/table_util.dart';

/// Description of databases
/// We describe a database using meta information such as version and the
/// descriptions of each DB table. Each DB table is described by a traditional
/// table of type [Table]. The head of [Table] object decides what information
/// of the DB table is provided.
class DatabaseDescription {
  /// Meta information
  final Map<String, dynamic> meta;

  /// The default [Table] head, used by [.addTable()] if a custom head is not specified
  final List<String> defaultHead;

  /// A map from DB table name to [Table] object as the description of that DB table
  Map<String, Table> tableDescriptions = {};

  DatabaseDescription(
      {this.defaultHead = const ['columnName', 'columnType'], this.meta});

  void addTable({
    @required String name, // DB table name
    List<String> withCustomHead, // Custom head of [Table] object
    List<dynamic> description, // The [body] of the description table
  }) {
    withCustomHead ??= defaultHead;
    tableDescriptions[name] = Table(head: withCustomHead, body: description);
  }
}

enum SqlLiteDatatype { NULL, INTEGER, REAL, TEXT, BLOB }
