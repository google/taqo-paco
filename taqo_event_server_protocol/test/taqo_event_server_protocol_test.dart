import 'dart:async';
import 'dart:io';

import 'package:taqo_event_server_protocol/src/tesp_message_socket.dart';
import 'package:taqo_event_server_protocol/taqo_event_server_protocol.dart';
import 'package:test/test.dart';

import 'tesp_matchers.dart';

const _stringAddEvent = 'addEvent';
const _stringPause = 'pause';
const _stringResume = 'resume';
const _stringAllData = 'allData';
const _stringWhiteListDataOnly = 'whiteListDataOnly';

void main() {
  group('TespServer - single client', () {
    int port;
    TestingEventServer server;
    Socket socket;
    TespMessageSocket<TespResponse, TespMessage> tespSocket;

    setUp(() async {
      server = TestingEventServer();
      await server.serve();
      port = server.port;
      socket = await Socket.connect('127.0.0.1', port);
      tespSocket = TespMessageSocket(socket);
    });

    tearDown(() async {
      tespSocket.close();
      socket.destroy();
      await server.close();
      port = null;
      tespSocket = null;
      socket = null;
      server = null;
    });

    test('ping request', () {
      tespSocket.add(TespRequestPing());
      tespSocket.close();
      expect(tespSocket,
          emitsInOrder([equalsTespMessage(TespResponseSuccess()), emitsDone]));
    });

    test('status change', () async {
      var tespStream = tespSocket.asBroadcastStream(
          onCancel: (subscription) => subscription.pause(),
          onListen: (subscription) => subscription.resume());

      expect(server.isPaused, isFalse);
      expect(server.isAllData, isTrue);
      tespSocket.add(TespRequestPause());
      await expectLater(
          tespStream,
          emits(
              equalsTespMessage(TespResponseAnswer.withPayload(_stringPause))));
      expect(server.isPaused, isTrue);
      tespSocket.add(TespRequestWhiteListDataOnly());
      await expectLater(
          tespStream,
          emits(equalsTespMessage(
              TespResponseAnswer.withPayload(_stringWhiteListDataOnly))));
      expect(server.isAllData, isFalse);
      tespSocket.close();
      expect(tespStream, emitsDone);
    });

    test('stream of requests', () {
      var requests = [
        TespRequestAddEvent.withPayload('1'),
        TespRequestAddEvent.withPayload('2'),
        TespRequestWhiteListDataOnly(),
        TespRequestAddEvent.withPayload('3'),
        TespRequestPause(),
        TespRequestAddEvent.withPayload('4'),
        TespRequestAddEvent.withPayload('5'),
        TespRequestResume(),
        TespRequestAddEvent.withPayload('6'),
        TespRequestAllData(),
        TespRequestAddEvent.withPayload('7')
      ];
      var responses = [
        TespResponseAnswer.withPayload('${_stringAddEvent}: 1'),
        TespResponseAnswer.withPayload('${_stringAddEvent}: 2'),
        TespResponseAnswer.withPayload(_stringWhiteListDataOnly),
        TespResponseAnswer.withPayload('${_stringAddEvent}: 3'),
        TespResponseAnswer.withPayload(_stringPause),
        TespResponsePaused(),
        TespResponsePaused(),
        TespResponseAnswer.withPayload(_stringResume),
        TespResponseAnswer.withPayload('${_stringAddEvent}: 6'),
        TespResponseAnswer.withPayload(_stringAllData),
        TespResponseAnswer.withPayload('${_stringAddEvent}: 7'),
      ];
      expect(
          tespSocket,
          emitsInOrder(responses.map((e) => equalsTespMessage(e)).toList() +
              [emitsDone]));
      requests.forEach((element) {
        tespSocket.add(element);
      });
      tespSocket.close();
    });

    test('error handling - wrong version', () {
      tespSocket.add(TespRequestAddEvent.withPayload('test'));
      socket.add([0xFF, 0x01, 0x02, 0x03, 0x04]);
      tespSocket.add(TespRequestAddEvent.withPayload('will not be responded'));
      expect(
          tespSocket,
          emitsInOrder([
            equalsTespMessage(
                TespResponseAnswer.withPayload('${_stringAddEvent}: test')),
            isA<TespResponseInvalidRequest>(),
            emitsDone
          ]));
    });

    test('error handling - wrong code', () {
      tespSocket.add(TespRequestAddEvent.withPayload('test'));
      socket.add([0x01, 0xFF, 0x01, 0x02, 0x03]);
      tespSocket.add(TespRequestAddEvent.withPayload('will not be responded'));
      expect(
          tespSocket,
          emitsInOrder([
            equalsTespMessage(
                TespResponseAnswer.withPayload('${_stringAddEvent}: test')),
            isA<TespResponseInvalidRequest>(),
            emitsDone
          ]));
    });

    test('error handling - bad payload', () {
      tespSocket.add(TespRequestAddEvent.withPayload('test'));
      socket.add([0x01, 0x01, 0x00, 0x00, 0x00, 0x03, 0xE1, 0xA0, 0xC0]);
      tespSocket.add(TespRequestAddEvent.withPayload('will not be responded'));
      expect(
          tespSocket,
          emitsInOrder([
            equalsTespMessage(
                TespResponseAnswer.withPayload('${_stringAddEvent}: test')),
            isA<TespResponseInvalidRequest>(),
            emitsDone
          ]));
    });

    test('error handling - sending response to server', () {
      tespSocket.add(TespRequestAddEvent.withPayload('1'));
      tespSocket.add(TespResponseAnswer.withPayload(
          'will cause an exception and be ignored'));
      tespSocket.add(TespRequestAddEvent.withPayload('2'));
      tespSocket.close();
      expect(
          tespSocket,
          emitsInOrder([
            equalsTespMessage(
                TespResponseAnswer.withPayload('${_stringAddEvent}: 1')),
            isA<TespResponseInvalidRequest>(),
            equalsTespMessage(
                TespResponseAnswer.withPayload('${_stringAddEvent}: 2')),
            emitsDone
          ]));
    });

    test('errors do not break the server', () async {
      tespSocket.add(TespRequestPause());
      socket.add([0xFF]);
      await expectLater(
          tespSocket,
          emitsInOrder([
            equalsTespMessage(
                TespResponseAnswer.withPayload('${_stringPause}')),
            isA<TespResponseInvalidRequest>(),
            emitsDone
          ]));
      socket.destroy();
      socket = await Socket.connect('127.0.0.1', port);
      tespSocket = TespMessageSocket(socket);
      tespSocket.add(TespRequestAddEvent.withPayload('will be ignored'));
      tespSocket.add(TespRequestResume());
      tespSocket.add(TespRequestAddEvent.withPayload('OK'));
      tespSocket.close();
      expect(
          tespSocket,
          emitsInOrder([
            TespResponsePaused(),
            TespResponseAnswer.withPayload('$_stringResume'),
            TespResponseAnswer.withPayload('${_stringAddEvent}: OK')
          ].map((e) => equalsTespMessage(e))));
    });
  });

  group('TespServer - multiple clients', () {
    int port;
    TestingEventServer server;
    Socket socket1, socket2;
    TespMessageSocket<TespResponse, TespMessage> tespSocket1, tespSocket2;

    setUp(() async {
      server = TestingEventServer();
      await server.serve();
      port = server.port;
      socket1 = await Socket.connect('127.0.0.1', port);
      tespSocket1 = TespMessageSocket(socket1);
      socket2 = await Socket.connect('127.0.0.1', port);
      tespSocket2 = TespMessageSocket(socket2);
    });

    tearDown(() async {
      await server.close();
      tespSocket1.close();
      tespSocket2.close();
      socket1.destroy();
      socket2.destroy();
      port = null;
      server = null;
      tespSocket1 = null;
      tespSocket2 = null;
      socket1 = null;
      socket2 = null;
    });

    test('clients receives responses to their own requests', () async {
      var requests1 = [
        TespRequestAddEvent.withPayload('1'),
        TespRequestAddEvent.withPayload('3'),
        TespRequestAddEvent.withPayload('5'),
        TespRequestAddEvent.withPayload('7'),
        TespRequestAddEvent.withPayload('9'),
      ];
      var responses1 = [
        TespResponseAnswer.withPayload('${_stringAddEvent}: 1'),
        TespResponseAnswer.withPayload('${_stringAddEvent}: 3'),
        TespResponseAnswer.withPayload('${_stringAddEvent}: 5'),
        TespResponseAnswer.withPayload('${_stringAddEvent}: 7'),
        TespResponseAnswer.withPayload('${_stringAddEvent}: 9'),
      ];
      var requests2 = [
        TespRequestAddEvent.withPayload('2'),
        TespRequestAddEvent.withPayload('4'),
        TespRequestAddEvent.withPayload('6'),
        TespRequestAddEvent.withPayload('8'),
        TespRequestAddEvent.withPayload('10'),
      ];
      var responses2 = [
        TespResponseAnswer.withPayload('${_stringAddEvent}: 2'),
        TespResponseAnswer.withPayload('${_stringAddEvent}: 4'),
        TespResponseAnswer.withPayload('${_stringAddEvent}: 6'),
        TespResponseAnswer.withPayload('${_stringAddEvent}: 8'),
        TespResponseAnswer.withPayload('${_stringAddEvent}: 10'),
      ];

      var client1 = Future(() async {
        for (var request in requests1) {
          await Future(() => tespSocket1.add(request));
        }
      });
      var client2 = Future(() async {
        for (var request in requests2) {
          await Future(() => tespSocket2.add(request));
        }
      });

      expect(
          tespSocket1,
          emitsInOrder(responses1.map((e) => equalsTespMessage(e)).toList() +
              [emitsDone]));
      expect(
          tespSocket2,
          emitsInOrder(responses2.map((e) => equalsTespMessage(e)).toList() +
              [emitsDone]));
      await Future.wait([client1, client2]);
      tespSocket1.close();
      tespSocket2.close();
    });

    test('one client pause/resume the server', () async {
      var beforePauseCompleter = Completer();
      var pauseCompleter = Completer();
      var beforeResumeCompleter = Completer();
      var resumeCompleter = Completer();
      var tespStream1 = tespSocket1.asBroadcastStream(
          onCancel: (subscription) => subscription.pause(),
          onListen: (subscription) => subscription.resume());
      var tespStream2 = tespSocket2.asBroadcastStream(
          onCancel: (subscription) => subscription.pause(),
          onListen: (subscription) => subscription.resume());

      var client1 = Future(() async {
        await Future(
            () => tespSocket1.add(TespRequestAddEvent.withPayload('1')));
        await beforePauseCompleter.future;
        await Future(() => tespSocket1.add(TespRequestPause()));
        await expectLater(
            tespStream1,
            emitsInOrder([
              equalsTespMessage(
                  TespResponseAnswer.withPayload('${_stringAddEvent}: 1')),
              equalsTespMessage(TespResponseAnswer.withPayload('$_stringPause'))
            ]));
        pauseCompleter.complete();
        await Future(
            () => tespSocket1.add(TespRequestAddEvent.withPayload('3')));
        beforeResumeCompleter.complete();
        await resumeCompleter.future;
        await Future(
            () => tespSocket1.add(TespRequestAddEvent.withPayload('5')));
      });
      var client2 = Future(() async {
        await Future(
            () => tespSocket2.add(TespRequestAddEvent.withPayload('2')));
        beforePauseCompleter.complete();
        await pauseCompleter.future;
        await Future(
            () => tespSocket2.add(TespRequestAddEvent.withPayload('4')));
        await beforeResumeCompleter.future;
        await Future(() => tespSocket2.add(TespRequestResume()));
        await expectLater(
            tespStream2,
            emitsInOrder([
              equalsTespMessage(
                  TespResponseAnswer.withPayload('${_stringAddEvent}: 2')),
              equalsTespMessage(TespResponsePaused()),
              equalsTespMessage(
                  TespResponseAnswer.withPayload('$_stringResume'))
            ]));
        resumeCompleter.complete();
        await Future(
            () => tespSocket2.add(TespRequestAddEvent.withPayload('6')));
      });
      await Future.wait([client1, client2]);
      expect(
          tespStream1,
          emitsInOrder([
            equalsTespMessage(TespResponsePaused()),
            equalsTespMessage(
                TespResponseAnswer.withPayload('${_stringAddEvent}: 5')),
            emitsDone
          ]));
      expect(
          tespStream2,
          emitsInOrder([
            equalsTespMessage(
                TespResponseAnswer.withPayload('${_stringAddEvent}: 6')),
            emitsDone
          ]));
      tespSocket1.close();
      tespSocket2.close();
    });

    test('one client error does not affect the other', () async {
      var requests2 = [
        TespRequestAddEvent.withPayload('2'),
        TespRequestAddEvent.withPayload('4'),
        TespRequestAddEvent.withPayload('6'),
        TespRequestAddEvent.withPayload('8'),
        TespRequestAddEvent.withPayload('10'),
      ];
      var responses2 = [
        TespResponseAnswer.withPayload('${_stringAddEvent}: 2'),
        TespResponseAnswer.withPayload('${_stringAddEvent}: 4'),
        TespResponseAnswer.withPayload('${_stringAddEvent}: 6'),
        TespResponseAnswer.withPayload('${_stringAddEvent}: 8'),
        TespResponseAnswer.withPayload('${_stringAddEvent}: 10'),
      ];

      var client1 = Future(() async {
        await Future(
            () => tespSocket1.add(TespRequestAddEvent.withPayload('1')));
        await Future(
            () => tespSocket1.add(TespRequestAddEvent.withPayload('3')));
        await Future(() => socket1.add([0xFF]));
        await Future(
            () => tespSocket1.add(TespRequestAddEvent.withPayload('7')));
        await Future(
            () => tespSocket1.add(TespRequestAddEvent.withPayload('9')));
      });
      var client2 = Future(() async {
        for (var request in requests2) {
          await Future(() => tespSocket2.add(request));
        }
      });
      expect(
          tespSocket1,
          emitsInOrder([
            equalsTespMessage(
                TespResponseAnswer.withPayload('${_stringAddEvent}: 1')),
            equalsTespMessage(
                TespResponseAnswer.withPayload('${_stringAddEvent}: 3')),
            isA<TespResponseInvalidRequest>(),
            emitsDone
          ]));
      expect(
          tespSocket2,
          emitsInOrder(responses2.map((e) => equalsTespMessage(e)).toList() +
              [emitsDone]));
      await Future.wait([client1, client2]);
      tespSocket1.close();
      tespSocket2.close();
    });
  });
}

class TestingEventServer with TespRequestHandlerMixin {
  TespServer _tespServer;

  TestingEventServer() {
    _tespServer = TespServer(this);
  }

  int get port => _tespServer.port;

  Future<void> serve() async {
    await _tespServer.serve(address: "127.0.0.1", port: 0);
  }

  Future<void> close() async {
    await _tespServer.close();
  }

  bool isAllData = true;
  bool isPaused = false;

  @override
  Future<TespResponse> addEvent(String eventPayload) async {
    if (isPaused) {
      return TespResponsePaused();
    }
    await Future.delayed(Duration(milliseconds: 200));
    return TespResponseAnswer.withPayload('${_stringAddEvent}: $eventPayload');
  }

  @override
  TespResponse allData() {
    isAllData = true;
    return TespResponseAnswer.withPayload(_stringAllData);
  }

  @override
  TespResponse pause() {
    isPaused = true;
    return TespResponseAnswer.withPayload(_stringPause);
  }

  @override
  TespResponse resume() {
    isPaused = false;
    return TespResponseAnswer.withPayload(_stringResume);
  }

  @override
  TespResponse whiteListDataOnly() {
    isAllData = false;
    return TespResponseAnswer.withPayload(_stringWhiteListDataOnly);
  }
}
