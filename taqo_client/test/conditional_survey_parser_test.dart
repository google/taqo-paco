import 'package:petitparser/petitparser.dart';
import 'package:taqo_client/util/conditional_survey_parser.dart';
import 'package:test/test.dart';

class SuccessMatcher extends TypeMatcher<Success> {
  final bool _value;
  SuccessMatcher(this._value);

  @override
  bool matches(Object item, Map matchState) => item is Success && item.value as bool == _value;
}

class FailureMatcher extends TypeMatcher<Failure> {
  @override
  bool matches(Object item, Map matchState) => item is Failure;
}

// Test constants
final _lookup = <String, dynamic>{
  'pi': 3.141592,
  '_e': 2.71828,
  'input1': 7,
  'input455': '-11',
  'list14a': [1, 2, 4, ],
  '8adSymbol': 666,
  '__123_4': [1234, ],
};
final _parser = InputParser(_lookup);

void main() {
  test('Basic tests', () {
    expect(_parser.parse('pi < 3.1416'), SuccessMatcher(true));
    expect(_parser.parse('(pi >= 3 && _e <= 3) && input1 == 7'), SuccessMatcher(true));
    expect(_parser.parse('input455 != -11 || input1 < pi'), SuccessMatcher(false));
    expect(_parser.parse('list14a contains 1 && (list14a == 2 && list14a != 3)'), SuccessMatcher(true));
    expect(_parser.parse('list14a > 2'), SuccessMatcher(false));
    expect(_parser.parse('__123_4 < 2000'), SuccessMatcher(true));
    expect(_parser.parse("/* doesn't matter should be ignored */ _e > -2\n//ignore this too\n && _e < 3"),
        SuccessMatcher(true));
  });

  test('Test illegal grammar', () {
    expect(_parser.parse('8adSymbol == 666'), FailureMatcher());
  });
}
