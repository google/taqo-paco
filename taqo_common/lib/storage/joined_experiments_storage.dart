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
import 'package:taqo_common/storage/base_database.dart';

final _logger = Logger('JoinedExperimentStorage');

class JoinedExperimentsStorage {
  static Completer<JoinedExperimentsStorage> _completer;
  static JoinedExperimentsStorage _instance;

  BaseDatabase _db;

  JoinedExperimentsStorage._();

  static Future<JoinedExperimentsStorage> get() {
    if (_completer != null && !_completer.isCompleted) {
      return _completer.future;
    }
    if (_instance == null) {
      _completer = Completer<JoinedExperimentsStorage>();
      final temp = JoinedExperimentsStorage._();
      temp._initialize().then((_) {
        _instance = temp;
        _completer.complete(_instance);
      });
      return _completer.future;
    }
    return Future.value(_instance);
  }

  Future _initialize() async {
    _db = await DatabaseFactory.makeDatabaseOrFuture();
  }

  Future<List<Experiment>> readJoinedExperiments() async {
    try {
      return _db.getJoinedExperiments();
    } catch (e) {
      _logger.warning("Error loading joined experiments: $e");
      return [];
    }
  }

  Future<void> saveJoinedExperiments(List<Experiment> experiments) async {
    await _db.saveJoinedExperiments(experiments);
  }

  Future<Experiment> getExperimentById(int experimentId) {
    return _db.getExperimentById(experimentId);
  }

  Future<void> savePausedStatus(Experiment experiment, bool paused) async {
    await _db.setExperimentPausedStatus(experiment, paused);
  }

  Future<Map<int, bool>> loadPausedStatuses(
      Iterable<Experiment> experiments) async {
    return await _db.getExperimentsPausedStatus(experiments);
  }
}
