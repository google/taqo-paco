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

bool matches(String text, String pattern, {bool caseInsensitive = false}) =>
    text != null &&
    RegExp(pattern, caseSensitive: !caseInsensitive).hasMatch(text);

bool matchesHost(Uri url, String host) =>
    url != null && matches(url.host, '$host\$', caseInsensitive: true);

bool matchesPath(Uri url, String path) =>
    url != null && matches(url.path, path);

bool matchesPort(Uri url, int port) =>
    url != null && matches('${url.port}', '^${url.port}\$');

bool matchesHostAndPath(Uri url, String host, String path) =>
    url != null && matchesHost(url, host) && matchesPath(url, path);

bool matchesHostAndPort(Uri url, String host, int port) =>
    url != null && matchesHost(url, host) && matchesPort(url, port);
