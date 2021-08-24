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

// @dart=2.9

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
