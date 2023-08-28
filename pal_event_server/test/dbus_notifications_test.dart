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

void main() {
  group('All', ()
  {
    test('A notification fired with an empty event while no notifications are outstanding should not throw a StateException', () {
      notifications = <int, int>{};
      listen("");
      expect(true, true);
    });
    test('A notification fired with an event while no notifications are outstanding should nto throw a StateException', () {
      notifications = <int, int>{};
      listen("/org/freedesktop/Notifications: org.freedesktop.Notifications.ActionInvoked (uint32 27, 'default')\n" +
        "/org/freedesktop/Notifications: org.freedesktop.Notifications.NotificationClosed (uint32 27, uint32 2)");
      expect(true, true);
   });
   test('A notification fired with an unmatched Event while a notification is outstanding should not throw a StateException', () {
     notifications = <int, int>{1:1};
     listen("/org/freedesktop/Notifications: org.freedesktop.Notifications.ActionInvoked (uint32 27, 'default')\n" +
        "/org/freedesktop/Notifications: org.freedesktop.Notifications.NotificationClosed (uint32 27, uint32 2)");
     expect(true, true);
   });
   // commented out since it causes the Taqo graphical client to open
   // test('A notification fired with a matched event while a notification is outstanding should not throw a StateException', () {
   //   sut.notifications = <int, int>{1:27};
   //   sut.openSurvey = (id) => print("Called");
   //   sut.listen("/org/freedesktop/Notifications: org.freedesktop.Notifications.ActionInvoked (uint32 27, 'default')\n" +
   //      "/org/freedesktop/Notifications: org.freedesktop.Notifications.NotificationClosed (uint32 27, uint32 2)");
   //   expect(true, true);
   // });
  });
}