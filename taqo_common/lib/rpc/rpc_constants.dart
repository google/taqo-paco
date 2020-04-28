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
