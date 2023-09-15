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

const APPS_USED_RULE_TYPE = 'apps_used';
const APP_CONTENT_RULE_TYPE = 'app_content';

final _logger = Logger('AllowListLogger');

class AllowListRule {
  String _type;
  RegExp _expression;
  String _appForContentRule;

  AllowListRule(Map<String, String> map) {
    _type = map['type'];
    _expression = RegExp(map['expression']);
    if (_type == APP_CONTENT_RULE_TYPE) {
      _appForContentRule = map['app'];
    }
  }
  
  bool matches(value) => _expression.hasMatch(value);

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
    _appContentRules = _rules.where((element) => element._type == APP_CONTENT_RULE_TYPE);
  }

  List<Event> filterData(List events) {
    for (var event in events) {
      filter(event);
    }
    return events;
  }

  filter(Event event) {
    _logger.info("Event: ${event.toJson()}");
    if (event.groupName != 'APPUSAGE_DESKTOP') {
      return event;
    }
    if (_appRules == null) {
      hashAllAppLoggerFields(event);
      return;
    }
    var allowed = false;
    for (var appRule in _appRules) {
       if (event.responses.containsKey(appsUsedKey) &&
           event.responses[appsUsedKey] != null &&
           appRule.matches(event.responses[appsUsedKey])) {
         allowed = true;
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
        if (event.responses.containsKey(appContentKey) &&
            event.responses[appContentKey] != null &&
            appContentRule.matches(event.responses[appContentKey])) {
          allowAppContents = true;
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
    var appsUsedValue = responses[appsUsedKey];
    if (appsUsedValue == null) {
      appsUsedValue = "";
    }
    var appsUsedValueHash = hash(appsUsedValue);
    responses[appsUsedKey] = appsUsedValueHash;
    var appContentValue = responses[appContentKey];
    if (appContentValue == null) {
      appContentValue = "";
    }
    var appContentValueHash = hash(appContentValue);
    responses[appContentKey] = appContentValueHash;
    responses[appsUsedRawKey] = appsUsedValueHash + ":" + appContentValueHash;
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
    var appContentValue = responses[appContentKey];
    if (appContentValue == null) {
      appContentValue = "";
    }
    var appsUsedValue = responses[appsUsedKey];
    if (appsUsedValue ==null) {
      appsUsedValue = "";
    }
    var hashedAppContent = hash(appContentValue);
    responses[appContentKey] = hashedAppContent;
    responses[appsUsedRawKey] = appsUsedValue + ":" + hashedAppContent;
  }
}
