import 'dart:async';

import 'package:taqo_common/model/experiment.dart';
import 'package:taqo_common/storage/joined_experiments_storage.dart';

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

  bool restorePaused(Experiment experiment) {
    experiment.paused = _cache[experiment.id] ?? false;
  }

  Future<void> loadPausedStatusForExperiments(Iterable<Experiment> experiments) async {
    _cache = await _storage.loadPausedStatuses(experiments);
  }

  void removeExperiment(Experiment experiment) {
    _cache.remove(experiment.id);
  }

}