import 'dart:async';

import 'package:logging/logging.dart';
import 'package:taqo_common/model/experiment.dart';
import 'package:taqo_common/storage/joined_experiments_storage.dart';

final logger = Logger('ExperimentCache');

class ExperimentCache {
  JoinedExperimentsStorage _storage;
  Map<int, Experiment> _cache = <int, Experiment>{};
  List<Experiment> _joinedExperiments = <Experiment>[];

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
    updateCacheWithJoinedExperiment(await _storage.readJoinedExperiments());
  }

  void updateCacheWithJoinedExperiment(List<Experiment> experiments) {
    _joinedExperiments = experiments;
    for (var experiment in experiments) {
      _cache[experiment.id] = experiment;
    }
  }

  List<Experiment> getJoinedExperiments() {
    return _joinedExperiments;
  }

  Future<Experiment> getExperimentById(int experimentId) async {
    var experiment = _cache[experimentId];
    if (experiment == null) {
      logger.info(
          'Cache miss for experiment $experimentId. Retrieving from the database...');
      experiment = await _storage.getExperimentById(experimentId);
    }
    if (experiment == null) {
      logger.warning('Cannot find experiment $experimentId in the database...');
    } else {
      _cache[experimentId] = experiment;
    }
    return experiment;
  }
}
