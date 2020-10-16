import 'validator.dart';

abstract class Validatable {
  void validateWith(Validator validator);
}
