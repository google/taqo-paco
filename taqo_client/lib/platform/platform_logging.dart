import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

final logger = Logger('MethodChannel.Logging');

const _platform = const MethodChannel('com.taqo.survey.taqosurvey/logging');

void setupLoggingMethodChannel() {
  _platform.setMethodCallHandler((MethodCall call) async {
    switch (call.method) {
      case 'log':
        var arguments = call.arguments as Map;
        _log(arguments['level'], arguments['message']);
        break;
      default:
        throw MissingPluginException();
    }
  });
}

final StringLevelMap =
Map.fromIterable(Level.LEVELS, key: (e) => e.name, value: (e) => e);
void _log(String level, String message) {
  logger.log(StringLevelMap[level], message);
}
