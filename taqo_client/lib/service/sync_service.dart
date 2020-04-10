import 'dart:convert';

import 'package:logging/logging.dart';

import '../model/event.dart';
import '../model/event_save_outcome.dart';
import '../net/google_auth.dart';
import '../storage/flutter_file_storage.dart';
import '../storage/local_database.dart';

final logger = Logger('SyncService');

List<EventSaveOutcome> _parseSyncResponse(PacoResponse response) {
  final outcomes = <EventSaveOutcome>[];
  try {
    //print(response.body);
    final List responseOutcomes = jsonDecode(response.body);
    //print(responseOutcomes);
    for (var json in responseOutcomes) {
      //print(json);
      outcomes.add(EventSaveOutcome.fromJson(json));
    }
  } catch (e) {
    print(e);
  }
  //print(outcomes);
  return outcomes;
}

List<Event> _getUploadedEvents(List<Event> allEvents,
    List<EventSaveOutcome> outcomes) {
  final uploaded = <Event>[];
  for (var i = 0; i < outcomes.length; i++) {
    if (outcomes[i].status) {
      uploaded.add(allEvents[i]);
    }
  }
  return uploaded;
}

Future<bool> syncData() async {
  logger.info("Start syncing data...");
  final storage = await LocalDatabase.get(FlutterFileStorage(LocalDatabase.dbFilename));
  final events = await storage.getUnuploadedEvents();
  final gAuth = GoogleAuth();

  // TODO: handle upload limit size
  if (events.length > 0) {
    final response = await gAuth.postEvents(jsonEncode(events));
    if (response.isSuccess) {
      final outcomes = _parseSyncResponse(response);
      if (outcomes.length == events.length) {
        final eventList = events.toList();
        await storage.markEventsAsUploaded(_getUploadedEvents(
            eventList, outcomes));
      } else {
        logger.warning(
            'Event upload result length differs from number of Events uploaded');
      }
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
