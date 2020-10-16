import 'dart:async';

import 'package:flutter/services.dart';

class MacosLaunchDaemon {
  static const MethodChannel _channel = MethodChannel('macos_launch_daemon');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
