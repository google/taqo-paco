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

import 'dart:io';

final localServerHost = InternetAddress.loopbackIPv4;
const localServerPort = 31415;

const scheduleAlarmMethod = 'schedule';
const cancelAlarmMethod = 'cancel';
const cancelNotificationMethod = 'cancelNotify';
const cancelExperimentNotificationMethod = 'cancelExperimentNotify';
const checkActiveNotificationMethod = 'checkActiveNotification';

const notifyMethod = 'notify';
const expireMethod = 'expire';

const createMissedEventMethod = 'missedEvent';

const openSurveyMethod = 'openSurvey';

// Sqlite
const insertAlarm = 'insertAlarm';
const insertNotification = 'insertNotification';
const insertEvent = 'insertEvent';

const selectAlarmById = 'selectAlarm';
const selectAllAlarms = 'selectAllAlarms';
const removeAlarmById = 'removeAlarm';
const selectNotificationById = 'selectNotification';
const selectNotificationsByExperiment = 'selectNotificationsByExperiment';
const selectAllNotifications = 'selectAllNotifications';
const removeNotificationById = 'removeNotification';
const removeAllNotifications = 'removeAllNotifications';
