import 'package:petitparser/petitparser.dart';

typedef OpFunction = bool Function(dynamic, dynamic);

// Common function for operations
// Handles null checking
bool _op(OpFunction func, dynamic a, dynamic b) {
  if (a == null || b == null) return false;
  return func(a, b);
}

// Common function for equality operations
// Defers to 'contains' for list arg
bool _equalOp(OpFunction func, dynamic a, dynamic b) {
  if (a is List) return a.contains(b);
  return _op(func, a, b);
}

// Common function for non-equality operations
// Uses first element of list arg
bool _orderOp(OpFunction func, dynamic a, dynamic b) {
  if (a is List) return a.length == 1 && func(a.first, b);
  return _op(func, a, b);
}

class InputParser {
  /// It seems like using [ExpressionBuilder] will not easily support a comment syntax
  /// Removing them with regular expressions seems like a good alternative
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
          if (aVal is num || aVal is List || aVal == null) {
            return aVal;
          } else if (aVal is String) {
            if (aVal.contains(',')) {
              return aVal.split(',').map((s) => num.tryParse(s)).toList();
            }
            return num.tryParse(aVal);
          }
          return null;
      }));

    // Supports negation
    builder.group()
      ..prefix(char('-').trim(), (op, a) => -a);

    // Parentheses
    builder.group()
      ..wrapper(char('(').trim(), char(')').trim(), (l, a, r) => a);

    // Comparison operators
    builder.group()
      ..left(string('contains').trim(), (a, _, b) => _equalOp((a, b) => false, a, b))
      ..left(string('==').trim(), (a, _, b) => _equalOp((a, b) => a == b, a, b))
      ..left(string('!=').trim(), (a, _, b) => !_equalOp((a, b) => a == b, a, b))
      ..left(string('=').trim(), (a, _, b) => _equalOp((a, b) => a == b, a, b))
      ..left(string('<=').trim(), (a, _, b) => _orderOp((a, b) => a <= b, a, b))
      ..left(string('>=').trim(), (a, _, b) => _orderOp((a, b) => a >= b, a, b))
      ..left(string('<').trim(), (a, _, b) => _orderOp((a, b) => a < b, a, b))
      ..left(string('>').trim(), (a, _, b) => _orderOp((a, b) => a > b, a, b));

    // Logical operators. Have lower precedence than comparators
    builder.group()
      ..left(string('&&').trim(), (a, op, b) => a && b)
      ..left(string('||').trim(), (a, op, b) => a || b);

    _parser = builder.build().end();
  }

  /// Attempts to parse [expression] and returns either a [Success] or [Failure].
  /// Throws any exception from [_parser.parse]
  Result parse(String expression) {
    // Drop comments
    expression = expression.replaceAll(_blockComment, '');
    expression = expression.replaceAll(_lineComment, '');
    return _parser.parse(expression);
  }

  /// Get the boolean result of parsing [expression]. Returns true iff parsing succeeds and the
  /// [Success.value] is true, otherwise false (including exceptions)
  bool getParseResult(String expression) {
    try {
      final result = parse(expression);
      if (result is Success) {
        return result.value;
      } else {
        print('failure parsing $expression: ${result.message}');
        return false;
      }
    } catch (e) {
      print('exception parsing $expression: $e, with conditions: $_conditions');
      return false;
    }
  }
}
