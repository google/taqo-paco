import 'package:petitparser/petitparser.dart';

class InputParser {
  /// It seems like using [ExpressionBuilder] will not easily support a comment syntax
  /// Removing them with regular expressions seems like a good alternative
  /// TODO Gauge the performance impact
  static final _blockComment = RegExp(r'\/\*[\S\s]*?\*\/');
  static final _lineComment = RegExp(r'\/\/.*$', multiLine: true);

  final Map<String, dynamic> _conditions;
  Parser _parser;

  InputParser(this._conditions) {
    final builder = ExpressionBuilder();

    // TODO Support for escaped unicode literals?
    // TODO Support for "escaped" octal literals?

    // Numbers and symbols
    // Numbers are any valid integer, floating point or hex literal (but not octal)
    // Symbols begin with a character or underscore (_), followed by zero or more characters,
    // underscores, and digits
    builder.group()
      ..primitive((digit().plus() & (char('.') & digit().plus()).optional()).trim().flatten()
          .map((a) => num.tryParse(a)))
      ..primitive(((char('_') | letter()) & (word() | char('_')).star()).trim().flatten()
          .map((a) {
          final aVal = _conditions[a.trim()];
          if (aVal is num || aVal is List) {
            return aVal;
          } else /*if (aVal is String)*/ {
            return num.tryParse(aVal);
          }
      }));
    // Supports negation
    builder.group()
      ..prefix(char('-').trim(), (op, a) => -a);
    // Parentheses
    builder.group()
      ..wrapper(char('(').trim(), char(')').trim(), (l, a, r) => a);
    // Comparison operators
    builder.group()
      ..left(string('contains').trim(), (a, op, b) => a is List ? a.contains(b) : false)
      ..left(string('==').trim(), (a, op, b) => a is List ? a.contains(b) : a == b)
      ..left(string('!=').trim(), (a, op, b) => a is List ? !a.contains(b) : a != b)
      ..left(string('<=').trim(), (a, op, b) => a is List ? (a.length == 1 && a.first <= b) : a <= b)
      ..left(string('>=').trim(), (a, op, b) => a is List ? (a.length == 1 && a.first >= b) : a >= b)
      ..left(char('=').trim(), (a, op, b) => a is List ? (a.contains(b)) : a == b)
      ..left(char('<').trim(), (a, op, b) => a is List ? (a.length == 1 && a.first < b) : a < b)
      ..left(char('>').trim(), (a, op, b) => a is List ? (a.length == 1 && a.first > b) : a > b);
    // Logical operators. Have lower precedence than comparators
    builder.group()
      ..left(string('&&').trim(), (a, op, b) => a && b)
      ..left(string('||').trim(), (a, op, b) => a || b);

    _parser = builder.build().end();
  }

  Result parse(String expression) {
    // Drop comments
    expression = expression.replaceAll(_blockComment, '');
    expression = expression.replaceAll(_lineComment, '');
//    print(expression);
//    print(_parser.parse(expression));
    return _parser.parse(expression);
  }
}
