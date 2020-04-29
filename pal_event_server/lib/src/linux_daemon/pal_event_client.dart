import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:taqo_common/model/experiment.dart';
import 'loggers/app_logger.dart' show appNameField, windowNameField;

const _experimentId = 'experimentId';
const _experimentName = 'experimentName';
const _experimentVersion = 'experimentVersion';
const _responseTime = 'responseTime';
const _experimentGroupName = 'experimentGroupName';
const _participantId = 'participantId';

const _responses = 'responses';
const _responseName = 'name';
const _responseAnswer = 'answer';

Map<String, dynamic> _createPacoEvent(Experiment experiment, String groupName) {
  final responses = <Map<String, String>>[
    {
      _responseName: _participantId,
      _responseAnswer: 'TODO:participantId',
    },
  ];
  return <String, dynamic>{
    _experimentId: experiment.id,
    _experimentName: experiment.title,
    _experimentVersion: experiment.version,
    _responseTime: DateTime.now().toIso8601String(),
    _experimentGroupName: groupName,
    _responses: responses,
  };
}

const _appsUsedKey = 'apps_used';
const _appContentKey = 'app_content';
const _appsUsedRawKey = 'apps_used_raw';

Future<Map<String, dynamic>> createAppUsagePacoEvent(Experiment experiment, String groupName,
    Map<String, dynamic> response) async {
  final json = await _createPacoEvent(experiment, groupName);
  final responses = <Map<String, String>>[
    {
      _responseName: _appsUsedKey,
      _responseAnswer: response[appNameField],
    },
    {
      _responseName: _appContentKey,
      _responseAnswer: response[windowNameField],
    },
//    {
//      _responseName: 'url',
//      _responseAnswer: response['url'],
//    },
    {
      _responseName: _appsUsedRawKey,
      _responseAnswer: '${response[appNameField]}:${response[windowNameField]}',
    },
  ];
  json[_responses].addAll(responses);
  return json;
}

const _uidKey = 'uid';
const _pidKey = 'pid';
const _cmdRawKey = 'cmd_raw';
const _cmdRetKey = 'cmd_ret';

Future<Map<String, dynamic>> createCmdUsagePacoEvent(Experiment experiment, String groupName,
    Map<String, dynamic> response) async {
  final json = await _createPacoEvent(experiment, groupName);
  final responses = <Map<String, String>>[
    {
      _responseName: _uidKey,
      _responseAnswer: response[_uidKey],
    },
    {
      _responseName: _pidKey,
      _responseAnswer: '${response[_pidKey]}',
    },
    {
      _responseName: _cmdRetKey,
      _responseAnswer: '${response[_cmdRetKey]}',
    },
    {
      _responseName: _cmdRawKey,
      _responseAnswer: response[_cmdRawKey].trim(),
    },
  ];
  json[_responses].addAll(responses);
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
