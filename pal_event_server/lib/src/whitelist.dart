import 'url_matcher.dart';

typedef TestFunc = bool Function(String, String, String, String);

class WhitelistRule {
  final TestFunc _test;

  WhitelistRule(this._test);

  bool matches(String appName, String appsUsedRaw, String appContent, String appUrl) =>
      _test(appName, appsUsedRaw, appContent, appUrl);
}

class Whitelist {
  final _rules = <WhitelistRule>[
    WhitelistRule((String appName, String appsUsedRaw, String appContent, String appUrl) {
      return appUrl != null ? matchesHost(Uri.dataFromString(appUrl), 'flutter.io') : false;
    }),
    WhitelistRule((String appName, String appsUsedRaw, String appContent, String appUrl) {
      return appUrl != null
          ? matchesHostAndPath(Uri.dataFromString(appUrl), 'github.com', '^/flutter*')
          : false;
    }),
    WhitelistRule((String appName, String appsUsedRaw, String appContent, String appUrl) {
      return appUrl != null ? matchesHost(Uri.dataFromString(appUrl), 'stackoverflow.com') : false;
    }),
    WhitelistRule((String appName, String appsUsedRaw, String appContent, String appUrl) {
      return appUrl != null
          ? matchesHostAndPort(Uri.dataFromString(appUrl), '127.0.0.1', 8100) &&
              matches(appContent, '^Dart VM Observatory')
          : false;
    }),
    WhitelistRule((String appName, String appsUsedRaw, String appContent, String appUrl) {
      return appUrl != null
          ? matchesHostAndPath(Uri.dataFromString(appUrl), 'gitter.im', '/flutter/flutter')
          : false;
    }),
    WhitelistRule((String appName, String appsUsedRaw, String appContent, String appUrl) {
      return appUrl != null
          ? matchesHostAndPath(
              Uri.dataFromString(appUrl), 'google.com', '^/search?.*&q=.*flutter.*')
          : false;
    }),
    WhitelistRule((String appName, String appsUsedRaw, String appContent, String appUrl) {
      return matches(appContent, '.*flutter.*');
    })
  ];

  List<String> _hideAllButAppName(String appName) =>
      <String>[appName, '$appName❣hidden', 'hidden', 'hidden'];

  List<String> _blackOutData(String appName, String appsUsedRaw, String appContent, String appUrl) {
    for (var rule in _rules) {
      if (rule.matches(appName, appsUsedRaw, appContent, appUrl)) {
        return <String>[appName, appsUsedRaw, appContent, appUrl];
      }
    }

    return _hideAllButAppName(appName);
  }

  List<Map<String, dynamic>> blackOutData(List eventJson) {
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

        final responsesWhitelisted = <Map<String, dynamic>>[];
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
            responsesWhitelisted.add(response);
          }
        }

        final data = _blackOutData(appName, appsUsedRaw, appContent, appUrl);

        responsesWhitelisted.add(<String, dynamic>{'name': 'apps_used', 'answer': data[0]});
        responsesWhitelisted.add(<String, dynamic>{'name': 'apps_used_raw', 'answer': data[1]});
        responsesWhitelisted.add(<String, dynamic>{'name': 'app_content', 'answer': data[2]});
        responsesWhitelisted.add(<String, dynamic>{'name': 'url', 'answer': data[3]});

        event['responses'] = responsesWhitelisted;
        results.add(event);
      }
    }

    return results;
  }
}
