import 'dart:developer' as developer;

import 'package:flutter/services.dart';
import 'package:taqo_client/service/sync_service.dart';

const _platform =
    const MethodChannel("com.taqo.survey.taqosurvey/sync-service");
const _notifySyncServiceMethod = 'notifySyncService';
const _runSyncServiceMethod = 'runSyncService';

void setupSyncServiceMethodChannel() {
  _platform.setMethodCallHandler((MethodCall call) async {
    switch (call.method) {
      case _runSyncServiceMethod:
        await syncData();
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
    developer.log("Failed calling $_notifySyncServiceMethod: '${e.message}'.");
  }
}
