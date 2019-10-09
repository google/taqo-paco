
import 'package:taqo_client/model/validator.dart';

abstract class Validatable {
  void validateWith(Validator validator);
}