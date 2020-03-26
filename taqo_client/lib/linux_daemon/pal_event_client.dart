import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'app_logger.dart' show appNameField, windowNameField;
import 'util.dart';

Future<Map<String, dynamic>> _createPacoEvent() async {
  final experiment = (await readJoinedExperiments()).firstWhere((_) => true, orElse: null);
  if (experiment == null) {
    print('No experiment joined');
    return null;
  }

  final json = <String, dynamic>{};
  json['experimentId'] = experiment.id;
  json['experimentName'] = experiment.title;
  json['experimentVersion'] = experiment.version;
  json['responseTime'] = DateTime.now().toIso8601String();
  json['experimentGroupName'] = experiment.groups.first.name;
  return json;
}

Future<Map<String, dynamic>> createAppUsagePacoEvent(Map<String, String> response) async {
  final json = await _createPacoEvent();
  final responses = <Map<String, String>>[];

  final appsUsed = <String, String>{};
  appsUsed['name'] = 'apps_used';
  appsUsed['answer'] =  response[appNameField];
  responses.add(appsUsed);

  final appContent = <String, String>{};
  appContent['name'] = 'app_content';
  appContent['answer'] =  response[windowNameField];
  responses.add(appContent);

//  final url = <String, String>{};
//  url['name'] = 'url';
//  url['answer'] =  response[];
//  responses.add(url);

  final appsUsedRaw = <String, String>{};
  appsUsedRaw['name'] = 'apps_used_raw';
  appsUsedRaw['answer'] =  '${response[appNameField]}:${response[windowNameField]}';
  responses.add(appsUsedRaw);

  json['responses'] = responses;
  return json;
}

Future<Map<String, dynamic>> createCmdUsagePacoEvent(Map<String, dynamic> response) async {
  final json = await _createPacoEvent();
  final responses = <Map<String, String>>[];

  final cmdUid = <String, String>{};
  cmdUid['name'] = 'uid';
  cmdUid['answer'] =  response['uid'];
  responses.add(cmdUid);

  final cmdPid = <String, String>{};
  cmdPid['name'] = 'pid';
  cmdPid['answer'] =  '${response['pid']}';
  responses.add(cmdPid);

  final cmdUsedRaw = <String, String>{};
  cmdUsedRaw['name'] = 'cmd_raw';
  cmdUsedRaw['answer'] =  response['cmd_raw'].trim();
  responses.add(cmdUsedRaw);

  final cmdRet = <String, String>{};
  cmdRet['name'] = 'cmd_ret';
  cmdRet['answer'] =  '${response['ret']}';
  responses.add(cmdRet);

  json['responses'] = responses;
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
