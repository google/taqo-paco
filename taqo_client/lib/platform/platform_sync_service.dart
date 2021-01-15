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

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:taqo_common/service/experiment_service_lite.dart';
import 'package:taqo_common/service/logging_service.dart';
import 'package:taqo_common/service/sync_service.dart';
import 'package:taqo_common/storage/base_database.dart';
import 'package:taqo_common/storage/local_file_storage.dart';
import 'package:workmanager/workmanager.dart';

import '../service/experiment_service.dart';
import '../service/platform_service.dart';
import '../storage/flutter_file_storage.dart';

final _logger = Logger('SyncService');

const _platform = MethodChannel('com.taqo.survey.taqosurvey/sync-service');
const _notifySyncServiceMethod = 'notifySyncService';
const _runSyncServiceMethod = 'runSyncService';

const _workManagerTaskName = 'taqoSyncService';

void _workMangerCallbackDispatcher() {
  Workmanager.executeTask((task, inputData) async {
    print("Native called background task: $task");

    // Since we are a new (background) Isolate, we need to re-initialize all
    // the important bits for [SyncService]
    WidgetsFlutterBinding.ensureInitialized();
    LocalFileStorageFactory.initialize(
        (fileName) => FlutterFileStorage(fileName),
        await FlutterFileStorage.getLocalStorageDir());
    await LoggingService.initialize(
        logFilePrefix: 'client-', outputsToStdout: kDebugMode);
    DatabaseFactory.initialize(() => databaseImpl);
    ExperimentServiceLiteFactory.initialize(ExperimentService.getInstance);

    return SyncService.syncData();
  });
}

Future setupSyncServiceMethodChannel() async {
  // PAL Event server handles sync service on desktop
  if (isTaqoDesktop) {
    return;
  }

  // TODO Can we transition iOS to use this framework?
  if (Platform.isAndroid) {
    await Workmanager.initialize(_workMangerCallbackDispatcher,
        isInDebugMode: false);
    return;
  }

  _platform.setMethodCallHandler((MethodCall call) async {
    switch (call.method) {
      case _runSyncServiceMethod:
        var success = await SyncService.syncData();
        if (!success) {
          throw PlatformException(code: 'SyncDataFailed');
        }
        break;
      default:
        throw MissingPluginException();
    }
  });
}

Future<void> notifySyncService() async {
  // PAL Event server handles sync service on desktop
  if (isTaqoDesktop) {
    return;
  }

  if (Platform.isAndroid) {
    Workmanager.registerOneOffTask(
        '${DateTime.now().millisecondsSinceEpoch}', _workManagerTaskName,
        constraints: Constraints(
          networkType: NetworkType.connected,
          //requiresBatteryNotLow: true,
          //requiresCharging: true,
          //requiresDeviceIdle: true,
          //requiresStorageNotLow: false,
        ));
    return;
  }

  try {
    await _platform.invokeMethod(_notifySyncServiceMethod);
  } on PlatformException catch (e) {
    _logger
        .warning("Failed calling $_notifySyncServiceMethod: '${e.message}'.");
  }
}
