import 'dart:convert';
import 'dart:io';

import 'constants.dart';
import 'event_uploader.dart';
import 'pal_command.dart';
import 'whitelist.dart';

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
        _addNewConnection(socket);
      }, onError: (e) {
        print('Error is serverSocket.listen(): $e');
      });
    }).catchError((e) {
      print('Error in ServerSocket.bind(): $e');
    });
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
        await storeEvent(whiteListJson);
      } else {
        await storeEvent(eventJson);
      }
    }

    socket.write('OK\n');
    socket.flush();
  }

  void _onError(Socket socket, dynamic error) {
    print('Server: error listening to socket $socket: $error');
  }

  void _onDone(Socket socket) {
    print('Server: client disconnected');
    socket.close();
    _connectedSockets.remove(socket);
  }

  void _addNewConnection(Socket socket) {
    print('Server: client connected');
    _connectedSockets.add(socket);
    socket.listen((bytes) => _listen(socket, bytes),
        onError: (err) => _onError(socket, err), onDone: () => _onDone(socket));
  }

  void _shutdownServer() {
    for (var socket in _connectedSockets) {
      socket.close();
    }
    _serverSocket.close();
  }
}
