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

const _platform =
    const MethodChannel('com.taqo.survey.taqosurvey/sync-service');
const _notifySyncServiceMethod = 'notifySyncService';
const _runSyncServiceMethod = 'runSyncService';

const _workManagerTaskName = 'taqoSyncService';

void _workMangerCallbackDispatcher() {
  Workmanager.executeTask((task, inputData) async {
    print("Native called background task: $task");

    // Since we are a new (background) Isolate, we need to re-initialize all
    // the important bits for [SyncService]
    WidgetsFlutterBinding.ensureInitialized();
    LocalFileStorageFactory.initialize((fileName) => FlutterFileStorage(fileName),
        await FlutterFileStorage.getLocalStorageDir());
    await LoggingService.initialize(logFilePrefix: 'client-',
        outputsToStdout: kDebugMode);
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
    await Workmanager.initialize(
        _workMangerCallbackDispatcher, isInDebugMode: true);
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
    _logger.warning("Failed calling $_notifySyncServiceMethod: '${e.message}'.");
  }
}
