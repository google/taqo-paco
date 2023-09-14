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

// @dart=2.9

import 'package:logging/logging.dart';
import 'package:pal_event_server/src/experiment_service_local.dart';
import 'package:pal_event_server/src/machine_id.dart';
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
  await LoggingService.initialize(
      logFilePrefix: 'server-', outputsToStdout: true);
  _logger.info('Logging service is ready');
  DatabaseFactory.initialize(() => SqliteDatabase.get());
  ExperimentServiceLiteFactory.initialize(ExperimentServiceLocal.getInstance);
  await MachineId.initialize();

  final server = PALTespServer();
  await server.serve(address: localServerHost, port: localServerPort);
  _logger.info('Server ready');

  daemon.start();
}
