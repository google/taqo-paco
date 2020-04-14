import 'package:json_annotation/json_annotation.dart';

import 'validation_message.dart';
import 'validator.dart';

part 'experiment_validator.g.dart';

@JsonSerializable()
class ExperimentValidator implements Validator {
  List<ValidationMessage> results;

  ExperimentValidator() {
    results = List<ValidationMessage>();
  }

  factory ExperimentValidator.fromJson(Map<String, dynamic> json) => _$ExperimentValidatorFromJson(json);

  Map<String, dynamic> toJson() => _$ExperimentValidatorToJson(this);
  void addError(String msg) {
    results.add(new ValidationMessage(msg, Validator.MANDATORY));
  }

  bool isNonEmptyString(String value, String msg) {
    bool b = isNullOrEmptyString(value);
    if (b) {
      addError(msg);
      return false;
    }
    return true;
  }

  bool isNullOrEmptyString(String value) {
    return value == null || value.length == 0;
  }

  bool isNotNullAndNonEmptyCollection(List collection, String message) {
    bool empty = collection == null || collection.isEmpty;
    if (empty) {
      addError(message);
    }
    return empty;
  }

  /**
   * TODO replace this with a real email address validator
   */

  bool isValidEmail(String address, String errorMessage) {
    if (!isNonEmptyString(address, errorMessage)) {
      return false;
    }
    int atIndex = address.indexOf('@');
    if (atIndex == -1) {
      addError(errorMessage);
      return false;
    }
    String namePart = address.substring(0, atIndex);
    String domainPart = address.substring(atIndex + 1);
    if (!isNonEmptyString(namePart, errorMessage)) {
      return false;
    }
    if (!isNonEmptyString(domainPart, errorMessage)) {
      return false;
    }
    if (domainPart.indexOf('.') == -1) {
      addError(errorMessage);
      return false;
    }
    return true;
  }

  bool isValidCollectionOfEmailAddresses(
      List<String> collection, String errorMessage) {
    if (!isNotNullAndNonEmptyCollection(collection, errorMessage)) {
      return false;
    }
    for (String email in collection) {
      if (!isValidEmail(email, errorMessage)) {
        return false;
      }
    }
    return true;
  }

  bool isNotNullCollection(List collection, String errorMessage) {
    if (collection == null) {
      addError(errorMessage);
      return false;
    }
    return true;
  }

  /**
   * TODO replace with real date formatter that is serializable
   */

  bool isValidDateString(String dateStr, String errorMessage) {
    if (!isNonEmptyString(dateStr, errorMessage)) {
      return false;
    }

    try {
      DateTime.parse(dateStr); // TODO does this work for "yyyy/MM/dd HH:mm:ssZ"
      return true;
    } catch (e) {
      return false;
    }
//
//    String[] ymd = dateStr.split("/");
//    if (!isArrayWithNElements(3, ymd, errorMessage)) {
//      return false;
//    }
//    if (!isValid4DigitYear(ymd[0], errorMessage)) {
//      return false;
//    }
//    if (!isValid2DigitMonth(ymd[1], errorMessage)) {
//      return false;
//    }
//    if (!isValid2DigitDay(ymd[2], errorMessage)) {
//      return false;
//    }
//    return true;
  }

  bool isValid2DigitMonth(String monthString, String errorMessage) {
    if (monthString.length != 2) {
      addError(errorMessage);
      return false;
    }
    int month;
    try {
      month = int.parse(monthString);
    } catch (nfe) {
      addError(errorMessage);
      return false;
    }
    if (month < 0 || month > 12) {
      addError(errorMessage);
      return false;
    }
    return true;
  }

  bool isValid2DigitDay(String dayString, String errorMessage) {
    if (dayString.length != 2) {
      addError(errorMessage);
      return false;
    }
    int day;
    try {
      day = int.parse(dayString);
    } catch (nfe) {
      addError(errorMessage);
      return false;
    }
    if (day < 0 || day > 31) {
      addError(errorMessage);
      return false;
    }
    return true;
  }

  bool isValid4DigitYear(String yearString, String errorMessage) {
    if (yearString.length != 4) {
      addError(errorMessage);
      return false;
    }
    int year;
    try {
      year = int.parse(yearString);
    } catch (nfe) {
      addError(errorMessage);
      return false;
    }
    return true;
  }

  bool isArrayWithNElements(
      int expectedLength, List<String> arr, String errorMessage) {
    if (!isNonNullArray(arr, errorMessage)) {
      return false;
    }
    if (arr.length != expectedLength) {
      addError(errorMessage);
      return false;
    }
    return true;
  }

  bool isNonNullArray(List<String> array, String errorMessage) {
    if (array == null) {
      addError(errorMessage);
      return false;
    }
    return true;
  }

  bool isNotNull(Object obj, String errorMessage) {
    if (obj == null) {
      addError(errorMessage);
      return false;
    }
    return true;
  }

  /**
   * TODO do some real basic javascript linting, some real paco symbol checking,
   * some caja sandboxing, etc..
   */

  bool isValidJavascript(String code, String errorMessage) {
    if (!isNonEmptyString(code, errorMessage)) {
      return false;
    }
    return true;
  }

  /**
   * TODO this is to validate simple html as well as javascript.
   * It is broader than isValidJavascript, but for now....
   */

  bool isValidHtmlOrJavascript(String text, String errorMessage) {
    return isValidJavascript(text, errorMessage);
  }

  bool isTrue(bool b, String errorMessage) {
    if (!b) {
      addError(errorMessage);
      return false;
    }
    return true;
  }

  bool isNotNullAndNonEmptyArray(List<String> arr, String errorMessage) {
    if (arr == null || arr.length == 0) {
      addError(errorMessage);
      return false;
    }
    return true;
  }

  bool isValidConditionalExpression(
      String conditionExpression, String errorMessage) {
    if (isNullOrEmptyString(conditionExpression)) {
      addError(errorMessage);
      return false;
    }
    // TODO validate the conditionExpression with the interpreter.
    // If it does not throw any errors, then we are good.
    return true;
  }

  List<ValidationMessage> getResults() {
    return results;
  }

  String stringifyResults() {
    var buf = "";
    for (ValidationMessage msg in results) {
      buf += msg.toString();
      buf += ("\n");
    }
    return buf.toString();
  }
}
