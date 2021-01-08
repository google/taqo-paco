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

String snakeCaseToCamelCase(String string) {
  if (string == null) {
    return null;
  }
  var wordList = string.split('_').skipWhile((s) => s.isEmpty);
  return wordList.isEmpty
      ? ''
      : wordList.first.toLowerCase() +
          wordList.skip(1).map(toSentenceCase).join();
}

String toSentenceCase(String string) => (string == null || string == '')
    ? string
    : string[0].toUpperCase() + string.substring(1).toLowerCase();

String templateFormat(String template, Map<String, String> map) =>
    template?.replaceAllMapped(
        RegExp('\{\{([^{}]+)\}\}'),
        (Match m) =>
            ((map ?? {})['${m[1]}']) ??
            (throw ArgumentError(
                'The replacement for placeholder ${m[1]} is not specified.')));
