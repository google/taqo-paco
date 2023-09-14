// Copyright 2023 Google LLC
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

import 'package:taqo_common/model/experiment.dart';
import 'package:taqo_common/storage/joined_experiments_storage.dart';

// TODO(#189): tech debt
// This class is duplicated from the Taqo client code for a fast
// implementation of a standalone Taqo CLI client. The class is to support
// pausing/resuming experiments. For a CLI client, such cache system is not
// necessary and should be removed.
class ExperimentPausedStatusCache {
  JoinedExperimentsStorage _storage;
  Map<int, bool> _cache = <int, bool>{};

  static ExperimentPausedStatusCache _instance;

  ExperimentPausedStatusCache._();

  static Future<ExperimentPausedStatusCache> getInstance() {
    if (_instance == null) {
      final completer = Completer<ExperimentPausedStatusCache>();
      final temp = ExperimentPausedStatusCache._();
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
  }

  Future<void> setPaused(Experiment experiment, bool paused) async {
    experiment.paused = paused;
    _cache[experiment.id] = paused;
    await _storage.savePausedStatus(experiment, paused);
  }

  void restorePaused(Experiment experiment) {
    experiment.paused = _cache[experiment.id] ?? false;
  }

  Future<void> loadPausedStatusForExperiments(
      Iterable<Experiment> experiments) async {
    _cache = await _storage.loadPausedStatuses(experiments);
  }

  void removeExperiment(Experiment experiment) {
    _cache.remove(experiment.id);
  }
}
