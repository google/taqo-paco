import 'dart:async';

import 'package:taqo_common/model/event.dart';
import 'package:taqo_event_server_protocol/taqo_event_server_protocol.dart';

// This is only a no-op example event server.
// The return type of each message handler is either Future<TespResponse> or
// TespResponse, based on wild guesses. Please use the actual type when
// implementing a real event server.
class ExampleEventServer with TespRequestHandlerMixin {
  TespServer _tespServer;

  ExampleEventServer() {
    _tespServer = TespServer(this);
  }

  int get port => _tespServer.port;

  Future<void> serve({dynamic address = '127.0.0.1', int port = 0}) async {
    await _tespServer.serve(address: address, port: port);
  }

  @override
  Future<TespResponse> palAddEvent(Event event) {
    print('addEvent: $event');
    return Future.value(TespResponseSuccess());
  }

  @override
  TespResponse palAllData() {
    print('allData');
    return TespResponseSuccess();
  }

  @override
  TespResponse palPause() {
    print('pause');
    return TespResponseSuccess();
  }

  @override
  TespResponse palResume() {
    print('resume');
    return TespResponseSuccess();
  }

  @override
  TespResponse palWhiteListDataOnly() {
    print('whiteListDataOnly');
    return TespResponseSuccess();
  }

  @override
  Future<TespResponse> alarmCancel(int alarmId) {
    print('alarmCancel: $alarmId');
    return Future.value(TespResponseSuccess());
  }

  @override
  Future<TespResponse> alarmSchedule() {
    print('alarmSchedule');
    return Future.value(TespResponseSuccess());
  }

  @override
  Future<TespResponse> alarmSelectAll() {
    print('alarmSelectAll');
    // Here we don't have access to the Alarm class, used string instead
    // In practice, they can be real objects.
    return Future.value(TespResponseAnswer(['Alarm(1)', 'Alarm(2)']));
  }

  @override
  Future<TespResponse> alarmSelectById(int alarmId) {
    print('alarmSelectById: $alarmId');
    return Future.value(TespResponseAnswer('Alarm'));
  }

  @override
  Future<TespResponse> createMissedEvent(Event event) {
    print('createMissedEvent: $event');
    return Future.value(TespResponseSuccess());
  }

  @override
  Future<TespResponse> notificationCancel(int notificationId) {
    print('notificationCancel: $notificationId');
    return Future.value(TespResponseSuccess());
  }

  @override
  Future<TespResponse> notificationCancelByExperiment(int experimentId) {
    print('notificationCancelByExperiment: $experimentId');
    return Future.value(TespResponseSuccess());
  }

  @override
  Future<TespResponse> notificationCheckActive() {
    print('notificationCheckActive');
    return Future.value(TespResponseAnswer(false));
  }

  @override
  Future<TespResponse> notificationSelectAll() {
    print('notificationSelectAll');
    return Future.value(
        TespResponseAnswer(['Notification(1)', 'Notification(2)']));
  }

  @override
  Future<TespResponse> notificationSelectByExperiment(int experimentId) {
    print('notificationSelectByExperiment: $experimentId');
    return Future.value(TespResponseAnswer('Notification(1)'));
  }

  @override
  Future<TespResponse> notificationSelectById(int notificationId) {
    print('notificationSelectById: $notificationId');
    return Future.value(TespResponseAnswer('Notification(2)'));
  }
}

void main() async {
  var server = ExampleEventServer();
  await server.serve(port: 4444);
  print('Waiting for request on port ${server.port}...');
}
