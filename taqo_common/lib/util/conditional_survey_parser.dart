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

import 'package:logging/logging.dart';
import 'package:petitparser/petitparser.dart';

final _logger = Logger('ConditionalSurveyParser');

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

  final Environment _env;
  Parser _parser;

  InputParser(this._env) {
    final builder = ExpressionBuilder();

    // TODO Support for escaped unicode literals?
    // TODO Support for "escaped" octal literals?

    // Numbers and symbols
    // Numbers are any valid integer, floating point or hex literal (but not octal)
    // Symbols begin with a character or underscore (_), followed by zero or more characters,
    // underscores, and digits
    builder.group()
      ..primitive((digit().plus() & (char('.') & digit().plus()).optional())
          .trim()
          .flatten()
          .map((a) => num.tryParse(a)))
      ..primitive(((char('_') | letter()) & (word() | char('_')).star())
          .trim()
          .flatten()
          .map((a) {
        final aVal = _env[a.trim()].value;
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
    builder.group().prefix(char('-').trim(), (op, a) => -a);

    // Parentheses
    builder.group().wrapper(char('(').trim(), char(')').trim(), (l, a, r) => a);

    // Comparison operators
    builder.group()
      ..left(string('contains').trim(),
          (a, _, b) => _equalOp((a, b) => false, a, b))
      ..left(string('==').trim(), (a, _, b) => _equalOp((a, b) => a == b, a, b))
      ..left(
          string('!=').trim(), (a, _, b) => !_equalOp((a, b) => a == b, a, b))
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
        _logger.warning('failure parsing $expression: ${result.message}');
        return false;
      }
    } catch (e) {
      _logger.warning('exception parsing $expression: $e, with env: $_env');
      return false;
    }
  }
}

class Binding {
  final String varName;
  final responseType;
  final value;

  Binding(this.varName, this.responseType, this.value);
}

class Environment {
  final _knownQuestions = <String, Binding>{};

  void operator []=(String id, Binding binding) =>
      _knownQuestions[id] = binding;

  Binding operator [](String id) => _knownQuestions[id];

  void remove(String id) => _knownQuestions.remove(id);

  @override
  String toString() => _knownQuestions.toString();
}
