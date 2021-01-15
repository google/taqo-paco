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

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';

final _logger = Logger('TaqoEmailPlugin');

const _channelName = "taqo_email_plugin";
const _sendEmailMethod = "send_email";
const _toArg = "to";
const _subjectArg = "subject";

const MethodChannel _channel = MethodChannel(_channelName);

const gmailTemplate = [
  "https://mail.google.com/mail/?view=cm&fs=1&to=",
  "&su=",
];

String getEmailSubjectForExperiment(String experimentTitle) =>
    'Participant email: $experimentTitle';

Future<void> sendEmail(String to, String experimentTitle) async {
  final subject = getEmailSubjectForExperiment(experimentTitle);
  if (Platform.isLinux) {
    final subjEncode = Uri.encodeQueryComponent(subject);
    final url = gmailTemplate[0] + to + gmailTemplate[1] + subjEncode;
    if (await canLaunch(url)) {
      await launch(url);
    }
  } else {
    try {
      final res = await _channel.invokeMethod(_sendEmailMethod, {
        _toArg: to,
        _subjectArg: subject,
      });
      _logger.info("Success sending email: $res");
    } on Exception catch (e) {
      _logger.warning("Failed sending email: $e");
    }
  }
}
