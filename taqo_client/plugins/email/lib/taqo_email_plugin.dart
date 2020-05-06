import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

const _channelName = "taqo_email_plugin";
const _sendEmailMethod = "send_email";
const _toArg = "to";
const _subjectArg = "subject";

const MethodChannel _channel = const MethodChannel(_channelName);

const gmailTemplate = ["https://mail.google.com/mail/?view=cm&fs=1&to=", "&su=", ];

Future<void> sendEmail(String to, String subject) async {
  if (Platform.isLinux) {
    final subjEncode = Uri.encodeQueryComponent(subject);
    final url = gmailTemplate[0] + to + gmailTemplate[1] + subjEncode;
    if (await canLaunch(url)) {
      await launch(url);
    }
  } else {
    try {
      final res = await _channel.invokeMethod(
          _sendEmailMethod,
          {
            _toArg: to,
            _subjectArg: subject,
          }
      );
      print("Success sending email: $res");
    } on Exception catch (e) {
      print("Failed sending email: $e");
    }
  }
}