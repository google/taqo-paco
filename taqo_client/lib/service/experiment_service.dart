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
import 'package:taqo_client/service/experiment_paused_status_cache.dart';
import 'package:taqo_common/model/event.dart';
import 'package:taqo_common/model/experiment.dart';
import 'package:taqo_common/net/paco_api.dart';
import 'package:taqo_common/service/experiment_service_lite.dart';
import 'package:taqo_common/storage/joined_experiments_storage.dart';
import 'package:taqo_common/util/schedule_printer.dart' as schedule_printer;
import 'package:taqo_common/util/zoned_date_time.dart';

import '../service/platform_service.dart' as platform_service;
import 'alarm/taqo_alarm.dart' as taqo_alarm;

final _logger = Logger('ExperimentService');

class ExperimentService implements ExperimentServiceLite {
  final PacoApi _pacoApi;

  var _joined = Map<int, Experiment>();
  ExperimentPausedStatusCache _pausedStatusCache;

  static ExperimentService _instance;

  ExperimentService._() : _pacoApi = PacoApi();

  static Future<ExperimentService> getInstance() {
    if (_instance == null) {
      final completer = Completer<ExperimentService>();
      final temp = ExperimentService._();
      temp._loadJoinedExperiments().then((_) {
        _instance = temp;
        completer.complete(_instance);
      });
      return completer.future;
    }

    return Future.value(_instance);
  }

  Future<void> _loadJoinedExperiments() async {
    final storage = await JoinedExperimentsStorage.get();
    var experiments = await storage.readJoinedExperiments();
    _pausedStatusCache = await ExperimentPausedStatusCache.getInstance();
    await _pausedStatusCache.loadPausedStatusForExperiments(experiments);
    experiments
        .forEach((experiment) => _pausedStatusCache.restorePaused(experiment));
    _mapifyExperimentsById(experiments);
  }

  Experiment _makeExperimentFromJson(Map<String, dynamic> json) {
    var experiment = Experiment.fromJson(json);
    _pausedStatusCache.restorePaused(experiment);
    return experiment;
  }

  Future<List<Experiment>> getExperimentsFromServer() {
    return _pacoApi.getExperimentsWithSavedCredentials().then((response) {
      if (!response.isSuccess) {
        return <Experiment>[];
      }
      final experimentJson = response.body;
      List experimentJsonList;
      try {
        experimentJsonList = jsonDecode(experimentJson);
      } catch (e) {
        _logger.warning('Error decoding Experiments response: $e');
        _logger.info('Response was: "$experimentJson"');
        return <Experiment>[];
      }
      final experiments = <Experiment>[];
      for (var experimentJson in experimentJsonList) {
        var experiment;
        try {
          experiment = _makeExperimentFromJson(experimentJson);
        } catch (e) {
          _logger
              .warning('Error parsing experiment ${experimentJson['id']}: $e');
          continue;
        }
        // Don't show Experiments already joined
        if (experiment != null && !_joined.containsKey(experiment.id)) {
          experiments.add(experiment);
        }
      }
      return experiments;
    });
  }

  Future<Experiment> getExperimentFromServerById(experimentId) {
    return _pacoApi
        .getExperimentByIdWithSavedCredentials(experimentId)
        .then((response) {
      if (!response.isSuccess) {
        return null;
      }
      final experimentJson = response.body;
      try {
        var experimentJsonObj = jsonDecode(experimentJson).elementAt(0);
        return _makeExperimentFromJson(experimentJsonObj);
      } catch (e) {
        _logger.warning('Error decoding Experiments response: $e');
        _logger.info('Response was: "$experimentJson"');
        return null;
      }
    });
  }

  Future<Experiment> getPubExperimentFromServerById(experimentId) {
    return _pacoApi.getPubExperimentById(experimentId).then((response) {
      if (!response.isSuccess) {
        return null;
      }
      final experimentJson = response.body;
      try {
        var experimentJsonObj = jsonDecode(experimentJson).elementAt(0);
        return _makeExperimentFromJson(experimentJsonObj);
      } catch (e) {
        _logger.warning('Error decoding Experiments response: $e');
        _logger.info('Response was: "$experimentJson"');
        return null;
      }
    });
  }

  Future<List<Experiment>> updateJoinedExperiments() {
    return _pacoApi
        .getExperimentsByIdWithSavedCredentials(_joined.keys.toList())
        .then((response) {
      if (!response.isSuccess) {
        final experiments = <Experiment>[];
        _mapifyExperimentsById(experiments);
        saveJoinedExperiments();
        return experiments;
      }
      final experimentJson = response.body;
      List experimentJsonList;
      try {
        experimentJsonList = jsonDecode(experimentJson);
      } catch (e) {
        _logger.warning('Error decoding Experiments response: $e');
        _logger.info('Response was: "$experimentJson"');
        return <Experiment>[];
      }
      final experiments = <Experiment>[];
      for (var experimentJson in experimentJsonList) {
        var experiment = _makeExperimentFromJson(experimentJson);
        var experimentOld = _joined[experiment.id];
        if (experimentOld != null) {
          experiment.paused = experimentOld.paused;
        } else {
          _logger.warning(
              'Server has returned an experiment with id ${experiment.id},'
              'which we have not asked for.');
        }
        experiments.add(experiment);
      }

      _mapifyExperimentsById(experiments);
      saveJoinedExperiments();
      return experiments;
    });
  }

  List<Experiment> getJoinedExperiments() =>
      List<Experiment>.from(_joined.values);

  Event _createPacoEvent(Experiment experiment, PacoEventType eventType) {
    final event = Event();
    event.experimentId = experiment.id;
    event.experimentName = experiment.title;
    event.experimentVersion = experiment.version;
    event.responseTime = ZonedDateTime.now();
    event.responses = {
      "schedule": schedule_printer.createStringOfAllSchedules(experiment),
    };

    switch (eventType) {
      case PacoEventType.EXPERIMENT_JOIN:
        event.responses["joined"] = "true";
        break;
      case PacoEventType.EXPERIMENT_STOP:
        event.responses["joined"] = "false";
        break;
      case PacoEventType.EXPERIMENT_PAUSE:
        event.responses["paused"] = "true";
        break;
      case PacoEventType.EXPERIMENT_RESUME:
        event.responses["paused"] = "false";
        break;
      case PacoEventType.SCHEDULE_EDIT:
      default:
      // Nothing for now
    }

    if (experiment.recordPhoneDetails) {
      // TODO Platform implementation
    }

    return event;
  }

  Future<void> joinExperiment(Experiment experiment) async {
    _joined[experiment.id] = experiment;
    saveJoinedExperiments();
    final db = await platform_service.databaseImpl;
    db.insertEvent(_createPacoEvent(experiment, PacoEventType.EXPERIMENT_JOIN));
  }

  bool isJoined(Experiment experiment) => _joined.containsKey(experiment.id);

  Future<void> setExperimentPausedStatus(
      Experiment experiment, bool paused) async {
    await _pausedStatusCache.setPaused(experiment, paused);
    final db = await platform_service.databaseImpl;
    db.insertEvent(_createPacoEvent(
        experiment,
        paused
            ? PacoEventType.EXPERIMENT_PAUSE
            : PacoEventType.EXPERIMENT_RESUME));
    taqo_alarm.schedule();
  }

  Future<void> stopExperiment(Experiment experiment) async {
    _pausedStatusCache.removeExperiment(experiment);
    _joined.remove(experiment.id);
    await saveJoinedExperiments();
    final db = await platform_service.databaseImpl;
    db.insertEvent(_createPacoEvent(experiment, PacoEventType.EXPERIMENT_STOP));

    taqo_alarm.cancelForExperiment(experiment);
  }

  void _mapifyExperimentsById(List<Experiment> experiments) {
    _joined = Map.fromIterable(experiments, key: (e) => e.id);
  }

  Future<void> saveJoinedExperiments() async {
    final storage = await JoinedExperimentsStorage.get();
    await storage.saveJoinedExperiments(_joined.values.toList());
    taqo_alarm.schedule();
  }

  Future<void> updateExperimentSchedule(Experiment experiment) async {
    saveJoinedExperiments();

    final db = await platform_service.databaseImpl;
    db.insertEvent(_createPacoEvent(experiment, PacoEventType.SCHEDULE_EDIT));
  }

  Future<InvitationResponse> checkCode(String code) async {
    return _pacoApi.checkInvitationWithSavedCredentials(code).then((response) {
      if (!response.isSuccess) {
        return InvitationResponse.fromPaco(response);
      }

      final jsonResponse = response.body;
      var decodedResponse = jsonDecode(jsonResponse);

      if (jsonResponse.startsWith('[')) {
        return InvitationResponse.fromPaco(PacoResponse(
            PacoResponse.failure, decodedResponse["errorMessage"]));
      } else {
        return InvitationResponse.fromPaco(response,
            participantId: decodedResponse["participantId"],
            experimentId: decodedResponse["experimentId"]);
      }
    });
  }

  @override
  Future<Experiment> getExperimentById(int experimentId) async {
    var experiment = _joined[experimentId];
    if (experiment == null) {
      var storage = await JoinedExperimentsStorage.get();
      experiment = await storage.getExperimentById(experimentId);
    }
    return experiment;
  }
}

enum PacoEventType {
  EXPERIMENT_JOIN,
  SCHEDULE_EDIT,
  EXPERIMENT_STOP,
  EXPERIMENT_PAUSE,
  EXPERIMENT_RESUME
}

class InvitationResponse extends PacoResponse {
  final participantId;
  final experimentId;

  InvitationResponse.fromPaco(PacoResponse pacoResponse,
      {this.participantId, this.experimentId})
      : super(pacoResponse.statusCode, pacoResponse.statusMsg);
}
