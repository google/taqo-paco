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

import 'url_matcher.dart';

typedef TestFunc = bool Function(String, String, String, String);

class AllowlistRule {
  final TestFunc _test;

  AllowlistRule(this._test);

  bool matches(String appName, String appsUsedRaw, String appContent,
          String appUrl) =>
      _test(appName, appsUsedRaw, appContent, appUrl);
}

class Allowlist {
  final _rules = <AllowlistRule>[
    AllowlistRule(
        (String appName, String appsUsedRaw, String appContent, String appUrl) {
      return appUrl != null
          ? matchesHost(Uri.dataFromString(appUrl), 'flutter.io')
          : false;
    }),
    AllowlistRule(
        (String appName, String appsUsedRaw, String appContent, String appUrl) {
      return appUrl != null
          ? matchesHostAndPath(
              Uri.dataFromString(appUrl), 'github.com', '^/flutter*')
          : false;
    }),
    AllowlistRule(
        (String appName, String appsUsedRaw, String appContent, String appUrl) {
      return appUrl != null
          ? matchesHost(Uri.dataFromString(appUrl), 'stackoverflow.com')
          : false;
    }),
    AllowlistRule(
        (String appName, String appsUsedRaw, String appContent, String appUrl) {
      return appUrl != null
          ? matchesHostAndPort(Uri.dataFromString(appUrl), '127.0.0.1', 8100) &&
              matches(appContent, '^Dart VM Observatory')
          : false;
    }),
    AllowlistRule(
        (String appName, String appsUsedRaw, String appContent, String appUrl) {
      return appUrl != null
          ? matchesHostAndPath(
              Uri.dataFromString(appUrl), 'gitter.im', '/flutter/flutter')
          : false;
    }),
    AllowlistRule(
        (String appName, String appsUsedRaw, String appContent, String appUrl) {
      return appUrl != null
          ? matchesHostAndPath(Uri.dataFromString(appUrl), 'google.com',
              '^/search?.*&q=.*flutter.*')
          : false;
    }),
    AllowlistRule(
        (String appName, String appsUsedRaw, String appContent, String appUrl) {
      return matches(appContent, '.*flutter.*');
    })
  ];

  List<String> _hideAllButAppName(String appName) =>
      <String>[appName, '$appName❣hidden', 'hidden', 'hidden'];

  List<String> _filterData(
      String appName, String appsUsedRaw, String appContent, String appUrl) {
    for (var rule in _rules) {
      if (rule.matches(appName, appsUsedRaw, appContent, appUrl)) {
        return <String>[appName, appsUsedRaw, appContent, appUrl];
      }
    }

    return _hideAllButAppName(appName);
  }

  List<Map<String, dynamic>> filterData(List eventJson) {
    final results = <Map<String, dynamic>>[];
    for (var event in eventJson) {
      // TODO This probably shouldn't be here?
      if (event['experimentGroupName'] != 'AppLog') {
        results.add(event);
      } else {
        var appName = '';
        var appsUsedRaw = '';
        var appContent = '';
        var appUrl = '';

        final responsesAllowlisted = <Map<String, dynamic>>[];
        final responses = event['responses'];
        for (Map<String, dynamic> response in responses) {
          final responseName = response['name'];
          final responseAnswer = response['answer'];

          if (responseName == 'apps_used') {
            appName = responseAnswer;
          } else if (responseName == 'apps_used_raw') {
            appsUsedRaw = responseAnswer;
          } else if (responseName == 'app_content') {
            appContent = responseAnswer;
          } else if (responseName == 'url') {
            appUrl = responseAnswer;
          } else {
            responsesAllowlisted.add(response);
          }
        }

        final data = _filterData(appName, appsUsedRaw, appContent, appUrl);

        responsesAllowlisted
            .add(<String, dynamic>{'name': 'apps_used', 'answer': data[0]});
        responsesAllowlisted
            .add(<String, dynamic>{'name': 'apps_used_raw', 'answer': data[1]});
        responsesAllowlisted
            .add(<String, dynamic>{'name': 'app_content', 'answer': data[2]});
        responsesAllowlisted
            .add(<String, dynamic>{'name': 'url', 'answer': data[3]});

        event['responses'] = responsesAllowlisted;
        results.add(event);
      }
    }

    return results;
  }
}
