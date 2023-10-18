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

import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';

import 'package:taqo_common/model/event.dart';
import 'package:taqo_common/model/event_save_outcome.dart';
import 'package:taqo_common/net/paco_api.dart';
import 'package:taqo_common/service/experiment_service_lite.dart';
import 'package:taqo_common/storage/base_database.dart';

final _logger = Logger('SyncService');

List<EventSaveOutcome> _parseSyncResponse(PacoResponse response) {
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

List<Event> _getUploadedEvents(
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

Future<bool> processResponse(PacoResponse response, List<Event> events,
    {bool isPublic}) async {
  final db = await DatabaseFactory.makeDatabaseOrFuture();
  String eventType = isPublic ? 'public events' : 'private events';
  if (response.isSuccess) {
    final outcomes = _parseSyncResponse(response);
    if (outcomes.length == events.length) {
      final uploadedEvents = _getUploadedEvents(events, outcomes);
      _logger.info('Uploaded ${uploadedEvents.length} $eventType.');
      await db.markEventsAsUploaded(uploadedEvents);
    } else {
      _logger.warning(
          'Event upload result length differs from number of $eventType uploaded');
    }
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

Future<void> sendInBatch(List<Event> events,
    {bool isPublic, int batchSize}) async {
  final pacoApi = PacoApi();
  int sentCount = 0;
  if (batchSize <= 0) {
    batchSize = events.length;
  }
  while (sentCount < events.length) {
    final batch = events.skip(sentCount).take(batchSize).toList();
    final batchEncoded = jsonEncode(batch);
    final response = isPublic
        ? await pacoApi.postEventsPublic(batchEncoded)
        : await pacoApi.postEvents(batchEncoded);
    await processResponse(response, batch, isPublic: isPublic);
    sentCount += batchSize;
  }
}

Future<void> syncData([int batchSize = 0]) async {
  _logger.info("Start syncing data...");
  final db = await DatabaseFactory.makeDatabaseOrFuture();
  final events = await db.getUnuploadedEvents();
  final pacoApi = PacoApi();

  if (events.isNotEmpty) {
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
    await sendInBatch(publicEvents, batchSize: batchSize, isPublic: true);
    await sendInBatch(privateEvents, batchSize: batchSize, isPublic: false);
  } else {
    _logger.info('There is no unsynced data.');
  }
}
