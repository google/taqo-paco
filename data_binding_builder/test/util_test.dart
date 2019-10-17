import 'package:test/test.dart';

import 'package:data_binding_builder/src/util.dart';

void main() {
  group('toSentenceCase()', () {
    test('toSentenceCase() converts a string to sentence case', () {
      expect(toSentenceCase('tHis Is A sEnTENCE. '),
          equals('This is a sentence. '));
    });

    test(
        'when the first character is not a letter, toSentenceCase() is the same as toLowerCase()',
        () {
      expect(toSentenceCase(' THis Is A sEnTENCE. '),
          equals(' this is a sentence. '));
      expect(toSentenceCase('_THis Is A sEnTENCE. '),
          equals('_this is a sentence. '));
      expect(toSentenceCase('6THis Is A sEnTENCE. '),
          equals('6this is a sentence. '));
    });

    test('toSetnenceCase() corner cases', () {
      expect(toSentenceCase(null), equals(null));
      expect(toSentenceCase(''), equals(''));
      expect(toSentenceCase(' '), equals(' '));
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

  group('templateFormat()', () {
    test(
        'templateFormat() replaces placeholders in a string with content specified by a map',
        () {
      expect(templateFormat('{{ replace me }}', {' replace me ': 'true value'}),
          equals('true value'));
      expect(templateFormat('Hello {{var}}!', {'var': 'world'}),
          equals('Hello world!'));
      expect(
          templateFormat(
              'AllWords{{Connected}}IsOK', {'Connected': 'WithoutSpace'}),
          equals('AllWordsWithoutSpaceIsOK'));
      expect(
          templateFormat('Multiple {{replacements}} is also {{OK}}.',
              {'replacements': 'placeholders', 'OK': 'good'}),
          equals('Multiple placeholders is also good.'));
    });

    test('templateFormat() for unexpected input', () {
      expect(templateFormat(null, null), equals(null));
      expect(templateFormat(null, {}), equals(null));
      expect(templateFormat('', null), equals(''));
      expect(templateFormat('', {'unused placeholder': 'not replaced'}),
          equals(''));
      expect(
          templateFormat(
              'Single {brackets} does not work.', {'brackets': 'not replaced'}),
          'Single {brackets} does not work.');
      expect(
          templateFormat('Empty double brackets {{}} are not replaced.', null),
          equals('Empty double brackets {{}} are not replaced.'));
      expect(
          templateFormat(
              'Be careful with brackets inside double brackets. Some will be {{{replaced}}}, and some will {{}not{}}.',
              {
                'replaced': 'REPLACED',
                '}not{': 'not replaced'
              }),
          equals(
              'Be careful with brackets inside double brackets. Some will be {REPLACED}, and some will {{}not{}}.'));
      expect(
          templateFormat('Be careful with {{\{escaped\}}} \{\{brackets\}\}.',
              {'escaped': 'ESCAPED', 'brackets': 'BRACKETS'}),
          equals('Be careful with {ESCAPED} BRACKETS.'));
    });

    test('templateFormat() for errors', () {
      // It could be implemented in a slightly easier way so that undefined placeholders becomes 'null'
      // But in this case throwing an error is more helpful.
      expect(
          () => templateFormat('Undefined {{placeholders}} cause errors.', {}),
          throwsArgumentError);
      expect(
          () =>
              templateFormat('Undefined {{placeholders}} cause errors.', null),
          throwsArgumentError);
    });
  });
}
