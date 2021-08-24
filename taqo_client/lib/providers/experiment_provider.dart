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

import 'package:flutter/foundation.dart';
import 'package:taqo_common/model/experiment.dart';

import '../service/platform_service.dart' as platform_service;
import '../service/experiment_service.dart';

class ExperimentProvider with ChangeNotifier {
  ExperimentService _service;

  List<Experiment> _experiments;
  List<Experiment> get experiments => _experiments;

  static const _pollRate = Duration(seconds: 5);
  Timer _activeUpdateTimer;

  ExperimentProvider();

  /// A [Provider] with the user's joined Experiments
  ExperimentProvider.withRunningExperiments() {
    loadRunningExperiments();
  }

  Future loadRunningExperiments() async {
    _service = await ExperimentService.getInstance();
    _experiments = _service.getJoinedExperiments();
    notifyListeners();

    platform_service.databaseImpl.then((db) {
      db.getAllNotifications().then((all) {
        for (Experiment e in _experiments) {
          final n =
              all.firstWhere((n) => n.experimentId == e.id, orElse: () => null);
          if (n != null) {
            e.active = n.isActive;
          }
        }
        notifyListeners();
      });
    });

    _activeUpdateTimer = Timer.periodic(_pollRate, _updateActive);
  }

  Future loadAvailableExperiments() async {
    _service = await ExperimentService.getInstance();
    _experiments = await _service.getExperimentsFromServer();
    notifyListeners();
  }

  @override
  void dispose() {
    if (_activeUpdateTimer != null) {
      _activeUpdateTimer.cancel();
      _activeUpdateTimer = null;
    }
    super.dispose();
  }

  Future refreshRunningExperiments() async {
    _experiments.clear();
    _experiments = null;
    notifyListeners();

    _service = await ExperimentService.getInstance();
    _experiments = await _service.updateJoinedExperiments();
    notifyListeners();

    platform_service.databaseImpl.then((db) {
      db.getAllNotifications().then((all) {
        for (Experiment e in _experiments) {
          final n =
              all.firstWhere((n) => n.experimentId == e.id, orElse: () => null);
          if (n != null) {
            e.active = n.isActive;
          }
        }
        notifyListeners();
      });
    });
  }

  /// Periodically check if experiments are active
  /// Is there a better way? Only runs while running experiments page
  /// is open, so maybe not too bad for now
  void _updateActive(Timer _) {
    platform_service.databaseImpl.then((db) {
      db.getAllNotifications().then((all) {
        for (Experiment e in _experiments) {
          final n =
              all.firstWhere((n) => n.experimentId == e.id, orElse: () => null);
          e.active = n?.isActive ?? false;
        }
        notifyListeners();
      });
    });
  }

  Future<void> setPausedAndNotifyListeners(Experiment e, bool value) async {
    await _service.setExperimentPausedStatus(e, value);
    notifyListeners();
  }

  void stopExperiment(Experiment e) {
    _service.stopExperiment(e);
    _experiments.remove(e);
    notifyListeners();
  }
}
