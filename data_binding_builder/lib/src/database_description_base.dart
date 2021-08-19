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

// @dart=2.9

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
