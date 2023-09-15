// Copyright 2023 Google LLC
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

import 'package:taqo_common/model/event.dart';
import 'package:taqo_common/model/experiment.dart';
import 'package:taqo_common/model/experiment_group.dart';
import 'package:test/test.dart';
import 'package:pal_event_server/src/allowlist.dart';
import 'package:pal_event_server/src/loggers/pal_event_helper.dart';

void main() {
  group('All', ()
  {
    test("empty allowlist passes no app usage data", () async {
      var event = await createPacoEvent(createAppUsageExperiment(), 'APPUSAGE_DESKTOP');
      event.responses.addAll({ appsUsedKey : 'Chrome', appContentKey : 'Google',
        appsUsedRawKey : 'Chrome:Google'});

      var allowlist = AllowList();
      allowlist.rules = <AllowListRule>[];

      var resultantEvent = allowlist.filter(event);

      var resultResponses = resultantEvent.responses;
      expect(resultResponses[appsUsedKey], isNot(equals('Chrome')));
      expect(resultResponses[appContentKey], isNot(equals('Google')));
      expect(resultResponses[appsUsedRawKey], isNot(equals('Chrome:Google')));
    });
    test("app + app_content rule allowlist passes matching data", () async {
      var event = await createPacoEvent(createAppUsageExperiment(), 'APPUSAGE_DESKTOP');
      event.responses.addAll({ appsUsedKey : 'Chrome', appContentKey : 'Google',
        appsUsedRawKey : 'Chrome:Google'});

      var allowlist = AllowList();
      var appUsedAllowListRule = AllowListRule.ofAppUsed('Chrome');
      var appContentAllowListRule = AllowListRule.ofAppContent("Chrome", "Google");
      allowlist.rules = [appUsedAllowListRule, appContentAllowListRule];

      var resultantEvent = allowlist.filter(event);

      var resultResponses = resultantEvent.responses;
      expect(resultResponses[appsUsedKey], equals('Chrome'));
      expect(resultResponses[appContentKey], equals('Google'));
      expect(resultResponses[appsUsedRawKey], equals('Chrome:Google'));
    });
    test("app + app_content rule allowlist does not pass non-matching data", () async {
      var event = await createPacoEvent(createAppUsageExperiment(), 'APPUSAGE_DESKTOP');
      event.responses.addAll({ appsUsedKey : 'Chrome', appContentKey : 'Google',
        appsUsedRawKey : 'Chrome:Google'});

      var allowlist = AllowList();
      var appUsedAllowListRule = AllowListRule.ofAppUsed('Chrome');
      var appContentAllowListRule = AllowListRule.ofAppContent("Chrome", "fuchsia");
      allowlist.rules = [appUsedAllowListRule, appContentAllowListRule];

      var resultantEvent = allowlist.filter(event);

      var resultResponses = resultantEvent.responses;
      expect(resultResponses[appsUsedKey], equals('Chrome'));
      expect(resultResponses[appContentKey], isNot(equals('Google')));
      expect(resultResponses[appsUsedRawKey], startsWith('Chrome'));
      expect(resultResponses[appsUsedRawKey], isNot(endsWith('Google')));
    });
    test("simple app_content rule allowlist does not pass non-matching appcontent data", () async {
      var event = await createPacoEvent(createAppUsageExperiment(), 'APPUSAGE_DESKTOP');
      event.responses.addAll({ appsUsedKey : 'Chrome', appContentKey : 'Google',
        appsUsedRawKey : 'Chrome:Google'});

      var allowlist = AllowList();
      var allowListRule = AllowListRule.ofAppUsed('Safari');
      allowlist.rules = [allowListRule];

      var resultantEvent = allowlist.filter(event);

      var resultResponses = resultantEvent.responses;
      expect(resultResponses[appsUsedKey], isNot(equals('Chrome')));
      expect(resultResponses[appContentKey], isNot(equals('Google')));
      expect(resultResponses[appsUsedRawKey], isNot(equals('Chrome:Google')));
    });
    test("simple app_content rule allowlist passes non app usage logger data", () async {
      var event = await createPacoEvent(createAppUsageExperiment(), 'APPUSAGE_SHELL');
      event.responses.addAll({ cmdRawKey : 'ls -la', pidKey : '555',
        cmdRetKey : '0'});

      var allowlist = AllowList();
      var allowListRule = AllowListRule.ofAppUsed('Chrome');
      allowlist.rules = [allowListRule];

      var resultantEvent = allowlist.filter(event);

      var resultResponses = resultantEvent.responses;
      expect(resultResponses[cmdRawKey], equals('ls -la'));
      expect(resultResponses[pidKey], equals('555'));
      expect(resultResponses[cmdRetKey], equals('0'));
    });
    test("filterData processes two events that should pass", () async {
      var experiment = createAppUsageExperiment();
      var event = await createPacoEvent(experiment, 'APPUSAGE_DESKTOP');
      var event2 = await createPacoEvent(experiment, 'APPUSAGE_DESKTOP');
      event.responses.addAll({ appsUsedKey : 'Chrome', appContentKey : 'Google',
        appsUsedRawKey : 'Chrome:Google'});
      event2.responses.addAll({ appsUsedKey : 'Safari', appContentKey : 'Google',
        appsUsedRawKey : 'Safari:Google'});

      var allowlist = AllowList();
      var appUsedAllowListRule = AllowListRule.ofAppUsed('Chrome');
      var appUsedAllowListRuleSafari = AllowListRule.ofAppUsed('Safari');
      var appContentAllowListRule = AllowListRule.ofAppContent("Chrome", "Google");
      var appContentAllowListRuleSafariGoogle = AllowListRule.ofAppContent("Safari", "Google");
      allowlist.rules = [appUsedAllowListRule, appUsedAllowListRuleSafari,
        appContentAllowListRuleSafariGoogle, appContentAllowListRule];

      allowlist.filterData([event,event2]);

      var resultResponses = event.responses;
      expect(resultResponses[appsUsedKey], equals('Chrome'));
      expect(resultResponses[appContentKey], equals('Google'));
      expect(resultResponses[appsUsedRawKey], equals('Chrome:Google'));

      var resultResponses2 = event2.responses;
      expect(resultResponses2[appsUsedKey], equals('Safari'));
      expect(resultResponses2[appContentKey], equals('Google'));
      expect(resultResponses2[appsUsedRawKey], equals('Safari:Google'));

    });
    test("filterData processes two events that should not pass", () async {
      var experiment = createAppUsageExperiment();
      var event = await createPacoEvent(experiment, 'APPUSAGE_DESKTOP');
      var event2 = await createPacoEvent(experiment, 'APPUSAGE_DESKTOP');
      event.responses.addAll({ appsUsedKey : 'Chrome', appContentKey : 'Google',
        appsUsedRawKey : 'Chrome:Google'});
      event2.responses.addAll({ appsUsedKey : 'Safari', appContentKey : 'Google',
        appsUsedRawKey : 'Safari:Google'});

      var allowlist = AllowList();
      var appUsedAllowListRule = AllowListRule.ofAppUsed('Firefox');
      var appContentAllowListRule = AllowListRule.ofAppContent("Firefox", "Google");
      allowlist.rules = [appUsedAllowListRule, appContentAllowListRule];

      allowlist.filterData([event,event2]);

      var resultResponses = event.responses;
      expect(resultResponses[appsUsedKey], isNot(equals('Chrome')));
      expect(resultResponses[appContentKey], isNot(equals('Google')));
      expect(resultResponses[appsUsedRawKey], isNot(equals('Chrome:Google')));

      var resultResponses2 = event2.responses;
      expect(resultResponses2[appsUsedKey], isNot(equals('Safari')));
      expect(resultResponses2[appContentKey], isNot(equals('Google')));
      expect(resultResponses2[appsUsedRawKey], isNot(equals('Safari:Google')));
    });
    test("wipeEvent scrubs matching data", () async {
      var event = await createPacoEvent(createAppUsageExperiment(), 'APPUSAGE_DESKTOP');
      event.responses.addAll({ appsUsedKey : 'Chrome', appContentKey : 'Google Docs - My design doc',
        appsUsedRawKey : 'Chrome:Google Docs - My design doc'});

      var allowlist = AllowList();
      allowlist.wipeDetailsOnEvent(event);

      var resultResponses = event.responses;
      expect(resultResponses[appsUsedKey], equals('Chrome'));
      expect(resultResponses[appContentKey], equals('Google Docs'));
      expect(resultResponses[appsUsedRawKey], equals('Chrome:Google Docs'));
    });
    test("wipeEvent scrubs matching data. Allowlist passes scrubbed value", () async {
      var event = await createPacoEvent(createAppUsageExperiment(), 'APPUSAGE_DESKTOP');
      event.responses.addAll({ appsUsedKey : 'Chrome', appContentKey : 'Google Docs - My design doc',
        appsUsedRawKey : 'Chrome:Google Docs - My design doc'});

      var allowlist = AllowList();
      var rules = <AllowListRule>[];
      allowlist.rules = rules;
      rules.add(AllowListRule.ofAppUsed('Chrome'));
      rules.add(AllowListRule.ofAppContent(".*", "Google Docs"));
      allowlist.wipeDetailsOnEvent(event);

      var resultResponses = event.responses;
      expect(resultResponses[appsUsedKey], equals('Chrome'));
      expect(resultResponses[appContentKey], equals('Google Docs'));
      expect(resultResponses[appsUsedRawKey], equals('Chrome:Google Docs'));

      allowlist.filter(event);

      expect(resultResponses[appsUsedKey], equals('Chrome'));
      expect(resultResponses[appContentKey], equals('Google Docs'));
      expect(resultResponses[appsUsedRawKey], equals('Chrome:Google Docs'));
    });
  });
}



Experiment createAppUsageExperiment() {
  var experiment = Experiment();
  experiment.id = 1;
  experiment.participantId = 100;
  var appUsageGroup = ExperimentGroup();
  appUsageGroup.name = 'APPUSAGE_DESKTOP';
  var shellUsageGroup = ExperimentGroup();
  shellUsageGroup.name = 'APPUSAGE_SHELL';
  experiment.groups = [appUsageGroup, shellUsageGroup];
  return experiment;
}

answerFor(key, resultResponses) => resultResponses.where((m) {
  return m["name"] == key;
}).map((r) => r['answer']).first;