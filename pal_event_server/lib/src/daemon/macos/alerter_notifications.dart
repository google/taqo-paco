import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';

import '../daemon.dart' as daemon;

const _alerterBinary = '/Applications/taqo_client.app/Contents/MacOS/alerter';
const _bundleId = '/com.taqo.survey.taqoClient';

final _logger = Logger('AlerterNotifications');

// On-going notification ids
final _notifications = <int>[];

void _listen(int id, List<int> event) {
  final json = jsonDecode(String.fromCharCodes(event));
  switch (json['activationType']) {
    case 'closed':
      // noop
      break;
    case 'actionClicked':
    case 'contentsClicked':
      daemon.openSurvey(id);
      break;
  }
}

void cancel(int id) {
  if (!_notifications.contains(id)) {
    return;
  }

  _notifications.remove(id);
  Process.run(_alerterBinary, ['-remove', '$id']);
}

Future<int> notify(int id, String title, String body, {int timeout = 0}) async {
  Process.start(_alerterBinary, [
    '-title', title, '-message', body, '-timeout', '$timeout', //
    '-sender', _bundleId, '-group', '$id', '-json'
  ]).then((Process p) {
    p.stdout.listen((List<int> event) {
      _listen(id, event);
    });
    p.stderr.listen((List<int> err) {
      _logger
          .warning('Error posting notification: ${String.fromCharCodes(err)}');
    });
  });

  _notifications.add(id);
  return id;
}
