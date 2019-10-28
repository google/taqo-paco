import 'package:data_binding_builder/src/map_literal.dart';
import 'package:test/test.dart';

import 'package:data_binding_builder/src/table.dart';

void main() {
  group('Table for normal use', () {
    var table = Table(
        columnSpec: MapLiteral({'column1': String, 'column2': int}),
        content: [
          ['row1', 1],
          ['row2', 2],
          ['row3', 3]
        ]);

    test('Table basics', () {
      expect(table.columnCount, equals(2));
      expect(table.rowCount, equals(3));
    });

    test('Table.rowsAsMaps', () {
      expect(
          table.rowsAsMaps,
          equals([
            {'column1': 'row1', 'column2': 1},
            {'column1': 'row2', 'column2': 2},
            {'column1': 'row3', 'column2': 3},
          ]));
    });

    test('Table.getColumn()', () {
      expect(table.getColumn('column1'), equals(['row1', 'row2', 'row3']));
      expect(table.getColumn('column2'), equals([1, 2, 3]));
    });

    test('Table.getColumnAsMapEntries()', () {
      expect(
          table.getColumnAsMapEntries('column1', 'column2'),
          pairwiseCompare(
              {'row1': 1, 'row2': 2, 'row3': 3}.entries,
              (MapEntry entry1, MapEntry entry2) =>
                  (entry1.key == entry2.key && entry1.value == entry2.value),
              'MapEntry comparator'));
    });
  });

  group('Table errors', () {
    test('ill-formed table content', () {
      expect(
          () => Table(
                  columnSpec: MapLiteral({'column1': String, 'column2': int}),
                  content: [
                    ['row1', 1],
                    ['row2'],
                    ['row3', 3]
                  ]),
          throwsArgumentError);

      expect(
          () => Table(
                  columnSpec: MapLiteral({'column1': String, 'column2': int}),
                  content: [
                    ['row1', 1],
                    ['row2', 2, 4],
                    ['row3', 3]
                  ]),
          throwsArgumentError);
    });

    test('Table content type errors', () {
      expect(
          () => Table(
                  columnSpec: MapLiteral({'column1': String, 'column2': int}),
                  content: [
                    ['row1', 1],
                    ['row2', 'wrong type'],
                    ['row3', 3]
                  ]),
          throwsArgumentError);

      expect(
          () => Table(
                  columnSpec: MapLiteral({'column1': String, 'column2': int}),
                  content: [
                    ['row1', 1],
                    [2, 2],
                    ['row3', 3]
                  ]),
          throwsArgumentError);
    });
  });
}
