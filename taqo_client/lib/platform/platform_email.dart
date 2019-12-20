import 'package:flutter/services.dart';

const _platform = const MethodChannel("com.taqo.survey.taqosurvey/email");
const String _sendEmailMethod = "send_email";
const String _toArg = "to";
const String _subjectArg = "subject";

Future<void> sendEmail(String to, String subject) async {
  try {
    await _platform.invokeMethod(_sendEmailMethod, {_toArg: to, _subjectArg: subject, });
  } catch (e) {
    print("Sending email failed");
  }
}
