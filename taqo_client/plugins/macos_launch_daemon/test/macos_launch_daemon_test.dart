import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_launch_daemon/macos_launch_daemon.dart';

void main() {
  const MethodChannel channel = MethodChannel('macos_launch_daemon');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await MacosLaunchDaemon.platformVersion, '42');
  });
}
