import 'dart:convert';

import 'package:logging/logging.dart';

import '../net/google_auth.dart';
import '../storage/flutter_file_storage.dart';
import '../storage/local_database.dart';

final logger = Logger('SyncService');

Future<bool> syncData() async {
  logger.info("Start syncing data...");
  final storage = await LocalDatabase.get(FlutterFileStorage(LocalDatabase.dbFilename));
  final events = await storage.getUnuploadedEvents();
  final gAuth = GoogleAuth();

  // TODO: handle upload limit size
  if (events.length > 0) {
    final response = await gAuth.postEvents(jsonEncode(events));
    if (response.isSuccess) {
      await storage.markEventsAsUploaded(events);
      logger.info('Syncing complete.');
      return true;
    } else if (response.isFailure) {
      logger.warning('Could not complete upload of events '
          'because of the following error: '
          '${response.body}\n');
      return false;
    } else {
      logger.warning('Could not complete upload of events. '
          'The server returns the following response: '
          '${response.statusCode} ${response.statusMsg}\n${response.body}\n');
      return false;
    }
  } else {
    logger.info('There is no unsynced data.');
    return true;
  }
}
