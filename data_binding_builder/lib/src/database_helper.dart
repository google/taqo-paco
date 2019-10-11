import 'package:meta/meta.dart';

import 'map_literal.dart';
import 'table.dart';

/// Description of a database
/// We describe a database using meta information such as version and the
/// specification of each DB table. Each DB table is specified by a traditional
/// table of type [Table]. The head of [Table] object decides what information
/// of the DB table is provided.
class DatabaseDescription {
  /// Meta information
  final Map<String, dynamic> meta;

  /// The default [Table] head, used by [.addTable()] if a custom head is not specified
  final MapLiteral<String, Type> defaultHead;

  /// A map from DB table name to [Table] object as the specification of that DB table
  Map<String, Table> tableSpecifications = {};

  /// An iterator of table names
  Iterable<String> get tableNames => tableSpecifications.keys;

  DatabaseDescription(
      {this.defaultHead = const MapLiteral(
          const {'columnName': String, 'columnType': SqlLiteDatatype}),
      this.meta});

  void addTable({
    @required String name, // DB table name
    MapLiteral<String, Type> withCustomHead, // Custom head of [Table] object
    @required
        List<dynamic> specification, // The [body] of the specification table
  }) {
    tableSpecifications[name] =
        Table(head: withCustomHead ?? defaultHead, body: specification);
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
