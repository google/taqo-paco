// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "../lib/sqlite.dart";

void main() {
  Database d = Database("test.db");
  d.execute("drop table if exists Cookies;");
  d.execute("""
      create table Cookies (
        id integer primary key,
        name text not null,
        alternative_name text
      );""");
  d.execute("""
      insert into Cookies (id, name, alternative_name)
      values
        (1,'Chocolade chip cookie', 'Chocolade cookie'),
        (2,'Ginger cookie', null),
        (3,'Cinnamon roll', null)
      ;""");
  d.execute("""
      insert into Cookies (id, name, alternative_name)
      values
        (?, ?, ?)
      ;""", params: [4, 'Snickerdoodle', 'Cinnamon']);
  Result result = d.query("""
      select
        id,
        name,
        alternative_name,
        case
          when id=1 then 'foo'
          when id=2 then 42
          when id=3 then null
          when id=4 then 'ok'
        end as multi_typed_column
      from Cookies
      ;""");
  for (Row r in result) {
    int id = r.readColumnAsInt("id");
    String name = r.readColumnByIndex(1);
    String alternativeName = r.readColumn("alternative_name");
    dynamic multiTypedValue = r.readColumn("multi_typed_column");
    print("$id $name $alternativeName $multiTypedValue");
  }
  result = d.query("""
      select
        id,
        name,
        alternative_name,
        case
          when id=1 then 'foo'
          when id=2 then 42
          when id=3 then null
          when id=4 then 'ok'
        end as multi_typed_column
      from Cookies
      ;""");
  for (Row r in result) {
    int id = r.readColumnAsInt("id");
    String name = r.readColumnByIndex(1);
    String alternativeName = r.readColumn("alternative_name");
    dynamic multiTypedValue = r.readColumn("multi_typed_column");
    print("$id $name $alternativeName $multiTypedValue");
    if (id == 2) {
      result.close();
      break;
    }
  }
  try {
    result.iterator.moveNext();
  } on SQLiteException catch (e) {
    print("expected exception on accessing result data after close: $e");
  }
  try {
    d.query("""
      select
        id,
        non_existing_column
      from Cookies
      ;""");
  } on SQLiteException catch (e) {
    print("expected this query to fail: $e");
  }
  result = d.query("""select name from Cookies where id = ?;""", params: [2]);
  for (Row r in result) {
    String name = r.readColumnByIndex(0);
    print(name);
  }
  d.execute("drop table Cookies;");
  d.close();
}
