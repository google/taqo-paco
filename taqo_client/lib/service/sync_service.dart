import 'dart:convert';

import 'package:logging/logging.dart';

import 'package:taqo_common/model/event.dart';
import 'package:taqo_common/model/event_save_outcome.dart';
import '../net/paco_api.dart';
import '../service/platform_service.dart' as platform_service;

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
    } else {
      logger.warning('Event failed to upload: ${outcomes[i].errorMessage}'
          'Event was: ${allEvents[i].toString()}');
    }
  }
  return uploaded;
}

Future<bool> syncData() async {
  logger.info("Start syncing data...");
  final db = await platform_service.databaseImpl;
  final events = await db.getUnuploadedEvents();
  final pacoApi = PacoApi();

  // TODO: handle upload limit size
  if (events.length > 0) {
    final response = await pacoApi.postEvents(jsonEncode(events));
    if (response.isSuccess) {
      final outcomes = _parseSyncResponse(response);
      if (outcomes.length == events.length) {
        final eventList = events.toList();
        await db.markEventsAsUploaded(_getUploadedEvents(
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
