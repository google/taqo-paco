import 'dart:async';

import 'package:flutter/services.dart';

const _channelName = "taqo_email_plugin";
const _sendEmailMethod = "send_email";
const _toArg = "to";
const _subjectArg = "subject";

const MethodChannel _channel = const MethodChannel(_channelName);

Future<void> sendEmail(String to, String subject) => _channel
    .invokeMethod(_sendEmailMethod, {
      _toArg: to,
      _subjectArg: subject,
    })
    .then((value) => print("Success sending email: $value"))
    .catchError((e, st) => print("Failed sending email: $e"));
