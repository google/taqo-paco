import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:glob/glob.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class LoggingService {
  static const _MAX_LOG_FILES_COUNT = 7;
  // The ISO8601 format used by DateTime is yyyy-MM-ddTHH:mm:ss.mmmuuuZ
  static const _ISO8601_INDEX_DAY = 10;

  static String _logDirectoryPath;
  static String _logFileName;
  static File _logFile;
  static IOSink __logSink;
  static final Glob _logGlob = Glob('*.log');

  // This init() function must be called before any logging activity.
  static Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();
    _logDirectoryPath = (await getApplicationDocumentsDirectory()).path;

    // Configure log level and handler for logging package
    Logger.root.level = Level.INFO;
    Logger.root.onRecord.listen((record) {
      LoggingService.log(
          '${record.time.toUtc().toIso8601String()} ${record.level.name} [${record.loggerName}]: ${record.message}');
    });
  }

  // log file name format is yyyy-MM-dd.log
  static String _getCurrentLogFileName() =>
      '${DateTime.now().toUtc().toIso8601String().substring(0, _ISO8601_INDEX_DAY)}.log';
  static IOSink get _logSink {
    var logFileName = _getCurrentLogFileName();
    if (logFileName != _logFileName) {
      _flushCloseSink(__logSink);
      _logFileName = logFileName;
      _logFile = File(p.join(_logDirectoryPath, _logFileName));
      __logSink = _logFile.openWrite(mode: FileMode.append);
      _clearOldLogFiles();
    }
    return __logSink;
  }

  static Future<void> _flushCloseSink(IOSink sink) async {
    await sink?.flush();
    await sink?.close();
  }

  static Future<void> _clearOldLogFiles() async {
    var logFiles = <File>[
      for (var entity
          in _logGlob.listSync(root: _logDirectoryPath, followLinks: false))
        if (entity is File) entity
    ];

    if (logFiles.length > _MAX_LOG_FILES_COUNT) {
      logFiles.sort(
          (File a, File b) => p.basename(a.path).compareTo(p.basename(b.path)));
      for (var file in logFiles.take(logFiles.length - _MAX_LOG_FILES_COUNT)) {
        await file.delete();
      }
    }
  }

  static void log(String message) {
    // Output to stdout (will be captured by console), only in debug mode
    if (kDebugMode) {
      debugPrint(message);
    }
    // Output to file
    _logSink.writeln(message);
  }
}
