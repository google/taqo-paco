abstract class Validator {
  static const MANDATORY = 1;
  static const OPTIONAL = 2;

  void addError(String errorMessage);

  bool isNonEmptyString(String value, String errorMsg);

  bool isNotNullAndNonEmptyCollection(List collection, String errorMessage);

  bool isValidEmail(String address, String errorMessage);

  bool isValidCollectionOfEmailAddresses(
      List<String> collection, String errorMessage);

  bool isNotNullCollection(List actionTriggers, String errorMessage);

  bool isValidDateString(String dateStr, String errorMessage);

  bool isNotNull(Object obj, String errorMessage);

  bool isValidJavascript(String customRenderingCode, String errorMessage);

  bool isValidHtmlOrJavascript(String text, String errorMessage);

  bool isTrue(bool b, String string);

  bool isNotNullAndNonEmptyArray(List<String> arr, String errorMessage);

  bool isValidConditionalExpression(
      String conditionExpression, String errorMessage);
}
