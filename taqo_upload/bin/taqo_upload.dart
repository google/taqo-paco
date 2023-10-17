import 'package:taqo_upload/taqo_upload.dart' as taqo_upload;

import 'dart:io';

import 'package:logging/logging.dart';
import 'package:pal_event_server/src/experiment_service_local.dart';
import 'package:pal_event_server/src/sqlite_database/sqlite_database.dart';
import 'package:taqo_common/service/experiment_service_lite.dart';
import 'package:taqo_common/service/logging_service.dart';
import 'package:taqo_common/storage/base_database.dart';
import 'package:taqo_common/storage/dart_file_storage.dart';
import 'package:taqo_common/storage/local_file_storage.dart';

const _defaultBatchSize = 20;
final _usageString =
    'Usage: ${Platform.script.pathSegments.last} [batch_size (default 20)]\n';
final _logger = Logger('EmergencyUploader');

void main(List<String> arguments) async {
  int batchSize;
  final executable = Platform.script.pathSegments.last;
  if (arguments.length > 1) {
    stderr.write(_usageString);
    exit(1);
  }

  if (arguments.length == 1) {
    try {
      batchSize = int.parse(arguments[0]);
    } on FormatException {
      stderr.write(_usageString);
      stderr.write('batch_size must be an integer\n');
      exit(1);
    }
  } else {
    // arguments.length == 0
    batchSize = _defaultBatchSize;
  }
  LocalFileStorageFactory.initialize((fileName) => DartFileStorage(fileName),
      await DartFileStorage.getLocalStorageDir());
  await LoggingService.initialize(
      logFilePrefix: 'emergency-uploader-', outputsToStdout: true);
  _logger.info('Logging service is ready');
  DatabaseFactory.initialize(() => SqliteDatabase.get());
  ExperimentServiceLiteFactory.initialize(ExperimentServiceLocal.getInstance);

  await taqo_upload.syncData(batchSize);
}
