import 'dart:io';

final localServerHost = InternetAddress.loopbackIPv4;
const localServerPort = 31415;

const scheduleAlarmMethod = 'schedule';
const cancelAlarmMethod = 'cancel';
const postNotificationMethod = 'notify';
const cancelNotificationMethod = 'cancelNotify';
const cancelExperimentNotificationMethod = 'cancelExperimentNotify';
const checkActiveNotificationMethod = 'checkActiveNotification';

const notifyMethod = 'notify';
const expireMethod = 'expire';

const createMissedEventMethod = 'missedEvent';

const openSurveyMethod = 'openSurvey';
