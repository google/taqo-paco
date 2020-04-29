import 'dart:async';
import 'dart:io';

import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:taqo_common/model/action_specification.dart';
import 'package:taqo_common/model/event.dart';
import 'package:taqo_common/model/notification_holder.dart';
import 'package:taqo_common/rpc/socket_channel.dart';
import 'package:taqo_common/rpc/rpc_constants.dart';

import '../sqlite_database/sqlite_database.dart';

class SqliteServer {
  final Socket _socket;
  Server _server;
  SqliteDatabase _database;

  SqliteServer._(this._socket);

  static Future<SqliteServer> get(Socket socket) {
    final completer = Completer<SqliteServer>();
    final instance = SqliteServer._(socket);
    instance._initialize().then((_) {
      completer.complete(instance);
    });
    return completer.future;
  }

  Future _initialize() async {
    _server = Server(SocketChannel(_socket));
    _server.registerMethod(insertAlarm, _insertAlarm);
    _server.registerMethod(insertNotification, _insertNotification);
    _server.registerMethod(insertEvent, _insertEvent);

    _server.registerMethod(selectAlarmById, _selectAlarmById);
    _server.registerMethod(selectAllAlarms, _selectAllAlarms);
    _server.registerMethod(removeAlarmById, _removeAlarmById);
    _server.registerMethod(selectNotificationById, _selectNotificationById);
    _server.registerMethod(selectNotificationsByExperiment, _selectNotificationsByExperiment);
    _server.registerMethod(selectAllNotifications, _selectAllNotifications);
    _server.registerMethod(removeNotificationById, _removeNotificationById);
    _server.registerMethod(removeAllNotifications, _removeAllNotifications);

    _database = await SqliteDatabase.get();
  }

  Future close() async {
    _database.close();
    _server?.close();
  }

  Future<int> _insertAlarm(Parameters args) {
    final alarm = ActionSpecification.fromJson(args.asMap);
    return _database.insertAlarm(alarm);
  }

  Future<int> _insertNotification(Parameters args) {
    final notification = NotificationHolder.fromJson(args.asMap);
    return _database.insertNotification(notification);
  }

  Future<int> _insertEvent(Parameters args) {
    final event = Event.fromJson(args.asMap);
    return _database.insertEvent(event);
  }

  Future<ActionSpecification> _selectAlarmById(Parameters args) {
    final id = args.asMap['id'];
    return _database.getAlarm(id);
  }

  Future<Map<int, ActionSpecification>> _selectAllAlarms(Parameters args) {
    return _database.getAllAlarms();
  }

  Future _removeAlarmById(Parameters args) {
    final id = args.asMap['id'];
    return _database.removeAlarm(id);
  }

  Future<NotificationHolder> _selectNotificationById(Parameters args) {
    final id = args.asMap['id'];
    return _database.getNotification(id);
  }

  Future<List<NotificationHolder>> _selectNotificationsByExperiment(Parameters args) {
    final id = args.asMap['id'];
    return _database.getAllNotificationsForExperiment(id);
  }

  Future<List<NotificationHolder>> _selectAllNotifications(Parameters args) {
    return _database.getAllNotifications();
  }

  Future _removeNotificationById(Parameters args) {
    final id = args.asMap['id'];
    return _database.removeNotification(id);
  }

  Future _removeAllNotifications(Parameters args) {
    return _database.removeAllNotifications();
  }
}
