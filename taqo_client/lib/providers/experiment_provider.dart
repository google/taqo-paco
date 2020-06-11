import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:taqo_client/service/experiment_paused_status_cache.dart';
import 'package:taqo_common/model/experiment.dart';

import '../service/alarm/taqo_alarm.dart' as taqo_alarm;
import '../service/platform_service.dart' as platform_service;
import '../service/experiment_service.dart';

class ExperimentProvider with ChangeNotifier {
  ExperimentService _service;

  List<Experiment> _experiments;
  List<Experiment> get experiments => _experiments;

  ExperimentPausedStatusCache _pausedStatusCache;

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
    _pausedStatusCache = await ExperimentPausedStatusCache.getInstance();
    notifyListeners();

    platform_service.databaseImpl.then((db) {
      db.getAllNotifications().then((all) {
        for (Experiment e in _experiments) {
          final n = all.firstWhere((n) => n.experimentId == e.id,
              orElse: () => null);
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
          final n = all.firstWhere((n) => n.experimentId == e.id,
              orElse: () => null);
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
          final n = all.firstWhere((n) => n.experimentId == e.id, orElse: () => null);
          e.active = n?.isActive ?? false;
        }
        notifyListeners();
      });
    });
  }

  Future<void> setPausedAndNotifyListeners(Experiment e, bool value) async {
    await _pausedStatusCache.setPaused(e, value);
    notifyListeners();
    taqo_alarm.schedule();
  }

  void stopExperiment(Experiment e) {
    _service.stopExperiment(e);
    _experiments.remove(e);
    notifyListeners();
  }
}
