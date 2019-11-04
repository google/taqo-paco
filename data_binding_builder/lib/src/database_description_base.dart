import 'package:meta/meta.dart';

import 'table.dart';

/// Description of a database, base class
/// We describe a database using meta information such as version and the
/// specification of each DB table. Each DB table is specified by a traditional
/// table of type [Table]. The columnSpecification of [Table] object decides what information
/// of the DB table is provided.
class DatabaseDescriptionBase {
  /// Meta information
  final Map<String, dynamic> meta;

  /// A map from DB table name to [Table] object as the specification of that DB table
  Map<String, Table> tableSpecifications = {};

  /// An iterator of table names
  Iterable<String> get tableNames => tableSpecifications.keys;

  DatabaseDescriptionBase({this.meta});

  void addTableSpecification({
    @required String name, // DB table name
    @required Table specification, // The specification [Table]
  }) {
    tableSpecifications[name] = specification;
  }

  Table getTableSpecification(String tableName) =>
      tableSpecifications[tableName] ??
      (throw ArgumentError(
          'There is no specification for table $tableName in the database description.'));
}
