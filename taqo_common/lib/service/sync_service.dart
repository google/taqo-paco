import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';

import 'package:taqo_common/model/event.dart';
import 'package:taqo_common/model/event_save_outcome.dart';
import 'package:taqo_common/net/paco_api.dart';
import 'package:taqo_common/service/experiment_service_lite.dart';
import 'package:taqo_common/storage/base_database.dart';

final _logger = Logger('SyncService');

class SyncEvent {}

class SyncService {
  static final SyncService _instance = SyncService._();

  final _syncEventsController = StreamController<SyncEvent>();
  Completer<bool> _completer;

  SyncService._() {
    StreamSubscription<SyncEvent> syncEventsSubscription;
    syncEventsSubscription = _syncEventsController.stream.listen((event) {
      syncEventsSubscription.pause();
      var completer = _completer;
      _completer = null;
      __syncData().then((value) {
        completer.complete(value);
        syncEventsSubscription.resume();
      }, onError: (e, st) {
        completer.completeError(e, st);
        syncEventsSubscription.resume();
      });
    });
  }

  Future<bool> _syncData() {
    if (_completer == null) {
      _completer = Completer();
      _syncEventsController.add(SyncEvent());
    }
    return _completer.future;
  }

  static Future<bool> syncData() => _instance._syncData();

  static List<EventSaveOutcome> _parseSyncResponse(PacoResponse response) {
    final outcomes = <EventSaveOutcome>[];
    try {
      final List responseOutcomes = jsonDecode(response.body);
      for (var json in responseOutcomes) {
        outcomes.add(EventSaveOutcome.fromJson(json));
      }
    } catch (e) {
      _logger.warning(e);
    }
    return outcomes;
  }

  static List<Event> _getUploadedEvents(
      List<Event> allEvents, List<EventSaveOutcome> outcomes) {
    final uploaded = <Event>[];
    for (var i = 0; i < outcomes.length; i++) {
      if (outcomes[i].status) {
        uploaded.add(allEvents[i]);
      } else {
        _logger.warning('Event failed to upload: ${outcomes[i].errorMessage}'
            'Event was: ${allEvents[i].toString()}');
      }
    }
    return uploaded;
  }

  static Future<bool> __syncData() async {
    _logger.info("Start syncing data...");
    final db = await DatabaseFactory.makeDatabaseOrFuture();
    final events = await db.getUnuploadedEvents();
    final pacoApi = PacoApi();

    // A nested function to process the response of posting events
    // Factored this out since we need to upload public and private events
    // separately.
    Future<bool> processResponse(PacoResponse response, List<Event> events,
        {bool isPublic}) async {
      String eventType = isPublic ? 'public events' : 'private events';
      if (response.isSuccess) {
        final outcomes = _parseSyncResponse(response);
        if (outcomes.length == events.length) {
          final eventList = events.toList();
          final uploadedEvents = _getUploadedEvents(eventList, outcomes);
          _logger.info('Uploaded ${uploadedEvents.length} $eventType.');
          await db
              .markEventsAsUploaded(_getUploadedEvents(eventList, outcomes));
        } else {
          _logger.warning(
              'Event upload result length differs from number of $eventType uploaded');
        }
        _logger.info('Syncing $eventType complete.');
        return true;
      } else if (response.isFailure) {
        _logger.warning('Could not complete upload of $eventType'
            'because of the following error: '
            '${response.body}\n');
        return false;
      } else {
        _logger.warning('Could not complete upload of $eventType'
            'The server returns the following response: '
            '${response.statusCode} ${response.statusMsg}\n${response.body}\n');
        return false;
      }
    }

    // TODO: handle upload limit size
    if (events.length > 0) {
      final publicEvents = <Event>[];
      final privateEvents = <Event>[];
      final experimentServiceLite =
          await ExperimentServiceLiteFactory.makeExperimentServiceLiteOrFuture();

      for (var event in events) {
        final experiment =
            await experimentServiceLite.getExperimentById(event.experimentId);
        if (experiment.anonymousPublic) {
          publicEvents.add(event);
        } else {
          privateEvents.add(event);
        }
      }
      _logger.info(
          'Found ${publicEvents.length} public events and ${privateEvents.length} private events to upload.');

      FutureOr<bool> resultPublicFuture = publicEvents.length > 0
          ? pacoApi.postEventsPublic(jsonEncode(publicEvents)).then(
              (response) =>
                  processResponse(response, publicEvents, isPublic: true))
          : true;
      FutureOr<bool> resultPrivateFuture = privateEvents.length > 0
          ? pacoApi.postEvents(jsonEncode(privateEvents)).then((response) =>
              processResponse(response, privateEvents, isPublic: false))
          : true;
      return (await resultPrivateFuture) && (await resultPublicFuture);
    } else {
      _logger.info('There is no unsynced data.');
      return true;
    }
  }
}
