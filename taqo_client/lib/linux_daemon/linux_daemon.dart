import 'dart:async';
import 'dart:io';

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;

import 'rpc_constants.dart';
import 'dbus_notifications.dart' as dbus;
import 'socket_channel.dart';

const _appName = 'Taqo';

json_rpc.Peer _peer;

// We can probably just store the id?
final _timers = <int, Future>{};

void openSurvey(int id) {
  try {
    // If the app is running, just notify it to open a survey
    _peer.sendNotification(openSurveyMethod, {'id': id,});
  } catch (e) {
    // Else launch the app and it will automatically open the survey
    // Note: this will only work if Taqo is in the user's PATH
    // For debugging/testing, maybe create a symlink in /usr/local/bin pointing to
    // build/linux/debug/taqo_survey
    Process.run('taqo_survey', []);
  }
}

bool _cancelAlarm(int id) {
  if (_timers.containsKey(id)) {
    _timers.remove(id);
    return true;
  }
  return false;
}

bool _handleCancelAlarm(json_rpc.Parameters args) {
  final id = (args.asMap)['id'];
  return _cancelAlarm(id);
}

bool _scheduleAlarm(int id, DateTime when, String action) {
  final timer = Future.delayed(when.difference(DateTime.now()));
  timer.then((_) {
    // Dart doesn't allow a Future to be "canceled"
    // So we use the Map to track which timers are still active
    if (_timers.containsKey(id)) {
      _peer.sendNotification(action, {'id': id});
    }
  });
  _timers[id] = timer;
  return true;
}

bool _handleScheduleAlarm(json_rpc.Parameters args) {
  final id = (args.asMap)['id'] as int;
  final when = DateTime.parse((args.asMap)['when'] as String);
  final action = (args.asMap)['what'] as String;
  return _scheduleAlarm(id, when, action);
}

bool _cancelNotification(int id) {
  dbus.cancel(id);
  return true;
}

bool _handleCancelNotify(json_rpc.Parameters args) {
  final id = (args.asMap)['id'] as int;
  return _cancelNotification(id);
}

Future<bool> _postNotification(int id, String title, String body) async {
  /*final id =*/ await dbus.notify(id, _appName, 0, title, body);
  return true;
}

Future<bool> _handleNotify(json_rpc.Parameters args) {
  final id = (args.asMap)['id'] as int;
  final title = (args.asMap)['title'] as String;
  final body = (args.asMap)['body'] as String;
  return _postNotification(id, title, body);
}

void main() async {
  // Monitor DBus for notification actions
  dbus.monitor();

  // Open a Socket for alarm scheduling
  ServerSocket.bind(localServerHost, localServerPort).then((serverSocket) {
    print('Listening');
    serverSocket.listen((socket) {
      print('Connected');

      _peer = json_rpc.Peer(SocketChannel(socket), onUnhandledError: (e, st) {
        print('linux_daemon socket error: $e');
      });

      _peer.registerMethod(scheduleAlarmMethod, _handleScheduleAlarm);
      _peer.registerMethod(cancelAlarmMethod, _handleCancelAlarm);
      _peer.registerMethod(postNotificationMethod, _handleNotify);
      _peer.registerMethod(cancelNotificationMethod, _handleCancelNotify);
      _peer.listen();

      _peer.done.then((_) {
        print('linux_daemon client socket closed');
        _peer = null;
      });

      // Only allow one connection?
      //serverSocket.close();
    },
    onDone: () {
      print('linux_daemon server socket closed');
      _peer = null;
    });
  });
}
