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

import 'package:test/test.dart';
import 'package:pal_event_server/src/daemon/linux/dbus_notifications.dart';

final _closedNotificationMessage = "signal time=1693957303.167479 sender=:1.130 -> destination=(null destination) serial=1217 path=/org/freedesktop/Notifications; interface=org.freedesktop.Notifications; member=NotificationClosed\n" +
  "   uint32 1\n" + 
  "   uint32 2\n\n";

final _actionInvokedMessage = "signal time=1693957303.166625 sender=:1.130 -> destination=(null destination) serial=1216 path=/org/freedesktop/Notifications; interface=org.freedesktop.Notifications; member=ActionInvoked\n"
  "   uint32 1\n" +
  "   string \"default\"\n\n";

final _inapplicableActionInvokedMessage = "signal time=1693957303.166625 sender=:1.130 -> destination=(null destination) serial=1216 path=/org/freedesktop/Notifications; interface=org.freedesktop.Notifications; member=ActionInvoked\n"
  "   uint32 15\n" +
  "   string \"other\"\n\n";


void main() {
  group('All', ()
  {
    test('A notification fired with an empty event while no notifications are outstanding should not throw a StateException', () {
      notifications = <int, int>{};
      listen("");
      expect(true, true);
    });
    test('A notification fired with an event while no notifications are outstanding should not throw a StateException', () {
      notifications = <int, int>{};
      listen(_actionInvokedMessage + _closedNotificationMessage);
      expect(true, true);
   });
   test('A notification fired with an unmatched Event while a notification is outstanding should not throw a StateException', () {
     notifications = <int, int>{1:1};
     listen(_inapplicableActionInvokedMessage);      
     expect(true, true);
   });
   // commented out since it causes the Taqo graphical client to open
   // test('A notification fired with a matched event while a notification is outstanding should not throw a StateException', () {
   //   sut.notifications = <int, int>{1:27};
   //   sut.openSurvey = (id) => print("Called");
   //   listen(_actionInvokedMessage + _closedNotificationMessage);      
   //   expect(true, true);
   // });
   test('actionInvoked regex matches', () {
     final action = actionPattern.matchAsPrefix(_actionInvokedMessage);
     expect(action, isNotNull);
     expect(action[1], equals("1"));
     expect(action[2], equals("default"));
});
   test('actionInvoked+closedNotification regex matches', () {
     final action = actionPattern.matchAsPrefix(_actionInvokedMessage + _closedNotificationMessage);
     expect(action, isNotNull);
     expect(action[1], equals("1"));
     expect(action[2], equals("default"));
   });
   test('closedNotification regex matches', () {
     final action = closedPattern.matchAsPrefix(_closedNotificationMessage);
     expect(action, isNotNull);
     expect(action[1], equals("1"));
     expect(action[2], equals("2"));
   });
   test('inApplicableNotification regex does not match', () {
     final action = actionPattern.matchAsPrefix(_inapplicableActionInvokedMessage);
     expect(action, isNotNull);
     expect(action[1], isNot(equals("1")));
     expect(action[2], isNot(equals("default")));
     expect(action[2], isNot(equals("taqo")));
   });
  });
}