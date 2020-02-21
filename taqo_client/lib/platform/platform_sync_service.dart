import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:taqo_client/service/sync_service.dart';

final logger = Logger('SyncService');

const _platform =
    const MethodChannel('com.taqo.survey.taqosurvey/sync-service');
const _notifySyncServiceMethod = 'notifySyncService';
const _runSyncServiceMethod = 'runSyncService';

void setupSyncServiceMethodChannel() {
  _platform.setMethodCallHandler((MethodCall call) async {
    switch (call.method) {
      case _runSyncServiceMethod:
        var success = await syncData();
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
  try {
    await _platform.invokeMethod(_notifySyncServiceMethod);
  } on PlatformException catch (e) {
    logger.warning("Failed calling $_notifySyncServiceMethod: '${e.message}'.");
  }
}
