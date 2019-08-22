
import 'package:taqo_survey/model/validator.dart';

abstract class Validatable {
  void validateWith(Validator validator);
}