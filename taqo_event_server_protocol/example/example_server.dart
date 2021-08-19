// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// @dart=2.9

import 'dart:async';

import 'package:taqo_common/model/action_specification.dart';
import 'package:taqo_common/model/event.dart';
import 'package:taqo_common/model/experiment.dart';
import 'package:taqo_common/model/notification_holder.dart';
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
  Future<TespResponse> palAddEvents(List<Event> events) {
    print('addEvents: $events');
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
  TespResponse palAllowlistDataOnly() {
    print('allowlistDataOnly');
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
  Future<TespResponse> alarmAdd(ActionSpecification alarm) {
    print('alarmAdd: $alarm');
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
  Future<TespResponse> alarmRemove(int alarmId) {
    print('alarmRemove: $alarmId');
    return Future.value(TespResponseSuccess());
  }

  @override
  Future<TespResponse> createMissedEvent(Event event) {
    print('createMissedEvent: $event');
    return Future.value(TespResponseSuccess());
  }

  @override
  Future<TespResponse> notificationAdd(NotificationHolder notification) {
    print('notificationAdd: $notification');
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
    return Future.value(TespResponseAnswer('Notification($notificationId)'));
  }

  @override
  Future<TespResponse> notificationRemove(int notificationId) {
    print('notificationRemove: $notificationId');
    return Future.value(TespResponseSuccess());
  }

  @override
  Future<TespResponse> notificationRemoveAll() {
    print('notificationRemoveAll');
    return Future.value(TespResponseSuccess());
  }

  @override
  Future<TespResponse> experimentSaveJoined(List<Experiment> experiments) {
    print('experimentSaveJoined: $experiments');
    return Future.value(TespResponseSuccess());
  }

  @override
  FutureOr<TespResponse> experimentSelectById(int experimentId) {
    print('experimentSelectById: $experimentId');
    return Future.value(TespResponseAnswer('Experiment($experimentId)'));
  }

  @override
  FutureOr<TespResponse> experimentSelectJoined() {
    print('experimentSelectJoined');
    return Future.value(TespResponseAnswer(['Experiment(1)', 'Experiment(2)']));
  }

  @override
  Future<TespResponse> experimentGetPausedStatuses(List<int> experimentIds) {
    print('experimentGetPausedStatuses: ${experimentIds}');
    return Future.value(
        TespResponseAnswer({for (var id in experimentIds) id: false}));
  }

  @override
  Future<TespResponse> experimentSetPausedStatus(
      int experimentId, bool paused) {
    print('experimentSetPausedStatus: $experimentId, $paused');
    return Future.value(TespResponseSuccess());
  }
}

void main() async {
  var server = ExampleEventServer();
  await server.serve(port: 4444);
  print('Waiting for request on port ${server.port}...');
}
