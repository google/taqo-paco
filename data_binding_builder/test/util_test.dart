import 'package:test/test.dart';

import 'package:data_binding_builder/src/util.dart';

void main() {
  group('sentenceCase()', () {
    test('sentenceCase() converts a string to sentence case', () {
      expect(
          sentenceCase('tHis Is A sEnTENCE. '), equals('This is a sentence. '));
    });

    test(
        'when the first character is not a letter, sentenceCase() is the same as toLowerCase()',
        () {
      expect(sentenceCase(' THis Is A sEnTENCE. '),
          equals(' this is a sentence. '));
      expect(sentenceCase('_THis Is A sEnTENCE. '),
          equals('_this is a sentence. '));
      expect(sentenceCase('6THis Is A sEnTENCE. '),
          equals('6this is a sentence. '));
    });

    test('setnenceCase() corner cases', () {
      expect(sentenceCase(null), equals(null));
      expect(sentenceCase(''), equals(''));
      expect(sentenceCase(' '), equals(' '));
    });
  });

  group('snakeCaseToCamelCase()', () {
    test('snakeCaseToCamelCase() converts snake_case to camelCase', () {
      expect(
          snakeCaseToCamelCase('SnAke_cAse_STring'), equals('snakeCaseString'));
      expect(snakeCaseToCamelCase('SnAke'), equals('snake'));
    });

    test('snakeCaseToCamelCase() for unexpected input', () {
      expect(snakeCaseToCamelCase(null), equals(null));
      expect(snakeCaseToCamelCase(''), equals(''));
      expect(snakeCaseToCamelCase(' '), equals(' '));
      expect(snakeCaseToCamelCase('_'), equals(''));
      expect(snakeCaseToCamelCase('_____'), equals(''));
      expect(snakeCaseToCamelCase('__aaa___bbb__ccc____'), equals('AaaBbbCcc'));
      expect(snakeCaseToCamelCase('   ___aaa___bbb__ccc____'),
          equals('   AaaBbbCcc'));
      expect(snakeCaseToCamelCase('aaa_bbb ccc_ddd_ eee'),
          equals('aaaBbb cccDdd eee'));
    });
  });
}
