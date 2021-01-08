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

import 'dart:convert';

// Convert any object to a json object.
// Reference:
// https://github.com/dart-lang/sdk/blob/f12284ca12b9076dcc86f1524fefd57a7318ee52/sdk/lib/convert/json.dart#L668
// Note that as a simple function for internal use only,
// here we don't check for cycles, unlike what is done in the reference.
Object toJsonObject(dynamic object) {
  if (object is num || object is bool || object == null || object is String) {
    return object;
  } else if (object is List) {
    return object.map((e) => toJsonObject(e)).toList();
  } else if (object is Map) {
    return object.map((key, value) {
      if (key is! String) {
        throw JsonUnsupportedObjectError(object,
            cause: 'JSON does not support non-string keys for map');
      }
      return MapEntry(key, toJsonObject(value));
    });
  } else {
    try {
      return object.toJson();
    } catch (e) {
      throw JsonUnsupportedObjectError(object, cause: e);
    }
  }
}
