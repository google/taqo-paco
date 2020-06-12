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
    Map<int, bool> pausedStatuses = await _storage.loadPausedStatuses(experiments);
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
    return [for (var experimentId in _joinedExperimentIds) _cache[experimentId]];
  }

  Future<Experiment> getExperimentById(int experimentId) async {
    var experiment = _cache[experimentId];
    if (experiment == null) {
      _logger.info(
          'Cache miss for experiment $experimentId. Retrieving from the database...');
      experiment = await _storage.getExperimentById(experimentId);
    }
    if (experiment == null) {
      _logger.warning('Cannot find experiment $experimentId in the database...');
    } else {
      _cache[experimentId] = experiment;
    }
    return experiment;
  }
}
