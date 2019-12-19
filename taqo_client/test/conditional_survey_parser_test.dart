import 'package:flutter_test/flutter_test.dart';
import 'package:taqo_client/util/conditional_survey_parser.dart';

// Test constants
final _lookup = <String, dynamic>{
  'pi': 3.141592,
  '_e': 2.71828,
  'input1': 7,
  'input455': '-11',
  'list14a': [1, 2, 4, ],
};
final _parser = InputParser(_lookup);

void main() {
  test('Basic tests', () {
    expect(_parser.parse('pi < 3.1416'), true);
    expect(_parser.parse('(pi >= 3 && _e <= 3) && input1 == 7'), true);
    expect(_parser.parse('input455 != -11 || input1 < pi'), false);
    expect(_parser.parse('list14a contains 1 && (list14a == 2 && list14a != 3)'), true);
    expect(_parser.parse("/* doesn't matter should be ignored */ _e > -2\n//ignore this too\n && _e < 3"), true);
  });
}
