import 'package:pal_event_server/src/sqlite_database/sqlite_database.dart';
import 'package:taqo_common/rpc/rpc_constants.dart';
import 'package:taqo_common/service/logging_service.dart';
import 'package:taqo_common/storage/base_database.dart';
import 'package:taqo_common/storage/dart_file_storage.dart';
import 'package:taqo_common/storage/local_file_storage.dart';

import 'src/tesp_server.dart';

void main() async {
  print('Server PAL starting');
  LocalFileStorageFactory.initialize((fileName) => DartFileStorage(fileName),
      await DartFileStorage.getLocalStorageDir());
  DatabaseFactory.initialize(() => SqliteDatabase.get());
  await LoggingService.initialize(outputsToStdout: true);

  final server = PALTespServer();
  await server.serve(address: localServerHost, port: localServerPort);
  print('Server ready');
}
