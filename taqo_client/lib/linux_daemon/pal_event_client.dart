import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'app_logger.dart' show appNameField, windowNameField;
import 'util.dart';

const _experimentId = 'experimentId';
const _experimentName = 'experimentName';
const _experimentVersion = 'experimentVersion';
const _responseTime = 'responseTime';
const _experimentGroupName = 'experimentGroupName';

const _responses = 'responses';
const _responseName = 'name';
const _responseAnswer = 'answer';

Future<Map<String, dynamic>> _createPacoEvent() async {
  final experiment = (await readJoinedExperiments()).firstWhere((_) => true, orElse: null);
  if (experiment == null) {
    print('No experiment joined');
    return null;
  }

  final json = <String, dynamic>{};
  json[_experimentId] = experiment.id;
  json[_experimentName] = experiment.title;
  json[_experimentVersion] = experiment.version;
  json[_responseTime] = DateTime.now().toIso8601String();
  json[_experimentGroupName] = experiment.groups.first.name;
  return json;
}

const _appsUsedKey = 'apps_used';
const _appContentKey = 'app_content';
const _appsUsedRawKey = 'apps_used_raw';

Future<Map<String, dynamic>> createAppUsagePacoEvent(Map<String, String> response) async {
  final json = await _createPacoEvent();
  final responses = <Map<String, String>>[];

  final appsUsed = <String, String>{};
  appsUsed[_responseName] = _appsUsedKey;
  appsUsed[_responseAnswer] =  response[appNameField];
  responses.add(appsUsed);

  final appContent = <String, String>{};
  appContent[_responseName] = _appContentKey;
  appContent[_responseAnswer] =  response[windowNameField];
  responses.add(appContent);

//  final url = <String, String>{};
//  url[_responseName] = 'url';
//  url[_responseAnswer] =  response['url'];
//  responses.add(url);

  final appsUsedRaw = <String, String>{};
  appsUsedRaw[_responseName] = _appsUsedRawKey;
  appsUsedRaw[_responseAnswer] =  '${response[appNameField]}:${response[windowNameField]}';
  responses.add(appsUsedRaw);

  json[_responses] = responses;
  return json;
}

const _uidKey = 'uid';
const _pidKey = 'pid';
const _cmdRawKey = 'cmd_raw';
const _cmdRetKey = 'cmd_ret';

Future<Map<String, dynamic>> createCmdUsagePacoEvent(Map<String, dynamic> response) async {
  final json = await _createPacoEvent();
  final responses = <Map<String, String>>[];

  final cmdUid = <String, String>{};
  cmdUid[_responseName] = _uidKey;
  cmdUid[_responseAnswer] =  response[_uidKey];
  responses.add(cmdUid);

  final cmdPid = <String, String>{};
  cmdPid[_responseName] = _pidKey;
  cmdPid[_responseAnswer] =  '${response[_pidKey]}';
  responses.add(cmdPid);

  final cmdUsedRaw = <String, String>{};
  cmdUsedRaw[_responseName] = _cmdRawKey;
  cmdUsedRaw[_responseAnswer] =  response[_cmdRawKey].trim();
  responses.add(cmdUsedRaw);

  final cmdRet = <String, String>{};
  cmdRet[_responseName] = _cmdRetKey;
  cmdRet[_responseAnswer] =  '${response[_cmdRetKey]}';
  responses.add(cmdRet);

  json[_responses] = responses;
  return json;
}

void sendPacoEvent(List<Map<String, dynamic>> event) {
  // TODO get port dynamically once code is shared with PAL
  Socket.connect(InternetAddress.loopbackIPv4, 6666).then((socket) {
    socket.listen((response) {
      final res = Utf8Decoder().convert(response);
      if (res == 'OK\n') {
        socket.close();
      }
    });
    socket.add(Utf8Encoder().convert(jsonEncode(event)));
  }).catchError((e) {
    print('Error sending to PAL event server: $e');
  });
}
