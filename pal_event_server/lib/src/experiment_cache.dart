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

import 'dart:async';

import 'package:logging/logging.dart';
import 'package:taqo_common/model/experiment.dart';
import 'package:taqo_common/storage/joined_experiments_storage.dart';

final _logger = Logger('ExperimentCache');

class ExperimentCache {
  JoinedExperimentsStorage _storage;
  Map<int, Experiment> _cache = <int, Experiment>{};
  List<int> _joinedExperimentIds = <int>[];

  static ExperimentCache _instance;

  ExperimentCache._();

  static Future<ExperimentCache> getInstance() {
    if (_instance == null) {
      final completer = Completer<ExperimentCache>();
      final temp = ExperimentCache._();
      temp._init().then((_) {
        _instance = temp;
        completer.complete(_instance);
      });
      return completer.future;
    }

    return Future.value(_instance);
  }

  Future<void> _init() async {
    _storage = await JoinedExperimentsStorage.get();
    List<Experiment> experiments = await _storage.readJoinedExperiments();
    Map<int, bool> pausedStatuses =
        await _storage.loadPausedStatuses(experiments);
    for (var experiment in experiments) {
      experiment.paused = pausedStatuses[experiment.id] ?? false;
    }
    updateCacheWithJoinedExperiment(experiments);
  }

  void updateCacheWithJoinedExperiment(List<Experiment> experiments) {
    _joinedExperimentIds.clear();
    for (var experiment in experiments) {
      _joinedExperimentIds.add(experiment.id);
      _cache[experiment.id] = experiment;
    }
  }

  List<Experiment> getJoinedExperiments() {
    return [
      for (var experimentId in _joinedExperimentIds) _cache[experimentId]
    ];
  }

  Future<Experiment> getExperimentById(int experimentId) async {
    var experiment = _cache[experimentId];
    if (experiment == null) {
      _logger.info(
          'Cache miss for experiment $experimentId. Retrieving from the database...');
      experiment = await _storage.getExperimentById(experimentId);
    }
    if (experiment == null) {
      _logger
          .warning('Cannot find experiment $experimentId in the database...');
    } else {
      _cache[experimentId] = experiment;
    }
    return experiment;
  }
}
