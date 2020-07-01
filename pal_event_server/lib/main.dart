import 'dart:io';

import 'package:logging/logging.dart';
import 'package:pal_event_server/src/experiment_service_local.dart';
import 'package:pal_event_server/src/sqlite_database/sqlite_database.dart';
import 'package:taqo_common/rpc/rpc_constants.dart';
import 'package:taqo_common/service/experiment_service_lite.dart';
import 'package:taqo_common/service/logging_service.dart';
import 'package:taqo_common/storage/base_database.dart';
import 'package:taqo_common/storage/dart_file_storage.dart';
import 'package:taqo_common/storage/local_file_storage.dart';

import 'src/daemon/daemon.dart' as daemon;
import 'src/tesp_server.dart';

final _logger = Logger('Main');

void main() async {
  print('Server PAL starting...');
  LocalFileStorageFactory.initialize((fileName) => DartFileStorage(fileName),
      await DartFileStorage.getLocalStorageDir());
  await LoggingService.initialize(logFilePrefix: 'server-',
      outputsToStdout: true);
  _logger.info('Logging service is ready');
  DatabaseFactory.initialize(() => SqliteDatabase.get());
  ExperimentServiceLiteFactory.initialize(ExperimentServiceLocal.getInstance);

  final server = PALTespServer();
  await server.serve(address: localServerHost, port: localServerPort);
  _logger.info('Server ready');

  daemon.start();
}
