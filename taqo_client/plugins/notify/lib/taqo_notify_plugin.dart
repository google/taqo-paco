import 'dart:async';

import 'package:flutter/services.dart';

const _channel = MethodChannel('taqo_notify_plugin');
const _initialize = 'initialize';
const _notify = 'notify';
const _cancel = 'cancel';
const _handleCallback = 'handle';

const _idArg = 'id';
const _titleArg = 'title';
const _bodyArg = 'body';
const _payloadArg = 'payload';

typedef OpenSurvey = Future<void> Function(int);
OpenSurvey _func;

Future<bool> initialize(OpenSurvey func) async {
  _channel.setMethodCallHandler(_callbackHandler);
  _func = func;

  final r = await _channel.invokeMethod<bool>(_initialize);
  return (r == null) ? false : r;
}

Future<bool> showNotification(int id, String title, String body) async {
  if (_func == null) return false;
  final args = <String, dynamic>{
    _titleArg: title,
    _bodyArg: body,
    _payloadArg: id,
  };
  final r = await _channel.invokeMethod<bool>(_notify, args);
  return (r == null) ? false : r;
}

Future<bool> cancel(int id) async {
  if (_func == null) return false;
  final args = <String, dynamic>{
    _idArg: id,
  };
  final r = await _channel.invokeMethod<bool>(_cancel, args);
  return (r == null) ? false : r;
}

Future<Null> _callbackHandler(MethodCall methodCall) async {
  if (_handleCallback == methodCall.method) {
    final id = methodCall.arguments;
    _func(id);
  }
  return null;
}
