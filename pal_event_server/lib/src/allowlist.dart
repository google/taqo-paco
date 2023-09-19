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

import 'package:pal_event_server/src/loggers/pal_event_helper.dart';
import 'package:taqo_common/model/event.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:logging/logging.dart';

import 'allowlist_default_rules.dart';

const APPS_USED_RULE_TYPE = 'apps_used';
const APP_CONTENT_RULE_TYPE = 'app_content';

final _logger = Logger('AllowListLogger');

class AllowListRule {
  String _type;
  RegExp _expression;
  String _appForContentRule;

  RegExp _appForContentRuleExpression;

  AllowListRule(Map<String, String> map) {
    _type = map['type'];
    _expression = RegExp(map['expression'], caseSensitive: false);
    if (_type == APP_CONTENT_RULE_TYPE) {
      _appForContentRule = map['app'];
      _appForContentRuleExpression = RegExp(_appForContentRule, caseSensitive: false);
    }
  }
  
  bool matches(appsUsedValue, appContentValue) {
    switch (_type) {
      case APPS_USED_RULE_TYPE:
        return _expression.hasMatch(appsUsedValue);
      case APP_CONTENT_RULE_TYPE:
        return _appForContentRuleExpression.hasMatch(appsUsedValue) &&
            _expression.hasMatch(appContentValue);
      default:
        false;
    }

  }

    @override
    String toString() {
      return 'AllowListRule{_type: $_type, _expression: $_expression, _appForContentRule: $_appForContentRule}';
    }

    static AllowListRule ofAppUsed(String expression) {
      return AllowListRule({"type": APPS_USED_RULE_TYPE, "expression": expression});
    }

    static AllowListRule ofAppContent(String app, String expression) {
      return AllowListRule({"type": APP_CONTENT_RULE_TYPE, "app": app, "expression": expression});
    }
  }


class AllowList {
  var _rules = <AllowListRule>[];

  Iterable<AllowListRule> _appRules;

  Iterable<AllowListRule> _appContentRules;

  get rules => _rules;

  set rules(value) {
    _rules = value;
    _appRules = _rules.where((element) => element._type == APPS_USED_RULE_TYPE);
    _appContentRules =
        _rules.where((element) => element._type == APP_CONTENT_RULE_TYPE);
  }

  List<Event> filterData(List<Event> events) {
    try {
      for (var event in events) {
            wipeDetailsOnEvent(event);
            filter(event);
          }
    } catch (e) {
      _logger.warning("Could not filter events", e);
    }
    return events;
  }

  filter(Event event) {
    try {
      _logger.info("Event: ${event.toJson()}");
    } catch (e) {
      _logger.warning("Cannot jsonify event", e);
    }

    if (event.groupName != 'APPUSAGE_DESKTOP') {
      return event;
    }
    if (_appRules == null) {
      hashAllAppLoggerFields(event);
      return;
    }
    var allowed = false;
    for (var appRule in _appRules) {
      if (appRule.matches(event.responses[appsUsedKey] ?? '', null)) {
        allowed = true;
        _logger.info("AppRule that allowed is $appRule");
        break;
      }
    }
    if (!allowed) {
      hashAllAppLoggerFields(event);
    } else {
      if (_appContentRules == null) {
        hashAllAppContentFields(event);
        return;
      }
      var allowAppContents = false;
      for (var appContentRule in _appContentRules) {
        if (appContentRule.matches(event.responses[appsUsedKey] ?? '',
            event.responses[appContentKey] ?? '')) {
          allowAppContents = true;
          _logger.info("AppContentRule that allowed is $appContentRule");
          break;
        }
      }
      if (!allowAppContents) {
        hashAllAppContentFields(event);
      }
    }
    return event;
  }

  void hashAllAppLoggerFields(Event event) {
    _logger.info("hashing all app fields");
    var responses = event.responses;
    var appsUsedValueHash = hash(responses[appsUsedKey] ?? "");
    responses[appsUsedKey] = appsUsedValueHash;
    var appContentValueHash = hash(responses[appContentKey] ?? "");
    responses[appContentKey] = appContentValueHash;
    responses[appsUsedRawKey] = appsUsedValueHash + ":" + appContentValueHash;
  }

  void wipeDetailsOnEvent(Event event) {
    if (event.responses.containsKey(appContentKey)) {
      var app_content = event.responses[appContentKey];
      if (chatRegex.hasMatch(app_content)) {
        event.responses[appContentKey] = 'Chat';
      } else if (meetRegex.hasMatch(app_content)) {
        event.responses[appContentKey] = 'Meet';
      } else if (mailRegex.hasMatch(app_content)) {
        event.responses[appContentKey] = 'Mail';
      } else if (calendarRegex.hasMatch(app_content)) {
        event.responses[appContentKey] = 'Calendar';
      } else if (googleDocsRegex.hasMatch(app_content)) {
        event.responses[appContentKey] = 'Google Docs';
      }
    
      var apps_used = '';
      if (event.responses.containsKey(appsUsedKey)) {
        apps_used = event.responses[appsUsedKey];
      }
      event.responses[appsUsedRawKey] =
          apps_used + ':' + event.responses[appContentKey];
    }
  }

  String hash(String value) {
    if (value == null) {
      value = "";
    }
    return sha1.convert(utf8.encode(value)).toString();
  }

  void hashAllAppContentFields(Event event) {
    _logger.info("hashing app  content fields");
    var responses = event.responses;
    var hashedAppContent = hash(responses[appContentKey] ?? "");
    responses[appContentKey] = hashedAppContent;
    responses[appsUsedRawKey] = (responses[appsUsedKey] ?? "") + ":" + hashedAppContent;
  }
}
