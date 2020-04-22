import 'dart:convert';
import 'dart:io';

import 'package:taqo_common/rpc/rpc_constants.dart';

import '../linux_daemon/linux_daemon.dart' as linux_daemon;
import '../sqlite_database/sqlite_database.dart';
import '../sqlite_database/sqlite_server.dart';
import '../whitelist.dart';
import 'pal_command.dart';

class PALLocalServer {
  final _whitelist = Whitelist();

  ServerSocket _serverSocket;
  final _connectedSockets = <Socket>[];
  bool continueRunning = true;

  void run() {
    ServerSocket.bind(InternetAddress.loopbackIPv4, localServerPort)
        .then((ServerSocket serverSocket) {
          print('Server: listening...');
      _serverSocket = serverSocket;
      serverSocket.listen((Socket socket) {
        linux_daemon.start(socket);
        _addNewConnection(socket);
      }, onError: (e) {
        print('Error is serverSocket.listen(): $e');
      });
    }).catchError((e) {
      print('Error in ServerSocket.bind(): $e');
    });
  }

  void shutdownServer() {
    for (var socket in _connectedSockets) {
      socket.close();
    }
    _serverSocket.close();
  }

  void _addNewConnection(Socket socket) {
    print('Server: client connected');
    _connectedSockets.add(socket);

    print('Starting sqlite server...');
    final _ = SqliteServer.get(socket);
    print('done');

    socket.listen((bytes) => _listen(socket, bytes),
        onError: (err) => _onError(socket, err), onDone: () => _onDone(socket));
  }

  void _listen(Socket socket, dynamic bytes) async {
    final data = String.fromCharCodes(bytes);
    print('Server received: \n$data\n');
    var eventJson = jsonDecode(data);

    if (!(await isRunning())) {
      print('Experiment not running');
    } else if (isPauseMessage(eventJson)) {
      await pauseDataUpload();
    } else if (isResumeMessage(eventJson)) {
      await resumeDataUpload();
    } else if (isWhitelistedDataOnlyMessage(eventJson)) {
      await setWhitelistedDataOnly();
    } else if (isAllDataMessage(eventJson)) {
      await setAllDataOnly();
    } else if (!(await isPaused())) {
      if (await isWhitelistedDataOnly()) {
        var whiteListJson = _whitelist.blackOutData(eventJson);
        await _storeEvent(whiteListJson);
      } else {
        await _storeEvent(eventJson);
      }
    }

    socket.write('OK\n');
    socket.flush();
  }

  Future _storeEvent(List events) async {
    final database = await SqliteDatabase.get();
    for (var e in events) {
      print('storeEvent: $e');
      await database.insertEvent(e);
    }
  }

  void _onError(Socket socket, dynamic error) {
    print('Server: error listening to socket $socket: $error');
  }

  void _onDone(Socket socket) {
    print('Server: client disconnected');
    linux_daemon.stop();
    socket.close();
    _connectedSockets.remove(socket);
  }
}
