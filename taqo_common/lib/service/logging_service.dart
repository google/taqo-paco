import 'dart:io';

import 'package:glob/glob.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import '../storage/local_file_storage.dart';

class LoggingService {
  static const _MAX_LOG_FILES_COUNT = 7;
  // The ISO8601 format used by DateTime is yyyy-MM-ddTHH:mm:ss.mmmuuuZ
  static const _ISO8601_INDEX_DAY = 10;

  static String _logDirectoryPath;
  static String _logFileName;
  static File _logFile;
  static IOSink __logSink;
  static Glob _logGlob;
  static bool _outputsToStdout;
  static String _logFilePrefix = '';

  // This init() function must be called before any logging activity and after
  // LocalFileStorageFactory is initialized
  static Future<void> initialize({String logFilePrefix = '',
    bool outputsToStdout = true}) async {
    _outputsToStdout = outputsToStdout;
    _logFilePrefix = logFilePrefix;
    _logGlob = Glob('${_logFilePrefix}*.log');
    if (!LocalFileStorageFactory.isInitialized) {
      throw StateError("LoggingService must be initialized after LocalFileStorageFactory.");
    }
    _logDirectoryPath = LocalFileStorageFactory.localStorageDirectory.path;

    // Configure log level and handler for logging package
    Logger.root.level = Level.INFO;
    Logger.root.onRecord.listen((record) {
      LoggingService.log(
          '${record.time.toUtc().toIso8601String()} ${record.level.name} [${record.loggerName}]: ${record.message}');
    });
  }

  // log file name format is yyyy-MM-dd.log
  static String _getCurrentLogFileName() =>
      '$_logFilePrefix${DateTime.now().toUtc().toIso8601String().substring(0, _ISO8601_INDEX_DAY)}.log';
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

  // Be careful when modifying code calling the following function, since it
  // will modify its argument and its return value also depends on its argument.
  @visibleForTesting
  static Iterable<String> filterOldLogFileNames(List<String> logFileNames,
      {int maxLogFilesCount = _MAX_LOG_FILES_COUNT}) {
    if (logFileNames.length <= maxLogFilesCount) {
      return Iterable<String>.empty();
    } else {
      logFileNames.sort((a, b) => p.basename(a).compareTo(p.basename(b)));
      return logFileNames.take(logFileNames.length - maxLogFilesCount);
    }
  }

  static void _clearOldLogFiles() {
    var logFileNames = <String>[
      for (var entity
          in _logGlob.listSync(root: _logDirectoryPath, followLinks: false))
        if (entity is File) entity.path
    ];
    for (var fileName in filterOldLogFileNames(logFileNames)) {
      File(fileName).delete();
    }
  }

  static void log(String message) {
    // Output to stdout (will be captured by console)
    if (_outputsToStdout) {
      print(message);
    }
    // Output to file
    _logSink.writeln(message);
  }
}
