import 'dart:io';

import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:taqo_common/service/sync_service.dart';

final _logger = Logger('SyncService');

const _platform =
    const MethodChannel('com.taqo.survey.taqosurvey/sync-service');
const _notifySyncServiceMethod = 'notifySyncService';
const _runSyncServiceMethod = 'runSyncService';

void setupSyncServiceMethodChannel() {
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
  // TODO on linux and Android
  if (Platform.isLinux || Platform.isAndroid) return;
  try {
    await _platform.invokeMethod(_notifySyncServiceMethod);
  } on PlatformException catch (e) {
    _logger.warning("Failed calling $_notifySyncServiceMethod: '${e.message}'.");
  }
}
