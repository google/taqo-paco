import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'linux_daemon.dart';

const _objectPath = '/org/freedesktop/Notifications';
const _dest = 'org.freedesktop.Notifications';
const _notifyMethod = 'org.freedesktop.Notifications.Notify';
const _cancelMethod = 'org.freedesktop.Notifications.CloseNotification';

const _actionInvoked = 'org.freedesktop.Notifications.ActionInvoked';
const _notificationClosed = 'org.freedesktop.Notifications.NotificationClosed';

final _actionPattern =
    RegExp("$_objectPath:\\s+$_actionInvoked\\s+\\(uint32\\s+(\\d+),\\s+'([a-zA-Z]+)'");
final _closedPattern =
    RegExp("$_objectPath:\\s+$_notificationClosed\\s+\\(uint32\\s+(\\d+),\\s+uint32\\s+(\\d+)");

// Map between Taqo database notification id and libnotify id
final _notifications = <int, int>{};

void _listen(String event) {
  final action = _actionPattern.matchAsPrefix(event);
  if (action != null) {
    print('action: id: ${action[1]} action: ${action[2]}');
    if (action.groupCount >= 2 && action[2] == 'default') {
      final notifId = int.tryParse(action[1]);
      if (notifId != null) {
        // Not super efficient, but fine for now
        final id = _notifications.keys.firstWhere((k) => _notifications[k] == notifId);
        openSurvey(id);
      }
    }
  }

  final closed = _closedPattern.matchAsPrefix(event);
  if (closed != null) {
    // TODO Handle?
    print('closed: id: ${closed[1]} reason: ${closed[2]}');
  }
}

void cancel(int id) {
  final notifId = _notifications[id];
  if (notifId == null) return;
  _notifications.remove(id);
  
  Process.run('gdbus', ['call',
    '--session',
    '--dest', _dest,
    '--object-path', _objectPath,
    '--method', _cancelMethod,
    '$notifId']);
}

void monitor() {
  Process.start('gdbus', ['monitor',
    '--session',
    '--dest', _dest,
    '--object-path', _objectPath,
  ]).then((Process process) {
    //stdout.addStream(process.stdout);
    //stderr.addStream(process.stderr);
    Utf8Codec().decoder.bind(process.stdout).listen(_listen);
  });
}

enum Priority {
  low,
  normal,
  critical,
}

String _priorityToString(Priority p) => '<byte ${p.index}>';

String _parseActions(List<String> actions) =>
    '[' + actions.map((String a) => '"$a"').join(', ') + ']';

String _parseHints(Map<String, dynamic> hints) {
  final sb = StringBuffer();
  sb.write('{');
  for (var h in hints.entries) {
    sb.write('"${h.key}"');
    sb.write(': ');
    if (h.value is Priority) {
      sb.write(_priorityToString(h.value));
    } else {
      // TODO Support more types
      sb.write('"{h.value}"');
    }
  }
  sb.write('}');
  return sb.toString();
}

String _parseTimeout(int timeout) => 'int32 $timeout';

Future<int> notify(int id, String appName, int replaceId, String title, String body,
    {String iconPath = '',
    List<String> actions = const <String>['default', ''],
    Map<String, dynamic> hints = const {'urgency': Priority.critical, },
    int timeout = 0}) async {
  final processResult = await Process.run('gdbus', ['call',
    '--session',
    '--dest', _dest,
    '--object-path', _objectPath,
    '--method', _notifyMethod,
    appName, '$replaceId', iconPath, title, body,
    _parseActions(actions), _parseHints(hints), _parseTimeout(timeout),
  ]);

  final idString = processResult.stdout;
  final notifId = int.tryParse(RegExp(r'\(uint32 (\d+),\)').matchAsPrefix(idString)?.group(1));
  _notifications[id] = notifId;
  return notifId;
}
