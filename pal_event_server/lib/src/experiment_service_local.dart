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
import 'package:pal_event_server/src/experiment_cache.dart';

import 'package:taqo_common/model/experiment.dart';
import 'package:taqo_common/service/experiment_service_lite.dart';

final _logger = Logger('ExperimentServiceLocal');

class ExperimentServiceLocal implements ExperimentServiceLite {
  ExperimentCache _cache;

  static ExperimentServiceLocal _instance;

  ExperimentServiceLocal._();

  static Future<ExperimentServiceLocal> getInstance() {
    if (_instance == null) {
      final completer = Completer<ExperimentServiceLocal>();
      final temp = ExperimentServiceLocal._();
      temp._init().then((_) {
        _instance = temp;
        completer.complete(_instance);
      });
      return completer.future;
    }

    return Future.value(_instance);
  }

  Future<void> _init() async {
    _cache = await ExperimentCache.getInstance();
  }

  @override
  Future<Experiment> getExperimentById(int experimentId) async {
    var experiment = await _cache.getExperimentById(experimentId);

    if (experiment == null) {
      _logger.info(
          'Cannot find experiment $experimentId in the cache or the database. Using the fallback value...');
      experiment = Experiment()
        ..id = experimentId
        ..anonymousPublic = true;
    }
    return experiment;
  }

  Future<List<Experiment>> getJoinedExperiments() async {
    return _cache.getJoinedExperiments();
  }
}
